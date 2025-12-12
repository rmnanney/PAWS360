package com.uwm.paws360.Controller;

import com.uwm.paws360.DTO.Finances.*;
import com.uwm.paws360.Entity.Finances.*;
import com.uwm.paws360.Entity.UserTypes.Student;
import com.uwm.paws360.JPARepository.Finances.*;
import com.uwm.paws360.JPARepository.User.StudentRepository;
import com.uwm.paws360.Service.FinancesService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

@RestController
@RequestMapping("/finances/admin")
public class FinancesAdminController {

    private final StudentRepository studentRepository;
    private final FinancialAccountRepository financialAccountRepository;
    private final AccountTransactionRepository transactionRepository;
    private final AidAwardRepository aidAwardRepository;
    private final PaymentPlanRepository paymentPlanRepository;
    private final FinancesService financesService;

    public FinancesAdminController(StudentRepository studentRepository,
                                   FinancialAccountRepository financialAccountRepository,
                                   AccountTransactionRepository transactionRepository,
                                   AidAwardRepository aidAwardRepository,
                                   PaymentPlanRepository paymentPlanRepository,
                                   FinancesService financesService) {
        this.studentRepository = studentRepository;
        this.financialAccountRepository = financialAccountRepository;
        this.transactionRepository = transactionRepository;
        this.aidAwardRepository = aidAwardRepository;
        this.paymentPlanRepository = paymentPlanRepository;
        this.financesService = financesService;
    }

    @PostMapping("/students/{studentId}/account")
    public ResponseEntity<FinancesSummaryResponseDTO> upsertAccount(@PathVariable Integer studentId,
                                                                    @Valid @RequestBody UpsertFinancialAccountRequestDTO req) {
        Student s = studentRepository.findById(studentId)
                .orElseThrow(() -> new jakarta.persistence.EntityNotFoundException("Student not found for id " + studentId));
        FinancialAccount acc = financialAccountRepository.findByStudent(s).orElse(new FinancialAccount());
        acc.setStudent(s);
        acc.setAccountBalance(req.accountBalance());
        acc.setChargesDue(req.chargesDue());
        acc.setPendingAid(req.pendingAid());
        acc.setLastPaymentAmount(req.lastPaymentAmount());
        acc.setLastPaymentAt(req.lastPaymentAt());
        acc.setDueDate(req.dueDate());
        FinancialAccount saved = financialAccountRepository.save(acc);
        return ResponseEntity.ok(new FinancesSummaryResponseDTO(
                saved.getChargesDue(), saved.getAccountBalance(), saved.getPendingAid(),
                saved.getLastPaymentAmount(), saved.getLastPaymentAt(), saved.getDueDate()
        ));
    }

    @PostMapping("/students/{studentId}/transactions")
    public ResponseEntity<TransactionDTO> createTransaction(@PathVariable Integer studentId,
                                                            @Valid @RequestBody CreateTransactionRequestDTO req) {
        Student s = studentRepository.findById(studentId)
                .orElseThrow(() -> new jakarta.persistence.EntityNotFoundException("Student not found for id " + studentId));
        // Ensure account exists so downstream balance adjustments succeed
        financialAccountRepository.findByStudent(s).orElseGet(() -> {
            FinancialAccount created = new FinancialAccount();
            created.setStudent(s);
            created.setAccountBalance(java.math.BigDecimal.ZERO);
            created.setChargesDue(java.math.BigDecimal.ZERO);
            return financialAccountRepository.save(created);
        });
        AccountTransaction t = new AccountTransaction();
        t.setStudent(s);
        // Cap payments to the remaining balance to avoid overpayment
        if (req.type() == AccountTransaction.Type.PAYMENT && req.status() == AccountTransaction.Status.POSTED) {
            var summary = financesService.getSummary(studentId);
            java.math.BigDecimal due = java.util.Optional.ofNullable(summary.accountBalance()).orElse(java.math.BigDecimal.ZERO);
            if (due.signum() <= 0) {
                return ResponseEntity.badRequest().build();
            }
            java.math.BigDecimal requested = req.amount();
            java.math.BigDecimal toPay = requested.min(due);
            t.setAmount(toPay);
            if (requested.compareTo(toPay) > 0) {
                String desc = (req.description() != null ? req.description() + " " : "").trim();
                t.setDescription((desc + "(capped to remaining balance)").trim());
            }
        } else {
            t.setAmount(req.amount());
        }
        t.setType(req.type());
        t.setStatus(req.status());
        if (t.getDescription() == null) t.setDescription(req.description());
        if (req.postedAt() != null) t.setPostedAt(req.postedAt());
        t.setDueDate(req.dueDate());
        AccountTransaction saved = transactionRepository.save(t);
        // If posted, adjust stored balances to keep legacy views consistent
        if (saved.getStatus() == AccountTransaction.Status.POSTED) {
            financialAccountRepository.findByStudent(s).ifPresent(acc -> {
                switch (saved.getType()) {
                    case PAYMENT:
                        acc.setLastPaymentAmount(saved.getAmount());
                        acc.setLastPaymentAt(saved.getPostedAt());
                        acc.setAccountBalance(acc.getAccountBalance().subtract(saved.getAmount()));
                        acc.setChargesDue(acc.getChargesDue().subtract(saved.getAmount()));
                        break;
                    case CHARGE:
                        acc.setAccountBalance(acc.getAccountBalance().add(saved.getAmount()));
                        acc.setChargesDue(acc.getChargesDue().add(saved.getAmount()));
                        break;
                    case CREDIT:
                        acc.setAccountBalance(acc.getAccountBalance().subtract(saved.getAmount()));
                        acc.setChargesDue(acc.getChargesDue().subtract(saved.getAmount()));
                        break;
                }
                // Prevent negative chargesDue for stored field (summary derives true values anyway)
                if (acc.getChargesDue().signum() < 0) {
                    acc.setChargesDue(java.math.BigDecimal.ZERO);
                }
                financialAccountRepository.save(acc);
            });
        }
        return ResponseEntity.ok(new TransactionDTO(saved.getId(), saved.getPostedAt(), saved.getDueDate(),
                saved.getDescription(), saved.getAmount(), saved.getType(), saved.getStatus()));
    }

    @PostMapping("/students/{studentId}/aid")
    public ResponseEntity<AidAwardDTO> createAid(@PathVariable Integer studentId,
                                                 @Valid @RequestBody CreateAidAwardRequestDTO req) {
        Student s = studentRepository.findById(studentId)
                .orElseThrow(() -> new jakarta.persistence.EntityNotFoundException("Student not found for id " + studentId));
        AidAward a = new AidAward();
        a.setStudent(s);
        a.setType(req.type());
        a.setDescription(req.description());
        if (req.amountOffered() != null) a.setAmountOffered(req.amountOffered());
        if (req.amountAccepted() != null) a.setAmountAccepted(req.amountAccepted());
        if (req.amountDisbursed() != null) a.setAmountDisbursed(req.amountDisbursed());
        if (req.status() != null) a.setStatus(req.status());
        a.setTerm(req.term());
        a.setAcademicYear(req.academicYear());
        AidAward saved = aidAwardRepository.save(a);
        return ResponseEntity.ok(new AidAwardDTO(saved.getId(), saved.getType(), saved.getDescription(),
                saved.getAmountOffered(), saved.getAmountAccepted(), saved.getAmountDisbursed(), saved.getStatus(),
                saved.getTerm(), saved.getAcademicYear()));
    }

    @PostMapping("/students/{studentId}/payment-plans")
    public ResponseEntity<PaymentPlanDTO> createPaymentPlan(@PathVariable Integer studentId,
                                                            @Valid @RequestBody CreatePaymentPlanRequestDTO req) {
        Student s = studentRepository.findById(studentId)
                .orElseThrow(() -> new jakarta.persistence.EntityNotFoundException("Student not found for id " + studentId));
        PaymentPlan p = new PaymentPlan();
        p.setStudent(s);
        p.setName(req.name());
        p.setTotalAmount(req.totalAmount());
        p.setMonthlyPayment(req.monthlyPayment());
        p.setRemainingPayments(req.remainingPayments());
        p.setNextPaymentDate(req.nextPaymentDate());
        if (req.status() != null) p.setStatus(req.status());
        PaymentPlan saved = paymentPlanRepository.save(p);
        return ResponseEntity.ok(new PaymentPlanDTO(saved.getId(), saved.getName(), saved.getTotalAmount(),
                saved.getMonthlyPayment(), saved.getRemainingPayments(), saved.getNextPaymentDate(), saved.getStatus()));
    }

    @PostMapping("/students/{studentId}/charges/seed")
    public ResponseEntity<List<TransactionDTO>> seedCharges(@PathVariable Integer studentId,
                                                            @RequestBody(required = false) com.uwm.paws360.DTO.Finances.SeedChargesRequestDTO req) {
        Student s = studentRepository.findById(studentId)
                .orElseThrow(() -> new jakarta.persistence.EntityNotFoundException("Student not found for id " + studentId));

        // Ensure a financial account exists
        financialAccountRepository.findByStudent(s).orElseGet(() -> {
            FinancialAccount acc = new FinancialAccount();
            acc.setStudent(s);
            return financialAccountRepository.save(acc);
        });

        BigDecimal tuition = (req != null && req.tuitionAmount() != null) ? req.tuitionAmount() : new BigDecimal("4500.00");
        BigDecimal fees = (req != null && req.feesAmount() != null) ? req.feesAmount() : new BigDecimal("350.00");
        LocalDate due = (req != null && req.dueDate() != null) ? req.dueDate() : LocalDate.now().plusDays(30);

        List<TransactionDTO> created = new ArrayList<>();

        AccountTransaction t1 = new AccountTransaction();
        t1.setStudent(s);
        t1.setAmount(tuition);
        t1.setType(AccountTransaction.Type.CHARGE);
        t1.setStatus(AccountTransaction.Status.POSTED);
        t1.setDescription("Tuition");
        t1.setDueDate(due);
        AccountTransaction saved1 = transactionRepository.save(t1);
        created.add(new TransactionDTO(saved1.getId(), saved1.getPostedAt(), saved1.getDueDate(), saved1.getDescription(), saved1.getAmount(), saved1.getType(), saved1.getStatus()));

        AccountTransaction t2 = new AccountTransaction();
        t2.setStudent(s);
        t2.setAmount(fees);
        t2.setType(AccountTransaction.Type.CHARGE);
        t2.setStatus(AccountTransaction.Status.POSTED);
        t2.setDescription("Student Fees");
        t2.setDueDate(due);
        AccountTransaction saved2 = transactionRepository.save(t2);
        created.add(new TransactionDTO(saved2.getId(), saved2.getPostedAt(), saved2.getDueDate(), saved2.getDescription(), saved2.getAmount(), saved2.getType(), saved2.getStatus()));

        // Stored balances are adjusted by createTransaction logic for POSTED items
        financialAccountRepository.findByStudent(s).ifPresent(acc -> {
            acc.setAccountBalance(acc.getAccountBalance().add(tuition.add(fees)));
            acc.setChargesDue(acc.getChargesDue().add(tuition.add(fees)));
            financialAccountRepository.save(acc);
        });

        return ResponseEntity.ok(created);
    }
}
