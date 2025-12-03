// Shared frontend DTO types mirroring backend records

// Users
export type GetStudentIdResponse = {
  student_id: number;
  email: string;
};

// Academics
export type AcademicSummary = {
  cumulativeGPA: number | null;
  totalCredits: number | null;
  semestersCompleted: number | null;
  academicStanding: string | null;
  graduationProgress: number | null;
  expectedGraduation: string | null;
  currentTermGPA?: number | null;
  currentTermLabel?: string | null;
};

export type TranscriptCourse = {
  courseCode: string;
  title: string;
  grade: string | null;
  credits: number | null;
};

export type TranscriptTerm = {
  termLabel: string;
  gpa: number | null;
  credits: number | null;
  courses: TranscriptCourse[];
};

export type Transcript = {
  terms: TranscriptTerm[];
};

// Current Grades
export type CurrentGradeItem = {
  courseCode: string;
  title: string;
  letter?: string | null;
  credits?: number | null;
  percentage?: number | null;
  status?: string | null;
  lastUpdated?: string | null;
};

export type CurrentGradesResponse = {
  termLabel?: string | null;
  grades: CurrentGradeItem[];
};

// Degree requirements / program
export type RequirementCategory = {
  category: string;
  required: number | null;
  completed: number | null;
  remaining: number | null;
  status: string | null;
};

export type DegreeRequirementsBreakdown = {
  totalRequiredCredits?: number | null;
  totalCompletedCredits?: number | null;
  categories: RequirementCategory[];
};

export type RequirementItem = {
  courseId: number;
  courseCode: string;
  courseName: string;
  credits: number | null;
  required: boolean;
  completed: boolean;
  finalLetter?: string | null;
  termLabel?: string | null;
};

// Advising
export type Advisor = {
  advisorId: number;
  name: string;
  title: string;
  department?: string | null;
  email?: string | null;
  phone?: string | null;
  officeLocation?: string | null;
  availability?: string | null;
};

export type Appointment = {
  id: number;
  scheduledAt: string; // ISO OffsetDateTime
  advisorName: string;
  type: string; // enum value
  location?: string | null;
  status: string; // enum value
  notes?: string | null;
};

export type AdvisingMessage = {
  id: number;
  studentId: number;
  advisorId: number;
  advisorName: string;
  sender: string;
  content: string;
  sentAt: string; // ISO OffsetDateTime
};

// Finances
export type FinancesSummary = {
  chargesDue: number | null;
  accountBalance: number | null;
  pendingAid: number | null;
  lastPaymentAmount: number | null;
  lastPaymentAt: string | null; // ISO OffsetDateTime
  dueDate: string | null; // ISO LocalDate
};

export type Transaction = {
  id: number;
  postedAt: string | null; // ISO OffsetDateTime
  dueDate: string | null; // ISO LocalDate
  description: string | null;
  amount: number | null;
  type: string | null; // AccountTransaction.Type
  status: string | null; // AccountTransaction.Status
};

export type AidAward = {
  id: number;
  type: string | null; // AidAward.AidType
  description: string | null;
  amountOffered: number | null;
  amountAccepted: number | null;
  amountDisbursed: number | null;
  status: string | null; // AidAward.AidStatus
  term: string | null;
  academicYear: number | null;
};

export type AidOverview = {
  totalOffered: number | null;
  totalAccepted: number | null;
  totalDisbursed: number | null;
  awards: AidAward[];
};

export type PaymentPlan = {
  id: number;
  name: string;
  totalAmount: number | null;
  monthlyPayment: number | null;
  remainingPayments: number | null;
  nextPaymentDate: string | null; // ISO LocalDate
  status: string | null; // PaymentPlan.PlanStatus
};
