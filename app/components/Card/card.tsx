"use client";

import * as React from "react";
import { LucideIcon, Calendar, Clock } from "lucide-react";

import { cn } from "../../lib/utils";
import s from "./styles.module.css";
import { Spinner } from "../Others/spinner";

const Card = React.forwardRef<
	HTMLDivElement,
	React.HTMLAttributes<HTMLDivElement>
>(({ className, ...props }, ref) => (
	<div ref={ref} className={cn(s.card, className)} {...props} />
));
Card.displayName = "Card";

const CardHeader = React.forwardRef<
	HTMLDivElement,
	React.HTMLAttributes<HTMLDivElement>
>(({ className, ...props }, ref) => (
	<div ref={ref} className={cn(s.cardHeader, className)} {...props} />
));
CardHeader.displayName = "CardHeader";

const CardTitle = React.forwardRef<
	HTMLDivElement,
	React.HTMLAttributes<HTMLDivElement>
>(({ className, ...props }, ref) => (
	<div ref={ref} className={cn(s.cardTitle, className)} {...props} />
));
CardTitle.displayName = "CardTitle";

const CardDescription = React.forwardRef<
	HTMLDivElement,
	React.HTMLAttributes<HTMLDivElement>
>(({ className, ...props }, ref) => (
	<div ref={ref} className={cn(s.cardDescription, className)} {...props} />
));
CardDescription.displayName = "CardDescription";

const CardContent = React.forwardRef<
	HTMLDivElement,
	React.HTMLAttributes<HTMLDivElement>
>(({ className, ...props }, ref) => (
	<div ref={ref} className={cn(s.cardContent, className)} {...props} />
));
CardContent.displayName = "CardContent";

const CardFooter = React.forwardRef<
	HTMLDivElement,
	React.HTMLAttributes<HTMLDivElement>
>(({ className, ...props }, ref) => (
	<div ref={ref} className={cn(s.cardFooter, className)} {...props} />
));
CardFooter.displayName = "CardFooter";

interface HomepageCardProps {
	title: string;
	icon: LucideIcon;
	description?: string;
	className?: string;
	onClick?: () => void;
}

export {
	Card,
	CardHeader,
	CardFooter,
	CardTitle,
	CardDescription,
	CardContent,
};

export function HomepageCard({
	title,
	icon: Icon,
	description,
	className = "",
	onClick,
}: HomepageCardProps) {
	return (
		<Card className={`${s.homepageCard} ${className}`} onClick={onClick}>
			<div className="flex flex-col items-start space-y-3">
				<div className={s.homepageIcon}>
					<Icon className="h-6 w-6 text-primary" />
				</div>
				<div>
					<h3 className={s.homepageTitle}>{title}</h3>
					{description && (
						<p className={s.homepageDescription}>{description}</p>
					)}
				</div>
			</div>
		</Card>
	);
}

export function ScheduleCard() {
    const [items, setItems] = React.useState<Array<{ time: string; course: string; title: string; room: string }>>([]);
    const [loading, setLoading] = React.useState<boolean>(true);
    const { toast } = require("@/hooks/useToast");
    const { API_BASE } = require("@/lib/api");

    React.useEffect(() => {
        const load = async () => {
            try {
                const email = typeof window !== "undefined" ? localStorage.getItem("userEmail") : null;
                if (!email) return;
                const sidRes = await fetch(`${API_BASE}/users/student-id?email=${encodeURIComponent(email)}`);
                const sidData = await sidRes.json();
                if (!sidRes.ok || typeof sidData.student_id !== "number" || sidData.student_id < 0) {
                    if (sidRes.status === 400) {
                        toast({ variant: "destructive", title: "User not found", description: "Please verify your account." });
                    }
                    return;
                }
                const res = await fetch(`${API_BASE}/enrollments/student/${sidData.student_id}/today-schedule`);
                if (!res.ok) return;
                const data = await res.json();
                const mapped = (data || []).map((d: any) => ({
                    time: d.start_time ? new Date(`1970-01-01T${d.start_time}`).toLocaleTimeString([], { hour: 'numeric', minute: '2-digit' }) : "",
                    course: d.course_code,
                    title: d.title,
                    room: d.room || "TBD",
                }));
                setItems(mapped);
            } catch (e: any) {
                toast({ variant: "destructive", title: "Failed to load schedule", description: e?.message || "Try again later." });
            } finally {
                setLoading(false);
            }
        };
        load();
    }, [toast]);

	return (
		<Card className={s.scheduleCard}>
			{/* Header with calendar icon and title */}
			<div className={s.scheduleHeader}>
				<Calendar className="h-6 w-6 text-primary" />
				<h3 className={s.scheduleTitle}>Today's Schedule</h3>
			</div>

			{/* Schedule items list */}
			{loading ? (
				<div className="flex items-center justify-center text-sm text-muted-foreground" style={{ minHeight: 120 }}>
					<span className="inline-flex items-center gap-2"><Spinner size="sm" /> Loading schedule…</span>
				</div>
			) : (
				<div className="space-y-3">
					{items.map((classItem, index) => (
						<div key={index} className={s.scheduleClass}>
							<div className={s.scheduleClassInfo}>
								<div className={s.scheduleClassTime}>
									<Clock className="h-4 w-4" />
									<span>{classItem.time}</span>
								</div>
								<div>
									<p className="font-medium text-card-foreground">
										{classItem.course}
									</p>
									<p className="text-sm text-muted-foreground">
										{classItem.title}
									</p>
								</div>
							</div>
							<div className={s.scheduleClassRoom}>{classItem.room}</div>
						</div>
					))}
					{items.length === 0 && (
						<div className="text-sm text-muted-foreground">No classes today.</div>
					)}
				</div>
			)}

			{/* Footer with view full schedule link */}
			<div className={s.scheduleViewFull}>
				<button className={s.scheduleViewButton}>View Full Schedule →</button>
			</div>
		</Card>
	);
}
