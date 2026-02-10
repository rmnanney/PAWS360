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
    const [weeklySchedule, setWeeklySchedule] = React.useState<Record<string, Array<{ time: string; course: string; title: string; room: string }>>>({});
    const [loading, setLoading] = React.useState(true);
    const { toast } = require("@/hooks/useToast");
    const { API_BASE } = require("@/lib/api");

    const days = ['MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'TBD'];
    const dayAbbr: Record<string, string> = {
        'MONDAY': 'Mon',
        'TUESDAY': 'Tue',
        'WEDNESDAY': 'Wed',
        'THURSDAY': 'Thu',
        'FRIDAY': 'Fri',
        'TBD': 'TBD',
    };

    React.useEffect(() => {
        const load = async () => {
            try {
                const email = typeof window !== "undefined" 
                    ? (sessionStorage.getItem("userEmail") || localStorage.getItem("userEmail"))
                    : null;
                if (!email) return;
                const sidRes = await fetch(`${API_BASE}/users/student-id?email=${encodeURIComponent(email)}`);
                const sidData = await sidRes.json();
                if (!sidRes.ok || typeof sidData.student_id !== "number" || sidData.student_id < 0) return;
                const res = await fetch(`${API_BASE}/api/course-search/student/${sidData.student_id}/weekly-schedule`);
                if (!res.ok) return;
                const data = await res.json();
                
                // Group classes by day
                const grouped: Record<string, Array<{ time: string; course: string; title: string; room: string }>> = {};
                days.forEach(day => { grouped[day] = []; });
                
                // Track courses we've already added to avoid duplicates
                const addedCourses = new Set<string>();
                
                (data || []).forEach((d: any) => {
                    const courseKey = `${d.course_code}-${d.title}`;
                    const day = d.meeting_day?.toUpperCase();
                    if (day && grouped[day]) {
                        grouped[day].push({
                            time: d.start_time ? new Date(`1970-01-01T${d.start_time}`).toLocaleTimeString([], { hour: 'numeric', minute: '2-digit' }) : "TBD",
                            course: d.course_code,
                            title: d.title,
                            room: d.room || "TBD",
                        });
                        addedCourses.add(courseKey);
                    } else if (!day && !addedCourses.has(courseKey)) {
                        // Course has no scheduled meeting day - add to TBD section
                        grouped['TBD'].push({
                            time: d.start_time ? new Date(`1970-01-01T${d.start_time}`).toLocaleTimeString([], { hour: 'numeric', minute: '2-digit' }) : "TBD",
                            course: d.course_code,
                            title: d.title,
                            room: d.room || "TBD",
                        });
                        addedCourses.add(courseKey);
                    }
                });
                
                setWeeklySchedule(grouped);
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
				<h3 className={s.scheduleTitle}>This Week's Schedule</h3>
			</div>

			{/* Weekly schedule grid */}
			<div className="space-y-4">
				{days.map((day) => (
					<div key={day} className="space-y-2">
						<h4 className="font-semibold text-sm text-muted-foreground">{dayAbbr[day]}</h4>
						{weeklySchedule[day]?.length > 0 ? (
							<div className="space-y-2">
								{weeklySchedule[day].map((classItem, index) => (
									<div key={index} className={s.scheduleClass}>
										<div className={s.scheduleClassInfo}>
											<div className={s.scheduleClassTime}>
												<Clock className="h-4 w-4" />
												<span>{classItem.time}</span>
											</div>
											<div>
												<p className="font-medium text-card-foreground text-sm">
													{classItem.course}
												</p>
												<p className="text-xs text-muted-foreground">
													{classItem.title}
												</p>
											</div>
										</div>
										<div className={s.scheduleClassRoom}>{classItem.room}</div>
									</div>
								))}
							</div>
						) : (
							<div className="text-xs text-muted-foreground ml-4">No classes</div>
						)}
					</div>
				))}
			</div>

			{/* Footer with view full schedule link */}
			<div className={s.scheduleViewFull}>
				<button className={s.scheduleViewButton}>View Full Schedule →</button>
			</div>
		</Card>
	);
}
