import * as React from "react";
import { LucideIcon, Calendar, Clock } from "lucide-react";

import { cn } from "../../lib/utils";
import s from "./styles.module.css";

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

interface DashboardCardProps {
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

export function DashboardCard({
	title,
	icon: Icon,
	description,
	className = "",
	onClick,
}: DashboardCardProps) {
	return (
		<Card className={`${s.dashboardCard} ${className}`} onClick={onClick}>
			<div className="flex flex-col items-start space-y-3">
				<div className={s.dashboardIcon}>
					<Icon className="h-6 w-6 text-primary" />
				</div>
				<div>
					<h3 className={s.dashboardTitle}>{title}</h3>
					{description && (
						<p className={s.dashboardDescription}>{description}</p>
					)}
				</div>
			</div>
		</Card>
	);
}

export function ScheduleCard() {
	// Sample schedule data - in a real app, this would come from an API
	const todayClasses = [
		{
			time: "9:00 AM",
			course: "CS 301",
			title: "Data Structures",
			room: "Room 204",
		},
		{
			time: "11:00 AM",
			course: "MATH 205",
			title: "Calculus II",
			room: "Room 156",
		},
		{
			time: "2:00 PM",
			course: "ENG 102",
			title: "English Composition",
			room: "Room 89",
		},
		{
			time: "4:00 PM",
			course: "PHYS 201",
			title: "Physics Lab",
			room: "Lab 3",
		},
	];

	return (
		<Card className={s.scheduleCard}>
			{/* Header with calendar icon and title */}
			<div className={s.scheduleHeader}>
				<Calendar className="h-6 w-6 text-primary" />
				<h3 className={s.scheduleTitle}>Today's Schedule</h3>
			</div>

			{/* Schedule items list */}
			<div className="space-y-3">
				{todayClasses.map((classItem, index) => (
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
			</div>

			{/* Footer with view full schedule link */}
			<div className={s.scheduleViewFull}>
				<button className={s.scheduleViewButton}>View Full Schedule →</button>
			</div>
		</Card>
	);
}
