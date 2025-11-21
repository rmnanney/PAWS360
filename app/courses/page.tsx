"use client";

import React from "react";
import { Calendar, Clock, Search } from "lucide-react";
import s from "../homepage/styles.module.css";
import cardStyles from "../components/Card/styles.module.css";
import { useRouter } from "next/navigation";

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
};

export default function CoursesPage() {
	const router = useRouter();

	return (
		<div className={s.contentWrapper}>
			<div className={s.mainGrid}>
				<div className={s.leftCards}>
					<CurrentlyEnrolledCard />
				</div>

				<div className={s.scheduleCard}>
					<EnrollmentCart />

					<div style={{ marginTop: 16 }}>
						<button
							className={cardStyles.scheduleViewButton}
							onClick={() => router.push("/courses/search")}
						>
							<Search className="inline h-4 w-4 mr-2" />
							Class Search
						</button>
					</div>
				</div>
			</div>
		</div>
	);
}

function CurrentlyEnrolledCard() {
	const [items, setItems] = React.useState<
		Array<{
			course: string;
			title: string;
			meeting_pattern: string;
			instructor: string;
			credits: number;
			room: string;
		}>
	>([]);
	const { toast } = require("@/hooks/useToast");
	const { API_BASE } = require("@/lib/api");

	React.useEffect(() => {
		const load = async () => {
			try {
				const email =
					typeof window !== "undefined" ? localStorage.getItem("userEmail") : null;
				if (!email) return;
				const sidRes = await fetch(
					`${API_BASE}/users/student-id?email=${encodeURIComponent(email)}`
				);
				const sidData = await sidRes.json();
				if (!sidRes.ok || typeof sidData.student_id !== "number" || sidData.student_id < 0)
					return;
				const res = await fetch(
					`${API_BASE}/api/course-search/student/${sidData.student_id}/all-enrolled`
				);
				if (!res.ok) return;
				const data = await res.json();
				const mapped = (data || []).map((d: any) => ({
					course: d.course_code,
					title: d.title,
					meeting_pattern: d.meeting_pattern || "TBD",
					instructor: d.instructor || "TBD",
					credits: d.credits || 0,
					room: d.room || "TBD",
				}));
				setItems(mapped);
			} catch (e: any) {
				toast({
					variant: "destructive",
					title: "Failed to load enrolled classes",
					description: e?.message || "Try again later.",
				});
			}
		};
		load();
	}, [toast]);

	return (
		<div className={cardStyles.scheduleCard}>
			<div className={cardStyles.scheduleHeader}>
				<Calendar className="h-6 w-6 text-primary" />
				<h3 className={cardStyles.scheduleTitle}>Currently Enrolled Classes</h3>
			</div>

			<div className="space-y-3">
				{items.map((classItem, index) => (
					<div key={index} className={cardStyles.scheduleClass}>
						<div className={cardStyles.scheduleClassInfo}>
							<div className={cardStyles.scheduleClassTime}>
								<Clock className="h-4 w-4" />
							</div>
							<div>
								<p className="font-medium text-card-foreground">{classItem.course}</p>
								<p className="text-sm text-muted-foreground">{classItem.title}</p>
								<div className="text-xs text-muted-foreground mt-1">
									{classItem.meeting_pattern && (
										<div>Schedule: {classItem.meeting_pattern}</div>
									)}
									{classItem.instructor && (
										<div>Instructor: {classItem.instructor}</div>
									)}
								</div>
							</div>
						</div>
						<div className="text-sm text-muted-foreground">
							<div>{classItem.room}</div>
							<div>{classItem.credits} cr</div>
						</div>
					</div>
				))}
				{items.length === 0 && (
					<div className="text-sm text-muted-foreground">No enrolled classes.</div>
				)}
			</div>
		</div>
	);
}

function EnrollmentCart() {
	const router = useRouter();
	const [cartItems, setCartItems] = React.useState<CartItem[]>([]);

	React.useEffect(() => {
		const loadCart = () => {
			try {
				const cartKey = "enrollment_cart";
				const existingCart = localStorage.getItem(cartKey);
				const cart: CartItem[] = existingCart ? JSON.parse(existingCart) : [];
				setCartItems(cart);
			} catch (err) {
				console.error("Failed to load cart:", err);
			}
		};
		loadCart();
		window.addEventListener("storage", loadCart);
		return () => window.removeEventListener("storage", loadCart);
	}, []);

	const removeFromCart = (sectionId: number) => {
		try {
			const cartKey = "enrollment_cart";
			const filtered = cartItems.filter((item) => item.sectionId !== sectionId);
			localStorage.setItem(cartKey, JSON.stringify(filtered));
			setCartItems(filtered);
		} catch (err) {
			console.error("Failed to remove from cart:", err);
		}
	};

	return (
		<div className={cardStyles.scheduleCard}>
			<div className={cardStyles.scheduleHeader}>
				<Calendar className="h-6 w-6 text-primary" />
				<h3 className={cardStyles.scheduleTitle}>Enrollment Shopping Cart</h3>
			</div>

			<div className="space-y-3">
				{cartItems.length === 0 ? (
					<div className={cardStyles.scheduleClass}>
						<div className={cardStyles.scheduleClassInfo}>
							<div className={cardStyles.scheduleClassTime}>
								<Clock className="h-4 w-4" />
								<span>-</span>
							</div>
							<div>
								<p className="font-medium text-card-foreground">No items</p>
								<p className="text-sm text-muted-foreground">
									Add classes from the Class Search to your cart.
								</p>
							</div>
						</div>
						<div className={cardStyles.scheduleClassRoom}>-</div>
					</div>
				) : (
					cartItems.map((item, idx) => (
						<div key={idx} className={cardStyles.scheduleClass}>
							<div className={cardStyles.scheduleClassInfo}>
								<div className={cardStyles.scheduleClassTime}>
									<Clock className="h-4 w-4" />
								</div>
								<div>
									<p className="font-medium text-card-foreground">
										{item.courseCode} {item.sectionCode || ""}
									</p>
									<p className="text-sm text-muted-foreground">{item.courseName}</p>
									<p className="text-xs text-muted-foreground">
										{item.term || "Term TBD"}
									</p>
								</div>
							</div>
							<div className="flex items-center gap-2">
								<div className={cardStyles.scheduleClassRoom}>
									{item.creditHours ?? 0} cr
								</div>
								<button
									onClick={() => removeFromCart(item.sectionId)}
									className="text-xs text-destructive hover:underline"
								>
									Remove
								</button>
							</div>
						</div>
					))
				)}
			</div>

			<div className={cardStyles.scheduleViewFull}>
				<button
					className={cardStyles.scheduleViewButton}
					onClick={() => router.push("/courses/enrollment")}
					disabled={cartItems.length === 0}
				>
					Proceed to Enrollment ->
				</button>
			</div>
		</div>
	);
}
