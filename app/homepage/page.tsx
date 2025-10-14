"use client";

import React from "react";
import { useRouter } from "next/navigation";
import SearchBar from "../components/SearchBar/searchbar";
import { Header } from "../components/Header/header";

import { DashboardCard } from "../components/Card/card";
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

import {
	SidebarInset,
	SidebarProvider,
} from "../components/SideBar/Base/sidebarbase";
import { AppSidebar } from "../components/SideBar/sidebar";
import { PlaceHolderImages } from "@/lib/placeholder-img";

export default function Homepage() {
	const bgImage = PlaceHolderImages.find((img) => img.id === "uwm-building");

	const router = useRouter();
	const [authChecked, setAuthChecked] = React.useState(false);

	React.useEffect(() => {
		if (typeof window !== "undefined") {
			const authToken = localStorage.getItem("authToken");
			if (!authToken) {
				localStorage.setItem("showAuthToast", "true");
				router?.push?.("/login");
				setAuthChecked(false);
			} else {
				setAuthChecked(true);
			}
		}
	}, [router]);

	if (!authChecked) {
		// Optionally show a spinner here
		return null;
	}

	const handleNavigation = (section: string) => {
		console.log(`Navigating to ${section}`);
		// Here you would implement actual navigation logic
	};

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
		} else {
			handleNavigation(section);
		}
	};

	return (
		<SidebarProvider>
			<Header />
			<SidebarInset>
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
							<DashboardCard
								title="Academic"
								icon={GraduationCap}
								description="Grades, transcripts, and academic records"
								onClick={() => handleCardClick("Academic")}
							/>
							<DashboardCard
								title="Advising"
								icon={MessageSquare}
								description="Meet with advisors and plan your academic journey"
								onClick={() => handleCardClick("Advising")}
							/>
							<DashboardCard
								title="Finances"
								icon={DollarSign}
								description="Tuition, fees, and financial aid"
								onClick={() => handleCardClick("Finances")}
							/>
							<DashboardCard
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
							<DashboardCard
								title="Resources"
								icon={BookOpen}
								description="Library, tutoring, and study resources"
								onClick={() => handleCardClick("Resources")}
							/>
							<DashboardCard
								title="Handshake"
								icon={Briefcase}
								description="Career services and job opportunities"
								onClick={() => handleCardClick("Handshake/Workday")}
							/>
							<DashboardCard
								title="Holds & Tasks"
								icon={AlertCircle}
								description="Important items requiring attention"
								onClick={() => handleCardClick("Holds/To Do List")}
							/>
							<DashboardCard
								title="Enrollment Date"
								icon={CalendarDays}
								description="View enrollment dates and registration periods"
								onClick={() => handleCardClick("Enrollment Date")}
							/>
							<DashboardCard
								title="Class Search"
								icon={Search}
								description="Search course catalog and class schedules"
								onClick={() => handleCardClick("Class Search/Catalog")}
							/>
							<DashboardCard
								title="Quick Links"
								icon={Link}
								description="Frequently accessed tools and links"
								onClick={() => handleCardClick("Quick Links")}
							/>
						</div>
					</div>
				</div>
			</SidebarInset>
			<AppSidebar onNavigate={handleNavigation} />
		</SidebarProvider>
	);
}
