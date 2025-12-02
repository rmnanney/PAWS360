"use client";

import SearchBar from "../SearchBar/searchbar";
import { SidebarTrigger } from "../SideBar/Base/sidebarbase";
import { Button } from "../Others/button";
import { useState } from "react";
import {
	GraduationCap,
	DollarSign,
	User,
	MessageSquare,
	BookOpen,
	Briefcase,
	AlertCircle,
	CalendarDays,
	Search,
	Link,
} from "lucide-react";
import s from "../../homepage/styles.module.css";

// Homepage items for the main cards
const homepageItems = [
	{
		title: "Academic",
		description: "Grades, transcripts, and academic records",
		icon: GraduationCap,
	},
	{
		title: "Advising",
		description: "Meet with advisors and plan your academic journey",
		icon: MessageSquare,
	},
	{
		title: "Finances",
		description: "Tuition, fees, and financial aid",
		icon: DollarSign,
	},
	{
		title: "Personal Information",
		description: "Update your personal details",
		icon: User,
	},
	{
		title: "Resources",
		description: "Library, tutoring, and study resources",
		icon: BookOpen,
	},
	{
		title: "Handshake",
		description: "Career services and job opportunities",
		icon: Briefcase,
	},
	{
		title: "Holds & Tasks",
		description: "Important items requiring attention",
		icon: AlertCircle,
	},
	{
		title: "Enrollment Date",
		description: "View enrollment dates and registration periods",
		icon: CalendarDays,
	},
	{
		title: "Class Search",
		description: "Search course catalog and class schedules",
		icon: Search,
	},
	{
		title: "Quick Links",
		description: "Frequently accessed tools and links",
		icon: Link,
	},
];

export function Header() {
	const [showMobileSearch, setShowMobileSearch] = useState(false);

	return (
		<header className={s.header}>
			<div className={s.headerContainer}>
				<div className={s.headerLeft}>
					<SidebarTrigger className={s.sidebarTrigger} />

					<div className={s.headerInner}>
						{/* Desktop Search Bar */}
						<div className={s.desktopSearch}>
							<SearchBar
								items={homepageItems}
								// onResultClick={(item) => handleNavigation(item.title)}
							/>
						</div>

						{/* Mobile Search Button */}
						<div className={s.mobileSearch}>
							<Button
								variant="outline"
								size="sm"
								onClick={() => setShowMobileSearch(!showMobileSearch)}
								className={s.mobileSearchButton}
							>
								<Search className="h-4 w-4" />
							</Button>
						</div>
					</div>
				</div>

				<a href="/homepage">
					<img src="/PS_LG_HOME.jpeg" alt="Logo" className={s.logo} />
				</a>
			</div>

			{/* Mobile Search Dropdown */}
			{showMobileSearch && (
				<div className={s.mobileSearchDropdown}>
					<SearchBar
						items={homepageItems}
						onResultClick={() => setShowMobileSearch(false)}
					/>
				</div>
			)}
		</header>
	);
}
