"use client";

import React from "react";
import { useRouter } from "next/navigation";
import { ArrowLeft, AlertCircle, CheckCircle, ShoppingCart, Clock } from "lucide-react";
import s from "../../homepage/styles.module.css";
import cardStyles from "../../components/Card/styles.module.css";
import { API_BASE } from "@/lib/api";
import { Spinner } from "../../components/Others/spinner";

type CartItem = {
	sectionId: number;
	sectionCode: string | null;
	courseId: number;
	courseCode: string;
	courseName: string;
	creditHours?: number | null;
	meetingDays?: string[] | null;
	startTime?: string | null;
	endTime?: string | null;
	term?: string | null;
	academicYear?: number | null;
	sectionStatus?: string | null;
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

function seatsLabel(section: CartItem) {
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

export default function EnrollmentPage() {
	const router = useRouter();
	const { toast } = require("@/hooks/useToast");
	const [cart, setCart] = React.useState<CartItem[]>([]);
	const [studentId, setStudentId] = React.useState<number | null>(null);
	const [enrolling, setEnrolling] = React.useState<number | null>(null);
	const [loading, setLoading] = React.useState(true);

	React.useEffect(() => {
		const existing = localStorage.getItem("enrollment_cart");
		const cartItems: CartItem[] = existing ? JSON.parse(existing) : [];
		setCart(cartItems);
		setLoading(false);
	}, []);

	React.useEffect(() => {
		const loadStudent = async () => {
			try {
				const email =
					typeof window !== "undefined" ? localStorage.getItem("userEmail") : null;
				if (!email) return;
				const res = await fetch(
					`${API_BASE}/users/student-id?email=${encodeURIComponent(email)}`
				);
				const data = await res.json();
				if (res.ok && typeof data.student_id === "number" && data.student_id >= 0) {
					setStudentId(data.student_id);
				}
			} catch (e: any) {
				toast({
					variant: "destructive",
					title: "Could not load your student record",
					description: e?.message || "Sign in again and retry.",
				});
			}
		};
		loadStudent();
	}, [toast]);

	const removeFromCart = (sectionId: number) => {
		const updatedCart = cart.filter((c) => c.sectionId !== sectionId);
		setCart(updatedCart);
		localStorage.setItem("enrollment_cart", JSON.stringify(updatedCart));
	};

	const enroll = async (item: CartItem) => {
		if (!studentId) {
			toast({
				variant: "destructive",
				title: "Login required",
				description: "We could not resolve your student ID.",
			});
			return;
		}
		setEnrolling(item.sectionId);
		try {
			const res = await fetch(`${API_BASE}/enrollments/enroll`, {
				method: "POST",
				headers: { "Content-Type": "application/json" },
				body: JSON.stringify({
					studentId,
					lectureSectionId: item.sectionId,
					labSectionId: null,
				}),
			});
			const data = await res.json().catch(() => null);
			if (!res.ok) {
				throw new Error(data?.message || data?.error || "Enrollment failed");
			}
			removeFromCart(item.sectionId);
			toast({
				title: "Request submitted",
				description:
					(data?.status && String(data.status).toUpperCase() === "WAITLISTED")
						? "Added to waitlist; you'll be promoted when a seat opens."
						: "Enrollment successful.",
			});
		} catch (e: any) {
			toast({
				variant: "destructive",
				title: "Unable to enroll",
				description: e?.message || "Please try again later.",
			});
		} finally {
			setEnrolling(null);
		}
	};

	if (loading) {
		return (
			<div className={s.contentWrapper}>
				<div className={s.mainGrid}>
					<div className={s.scheduleCard}>
						<div className="flex items-center gap-2 text-muted-foreground text-sm">
							<Spinner size="sm" />
							<span>Loading enrollment cart...</span>
						</div>
					</div>
				</div>
			</div>
		);
	}

	if (cart.length === 0) {
		return (
			<div className={s.contentWrapper}>
				<div className={s.mainGrid}>
					<div className={s.scheduleCard}>
						<button
							onClick={() => router.push("/courses")}
							className="flex items-center gap-1 text-sm text-primary hover:underline mb-4"
						>
							<ArrowLeft className="h-4 w-4" />
							Back to Courses
						</button>

						<div className="text-center py-8">
							<ShoppingCart className="h-12 w-12 mx-auto text-muted-foreground mb-4" />
							<p className="text-muted-foreground">Your enrollment cart is empty</p>
							<button
								onClick={() => router.push("/courses/search")}
								className="mt-4 px-4 py-2 bg-primary text-primary-foreground rounded-md hover:bg-primary/90"
							>
								Search for Courses
							</button>
						</div>
					</div>
				</div>
			</div>
		);
	}

	return (
		<div className={s.contentWrapper}>
			<div className={s.mainGrid}>
				<div className={s.scheduleCard}>
					<div className="flex items-center justify-between mb-6">
						<div>
							<button
								onClick={() => router.push("/courses")}
								className="flex items-center gap-1 text-sm text-primary hover:underline mb-2"
							>
								<ArrowLeft className="h-4 w-4" />
								Back to Courses
							</button>
							<h2 className={cardStyles.scheduleTitle}>Enrollment Review</h2>
							<p className="text-sm text-muted-foreground mt-1">
								Check availability and submit enrollment for selected sections.
							</p>
						</div>
					</div>

					<div className="space-y-4">
						{cart.map((course) => (
							<div key={course.sectionId} className="border rounded-lg p-4 bg-card">
								<div className="flex justify-between items-start mb-3">
									<div>
										<h3 className="font-semibold text-lg">
											{course.courseCode} {course.sectionCode || ""}
										</h3>
										<p className="text-sm text-muted-foreground">{course.courseName}</p>
										<div className="text-sm text-muted-foreground mt-1 space-y-1">
											<div>
												{formatMeetingDays(course.meetingDays)} -{" "}
												{formatTimeLabel(course.startTime)} to{" "}
												{formatTimeLabel(course.endTime)}
											</div>
											<div>{course.term || "Term TBD"}</div>
											<div>{seatsLabel(course)}</div>
										</div>
									</div>

									<div className="flex gap-2">
										<button
											onClick={() => removeFromCart(course.sectionId)}
											className="px-3 py-1 text-sm border rounded hover:bg-secondary/50"
										>
											Remove
										</button>
										<button
											onClick={() => enroll(course)}
											disabled={enrolling === course.sectionId}
											className="px-3 py-1 text-sm bg-primary text-primary-foreground rounded hover:bg-primary/90 disabled:opacity-50"
										>
											{enrolling === course.sectionId ? "Submitting..." : "Enroll"}
										</button>
									</div>
								</div>
								{course.sectionStatus && (
									<div className="flex items-start gap-2 text-sm text-yellow-700">
										<AlertCircle className="h-4 w-4 mt-0.5" />
										<span>{course.sectionStatus}</span>
									</div>
								)}
							</div>
						))}
					</div>

					{cart.length > 0 && (
						<div className="mt-6 pt-6 border-t">
							<div className="flex justify-between items-center">
								<div className="text-sm text-muted-foreground">
									Total Credits:{" "}
									{cart.reduce((sum, c) => sum + (c.creditHours ?? 0), 0)}
								</div>
								<div className="text-sm text-muted-foreground">
									{cart.length} course{cart.length !== 1 ? "s" : ""} in cart
								</div>
							</div>
						</div>
					)}
				</div>
			</div>
		</div>
	);
}
