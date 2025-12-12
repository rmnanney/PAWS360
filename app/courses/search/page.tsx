"use client";

import React from "react";
import s from "../../homepage/styles.module.css";
import cardStyles from "../../components/Card/styles.module.css";
import { API_BASE } from "@/lib/api";
import { Clock, ArrowLeft, ShoppingCart, RefreshCcw } from "lucide-react";
import { useRouter } from "next/navigation";
import { Spinner } from "../../components/Others/spinner";

type CourseSection = {
	sectionId: number;
	sectionType: string;
	sectionCode: string | null;
	meetingDays?: string[] | null;
	startTime?: string | null;
	endTime?: string | null;
	maxEnrollment?: number | null;
	currentEnrollment?: number | null;
	waitlistCapacity?: number | null;
	currentWaitlist?: number | null;
	term?: string | null;
	academicYear?: number | null;
	parentSectionId?: number | null;
};

type CourseCatalog = {
	courseId: number;
	courseCode: string;
	courseName: string;
	creditHours?: number | null;
	term?: string | null;
	sections?: CourseSection[] | null;
};

type SectionResult = {
	section: CourseSection;
	course: CourseCatalog;
};

type CartItem = {
	sectionId: number;
	sectionCode: string | null;
	courseId: number;
	courseCode: string;
	courseName: string;
	creditHours?: number | null;
	term?: string | null;
	academicYear?: number | null;
	meetingDays?: string[] | null;
	startTime?: string | null;
	endTime?: string | null;
	maxEnrollment?: number | null;
	currentEnrollment?: number | null;
	waitlistCapacity?: number | null;
	currentWaitlist?: number | null;
};

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

function formatTimeLabel(value?: string | null) {
	if (!value) return "Time TBD";
	const [hours = 0, minutes = 0] = value.split(":").map((v) => parseInt(v, 10));
	const date = new Date();
	date.setHours(hours);
	date.setMinutes(minutes);
	return new Intl.DateTimeFormat("en-US", {
		hour: "numeric",
		minute: "2-digit",
	}).format(date);
}

function seatsLabel(section: CourseSection) {
	const max = section.maxEnrollment ?? 0;
	const current = section.currentEnrollment ?? 0;
	const waitCap = section.waitlistCapacity ?? 0;
	const waitCur = section.currentWaitlist ?? 0;

	if (max > 0 && current >= max) {
		if (waitCap === 0) return "Full - no waitlist";
		if (waitCur >= waitCap) return "Waitlist full";
		return `${waitCap - waitCur} waitlist spots left`;
	}
	if (max > 0) return `${Math.max(0, max - current)} seats open`;
	return "Open seats";
}

export default function CourseSearchPage() {
	const router = useRouter();
	const { toast } = require("@/hooks/useToast");
	const [loading, setLoading] = React.useState(true);
	const [catalog, setCatalog] = React.useState<CourseCatalog[]>([]);
	const [selected, setSelected] = React.useState<SectionResult | null>(null);
	const [filters, setFilters] = React.useState({
		subject: "",
		courseCode: "",
		title: "",
		term: "",
		openOnly: false,
		startTime: "",
		endTime: "",
		days: [] as string[],
	});

	React.useEffect(() => {
		const load = async () => {
			setLoading(true);
			try {
				const res = await fetch(`${API_BASE}/courses`);
				if (res.ok) {
					setCatalog(await res.json());
				} else {
					throw new Error("Unable to load course catalog");
				}
			} catch (e: any) {
				toast({
					variant: "destructive",
					title: "Course catalog unavailable",
					description: e?.message || "Try again later.",
				});
			} finally {
				setLoading(false);
			}
		};
		load();
	}, [toast]);

	const filteredSections = React.useMemo(() => {
		const subj = filters.subject.trim().toUpperCase();
		const code = filters.courseCode.trim().toUpperCase();
		const title = filters.title.trim().toUpperCase();
		const term = filters.term.trim().toUpperCase();

		const list: SectionResult[] = [];
		catalog.forEach((course) => {
			(course.sections || []).forEach((section) => {
				if (!section || (section.sectionType || "").toUpperCase() !== "LECTURE") return;
				if (subj && !course.courseCode.toUpperCase().startsWith(subj)) return;
				if (code && !course.courseCode.toUpperCase().includes(code)) return;
				if (title && !course.courseName.toUpperCase().includes(title)) return;
				const sectionTerm = (section.term || course.term || "").toUpperCase();
				if (term && !sectionTerm.includes(term)) return;
				
				// Filter by open seats
				if (filters.openOnly) {
					const max = section.maxEnrollment ?? 0;
					const current = section.currentEnrollment ?? 0;
					if (max > 0 && current >= max) return; // Full, skip it
				}
				
				// Filter by time range
				if (filters.startTime && section.startTime) {
					const sectionStart = section.startTime.replace(":", "");
					const filterStart = filters.startTime.replace(":", "");
					if (sectionStart < filterStart) return;
				}
				if (filters.endTime && section.endTime) {
					const sectionEnd = section.endTime.replace(":", "");
					const filterEnd = filters.endTime.replace(":", "");
					if (sectionEnd > filterEnd) return;
				}
				
				// Filter by days of week
				if (filters.days.length > 0 && section.meetingDays && section.meetingDays.length > 0) {
					const hasMatchingDay = section.meetingDays.some(day => 
						filters.days.includes(day.toUpperCase())
					);
					if (!hasMatchingDay) return;
				}
				
				list.push({ section, course });
			});
		});
		return list;
	}, [catalog, filters]);

	const addToCart = () => {
		if (!selected) {
			toast({
				variant: "destructive",
				title: "No section selected",
				description: "Choose a section before adding to your cart.",
			});
			return;
		}
		try {
			const cartKey = "enrollment_cart";
			const existing = localStorage.getItem(cartKey);
			const cart: CartItem[] = existing ? JSON.parse(existing) : [];
			if (cart.some((c) => c.sectionId === selected.section.sectionId)) {
				toast({
					variant: "destructive",
					title: "Already in cart",
					description: "This section is already in your enrollment cart.",
				});
				return;
			}
			const item: CartItem = {
				sectionId: selected.section.sectionId,
				sectionCode: selected.section.sectionCode,
				courseId: selected.course.courseId,
				courseCode: selected.course.courseCode,
				courseName: selected.course.courseName,
				creditHours: selected.course.creditHours,
				term: selected.section.term || selected.course.term,
				academicYear: selected.section.academicYear,
				meetingDays: selected.section.meetingDays,
				startTime: selected.section.startTime,
				endTime: selected.section.endTime,
				maxEnrollment: selected.section.maxEnrollment,
				currentEnrollment: selected.section.currentEnrollment,
				waitlistCapacity: selected.section.waitlistCapacity,
				currentWaitlist: selected.section.currentWaitlist,
			};
			const updated = [...cart, item];
			localStorage.setItem(cartKey, JSON.stringify(updated));
			toast({
				title: "Added to cart",
				description: `${selected.course.courseCode} ${selected.section.sectionCode || ""} added.`,
			});
		} catch (e: any) {
			toast({
				variant: "destructive",
				title: "Failed to add",
				description: e?.message || "Try again.",
			});
		}
	};

	const renderSection = (item: SectionResult) => {
		const { course, section } = item;
		const selectedKey = selected?.section.sectionId === section.sectionId;
		const meeting = `${formatMeetingDays(section.meetingDays)} | ${formatTimeLabel(
			section.startTime
		)} - ${formatTimeLabel(section.endTime)}`;
		return (
			<div
				key={section.sectionId}
				className={`${cardStyles.scheduleClass} cursor-pointer transition-all ${
					selectedKey ? "ring-2 ring-primary bg-primary/10" : "hover:bg-secondary/70"
				}`}
				onClick={() => setSelected(item)}
			>
				<div className={cardStyles.scheduleClassInfo}>
					<div className={cardStyles.scheduleClassTime}>
						<Clock className="h-4 w-4" />
					</div>
					<div>
						<p className="font-medium text-card-foreground">
							{course.courseCode} {section.sectionCode || ""}
						</p>
						<p className="text-sm text-muted-foreground">{course.courseName}</p>
						<div className="text-xs text-muted-foreground mt-1 space-y-1">
							<div>{meeting}</div>
							<div>
								{section.term || "Term TBD"} | {seatsLabel(section)}
							</div>
						</div>
					</div>
				</div>
			</div>
		);
	};

	const clearFilters = () =>
		setFilters({ subject: "", courseCode: "", title: "", term: "", openOnly: false, startTime: "", endTime: "", days: [] });

	return (
		<div className={s.contentWrapper}>
			<div className={s.mainGrid}>
				<div className={s.leftCards}>
					<div className={cardStyles.scheduleCard}>
						<div className="flex items-center gap-2 mb-4">
							<button
								onClick={() => router.push("/courses")}
								className="flex items-center gap-1 text-sm text-primary hover:underline"
							>
								<ArrowLeft className="h-4 w-4" />
								Back to Courses
							</button>
						</div>
						<h2 className={cardStyles.scheduleTitle}>Course Search</h2>
						<div className="space-y-3 mt-4">
							<div>
								<label className="block text-sm font-medium text-muted-foreground">
									Subject / Department
								</label>
								<input
									className="w-full rounded-md border p-2 bg-background text-foreground"
									value={filters.subject}
									onChange={(e) =>
										setFilters((p) => ({ ...p, subject: e.target.value }))
									}
									placeholder="e.g. ENGLISH, COMP SCI"
								/>
							</div>
							<div>
								<label className="block text-sm font-medium text-muted-foreground">
									Course code
								</label>
								<input
									className="w-full rounded-md border p-2 bg-background text-foreground"
									value={filters.courseCode}
									onChange={(e) =>
										setFilters((p) => ({ ...p, courseCode: e.target.value }))
									}
									placeholder="e.g. ENGLISH 100"
								/>
							</div>
							<div>
								<label className="block text-sm font-medium text-muted-foreground">
									Course title
								</label>
								<input
									className="w-full rounded-md border p-2 bg-background text-foreground"
									value={filters.title}
									onChange={(e) =>
										setFilters((p) => ({ ...p, title: e.target.value }))
									}
									placeholder="Partial course title"
								/>
							</div>
							<div>
								<label className="block text-sm font-medium text-muted-foreground">
									Term (optional)
								</label>
								<input
									className="w-full rounded-md border p-2 bg-background text-foreground"
									value={filters.term}
									onChange={(e) =>
										setFilters((p) => ({ ...p, term: e.target.value }))
									}
									placeholder="e.g. Spring 2026"
								/>
							</div>
							
							<div className="flex items-center gap-2">
								<input
									type="checkbox"
									id="openOnly"
									checked={filters.openOnly}
									onChange={(e) =>
										setFilters((p) => ({ ...p, openOnly: e.target.checked }))
									}
									className="h-4 w-4"
								/>
								<label htmlFor="openOnly" className="text-sm text-muted-foreground cursor-pointer">
									Show only classes with open seats
								</label>
							</div>
							
							<div className="grid grid-cols-2 gap-2">
								<div>
									<label className="block text-sm font-medium text-muted-foreground">
										Start time (earliest)
									</label>
									<input
										type="time"
										className="w-full rounded-md border p-2 bg-background text-foreground"
										value={filters.startTime}
										onChange={(e) =>
											setFilters((p) => ({ ...p, startTime: e.target.value }))
										}
									/>
								</div>
								<div>
									<label className="block text-sm font-medium text-muted-foreground">
										End time (latest)
									</label>
									<input
										type="time"
										className="w-full rounded-md border p-2 bg-background text-foreground"
										value={filters.endTime}
										onChange={(e) =>
											setFilters((p) => ({ ...p, endTime: e.target.value }))
										}
									/>
								</div>
							</div>
							
							<div>
								<label className="block text-sm font-medium text-muted-foreground mb-2">
									Days of week
								</label>
								<div className="flex flex-wrap gap-2">
									{["MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY", "SATURDAY", "SUNDAY"].map((day) => (
										<button
											key={day}
											type="button"
											onClick={() => {
												setFilters((p) => ({
													...p,
													days: p.days.includes(day)
														? p.days.filter((d) => d !== day)
														: [...p.days, day],
												}));
											}}
											className={`px-3 py-1 text-xs rounded-md transition-colors ${
												filters.days.includes(day)
													? "bg-primary text-primary-foreground"
													: "bg-secondary text-secondary-foreground hover:bg-secondary/80"
											}`}
										>
											{day.slice(0, 3)}
										</button>
									))}
								</div>
							</div>
							
							<div className="flex gap-2">
								<button
									type="button"
									className={cardStyles.scheduleViewButton}
									onClick={clearFilters}
								>
									<RefreshCcw className="h-4 w-4 mr-2" />
									Clear
								</button>
							</div>
						</div>
					</div>
				</div>

				<div className={s.scheduleCard}>
					<div className={cardStyles.scheduleHeader}>
						<h3 className={cardStyles.scheduleTitle}>Results</h3>
						{selected && (
							<button
								onClick={addToCart}
								className="flex items-center gap-2 px-4 py-2 bg-primary text-primary-foreground rounded-md hover:bg-primary/90"
							>
								<ShoppingCart className="h-4 w-4" />
								Add to Cart
							</button>
						)}
					</div>

					<div className="space-y-3">
						{loading && (
							<div className="inline-flex items-center gap-2 text-sm text-muted-foreground">
								<Spinner size="sm" />
								<span>Loading courses...</span>
							</div>
						)}
						{!loading && filteredSections.length === 0 && (
							<div className="text-sm text-muted-foreground">
								No sections match your filters. Adjust filters to see more options.
							</div>
						)}
						{!loading && filteredSections.map(renderSection)}
					</div>
				</div>
			</div>
		</div>
	);
}
