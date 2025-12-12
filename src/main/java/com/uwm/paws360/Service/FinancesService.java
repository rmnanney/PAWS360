package com.uwm.paws360.Service;

import com.uwm.paws360.DTO.Finances.*;
import com.uwm.paws360.Entity.Finances.*;
import com.uwm.paws360.Entity.UserTypes.Student;
import com.uwm.paws360.JPARepository.Finances.*;
import com.uwm.paws360.JPARepository.User.StudentRepository;
import org.springframework.transaction.annotation.Transactional;
import jakarta.persistence.EntityNotFoundException;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
@Transactional(readOnly = true)
public class FinancesService {

    private final StudentRepository studentRepository;
    private final FinancialAccountRepository financialAccountRepository;
    private final AccountTransactionRepository transactionRepository;
    private final AidAwardRepository aidAwardRepository;
    private final PaymentPlanRepository paymentPlanRepository;

    public FinancesService(StudentRepository studentRepository,
                           FinancialAccountRepository financialAccountRepository,
                           AccountTransactionRepository transactionRepository,
                           AidAwardRepository aidAwardRepository,
                           PaymentPlanRepository paymentPlanRepository) {
        this.studentRepository = studentRepository;
        this.financialAccountRepository = financialAccountRepository;
        this.transactionRepository = transactionRepository;
        this.aidAwardRepository = aidAwardRepository;
        this.paymentPlanRepository = paymentPlanRepository;
    }

    public FinancesSummaryResponseDTO getSummary(Integer studentId) {
        Student s = studentRepository.findById(studentId)
                .orElseThrow(() -> new EntityNotFoundException("Student not found for id " + studentId));
        FinancialAccount acc = financialAccountRepository.findByStudent(s)
                .orElseGet(() -> {
                    FinancialAccount created = new FinancialAccount();
                    created.setStudent(s);
                    return financialAccountRepository.save(created);
                });
        // Derive balances from transactions and aid so the summary stays accurate
        var txns = transactionRepository.findByStudentOrderByPostedAtDesc(s);

        BigDecimal charges = txns.stream()
                .filter(t -> t.getStatus() == AccountTransaction.Status.POSTED && t.getType() == AccountTransaction.Type.CHARGE)
                .map(AccountTransaction::getAmount)
                .filter(java.util.Objects::nonNull)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        BigDecimal credits = txns.stream()
                .filter(t -> t.getStatus() == AccountTransaction.Status.POSTED && t.getType() == AccountTransaction.Type.CREDIT)
                .map(AccountTransaction::getAmount)
                .filter(java.util.Objects::nonNull)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        BigDecimal payments = txns.stream()
                .filter(t -> t.getStatus() == AccountTransaction.Status.POSTED && t.getType() == AccountTransaction.Type.PAYMENT)
                .map(AccountTransaction::getAmount)
                .filter(java.util.Objects::nonNull)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        var awards = aidAwardRepository.findByStudent(s).stream()
                .filter(a -> a.getStatus() != AidAward.AidStatus.CANCELLED)
                .collect(Collectors.toList());
        BigDecimal disbursedAid = awards.stream()
                .map(AidAward::getAmountDisbursed)
                .filter(java.util.Objects::nonNull)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        BigDecimal acceptedAid = awards.stream()
                .map(AidAward::getAmountAccepted)
                .filter(java.util.Objects::nonNull)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        BigDecimal pendingAid = acceptedAid.subtract(disbursedAid);
        if (pendingAid.compareTo(BigDecimal.ZERO) < 0) pendingAid = BigDecimal.ZERO; // guard against negatives

        boolean hasChargeOrCredit = (charges.compareTo(BigDecimal.ZERO) > 0) || (credits.compareTo(BigDecimal.ZERO) > 0);
        BigDecimal accountBalance = hasChargeOrCredit
                ? charges.subtract(credits).subtract(payments).subtract(disbursedAid)
                : acc.getAccountBalance().subtract(payments).subtract(disbursedAid);

        // Last payment derived from latest posted PAYMENT
        Optional<AccountTransaction> lastPayment = txns.stream()
                .filter(t -> t.getStatus() == AccountTransaction.Status.POSTED && t.getType() == AccountTransaction.Type.PAYMENT)
                .findFirst();

        BigDecimal chargesDue = accountBalance.compareTo(BigDecimal.ZERO) > 0 ? accountBalance : BigDecimal.ZERO;
        return new FinancesSummaryResponseDTO(
                chargesDue,
                accountBalance,
                pendingAid,
                lastPayment.map(AccountTransaction::getAmount).orElse(acc.getLastPaymentAmount()),
                lastPayment.map(AccountTransaction::getPostedAt).orElse(acc.getLastPaymentAt()),
                acc.getDueDate());
    }

    public List<TransactionDTO> listTransactions(Integer studentId) {
        Student s = studentRepository.findById(studentId)
                .orElseThrow(() -> new EntityNotFoundException("Student not found for id " + studentId));
        return transactionRepository.findByStudentOrderByPostedAtDesc(s)
                .stream()
                .map(t -> new TransactionDTO(
                        t.getId(), t.getPostedAt(), t.getDueDate(), t.getDescription(), t.getAmount(), t.getType(), t.getStatus()
                ))
                .collect(Collectors.toList());
    }

    public AidOverviewDTO getAidOverview(Integer studentId) {
        Student s = studentRepository.findById(studentId)
                .orElseThrow(() -> new EntityNotFoundException("Student not found for id " + studentId));
        var awards = aidAwardRepository.findByStudent(s);
        var list = awards.stream().map(a -> new AidAwardDTO(
                a.getId(), a.getType(), a.getDescription(), a.getAmountOffered(), a.getAmountAccepted(), a.getAmountDisbursed(), a.getStatus(), a.getTerm(), a.getAcademicYear()
        )).collect(Collectors.toList());
        var effectiveAwards = awards.stream()
                .filter(a -> a.getStatus() != AidAward.AidStatus.CANCELLED)
                .collect(Collectors.toList());
        BigDecimal offered = effectiveAwards.stream().map(AidAward::getAmountOffered).filter(java.util.Objects::nonNull).reduce(BigDecimal.ZERO, BigDecimal::add);
        BigDecimal accepted = effectiveAwards.stream().map(AidAward::getAmountAccepted).filter(java.util.Objects::nonNull).reduce(BigDecimal.ZERO, BigDecimal::add);
        BigDecimal disbursed = effectiveAwards.stream().map(AidAward::getAmountDisbursed).filter(java.util.Objects::nonNull).reduce(BigDecimal.ZERO, BigDecimal::add);
        return new AidOverviewDTO(offered, accepted, disbursed, list);
    }

    public List<PaymentPlanDTO> listPaymentPlans(Integer studentId) {
        Student s = studentRepository.findById(studentId)
                .orElseThrow(() -> new EntityNotFoundException("Student not found for id " + studentId));
        return paymentPlanRepository.findByStudent(s).stream()
                .map(p -> new PaymentPlanDTO(
                        p.getId(), p.getName(), p.getTotalAmount(), p.getMonthlyPayment(), p.getRemainingPayments(), p.getNextPaymentDate(), p.getStatus()
                ))
                .collect(Collectors.toList());
    }
}
