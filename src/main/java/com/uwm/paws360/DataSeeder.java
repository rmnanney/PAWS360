package com.uwm.paws360;

import com.uwm.paws360.Entity.Academics.DegreeProgram;
import com.uwm.paws360.Entity.Academics.StudentProgram;
import com.uwm.paws360.Entity.Advising.AdvisorAppointment;
import com.uwm.paws360.Entity.Advising.StudentAdvisor;
import com.uwm.paws360.Entity.Base.Address;
import com.uwm.paws360.Entity.Base.Users;
import com.uwm.paws360.Entity.Course.*;
import com.uwm.paws360.Entity.EntityDomains.*;
import com.uwm.paws360.Entity.EntityDomains.User.*;
import com.uwm.paws360.Entity.Finances.*;
import com.uwm.paws360.Entity.UserTypes.*;
import com.uwm.paws360.JPARepository.Academics.DegreeProgramRepository;
import com.uwm.paws360.JPARepository.Academics.StudentProgramRepository;
import com.uwm.paws360.JPARepository.Advising.AdvisorAppointmentRepository;
import com.uwm.paws360.JPARepository.Advising.StudentAdvisorRepository;
import com.uwm.paws360.JPARepository.Course.*;
import com.uwm.paws360.JPARepository.Finances.*;
import com.uwm.paws360.JPARepository.User.*;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

import java.math.BigDecimal;
import java.time.*;
import java.util.EnumSet;
import java.util.List;

@Configuration
public class DataSeeder {

    @Bean
    CommandLineRunner seedData(UserRepository userRepository,
                               StudentRepository studentRepository,
                               AdvisorRepository advisorRepository,
                               DegreeProgramRepository degreeProgramRepository,
                               StudentProgramRepository studentProgramRepository,
                               CourseRepository courseRepository,
                               CourseSectionRepository sectionRepository,
                               CourseEnrollmentRepository enrollmentRepository,
                               FinancialAccountRepository financialAccountRepository,
                               AccountTransactionRepository transactionRepository,
                               AidAwardRepository aidAwardRepository,
                               PaymentPlanRepository paymentPlanRepository,
                               StudentAdvisorRepository studentAdvisorRepository,
                               AdvisorAppointmentRepository appointmentRepository) {
        return args -> {
            BCryptPasswordEncoder enc = new BCryptPasswordEncoder();

            // Advisors
            Users adv1u = new Users("Sarah", null, "Johnson", LocalDate.of(1980, 3, 10),
                    "sarah.johnson@uwm.edu", enc.encode("password"), Country_Code.US, "4145550001",
                    Status.ACTIVE, Role.ADVISOR, "111223333", Ethnicity.WHITE, Nationality.UNITED_STATES, Gender.FEMALE);
            Users adv2u = new Users("Michael", null, "Chen", LocalDate.of(1977, 6, 2),
                    "michael.chen@uwm.edu", enc.encode("password"), Country_Code.US, "4145550002",
                    Status.ACTIVE, Role.ADVISOR, "222334444", Ethnicity.ASIAN, Nationality.UNITED_STATES, Gender.MALE);
            Users adv3u = new Users("Jennifer", null, "Davis", LocalDate.of(1985, 9, 21),
                    "jennifer.davis@uwm.edu", enc.encode("password"), Country_Code.US, "4145550003",
                    Status.ACTIVE, Role.ADVISOR, "333445555", Ethnicity.BLACK_OR_AFRICAN_AMERICAN, Nationality.UNITED_STATES, Gender.FEMALE);
            userRepository.saveAll(List.of(adv1u, adv2u, adv3u));

            Advisor adv1 = new Advisor(adv1u); adv1.setDepartment(Department.COMPUTER_SCIENCE); adv1.setOfficeLocation("SSB 201");
            Advisor adv2 = new Advisor(adv2u); adv2.setDepartment(Department.COMPUTER_SCIENCE); adv2.setOfficeLocation("Eng 305");
            Advisor adv3 = new Advisor(adv3u); adv3.setDepartment(Department.GENERAL_STUDIES); adv3.setOfficeLocation("Career 101");
            advisorRepository.saveAll(List.of(adv1, adv2, adv3));

            // Students
            Users stu1u = new Users("John", null, "Doe", LocalDate.of(2001,5,15),
                    "john.doe@uwm.edu", enc.encode("password"), Country_Code.US, "4145551001",
                    Status.ACTIVE, Role.STUDENT, "444556666", Ethnicity.WHITE, Nationality.UNITED_STATES, Gender.MALE);
            Address a1 = new Address(); a1.setAddress_type(Address_Type.HOME); a1.setStreet_address_1("123 University Dr"); a1.setCity("Milwaukee"); a1.setUs_state(US_States.WISCONSIN); a1.setZipcode("53211");
            stu1u.getAddresses().add(a1);
            Users stu2u = new Users("Alice", null, "Nguyen", LocalDate.of(2000,3,3),
                    "alice.cs@uwm.edu", enc.encode("password"), Country_Code.US, "4145551002",
                    Status.ACTIVE, Role.STUDENT, "555667777", Ethnicity.ASIAN, Nationality.UNITED_STATES, Gender.FEMALE);
            Address a2 = new Address(); a2.setAddress_type(Address_Type.HOME); a2.setStreet_address_1("456 Campus Way"); a2.setCity("Milwaukee"); a2.setUs_state(US_States.WISCONSIN); a2.setZipcode("53212");
            stu2u.getAddresses().add(a2);
            Users stu3u = new Users("Robert", null, "Senior", LocalDate.of(1999,12,12),
                    "senior.student@uwm.edu", enc.encode("password"), Country_Code.US, "4145551003",
                    Status.ACTIVE, Role.STUDENT, "666778888", Ethnicity.HISPANIC_OR_LATINO, Nationality.UNITED_STATES, Gender.MALE);
            Address a3 = new Address(); a3.setAddress_type(Address_Type.HOME); a3.setStreet_address_1("789 Panther Ave"); a3.setCity("Milwaukee"); a3.setUs_state(US_States.WISCONSIN); a3.setZipcode("53213");
            stu3u.getAddresses().add(a3);
            userRepository.saveAll(List.of(stu1u, stu2u, stu3u));

            Student stu1 = new Student(stu1u); stu1.setDepartment(Department.COMPUTER_SCIENCE); stu1.setStanding(Student_Standing.SOPHOMORE); stu1.setCampusId("S123456");
            Student stu2 = new Student(stu2u); stu2.setDepartment(Department.COMPUTER_SCIENCE); stu2.setStanding(Student_Standing.JUNIOR); stu2.setCampusId("S223344");
            Student stu3 = new Student(stu3u); stu3.setDepartment(Department.COMPUTER_SCIENCE); stu3.setStanding(Student_Standing.SENIOR); stu3.setCampusId("S998877");
            studentRepository.saveAll(List.of(stu1, stu2, stu3));

            // Advisor assignments
            StudentAdvisor sa1 = new StudentAdvisor(); sa1.setStudent(stu1); sa1.setAdvisor(adv1); sa1.setPrimaryAdvisor(true);
            StudentAdvisor sa2 = new StudentAdvisor(); sa2.setStudent(stu2); sa2.setAdvisor(adv2); sa2.setPrimaryAdvisor(true);
            StudentAdvisor sa3 = new StudentAdvisor(); sa3.setStudent(stu3); sa3.setAdvisor(adv1); sa3.setPrimaryAdvisor(true);
            studentAdvisorRepository.saveAll(List.of(sa1, sa2, sa3));

            // Degree programs and assignments
            DegreeProgram bscs = degreeProgramRepository.findByCodeIgnoreCase("BSCS")
                    .orElseGet(() -> {
                        DegreeProgram p = new DegreeProgram();
                        p.setCode("BSCS"); p.setName("B.S. Computer Science"); p.setTotalCreditsRequired(120);
                        return degreeProgramRepository.save(p);
                    });
            StudentProgram sp1 = new StudentProgram(); sp1.setStudent(stu1); sp1.setProgram(bscs); sp1.setExpectedGraduationTerm("Spring"); sp1.setExpectedGraduationYear(2027); sp1.setPrimary(true);
            StudentProgram sp2 = new StudentProgram(); sp2.setStudent(stu2); sp2.setProgram(bscs); sp2.setExpectedGraduationTerm("Fall"); sp2.setExpectedGraduationYear(2026); sp2.setPrimary(true);
            StudentProgram sp3 = new StudentProgram(); sp3.setStudent(stu3); sp3.setProgram(bscs); sp3.setExpectedGraduationTerm("Spring"); sp3.setExpectedGraduationYear(2025); sp3.setPrimary(true);
            studentProgramRepository.saveAll(List.of(sp1, sp2, sp3));

            // Courses
            Courses cs301 = courseRepository.findByCourseCodeIgnoreCase("CS 301").orElseGet(() -> {
                Courses c = new Courses();
                c.setCourseCode("CS 301"); c.setCourseName("Data Structures"); c.setCourseDescription("Data structures and algorithms");
                c.setDepartment(Department.COMPUTER_SCIENCE); c.setCourseLevel("300"); c.setCreditHours(new BigDecimal("3")); c.setCourseCost(new BigDecimal("1200"));
                c.setActive(true); c.setTerm("Fall"); c.setAcademicYear(2025);
                return courseRepository.save(c);
            });
            Courses math205 = courseRepository.findByCourseCodeIgnoreCase("MATH 205").orElseGet(() -> {
                Courses c = new Courses();
                c.setCourseCode("MATH 205"); c.setCourseName("Calculus II"); c.setCourseDescription("Integral calculus");
                c.setDepartment(Department.MATHEMATICAL_SCIENCES); c.setCourseLevel("200"); c.setCreditHours(new BigDecimal("4")); c.setCourseCost(new BigDecimal("1600"));
                c.setActive(true); c.setTerm("Fall"); c.setAcademicYear(2025);
                return courseRepository.save(c);
            });
            Courses eng102 = courseRepository.findByCourseCodeIgnoreCase("ENG 102").orElseGet(() -> {
                Courses c = new Courses();
                c.setCourseCode("ENG 102"); c.setCourseName("English Composition"); c.setCourseDescription("Writing and composition");
                c.setDepartment(Department.ENGLISH); c.setCourseLevel("100"); c.setCreditHours(new BigDecimal("3")); c.setCourseCost(new BigDecimal("900"));
                c.setActive(true); c.setTerm("Fall"); c.setAcademicYear(2025);
                return courseRepository.save(c);
            });
            Courses phys201 = courseRepository.findByCourseCodeIgnoreCase("PHYS 201").orElseGet(() -> {
                Courses c = new Courses();
                c.setCourseCode("PHYS 201"); c.setCourseName("Physics I"); c.setCourseDescription("Mechanics");
                c.setDepartment(Department.PHYSICS); c.setCourseLevel("200"); c.setCreditHours(new BigDecimal("4")); c.setCourseCost(new BigDecimal("1600"));
                c.setActive(true); c.setTerm("Fall"); c.setAcademicYear(2025);
                return courseRepository.save(c);
            });

            // Sections for Fall 2025 (current)
            CourseSection cs301s = new CourseSection(); cs301s.setCourse(cs301); cs301s.setSectionCode("001"); cs301s.setSectionType(SectionType.LECTURE);
            cs301s.setMeetingDays(EnumSet.of(DayOfWeek.MONDAY, DayOfWeek.WEDNESDAY)); cs301s.setStartTime(LocalTime.of(9,0)); cs301s.setEndTime(LocalTime.of(9,50));
            cs301s.setTerm("Fall"); cs301s.setAcademicYear(2025); cs301s.setMaxEnrollment(100);
            CourseSection math205s = new CourseSection(); math205s.setCourse(math205); math205s.setSectionCode("001"); math205s.setSectionType(SectionType.LECTURE);
            math205s.setMeetingDays(EnumSet.of(DayOfWeek.MONDAY, DayOfWeek.WEDNESDAY, DayOfWeek.FRIDAY)); math205s.setStartTime(LocalTime.of(11,0)); math205s.setEndTime(LocalTime.of(11,50));
            math205s.setTerm("Fall"); math205s.setAcademicYear(2025); math205s.setMaxEnrollment(120);
            CourseSection eng102s = new CourseSection(); eng102s.setCourse(eng102); eng102s.setSectionCode("001"); eng102s.setSectionType(SectionType.LECTURE);
            eng102s.setMeetingDays(EnumSet.of(DayOfWeek.TUESDAY, DayOfWeek.THURSDAY)); eng102s.setStartTime(LocalTime.of(14,0)); eng102s.setEndTime(LocalTime.of(14,50));
            eng102s.setTerm("Fall"); eng102s.setAcademicYear(2025); eng102s.setMaxEnrollment(80);
            CourseSection phys201s = new CourseSection(); phys201s.setCourse(phys201); phys201s.setSectionCode("LAB1"); phys201s.setSectionType(SectionType.LAB);
            phys201s.setMeetingDays(EnumSet.of(DayOfWeek.FRIDAY)); phys201s.setStartTime(LocalTime.of(16,0)); phys201s.setEndTime(LocalTime.of(18,0));
            phys201s.setTerm("Fall"); phys201s.setAcademicYear(2025); phys201s.setMaxEnrollment(40);
            sectionRepository.saveAll(List.of(cs301s, math205s, eng102s, phys201s));

            // Enrollments for students (current and past)
            CourseEnrollment e1 = new CourseEnrollment(stu1, cs301s, null, SectionEnrollmentStatus.ENROLLED);
            e1.setCurrentPercentage(88); e1.setCurrentLetter("B+"); e1.setLastGradeUpdate(OffsetDateTime.now());
            CourseEnrollment e2 = new CourseEnrollment(stu1, math205s, null, SectionEnrollmentStatus.ENROLLED);
            e2.setCurrentPercentage(92); e2.setCurrentLetter("A-"); e2.setLastGradeUpdate(OffsetDateTime.now());
            enrollmentRepository.saveAll(List.of(e1, e2));

            // Past term sections and enrollments for transcript
            CourseSection cs301_prev = new CourseSection(); cs301_prev.setCourse(cs301); cs301_prev.setSectionCode("001"); cs301_prev.setSectionType(SectionType.LECTURE);
            cs301_prev.setMeetingDays(EnumSet.of(DayOfWeek.MONDAY, DayOfWeek.WEDNESDAY)); cs301_prev.setStartTime(LocalTime.of(9,0)); cs301_prev.setEndTime(LocalTime.of(9,50));
            cs301_prev.setTerm("Spring"); cs301_prev.setAcademicYear(2025);
            CourseSection eng101_prev = new CourseSection(); eng101_prev.setCourse(eng102); eng101_prev.setSectionCode("001"); eng101_prev.setSectionType(SectionType.LECTURE);
            eng101_prev.setMeetingDays(EnumSet.of(DayOfWeek.TUESDAY, DayOfWeek.THURSDAY)); eng101_prev.setStartTime(LocalTime.of(10,0)); eng101_prev.setEndTime(LocalTime.of(10,50));
            eng101_prev.setTerm("Fall"); eng101_prev.setAcademicYear(2024);
            sectionRepository.saveAll(List.of(cs301_prev, eng101_prev));

            CourseEnrollment pe1 = new CourseEnrollment(stu1, cs301_prev, null, SectionEnrollmentStatus.COMPLETED);
            pe1.setFinalLetter("A"); pe1.setCompletedAt(OffsetDateTime.now().minusMonths(4));
            CourseEnrollment pe2 = new CourseEnrollment(stu1, eng101_prev, null, SectionEnrollmentStatus.COMPLETED);
            pe2.setFinalLetter("B"); pe2.setCompletedAt(OffsetDateTime.now().minusMonths(10));
            enrollmentRepository.saveAll(List.of(pe1, pe2));

            // Senior student with many completed
            for (int i = 1; i <= 8; i++) {
                CourseSection past = new CourseSection();
                past.setCourse(cs301); past.setSectionCode("T" + i); past.setSectionType(SectionType.LECTURE);
                past.setMeetingDays(EnumSet.of(DayOfWeek.MONDAY)); past.setStartTime(LocalTime.of(8,0)); past.setEndTime(LocalTime.of(8,50));
                past.setTerm(i % 2 == 0 ? "Spring" : "Fall"); past.setAcademicYear(2021 + (i/2));
                sectionRepository.save(past);
                CourseEnrollment ce = new CourseEnrollment(stu3, past, null, SectionEnrollmentStatus.COMPLETED);
                ce.setFinalLetter(i % 3 == 0 ? "A" : (i % 3 == 1 ? "B" : "A-"));
                ce.setCompletedAt(OffsetDateTime.now().minusMonths(12 - i));
                enrollmentRepository.save(ce);
            }

            // Finances: accounts
            FinancialAccount acc1 = new FinancialAccount(); acc1.setStudent(stu1);
            acc1.setAccountBalance(new BigDecimal("2450.75")); acc1.setChargesDue(new BigDecimal("4250.00")); acc1.setPendingAid(new BigDecimal("3200.00"));
            acc1.setDueDate(LocalDate.now().plusDays(15));
            FinancialAccount acc2 = new FinancialAccount(); acc2.setStudent(stu2); acc2.setAccountBalance(new BigDecimal("1200.00")); acc2.setChargesDue(new BigDecimal("2400.00")); acc2.setPendingAid(new BigDecimal("1800.00")); acc2.setDueDate(LocalDate.now().plusDays(30));
            FinancialAccount acc3 = new FinancialAccount(); acc3.setStudent(stu3); acc3.setAccountBalance(new BigDecimal("0.00")); acc3.setChargesDue(BigDecimal.ZERO); acc3.setPendingAid(BigDecimal.ZERO);
            financialAccountRepository.saveAll(List.of(acc1, acc2, acc3));

            // Transactions for stu1
            AccountTransaction t1 = new AccountTransaction(); t1.setStudent(stu1); t1.setType(AccountTransaction.Type.CHARGE); t1.setStatus(AccountTransaction.Status.POSTED);
            t1.setAmount(new BigDecimal("4250.00")); t1.setDescription("Tuition - Fall 2025"); t1.setPostedAt(OffsetDateTime.now().minusDays(14)); t1.setDueDate(LocalDate.now().plusDays(15));
            AccountTransaction t2 = new AccountTransaction(); t2.setStudent(stu1); t2.setType(AccountTransaction.Type.CREDIT); t2.setStatus(AccountTransaction.Status.POSTED);
            t2.setAmount(new BigDecimal("1600.00")); t2.setDescription("Financial Aid Disbursement"); t2.setPostedAt(OffsetDateTime.now().minusDays(18));
            AccountTransaction t3 = new AccountTransaction(); t3.setStudent(stu1); t3.setType(AccountTransaction.Type.CHARGE); t3.setStatus(AccountTransaction.Status.POSTED);
            t3.setAmount(new BigDecimal("1200.00")); t3.setDescription("Housing Deposit"); t3.setPostedAt(OffsetDateTime.now().minusDays(30));
            AccountTransaction t4 = new AccountTransaction(); t4.setStudent(stu1); t4.setType(AccountTransaction.Type.CHARGE); t4.setStatus(AccountTransaction.Status.POSTED);
            t4.setAmount(new BigDecimal("850.00")); t4.setDescription("Meal Plan - Semester"); t4.setPostedAt(OffsetDateTime.now().minusDays(35));
            AccountTransaction t5 = new AccountTransaction(); t5.setStudent(stu1); t5.setType(AccountTransaction.Type.PAYMENT); t5.setStatus(AccountTransaction.Status.POSTED);
            t5.setAmount(new BigDecimal("2000.00")); t5.setDescription("Payment Received"); t5.setPostedAt(OffsetDateTime.now().minusDays(40));
            transactionRepository.saveAll(List.of(t1, t2, t3, t4, t5));
            acc1.setLastPaymentAmount(t5.getAmount()); acc1.setLastPaymentAt(t5.getPostedAt()); financialAccountRepository.save(acc1);

            // Aid awards for stu1
            AidAward aw1 = new AidAward(); aw1.setStudent(stu1); aw1.setType(AidAward.AidType.GRANT); aw1.setDescription("Federal Pell Grant");
            aw1.setAmountOffered(new BigDecimal("1800.00")); aw1.setAmountAccepted(new BigDecimal("1800.00")); aw1.setAmountDisbursed(new BigDecimal("900.00")); aw1.setStatus(AidAward.AidStatus.ACTIVE); aw1.setTerm("Fall"); aw1.setAcademicYear(2025);
            AidAward aw2 = new AidAward(); aw2.setStudent(stu1); aw2.setType(AidAward.AidType.WORK_STUDY); aw2.setDescription("Federal Work Study");
            aw2.setAmountOffered(new BigDecimal("2400.00")); aw2.setAmountAccepted(new BigDecimal("2400.00")); aw2.setAmountDisbursed(new BigDecimal("1200.00")); aw2.setStatus(AidAward.AidStatus.ACTIVE); aw2.setTerm("Fall"); aw2.setAcademicYear(2025);
            AidAward aw3 = new AidAward(); aw3.setStudent(stu1); aw3.setType(AidAward.AidType.GRANT); aw3.setDescription("State Grant");
            aw3.setAmountOffered(new BigDecimal("800.00")); aw3.setAmountAccepted(new BigDecimal("800.00")); aw3.setAmountDisbursed(new BigDecimal("400.00")); aw3.setStatus(AidAward.AidStatus.ACTIVE); aw3.setTerm("Fall"); aw3.setAcademicYear(2025);
            aidAwardRepository.saveAll(List.of(aw1, aw2, aw3));

            PaymentPlan pp = new PaymentPlan(); pp.setStudent(stu1); pp.setName("Monthly Payment Plan"); pp.setTotalAmount(acc1.getAccountBalance());
            pp.setMonthlyPayment(new BigDecimal("245.08")); pp.setRemainingPayments(10); pp.setNextPaymentDate(LocalDate.now().plusDays(10));
            paymentPlanRepository.save(pp);

            // Appointments
            AdvisorAppointment ap1 = new AdvisorAppointment(); ap1.setStudent(stu1); ap1.setAdvisor(adv1);
            ap1.setType(AdvisorAppointment.AppointmentType.ACADEMIC_ADVISING); ap1.setStatus(AdvisorAppointment.AppointmentStatus.CONFIRMED);
            ap1.setScheduledAt(OffsetDateTime.now().plusDays(5).withHour(14).withMinute(0)); ap1.setLocation("Virtual"); ap1.setNotes("Discuss course selection for Spring 2026");
            AdvisorAppointment ap2 = new AdvisorAppointment(); ap2.setStudent(stu1); ap2.setAdvisor(adv2);
            ap2.setType(AdvisorAppointment.AppointmentType.DEGREE_PLANNING); ap2.setStatus(AdvisorAppointment.AppointmentStatus.CONFIRMED);
            ap2.setScheduledAt(OffsetDateTime.now().plusDays(12).withHour(10).withMinute(0)); ap2.setLocation("Student Services Building, Room 204"); ap2.setNotes("Review graduation requirements");
            appointmentRepository.saveAll(List.of(ap1, ap2));
        };
    }
}
