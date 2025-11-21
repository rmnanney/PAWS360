"use client";

import React from "react";
import styles from "./styles.module.css";
import { useRouter } from "next/navigation";
import {
	Card,
	CardContent,
	CardDescription,
	CardHeader,
	CardTitle,
} from "../components/Card/card";
import { Button } from "../components/Button/button";
import { Badge } from "../components/Others/badge";
import {
	Tabs,
	TabsContent,
	TabsList,
	TabsTrigger,
} from "../components/Others/tabs";
import { Spinner } from "../components/Others/spinner";
import {
	AlertCircle,
	CalendarClock,
	CheckCircle2,
	Clock,
	GraduationCap,
	Hourglass,
	ListPlus,
	Loader2,
	MapPin,
	RefreshCcw,
	Search,
	UserCheck,
	XCircle,
} from "lucide-react";

type EnrollmentWindow = {
	term: string;
	opensAt: string;
	closesAt: string;
	priority?: string | null;
	note?: string | null;
};

type CourseSection = {
	sectionId: number;
	sectionType: string;
	sectionCode: string | null;
	parentSectionId: number | null;
	meetingDays?: string[] | null;
	startTime?: string | null;
	endTime?: string | null;
	maxEnrollment?: number | null;
	currentEnrollment?: number | null;
	waitlistCapacity?: number | null;
	currentWaitlist?: number | null;
	term?: string | null;
	academicYear?: number | null;
};

type CourseCatalog = {
	courseId: number;
	courseCode: string;
	courseName: string;
	courseDescription?: string | null;
	creditHours?: number | null;
	term?: string | null;
	sections?: CourseSection[] | null;
};

type EnrollmentRecord = {
	enrollmentId: number;
	studentId: number;
	lectureSectionId: number;
	labSectionId: number | null;
	status: string;
	waitlistPosition?: number | null;
	autoEnrolledFromWaitlist?: boolean;
	enrolledAt?: string | null;
	waitlistedAt?: string | null;
	droppedAt?: string | null;
};

type SectionWithCourse = { section: CourseSection; course: CourseCatalog };

type PlannerItem = { sectionId: number; addedAt: string };

function formatTimeLabel(value?: string | null) {
	if (!value) return "TBD";
	const [hours = 0, minutes = 0] = value.split(":").map((v) => parseInt(v, 10));
	const date = new Date();
	date.setHours(hours);
	date.setMinutes(minutes);
	return new Intl.DateTimeFormat("en-US", {
		hour: "numeric",
		minute: "2-digit",
	}).format(date);
}

function formatMeetingDays(days?: string[] | null) {
	if (!days || days.length === 0) return "Days TBD";
	const map: Record<string, string> = {
		MONDAY: "Mon",
		TUESDAY: "Tue",
		WEDNESDAY: "Wed",
		THURSDAY: "Thu",
		FRIDAY: "Fri",
		SATURDAY: "Sat",
		SUNDAY: "Sun",
	};
	return days.map((d) => map[d] || d).join(" / ");
}

function formatWindow(window: EnrollmentWindow) {
	if (!window.opensAt || !window.closesAt) return "Dates not set";
	const formatter = new Intl.DateTimeFormat("en-US", {
		month: "short",
		day: "numeric",
		hour: "numeric",
		minute: "2-digit",
	});
	return `${formatter.format(new Date(window.opensAt))} - ${formatter.format(
		new Date(window.closesAt)
	)}`;
}

function statusPill(status?: string) {
	const s = (status || "").toUpperCase();
	if (s === "ENROLLED") return <Badge variant="secondary">Enrolled</Badge>;
	if (s === "WAITLISTED") return <Badge variant="destructive">Waitlist</Badge>;
	if (s === "DROPPED") return <Badge variant="outline">Dropped</Badge>;
	return <Badge variant="outline">Planned</Badge>;
}

function sectionIsFull(section: CourseSection) {
	const max = section.maxEnrollment ?? 0;
	const current = section.currentEnrollment ?? 0;
	return max > 0 && current >= max;
}

function seatsLabel(section: CourseSection) {
	const full = sectionIsFull(section);
	if (!full) {
		const max = section.maxEnrollment ?? 0;
		const current = section.currentEnrollment ?? 0;
		const left = max > 0 ? Math.max(0, max - current) : null;
		return left !== null ? `${left} seats open` : "Open seats";
	}
	const waitCap = section.waitlistCapacity ?? 0;
	const waitCur = section.currentWaitlist ?? 0;
	if (waitCap === 0) return "Full - no waitlist";
	if (waitCur >= waitCap) return "Waitlist full";
	return `${waitCap - waitCur} waitlist spots left`;
}

export default function EnrollmentDatePage() {
	const { toast } = require("@/hooks/useToast");
	const { API_BASE } = require("@/lib/api");
	const router = useRouter();

	const [studentId, setStudentId] = React.useState<number | null>(null);
	const [catalog, setCatalog] = React.useState<CourseCatalog[]>([]);
	const [catalogLoading, setCatalogLoading] = React.useState(true);
	const [enrollments, setEnrollments] = React.useState<EnrollmentRecord[]>([]);
	const [enrollmentsLoading, setEnrollmentsLoading] = React.useState(true);
	const [search, setSearch] = React.useState({
		subject: "",
		courseCode: "",
		title: "",
		term: "",
	});
	const [planner, setPlanner] = React.useState<PlannerItem[]>([]);
	const [enrolling, setEnrolling] = React.useState<number | null>(null);
	const [dropping, setDropping] = React.useState<number | null>(null);
	const [enrollmentWindows, setEnrollmentWindows] = React.useState<EnrollmentWindow[]>([]);

	React.useEffect(() => {
		try {
			if (typeof window === "undefined") return;
			const stored = localStorage.getItem("enrollment_plan");
			if (stored) {
				setPlanner(JSON.parse(stored));
			}
		} catch {
			/* ignore */
		}
	}, []);

	React.useEffect(() => {
		try {
			if (typeof window !== "undefined") {
				localStorage.setItem("enrollment_plan", JSON.stringify(planner));
			}
		} catch {
			/* ignore */
		}
	}, [planner]);

	React.useEffect(() => {
		const load = async () => {
			try {
				const email =
					typeof window !== "undefined"
						? localStorage.getItem("userEmail")
						: null;
				if (!email) return;
				const res = await fetch(
					`${API_BASE}/users/student-id?email=${encodeURIComponent(email)}`
				);
				const data = await res.json();
				if (res.ok && typeof data.student_id === "number") {
					setStudentId(data.student_id);
				} else {
					toast({
						variant: "destructive",
						title: "Unable to load student profile",
						description: "Verify your login and try again.",
					});
				}
			} catch (e: any) {
				toast({
					variant: "destructive",
					title: "Failed to load student ID",
					description: e?.message || "Try again later.",
				});
			}
		};
		load();
	}, [API_BASE, toast]);

	React.useEffect(() => {
		const loadWindows = async () => {
			try {
				const res = await fetch(`${API_BASE}/api/enrollment/windows`);
				if (res.ok) {
					const data = await res.json();
					if (Array.isArray(data)) {
						setEnrollmentWindows(
							data.map((w: any) => ({
								term: w.term,
								opensAt: w.opensAt,
								closesAt: w.closesAt,
								priority: w.priority,
								note: w.note,
							}))
						);
					}
				}
			} catch {
				// optional endpoint; ignore if missing
			}
		};
		loadWindows();
	}, [API_BASE]);

	const refreshEnrollments = React.useCallback(
		async (id?: number | null) => {
			const sid = id ?? studentId;
			if (!sid) return;
			setEnrollmentsLoading(true);
			try {
				const res = await fetch(`${API_BASE}/enrollments/student/${sid}`);
				if (res.ok) {
					setEnrollments(await res.json());
				} else {
					toast({
						variant: "destructive",
						title: "Failed to load schedule",
						description: "Enrollment service unavailable.",
					});
				}
			} catch (e: any) {
				toast({
					variant: "destructive",
					title: "Failed to load schedule",
					description: e?.message || "Try again later.",
				});
			} finally {
				setEnrollmentsLoading(false);
			}
		},
		[API_BASE, studentId, toast]
	);

	React.useEffect(() => {
		const loadCatalog = async () => {
			setCatalogLoading(true);
			try {
				const res = await fetch(`${API_BASE}/courses`);
				if (res.ok) {
					setCatalog(await res.json());
				} else {
					toast({
						variant: "destructive",
						title: "Could not load catalog",
						description: "Please refresh and try again.",
					});
				}
			} catch (e: any) {
				toast({
					variant: "destructive",
					title: "Catalog unavailable",
					description: e?.message || "Try again later.",
				});
			} finally {
				setCatalogLoading(false);
			}
		};
		loadCatalog();
	}, [API_BASE, toast]);

	React.useEffect(() => {
		if (studentId !== null) {
			refreshEnrollments(studentId);
		}
	}, [studentId, refreshEnrollments]);

	const sectionIndex = React.useMemo(() => {
		const map = new Map<number, SectionWithCourse>();
		catalog.forEach((course) => {
			(course.sections || []).forEach((section) => {
				if (section?.sectionId != null) {
					map.set(Number(section.sectionId), { section, course });
				}
			});
		});
		return map;
	}, [catalog]);

	const filteredSections: SectionWithCourse[] = React.useMemo(() => {
		const filters = {
			subject: search.subject.trim().toUpperCase(),
			courseCode: search.courseCode.trim().toUpperCase(),
			title: search.title.trim().toUpperCase(),
			term: search.term.trim().toUpperCase(),
		};
		const results: SectionWithCourse[] = [];
		sectionIndex.forEach((value) => {
			const { section, course } = value;
			if ((section.sectionType || "").toUpperCase() !== "LECTURE") return;
			if (
				filters.subject &&
				!course.courseCode.toUpperCase().startsWith(filters.subject)
			)
				return;
			if (
				filters.courseCode &&
				!course.courseCode.toUpperCase().includes(filters.courseCode)
			)
				return;
			if (
				filters.title &&
				!course.courseName.toUpperCase().includes(filters.title)
			)
				return;
			const sectionTerm = (section.term || course.term || "").toUpperCase();
			if (filters.term && !sectionTerm.includes(filters.term)) return;
			results.push(value);
		});
		return results.slice(0, 120);
	}, [sectionIndex, search]);

	const plannedSections = React.useMemo(() => {
		return planner
			.map((item) => sectionIndex.get(item.sectionId))
			.filter(Boolean) as SectionWithCourse[];
	}, [planner, sectionIndex]);

	const enrollmentDetails = React.useMemo(() => {
		return enrollments
			.map((enr) => {
				const match = sectionIndex.get(enr.lectureSectionId);
				if (!match) return null;
				return {
					...enr,
					section: match.section,
					course: match.course,
				};
			})
			.filter(Boolean) as Array<
			EnrollmentRecord & { section: CourseSection; course: CourseCatalog }
		>;
	}, [enrollments, sectionIndex]);

	const upcomingWindow = React.useMemo(() => {
		const now = Date.now();
		return enrollmentWindows.find((w) => {
			if (!w.opensAt || !w.closesAt) return false;
			return new Date(w.closesAt).getTime() > now;
		});
	}, [enrollmentWindows]);

	const addToPlanner = (sectionId: number) => {
		if (planner.some((p) => p.sectionId === sectionId)) {
			toast({
				title: "Already planned",
				description: "This section is already in your planner.",
			});
			return;
		}
		setPlanner((prev) => [
			...prev,
			{ sectionId, addedAt: new Date().toISOString() },
		]);
		toast({
			title: "Added to planner",
			description: "Review and enroll from the Planner tab when ready.",
		});
	};

	const enrollSection = async (section: CourseSection, course: CourseCatalog) => {
		if (!studentId) {
			toast({
				variant: "destructive",
				title: "Login needed",
				description: "Sign in again to enroll.",
			});
			return;
		}
		if ((section.sectionType || "").toUpperCase() !== "LECTURE") {
			toast({
				variant: "destructive",
				title: "Pick a lecture section",
				description: "Select a lecture before adding labs.",
			});
			return;
		}
		setEnrolling(section.sectionId);
		try {
			const res = await fetch(`${API_BASE}/enrollments/enroll`, {
				method: "POST",
				headers: { "Content-Type": "application/json" },
				body: JSON.stringify({
					studentId,
					lectureSectionId: section.sectionId,
					labSectionId: null,
				}),
			});
			const data = await res.json().catch(() => null);
			if (!res.ok) {
				throw new Error(
					data?.message || data?.error || "Enrollment request failed"
				);
			}
			await refreshEnrollments(studentId);
			setPlanner((prev) =>
				prev.filter((p) => p.sectionId !== section.sectionId)
			);
			const status = (data?.status || sectionIsFull(section))
				? String(data.status || "").toUpperCase()
				: "";
			toast({
				title:
					status === "WAITLISTED"
						? "Added to waitlist"
						: "Enrollment requested",
				description: `${course.courseCode} ${
					section.sectionCode || ""
				} (${course.courseName})`,
			});
		} catch (e: any) {
			toast({
				variant: "destructive",
				title: "Unable to enroll",
				description: e?.message || "Try again later.",
			});
		} finally {
			setEnrolling(null);
		}
	};

	const dropSection = async (record: EnrollmentRecord) => {
		if (!studentId) return;
		setDropping(record.lectureSectionId);
		try {
			const res = await fetch(`${API_BASE}/enrollments/drop`, {
				method: "POST",
				headers: { "Content-Type": "application/json" },
				body: JSON.stringify({
					studentId,
					lectureSectionId: record.lectureSectionId,
				}),
			});
			if (!res.ok) {
				throw new Error("Drop failed");
			}
			await refreshEnrollments(studentId);
			toast({
				title: "Dropped",
				description: "Course removed from your schedule.",
			});
		} catch (e: any) {
			toast({
				variant: "destructive",
				title: "Unable to drop",
				description: e?.message || "Try again later.",
			});
		} finally {
			setDropping(null);
		}
	};

	const heroCards = [
		{
			title: "Next window",
			value: upcomingWindow
				? formatWindow(upcomingWindow)
				: "Windows not published",
			icon: CalendarClock,
			description:
				upcomingWindow?.priority ||
				"Check back later or contact the registrar",
		},
		{
			title: "Enrolled this term",
			value: enrollmentDetails.filter((e) => e.status === "ENROLLED").length,
			icon: UserCheck,
			description: "Active lecture enrollments",
		},
		{
			title: "On waitlist",
			value: enrollmentDetails.filter((e) => e.status === "WAITLISTED").length,
			icon: Hourglass,
			description: "Auto-promotes when seats open",
		},
		{
			title: "Planner",
			value: planner.length,
			icon: ListPlus,
			description: "Ready to validate and enroll",
		},
	];

	const formField = (
		label: string,
		placeholder: string,
		value: string,
		onChange: (v: string) => void
	) => (
		<div className={styles.formField}>
			<label className={styles.label}>{label}</label>
			<input
				className={styles.input}
				value={value}
				onChange={(e) => onChange(e.target.value)}
				placeholder={placeholder}
			/>
		</div>
	);

	return (
		<div className={styles.page}>
			<div className={styles.hero}>
				<div>
					<h1 className={styles.title}>Enrollment dates & next-term planner</h1>
					<p className={styles.subtitle}>
						Check your window, search classes, and enroll - all in one place.
					</p>
				</div>
				<div className={styles.heroActions}>
					<Button variant="secondary" onClick={() => router.push("/courses/search")}>
						<Search className="mr-2 h-4 w-4" />
						Go to Class Search
					</Button>
					<Button onClick={() => router.push("/courses/enrollment")}>
						<GraduationCap className="mr-2 h-4 w-4" />
						Review Enrollment
					</Button>
				</div>
			</div>

			<div className={styles.metricsGrid}>
				{heroCards.map((card) => {
					const Icon = card.icon;
					return (
						<Card key={card.title} className={styles.statCard}>
							<CardHeader className={styles.statHeader}>
								<div className={styles.iconCircle}>
									<Icon className="h-5 w-5" />
								</div>
								<CardTitle>{card.title}</CardTitle>
							</CardHeader>
							<CardContent className={styles.statContent}>
								<div className={styles.statValue}>{card.value}</div>
								<p className={styles.statDescription}>{card.description}</p>
							</CardContent>
						</Card>
					);
				})}
			</div>

			<Tabs defaultValue="overview" className="space-y-4">
				<TabsList className={styles.tabsList}>
					<TabsTrigger value="overview">Dates & eligibility</TabsTrigger>
					<TabsTrigger value="plan">Plan & search</TabsTrigger>
					<TabsTrigger value="schedule">My schedule</TabsTrigger>
				</TabsList>

				<TabsContent value="overview">
					<Card>
						<CardHeader>
							<CardTitle>Enrollment windows</CardTitle>
							<CardDescription>
								Your assigned window, priority groups, and reminders for next term.
							</CardDescription>
						</CardHeader>
						<CardContent className={styles.windowGrid}>
							{enrollmentWindows.length === 0 && (
								<p className="text-sm text-muted-foreground">
									Enrollment windows are not published yet. Watch your UWM email for
									opening times.
								</p>
							)}
							{enrollmentWindows.map((window, idx) => {
								const now = Date.now();
								const opens = window.opensAt ? new Date(window.opensAt).getTime() : 0;
								const closes = window.closesAt ? new Date(window.closesAt).getTime() : 0;
								const isOpen = window.opensAt && window.closesAt ? now >= opens && now < closes : false;
								const isFuture = window.opensAt ? now < opens : false;
								return (
									<div key={idx} className={styles.windowCard}>
										<div className={styles.windowHeader}>
											<div>
												<p className={styles.windowTerm}>{window.term}</p>
												{window.opensAt && window.closesAt && (
													<p className={styles.windowDate}>{formatWindow(window)}</p>
												)}
											</div>
											<Badge variant={isOpen ? "secondary" : "outline"}>
												{isOpen ? "Open now" : isFuture ? "Upcoming" : "Closed"}
											</Badge>
										</div>
										<div className={styles.windowBody}>
											{window.priority && (
												<div className={styles.windowRow}>
													<Clock className="h-4 w-4 text-muted-foreground" />
													<span>{window.priority}</span>
												</div>
											)}
											{window.note && (
												<div className={styles.windowRow}>
													<AlertCircle className="h-4 w-4 text-muted-foreground" />
													<span>{window.note}</span>
												</div>
											)}
										</div>
									</div>
								);
							})}
						</CardContent>
					</Card>
				</TabsContent>

				<TabsContent value="plan">
					<div className={styles.twoColumn}>
						<Card className={styles.searchCard}>
							<CardHeader>
								<CardTitle>Search the catalog</CardTitle>
								<CardDescription>
									Filter lectures, then add them to your planner or enroll directly.
								</CardDescription>
							</CardHeader>
							<CardContent className="space-y-3">
								{formField("Subject/Dept", "e.g. ENGLISH, COMP SCI", search.subject, (v) =>
									setSearch((prev) => ({ ...prev, subject: v }))
								)}
								{formField("Course code", "e.g. ENGLISH 100", search.courseCode, (v) =>
									setSearch((prev) => ({ ...prev, courseCode: v }))
								)}
								{formField("Title", "Partial course name", search.title, (v) =>
									setSearch((prev) => ({ ...prev, title: v }))
								)}
								{formField("Term (optional)", "Spring 2026", search.term, (v) =>
									setSearch((prev) => ({ ...prev, term: v }))
								)}
								<div className={styles.searchActions}>
									<Button
										variant="secondary"
										onClick={() =>
											setSearch({ subject: "", courseCode: "", title: "", term: "" })
										}
									>
										<RefreshCcw className="mr-2 h-4 w-4" />
										Clear filters
									</Button>
									<Button onClick={() => setSearch((prev) => ({ ...prev }))}>
										<Search className="mr-2 h-4 w-4" />
										Update results
									</Button>
								</div>
								<div className={styles.hint}>
									<CheckCircle2 className="h-4 w-4" />
									<span>
										Sections show live capacity and waitlist availability before you enroll.
									</span>
								</div>
							</CardContent>
						</Card>

						<Card className={styles.resultsCard}>
							<CardHeader className="flex flex-col gap-1 sm:flex-row sm:items-center sm:justify-between">
								<div>
									<CardTitle>Results</CardTitle>
									<CardDescription>
										Showing {filteredSections.length} matching lecture sections
									</CardDescription>
								</div>
							</CardHeader>
							<CardContent className="space-y-3">
								{catalogLoading && (
									<div className={styles.loadingRow}>
										<Spinner size="sm" />
										<span>Loading catalog...</span>
									</div>
								)}

								{!catalogLoading && filteredSections.length === 0 && (
									<div className="text-sm text-muted-foreground">
										No sections match your filters. Try a broader search.
									</div>
								)}

								{filteredSections.map(({ course, section }) => {
									const full = sectionIsFull(section);
									const meetingLabel = `${formatMeetingDays(
										section.meetingDays
									)} - ${formatTimeLabel(section.startTime)} to ${formatTimeLabel(
										section.endTime
									)}`;
									return (
										<div key={section.sectionId} className={styles.resultCard}>
											<div className={styles.resultTop}>
												<div>
													<div className={styles.courseCode}>
														{course.courseCode} {section.sectionCode || ""}
													</div>
													<div className={styles.courseTitle}>{course.courseName}</div>
													<div className={styles.metaRow}>
														<MapPin className="h-4 w-4 text-muted-foreground" />
														<span>{meetingLabel}</span>
													</div>
													<div className={styles.metaRow}>
														<Clock className="h-4 w-4 text-muted-foreground" />
														<span>{seatsLabel(section)}</span>
													</div>
												</div>
												<div className={styles.actionsCol}>
													<Button
														variant="outline"
														onClick={() => addToPlanner(section.sectionId)}
														disabled={planner.some(
															(p) => p.sectionId === section.sectionId
														)}
													>
														<ListPlus className="mr-2 h-4 w-4" />
														Plan
													</Button>
													<Button
														onClick={() => enrollSection(section, course)}
														disabled={enrolling === section.sectionId}
													>
														{enrolling === section.sectionId ? (
															<>
																<Loader2 className="mr-2 h-4 w-4 animate-spin" />
																Submitting...
															</>
														) : full ? (
															<>
																<Hourglass className="mr-2 h-4 w-4" />
																Join waitlist
															</>
														) : (
															<>
																<UserCheck className="mr-2 h-4 w-4" />
																Enroll
															</>
														)}
													</Button>
												</div>
											</div>
										</div>
									);
								})}
							</CardContent>
						</Card>
					</div>

					<Card className="mt-4">
						<CardHeader>
							<CardTitle>Planner (next term)</CardTitle>
							<CardDescription>
								Validate availability, then enroll or move items back to search.
							</CardDescription>
						</CardHeader>
						<CardContent className="space-y-3">
							{planner.length === 0 && (
								<p className="text-sm text-muted-foreground">
									No items in your planner yet. Add sections from the search panel.
								</p>
							)}

							{plannedSections.map(({ course, section }) => (
								<div key={section.sectionId} className={styles.planRow}>
									<div>
										<div className={styles.courseCode}>
											{course.courseCode} {section.sectionCode || ""}
										</div>
										<div className={styles.courseTitle}>{course.courseName}</div>
										<div className={styles.metaRow}>
											<Clock className="h-4 w-4 text-muted-foreground" />
											<span>
												{formatMeetingDays(section.meetingDays)} -{" "}
												{formatTimeLabel(section.startTime)} to{" "}
												{formatTimeLabel(section.endTime)}
											</span>
										</div>
									</div>
									<div className={styles.actionsCol}>
										<Button
											variant="outline"
											onClick={() =>
												setPlanner((prev) =>
													prev.filter((p) => p.sectionId !== section.sectionId)
												)
											}
										>
											<XCircle className="mr-2 h-4 w-4" />
											Remove
										</Button>
										<Button
											onClick={() => enrollSection(section, course)}
											disabled={enrolling === section.sectionId}
										>
											{enrolling === section.sectionId ? (
												<>
													<Loader2 className="mr-2 h-4 w-4 animate-spin" />
													Submitting...
												</>
											) : (
												<>
													<UserCheck className="mr-2 h-4 w-4" />
													Enroll
												</>
											)}
										</Button>
									</div>
								</div>
							))}
						</CardContent>
					</Card>
				</TabsContent>

				<TabsContent value="schedule">
					<Card>
						<CardHeader className="flex flex-col gap-1 sm:flex-row sm:items-center sm:justify-between">
							<div>
								<CardTitle>Current schedule & waitlists</CardTitle>
								<CardDescription>
									Drop courses or see where you stand in the waitlist.
								</CardDescription>
							</div>
							<Button variant="secondary" onClick={() => refreshEnrollments(studentId)}>
								<RefreshCcw className="mr-2 h-4 w-4" />
								Refresh
							</Button>
						</CardHeader>
						<CardContent className="space-y-3">
							{enrollmentsLoading && (
								<div className={styles.loadingRow}>
									<Spinner size="sm" />
									<span>Loading schedule...</span>
								</div>
							)}

							{!enrollmentsLoading && enrollmentDetails.length === 0 && (
								<p className="text-sm text-muted-foreground">
									You are not enrolled or waitlisted for any courses yet.
								</p>
							)}

							{enrollmentDetails.map((record) => (
								<div key={record.enrollmentId} className={styles.scheduleRow}>
									<div className={styles.scheduleMain}>
										<div className={styles.courseCode}>
											{record.course.courseCode}{" "}
											{record.section.sectionCode || ""}
										</div>
										<div className={styles.courseTitle}>
											{record.course.courseName}
										</div>
										<div className={styles.metaRow}>
											<Clock className="h-4 w-4 text-muted-foreground" />
											<span>
												{formatMeetingDays(record.section.meetingDays)} -{" "}
												{formatTimeLabel(record.section.startTime)} to{" "}
												{formatTimeLabel(record.section.endTime)}
											</span>
										</div>
										<div className={styles.metaRow}>
											<Hourglass className="h-4 w-4 text-muted-foreground" />
											<span>
												Status: {statusPill(record.status)}{" "}
												{record.status === "WAITLISTED" &&
													record.waitlistPosition !== null &&
													record.waitlistPosition !== undefined && (
														<span className="ml-2 text-muted-foreground">
															Position {record.waitlistPosition}
														</span>
													)}
											</span>
										</div>
									</div>
									<div className={styles.actionsCol}>
										<Button
											variant="outline"
											onClick={() => dropSection(record)}
											disabled={dropping === record.lectureSectionId}
										>
											{dropping === record.lectureSectionId ? (
												<>
													<Loader2 className="mr-2 h-4 w-4 animate-spin" />
													Dropping...
												</>
											) : (
												<>
													<AlertCircle className="mr-2 h-4 w-4" />
													Drop
												</>
											)}
										</Button>
									</div>
								</div>
							))}
						</CardContent>
					</Card>
				</TabsContent>
			</Tabs>
		</div>
	);
}
