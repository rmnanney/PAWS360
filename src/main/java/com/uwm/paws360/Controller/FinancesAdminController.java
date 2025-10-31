package com.uwm.paws360.Controller;

import com.uwm.paws360.DTO.Finances.*;
import com.uwm.paws360.Entity.Finances.*;
import com.uwm.paws360.Entity.UserTypes.Student;
import com.uwm.paws360.JPARepository.Finances.*;
import com.uwm.paws360.JPARepository.User.StudentRepository;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/finances/admin")
public class FinancesAdminController {

    private final StudentRepository studentRepository;
    private final FinancialAccountRepository financialAccountRepository;
    private final AccountTransactionRepository transactionRepository;
    private final AidAwardRepository aidAwardRepository;
    private final PaymentPlanRepository paymentPlanRepository;

    public FinancesAdminController(StudentRepository studentRepository,
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
        AccountTransaction t = new AccountTransaction();
        t.setStudent(s);
        t.setAmount(req.amount());
        t.setType(req.type());
        t.setStatus(req.status());
        t.setDescription(req.description());
        if (req.postedAt() != null) t.setPostedAt(req.postedAt());
        t.setDueDate(req.dueDate());
        AccountTransaction saved = transactionRepository.save(t);
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
}

