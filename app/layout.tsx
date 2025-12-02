"use client";

import type { Metadata } from "next";
import { useEffect } from "react";
import "./global.css";
import { Toaster } from "./components/Toaster/toaster";
import { Header } from "./components/Header/header";
import { AppSidebar } from "./components/SideBar/sidebar";
import {
	SidebarProvider,
	SidebarInset,
} from "./components/SideBar/Base/sidebarbase";
import { useRouter, usePathname } from "next/navigation";
import useAuth from "./hooks/useAuth";
import { useMonitoring } from "./hooks/useMonitoring";

// Note: metadata must be exported from a Server Component, not Client Component
// We'll need to move this or handle it differently
// export const metadata: Metadata = {
// 	title: "University of Wisconsin, Milwaukee Login",
// 	description: "Login page for University of Wisconsin, Milwaukee",
// };

export default function RootLayout({
	children,
}: Readonly<{
	children: React.ReactNode;
}>) {
	const router = useRouter();
	const pathname = usePathname();
	const { authChecked, isAuthenticated } = useAuth();
	const { recordPageView, recordUserInteraction } = useMonitoring();

	// Track page views
	useEffect(() => {
		recordPageView(pathname);
	}, [pathname, recordPageView]);

	// Pages that don't need authentication or sidebar
	const publicPages = ["/login", "/forgot-password"];
	const isPublicPage = publicPages.includes(pathname);

	const handleNavigation = (section: string) => {
		console.log(`Navigating to ${section}`);

		// Track navigation interaction
		recordUserInteraction("navigation", section, 0, true);

		// Route to appropriate pages
		if (section === "homepage") {
			router.push("/homepage");
		} else if (section === "finances") {
			router.push("/finances");
		} else if (section === "advising") {
			router.push("/advising");
		} else if (section === "academic") {
			router.push("/academic");
		} else if (section === "personal") {
			router.push("/personal");
		} else if (section === "resources") {
			router.push("/resources");
		} else if (section === "Class Search/Catalog" || section === "Class Search") {
			router.push("/courses/search");
		} else if (section === "Enrollment Date" || section === "Enrollment Dates") {
			router.push("/enrollment-date");
		} else if (section === "Class Search/Catalog") {
			router.push("/courses");
		} else if (section === "Quick Links") {
			router.push("/quick-links");
		} else if (section === "financial-aid") {
			router.push("/finances/financial-aid");
		} else if (section === "my-account") {
			router.push("/finances/my-account");
		} else if (section === "account-inquiry") {
			router.push("/finances/account-inquiry");
		} else if (section === "payment-history") {
			router.push("/finances/payment-history");
		} else if (section === "university-payments") {
			router.push("/finances/university-payments");
		} else if (section === "scholarships") {
			router.push("/finances/scholarships");
		} else if (section.startsWith("https://")) {
			recordUserInteraction("external_link", section, 0, true);
			window.open(section, "_blank");
		}
	};

	return (
		<html lang="en">
			<head>
				<title>PAWS360 - University of Wisconsin, Milwaukee</title>
				<meta
					name="description"
					content="PAWS360 - University of Wisconsin, Milwaukee Student Portal"
				/>
			</head>
			<body className="font-body antialiased">
				{isPublicPage || !authChecked || !isAuthenticated ? (
					// Render public pages without sidebar
					<>
						{children}
						<Toaster />
					</>
				) : (
					// Render authenticated pages with sidebar
					<SidebarProvider>
						<Header />
						<AppSidebar onNavigate={handleNavigation} />
						<SidebarInset className={pathname === "/homepage" ? "" : "pt-10"}>
							{children}
						</SidebarInset>
						<Toaster />
					</SidebarProvider>
				)}
			</body>
		</html>
	);
}
