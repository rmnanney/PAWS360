package com.uwm.paws360.Entity.Finances;

import com.uwm.paws360.Entity.UserTypes.Student;
import jakarta.persistence.*;

import java.math.BigDecimal;
import java.time.OffsetDateTime;

@Entity
@Table(name = "aid_awards")
public class AidAward {

    public enum AidType { GRANT, SCHOLARSHIP, LOAN, WORK_STUDY }
    public enum AidStatus { AVAILABLE, ACTIVE, PENDING, CANCELLED }

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "award_id")
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "student_id", nullable = false)
    private Student student;

    @Enumerated(EnumType.STRING)
    @Column(name = "type", nullable = false, length = 20)
    private AidType type;

    @Column(name = "description", length = 200)
    private String description;

    @Column(name = "amount_offered", precision = 12, scale = 2)
    private BigDecimal amountOffered = BigDecimal.ZERO;

    @Column(name = "amount_accepted", precision = 12, scale = 2)
    private BigDecimal amountAccepted = BigDecimal.ZERO;

    @Column(name = "amount_disbursed", precision = 12, scale = 2)
    private BigDecimal amountDisbursed = BigDecimal.ZERO;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 20)
    private AidStatus status = AidStatus.AVAILABLE;

    @Column(name = "term", length = 20)
    private String term;

    @Column(name = "academic_year")
    private Integer academicYear;

    @Column(name = "created_at", nullable = false)
    private OffsetDateTime createdAt = OffsetDateTime.now();

    @Column(name = "updated_at", nullable = false)
    private OffsetDateTime updatedAt = OffsetDateTime.now();

    @PrePersist
    public void onCreate(){
        this.createdAt = OffsetDateTime.now();
        this.updatedAt = this.createdAt;
    }

    @PreUpdate
    public void onUpdate(){
        this.updatedAt = OffsetDateTime.now();
    }

    public Long getId() { return id; }
    public Student getStudent() { return student; }
    public void setStudent(Student student) { this.student = student; }
    public AidType getType() { return type; }
    public void setType(AidType type) { this.type = type; }
    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
    public BigDecimal getAmountOffered() { return amountOffered; }
    public void setAmountOffered(BigDecimal amountOffered) { this.amountOffered = amountOffered; }
    public BigDecimal getAmountAccepted() { return amountAccepted; }
    public void setAmountAccepted(BigDecimal amountAccepted) { this.amountAccepted = amountAccepted; }
    public BigDecimal getAmountDisbursed() { return amountDisbursed; }
    public void setAmountDisbursed(BigDecimal amountDisbursed) { this.amountDisbursed = amountDisbursed; }
    public AidStatus getStatus() { return status; }
    public void setStatus(AidStatus status) { this.status = status; }
    public String getTerm() { return term; }
    public void setTerm(String term) { this.term = term; }
    public Integer getAcademicYear() { return academicYear; }
    public void setAcademicYear(Integer academicYear) { this.academicYear = academicYear; }
}

