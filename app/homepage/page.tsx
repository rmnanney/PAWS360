"use client";

import React, { useEffect, useState } from "react";
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
import useAuth from "../hooks/useAuth";

interface StudentProfile {
	user_id: number;
	firstname: string;
	lastname: string;
	preferred_name?: string;
	email: string;
	campus_id?: string;
	department?: string;
	standing?: string;
	gpa?: number;
	expected_graduation?: string;
	enrollment_status?: string;
}

export default function Homepage() {
	const bgImage = PlaceHolderImages.find((img) => img.id === "uwm-building");
	const router = useRouter();
	const { authChecked, isAuthenticated, user, isLoading } = useAuth();
	const [studentProfile, setStudentProfile] = useState<StudentProfile | null>(
		null
	);
	const [profileLoading, setProfileLoading] = useState(false);

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
		} else if (section === "Quick Links") {
			router.push("/quick-links");
		} else if (section === "Handshake") {
			window.open("https://uwm.joinhandshake.com/", "_blank");
		} else if (section === "Class Search/Catalog") {
			router.push("/courses");
		} else if (section === "Holds/To Do List") {
			router.push("/holds-tasks");
		}
	};

	/**
	 * Fetch student profile data from unified backend
	 */
	const fetchStudentProfile = async () => {
		if (!isAuthenticated) return;

		setProfileLoading(true);
		try {
			const response = await fetch("/api/profile/student", {
				method: "GET",
				credentials: "include", // Include SSO session cookie
				headers: {
					"X-Service-Origin": "student-portal",
				},
			});

			if (response.ok) {
				const data = await response.json();
				setStudentProfile(data);
			} else {
				console.error("Failed to fetch student profile:", response.status);
			}
		} catch (error) {
			console.error("Error fetching student profile:", error);
		} finally {
			setProfileLoading(false);
		}
	};

	// Load student profile when authenticated
	useEffect(() => {
		if (authChecked && isAuthenticated) {
			fetchStudentProfile();
		}
	}, [authChecked, isAuthenticated]);

	// Show loading state while checking authentication
	if (isLoading || !authChecked) {
		return (
			<div className={s.contentWrapper}>
				<div className="flex items-center justify-center h-64">
					<div className="text-lg">Loading...</div>
				</div>
			</div>
		);
	}

	// Redirect handled by useAuth hook if not authenticated
	if (!isAuthenticated) {
		return null;
	}

	const displayName =
		studentProfile?.preferred_name || user?.firstname || "Student";
	const welcomeMessage = studentProfile
		? `Welcome back, ${displayName}!`
		: `Welcome, ${displayName}!`;

	return (
		<div
			className={s.contentWrapper}
			style={
				{
					"--bg-image": bgImage ? `url('${bgImage.imageUrl}')` : "none",
				} as React.CSSProperties
			}
		>
			{/* Welcome Message with Student Info */}
			<div className={s.welcomeSection}>
				<h1 className={s.welcomeTitle}>{welcomeMessage}</h1>
				{studentProfile && (
					<div className={s.studentInfo}>
						<div className={s.studentDetails}>
							{studentProfile.campus_id && (
								<span className={s.studentDetail}>
									ID: {studentProfile.campus_id}
								</span>
							)}
							{studentProfile.department && (
								<span className={s.studentDetail}>
									Department: {studentProfile.department}
								</span>
							)}
							{studentProfile.standing && (
								<span className={s.studentDetail}>
									Standing: {studentProfile.standing}
								</span>
							)}
							{studentProfile.gpa && (
								<span className={s.studentDetail}>
									GPA: {studentProfile.gpa.toFixed(2)}
								</span>
							)}
						</div>
					</div>
				)}
				{profileLoading && (
					<div className={s.loadingProfile}>Loading student information...</div>
				)}
			</div>

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
						onClick={() => handleCardClick("Class Search/Catalog")}
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
