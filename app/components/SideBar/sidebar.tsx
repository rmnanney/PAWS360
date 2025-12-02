import React from "react";
import {
	GraduationCap,
	DollarSign,
	User,
	MessageSquare,
	BookOpen,
	Briefcase,
	AlertCircle,
	Link as LucideLink,
	CalendarDays,
	Search,
	Calendar,
	Home,
	Settings,
} from "lucide-react";

import {
	Sidebar,
	SidebarContent,
	SidebarFooter,
	SidebarGroup,
	SidebarGroupContent,
	SidebarGroupLabel,
	SidebarHeader,
	SidebarMenu,
	SidebarMenuButton,
	SidebarMenuItem,
} from "./Base/sidebarbase";

import { Button } from "../Others/button";
import s from "./styles.module.css";

interface AppSidebarProps {
	onNavigate: (section: string) => void;
}

export function AppSidebar({ onNavigate }: AppSidebarProps) {
    const { API_BASE } = require("@/lib/api");
    const [user, setUser] = React.useState<any | null>(null);
    const [imgError, setImgError] = React.useState<boolean>(false);
    const resolveImg = (u: string) => {
        if (!u) return "";
        if (/^(https?:|blob:|data:)/.test(u)) return u;
        return `${API_BASE}${u}`;
    };

    React.useEffect(() => {
        const load = async () => {
            try {
                const email = typeof window !== "undefined" ? localStorage.getItem("userEmail") : null;
                if (!email) return;
                const res = await fetch(`${API_BASE}/users/get?email=${encodeURIComponent(email)}`);
                if (res.ok) {
                    const u = await res.json();
                    setUser(u);
                    setImgError(false);
                }
            } catch {}
        };
        load();
    }, []);

    const firstName = (user?.firstname && String(user.firstname).trim()) || 'Profile';
    const initials = (
        `${(user?.firstname || '').charAt(0)}${(user?.lastname || '').charAt(0)}`.toUpperCase() || 'U'
    );
	const academicItems = [
		{
			title: "Homepage",
			icon: Home,
			onClick: () => onNavigate("homepage"),
		},
		{
			title: "Academic Records",
			icon: GraduationCap,
			onClick: () => onNavigate("academic"),
		},
		{
			title: "Schedule",
			icon: Calendar,
			onClick: () => onNavigate("schedule of classes"),
		},
		{
			title: "Class Search",
			icon: Search,
			onClick: () => onNavigate("Class Search/Catalog"),
		},
		{
			title: "Enrollment Dates",
			icon: CalendarDays,
			onClick: () => onNavigate("Enrollment Date"),
		},
	];

	const servicesItems = [
		{
			title: "Finances",
			icon: DollarSign,
			onClick: () => onNavigate("finances"),
		},
		{
			title: "Advising",
			icon: MessageSquare,
			onClick: () => onNavigate("advising"),
		},
		{
			title: "Career Services",
			icon: Briefcase,
			onClick: () => onNavigate("https://uwm.edu/set/"),
		},
		{
			title: "Resources",
			icon: BookOpen,
			onClick: () => onNavigate("resources"),
		},
	];

	const personalItems = [
		{
			title: "Personal Info",
			icon: User,
			onClick: () => onNavigate("personal"),
		},
		{
			title: "Holds & Tasks",
			icon: AlertCircle,
			onClick: () => onNavigate("Holds/To Do List"),
		},
		{
			title: "Quick Links",
			icon: LucideLink,
			onClick: () => onNavigate("quick-links"),
		},
	];

	const router = require("next/navigation").useRouter?.() || null;
	const { toast } = require("../../hooks/useToast");

	function handleLogout() {
		const success = true; // Set to false to simulate failure
		if (typeof window !== "undefined") {
			localStorage.removeItem("authToken");
		}
		if (success) {
			toast({
				title: "Logging Out",
				description: "You have been logged out successfully.",
				duration: 1500,
			});
			setTimeout(() => {
				router?.push?.("/");
			}, 1500);
		} else {
			toast({
				variant: "destructive",
				title: "Logout Failed",
				description: "There was a problem logging out. Please try again.",
			});
		}
	}

	return (
		<Sidebar variant="inset" side="left" className={s.sidebarSolid}>
			<SidebarHeader>
				<SidebarMenu>
					<SidebarMenuItem>
						<a
							href="https://uwm.edu"
							target="_blank"
							rel="noopener noreferrer"
							className="block"
						>
							<SidebarMenuButton
								size="lg"
								className="data-[state=open]:bg-sidebar-accent data-[state=open]:text-sidebar-accent-foreground w-full justify-start"
							>
								<div className="flex items-center justify-center w-10 h-10 rounded-lg overflow-hidden">
									<img
										src="/uwmLogo.png"
										alt="UWM Logo"
										className="w-8 h-8 object-contain"
										onError={(e) => {
											// Fallback if image doesn't load
											e.currentTarget.style.display = "none";
											e.currentTarget.parentElement!.innerHTML =
												'<span class="text-white font-bold text-sm">UWM</span>';
										}}
									/>
								</div>
								<div className={s.logoTextContainer}>
									<span className={s.logoTitle}>University of Wisconsin</span>
									<span className={s.logoSubtitle}>Milwaukee</span>
								</div>
							</SidebarMenuButton>
						</a>
					</SidebarMenuItem>
					<SidebarMenuItem>
						<div className={s.profileContainer}>
							<div className={s.profileImageContainer} onClick={() => onNavigate("personal")}>
								{/* eslint-disable-next-line @next/next/no-img-element */}
								{user?.profile_picture_url && !imgError ? (
									<img
										src={resolveImg(user.profile_picture_url)}
										alt="Profile"
										className={s.profileImage}
										onError={() => setImgError(true)}
									/>
								) : (
									<div className={s.profileFallback} aria-label="No profile picture">
										{initials.trim() || 'U'}
									</div>
								)}
							</div>
							<SidebarMenuButton
								onClick={() => onNavigate("personal")}
								className={s.profileButton}
							>
								<User className="w-4 h-4" />
								<span>{firstName}</span>
							</SidebarMenuButton>
						</div>
					</SidebarMenuItem>
				</SidebarMenu>
			</SidebarHeader>{" "}
			<SidebarContent>
				<SidebarGroup>
					<SidebarGroupLabel>Academic</SidebarGroupLabel>
					<SidebarGroupContent>
						<SidebarMenu>
							{academicItems.map((item) => (
								<SidebarMenuItem key={item.title}>
									<SidebarMenuButton onClick={item.onClick}>
										<item.icon />
										<span>{item.title}</span>
									</SidebarMenuButton>
								</SidebarMenuItem>
							))}
						</SidebarMenu>
					</SidebarGroupContent>
				</SidebarGroup>

				<SidebarGroup>
					<SidebarGroupLabel>Services</SidebarGroupLabel>
					<SidebarGroupContent>
						<SidebarMenu>
							{servicesItems.map((item) => (
								<SidebarMenuItem key={item.title}>
									<SidebarMenuButton onClick={item.onClick}>
										<item.icon />
										<span>{item.title}</span>
									</SidebarMenuButton>
								</SidebarMenuItem>
							))}
						</SidebarMenu>
					</SidebarGroupContent>
				</SidebarGroup>

				<SidebarGroup>
					<SidebarGroupLabel>Personal</SidebarGroupLabel>
					<SidebarGroupContent>
						<SidebarMenu>
							{personalItems.map((item) => (
								<SidebarMenuItem key={item.title}>
									<SidebarMenuButton onClick={item.onClick}>
										<item.icon />
										<span>{item.title}</span>
									</SidebarMenuButton>
								</SidebarMenuItem>
							))}
						</SidebarMenu>
					</SidebarGroupContent>
				</SidebarGroup>
			</SidebarContent>
			<SidebarFooter>
				<SidebarMenu>
					<SidebarMenuItem>
						<SidebarMenuButton onClick={() => onNavigate("Settings")}>
							<Settings />
							<span>Settings</span>
						</SidebarMenuButton>
					</SidebarMenuItem>
				</SidebarMenu>
				<Button onClick={handleLogout}>Log Out</Button>
			</SidebarFooter>
		</Sidebar>
	);
}
