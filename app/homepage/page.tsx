"use client";

import React from "react";
import SearchBar from "../components/SearchBar/searchbar";
import { HomepageCard } from "../components/Card/card";
import { ScheduleCard } from "../components/Card/card";
import {
	GraduationCap,
	DollarSign,
	User,
	MessageSquare,
	BookOpen,
	Briefcase,
	AlertCircle,
	Link,
	MoreHorizontal,
	CalendarDays,
	Search,
} from "lucide-react";

import s from "./styles.module.css";

import { PlaceHolderImages } from "@/lib/placeholder-img";
import { useRouter } from "next/navigation";

export default function Homepage() {
	const bgImage = PlaceHolderImages.find((img) => img.id === "uwm-building");
	const router = useRouter();

	const handleCardClick = (section: string) => {
		if (section === "Academic") {
			router.push("/academic");
		} else if (section === "Advising") {
			router.push("/advising");
		} else if (section === "Finances") {
			router.push("/finances");
		} else if (section === "Personal Information") {
			router.push("/personal");
		} else if (section === "Resources") {
			router.push("/resources");
		} else if (section === "Enrollment Date") {
			router.push("/enrollment-date");
		} else if (section === "Handshake") {
			window.open("https://uwm.joinhandshake.com/", "_blank");
		}
	};

	return (
		<div
			className={s.contentWrapper}
			style={
				{
					"--bg-image": bgImage ? `url('${bgImage.imageUrl}')` : "none",
				} as React.CSSProperties
			}
		>
			{/* Search Bar */}
			<div className={s.mainGrid}>
				{/* Main Grid Cards */}
				<div className={s.leftCards}>
					<HomepageCard
						title="Academic"
						icon={GraduationCap}
						description="Grades, transcripts, and academic records"
						onClick={() => handleCardClick("Academic")}
					/>
					<HomepageCard
						title="Advising"
						icon={MessageSquare}
						description="Meet with advisors and plan your academic journey"
						onClick={() => handleCardClick("Advising")}
					/>
					<HomepageCard
						title="Finances"
						icon={DollarSign}
						description="Tuition, fees, and financial aid"
						onClick={() => handleCardClick("Finances")}
					/>
					<HomepageCard
						title="Personal Information"
						icon={User}
						description="Update your personal details"
						onClick={() => handleCardClick("Personal Information")}
					/>
				</div>
				<div className={s.scheduleCard}>
					<ScheduleCard />
				</div>
				<div className={s.bottomGrid}>
					<HomepageCard
						title="Resources"
						icon={BookOpen}
						description="Library, tutoring, and study resources"
						onClick={() => handleCardClick("Resources")}
					/>
					<HomepageCard
						title="Handshake"
						icon={Briefcase}
						description="Career services and job opportunities"
						onClick={() => handleCardClick("Handshake")}
					/>
					<HomepageCard
						title="Holds & Tasks"
						icon={AlertCircle}
						description="Important items requiring attention"
						onClick={() => handleCardClick("Holds/To Do List")}
					/>
					<HomepageCard
						title="Enrollment Date"
						icon={CalendarDays}
						description="View enrollment dates and registration periods"
						onClick={() => handleCardClick("Enrollment Date")}
					/>
					<HomepageCard
						title="Class Search"
						icon={Search}
						description="Search course catalog and class schedules"
						onClick={() => router.push("/courses")}
					/>
					<HomepageCard
						title="Quick Links"
						icon={Link}
						description="Frequently accessed tools and links"
						onClick={() => handleCardClick("Quick Links")}
					/>
				</div>
			</div>
		</div>
	);
}
