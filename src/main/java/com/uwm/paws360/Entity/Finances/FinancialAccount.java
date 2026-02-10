package com.uwm.paws360.Entity.Finances;

import com.uwm.paws360.Entity.UserTypes.Student;
import jakarta.persistence.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.OffsetDateTime;

@Entity
@Table(name = "financial_accounts", uniqueConstraints = {
        @UniqueConstraint(columnNames = {"student_id"})
})
public class FinancialAccount {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "account_id")
    private Long id;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "student_id", nullable = false, unique = true)
    private Student student;

    @Column(name = "account_balance", precision = 12, scale = 2, nullable = false)
    private BigDecimal accountBalance = BigDecimal.ZERO;

    @Column(name = "charges_due", precision = 12, scale = 2, nullable = false)
    private BigDecimal chargesDue = BigDecimal.ZERO;

    @Column(name = "pending_aid", precision = 12, scale = 2, nullable = false)
    private BigDecimal pendingAid = BigDecimal.ZERO;

    @Column(name = "last_payment_amount", precision = 12, scale = 2)
    private BigDecimal lastPaymentAmount;

    @Column(name = "last_payment_at")
    private OffsetDateTime lastPaymentAt;

    @Column(name = "due_date")
    private LocalDate dueDate;

    @Column(name = "created_at", nullable = false)
    private OffsetDateTime createdAt = OffsetDateTime.now();

    @Column(name = "updated_at", nullable = false)
    private OffsetDateTime updatedAt = OffsetDateTime.now();

    @PrePersist
    public void onCreate() {
        this.createdAt = OffsetDateTime.now();
        this.updatedAt = this.createdAt;
    }

    @PreUpdate
    public void onUpdate() {
        this.updatedAt = OffsetDateTime.now();
    }

    public Long getId() { return id; }
    public Student getStudent() { return student; }
    public void setStudent(Student student) { this.student = student; }
    public BigDecimal getAccountBalance() { return accountBalance; }
    public void setAccountBalance(BigDecimal accountBalance) { this.accountBalance = accountBalance; }
    public BigDecimal getChargesDue() { return chargesDue; }
    public void setChargesDue(BigDecimal chargesDue) { this.chargesDue = chargesDue; }
    public BigDecimal getPendingAid() { return pendingAid; }
    public void setPendingAid(BigDecimal pendingAid) { this.pendingAid = pendingAid; }
    public BigDecimal getLastPaymentAmount() { return lastPaymentAmount; }
    public void setLastPaymentAmount(BigDecimal lastPaymentAmount) { this.lastPaymentAmount = lastPaymentAmount; }
    public OffsetDateTime getLastPaymentAt() { return lastPaymentAt; }
    public void setLastPaymentAt(OffsetDateTime lastPaymentAt) { this.lastPaymentAt = lastPaymentAt; }
    public LocalDate getDueDate() { return dueDate; }
    public void setDueDate(LocalDate dueDate) { this.dueDate = dueDate; }
}

