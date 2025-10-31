package com.uwm.paws360.Service;

import com.uwm.paws360.DTO.Finances.*;
import com.uwm.paws360.Entity.Finances.*;
import com.uwm.paws360.Entity.UserTypes.Student;
import com.uwm.paws360.JPARepository.Finances.*;
import com.uwm.paws360.JPARepository.User.StudentRepository;
import jakarta.persistence.EntityNotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;
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
                .orElseThrow(() -> new EntityNotFoundException("Financial account not found for student id " + studentId));
        return new FinancesSummaryResponseDTO(
                acc.getChargesDue(),
                acc.getAccountBalance(),
                acc.getPendingAid(),
                acc.getLastPaymentAmount(),
                acc.getLastPaymentAt(),
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
        BigDecimal offered = awards.stream().map(AidAward::getAmountOffered).filter(java.util.Objects::nonNull).reduce(BigDecimal.ZERO, BigDecimal::add);
        BigDecimal accepted = awards.stream().map(AidAward::getAmountAccepted).filter(java.util.Objects::nonNull).reduce(BigDecimal.ZERO, BigDecimal::add);
        BigDecimal disbursed = awards.stream().map(AidAward::getAmountDisbursed).filter(java.util.Objects::nonNull).reduce(BigDecimal.ZERO, BigDecimal::add);
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

