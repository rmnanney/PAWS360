"use client";

import React from "react";
import { Card, CardContent, CardHeader, CardTitle } from "../components/Card/card";
import { ExternalLink, MapPin, BookOpen, Calendar, AlertCircle } from "lucide-react";
import { LucideIcon } from "lucide-react";
import s from "./styles.module.css";

// ========================================
// CONFIGURATION: Add or edit links here
// ========================================
interface QuickLink {
	title: string;
	description: string;
	url: string;
	icon: LucideIcon;
	category?: string;
}

const quickLinks: QuickLink[] = [
	{
		title: "Campus Map",
		description: "Interactive map of UWM campus buildings and facilities",
		url: "https://apps.uwm.edu/map/",
		icon: MapPin,
		category: "Campus Resources",
	},
	{
		title: "Canvas",
		description: "Access your course materials and assignments",
		url: "https://uwm.edu/canvas/home/",
		icon: BookOpen,
		category: "Academic Tools",
	},
	{
		title: "Academic Calendar",
		description: "View semester schedules and academic calendars",
		url: "https://uwm.edu/secu/resources/calendars-schedules/",
		icon: Calendar,
		category: "Academic Resources",
	},
	{
		title: "Important Dates",
		description: "Key dates and deadlines for registration and terms",
		url: "https://uwm.edu/registrar/dates-deadlines/important-dates-by-term/",
		icon: AlertCircle,
		category: "Academic Resources",
	},
];

// ========================================
// Component
// ========================================
export default function QuickLinksPage() {
	const handleLinkClick = (url: string) => {
		window.open(url, "_blank", "noopener,noreferrer");
	};

	return (
		<div className={s.container}>
			<div className={s.header}>
				<h1 className={s.title}>Quick Links</h1>
				<p className={s.subtitle}>
					Frequently accessed tools and resources for UWM students
				</p>
			</div>

			<div className={s.grid}>
				{quickLinks.map((link, index) => (
					<Card
						key={index}
						className={s.linkCard}
						onClick={() => handleLinkClick(link.url)}
					>
						<CardHeader>
							<div className={s.cardHeader}>
								<div className={s.iconWrapper}>
									<link.icon className="h-6 w-6 text-primary" />
								</div>
								<ExternalLink className="h-4 w-4 text-muted-foreground" />
							</div>
							<CardTitle className={s.cardTitle}>{link.title}</CardTitle>
						</CardHeader>
						<CardContent>
							<p className={s.description}>{link.description}</p>
							{link.category && (
								<span className={s.category}>{link.category}</span>
							)}
						</CardContent>
					</Card>
				))}
			</div>
		</div>
	);
}
