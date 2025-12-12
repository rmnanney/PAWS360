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
		if (!section) return;

		const target = section.trim();
		const normalized = target.toLowerCase();

		// Track navigation interaction (using original label for analytics)
		recordUserInteraction("navigation", target, 0, true);

		// External links should open in a new tab
		if (target.startsWith("http://") || target.startsWith("https://")) {
			recordUserInteraction("external_link", target, 0, true);
			window.open(target, "_blank");
			return;
		}

		// Route to appropriate pages (case-insensitive, with aliases)
		switch (normalized) {
			case "homepage":
				router.push("/homepage");
				break;
			case "finances":
				router.push("/finances");
				break;
			case "advising":
				router.push("/advising");
				break;
			case "academic":
			case "academic records":
				router.push("/academic");
				break;
			case "personal":
			case "personal information":
				router.push("/personal");
				break;
			case "resources":
				router.push("/resources");
				break;
			case "class search":
			case "class search/catalog":
				router.push("/courses/search");
				break;
			case "enrollment date":
			case "enrollment dates":
				router.push("/enrollment-date");
				break;
			case "quick links":
				router.push("/quick-links");
				break;
			case "holds & tasks":
			case "holds/ to do list":
			case "holds/to do list":
				router.push("/holds-tasks");
				break;
			case "handshake":
				window.open("https://uwm.joinhandshake.com/", "_blank");
				break;
			case "financial-aid":
				router.push("/finances/financial-aid");
				break;
			case "my-account":
				router.push("/finances/my-account");
				break;
			case "account-inquiry":
				router.push("/finances/account-inquiry");
				break;
			case "payment-history":
				router.push("/finances/payment-history");
				break;
			case "university-payments":
				router.push("/finances/university-payments");
				break;
			case "scholarships":
				router.push("/finances/scholarships");
				break;
			default:
				console.warn(`No navigation mapping for section: ${target}`);
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
			<body className="font-body antialiased" key={`auth-${authChecked}-${isAuthenticated}`}>
				{!authChecked && !isPublicPage ? (
					// Show loading state while checking auth (only for protected pages)
					<div className="flex items-center justify-center min-h-screen">
						<div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div>
					</div>
				) : isPublicPage || !isAuthenticated ? (
					// Render public pages or unauthenticated state without sidebar
					<>
						{children}
						<Toaster />
					</>
				) : (
					// Render authenticated pages with sidebar
					<SidebarProvider>
						<Header onNavigate={handleNavigation} />
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
