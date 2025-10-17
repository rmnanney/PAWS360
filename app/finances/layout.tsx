"use client";

import React from "react";
import { Header } from "../components/Header/header";
import { AppSidebar } from "../components/SideBar/sidebar";
import {
	SidebarProvider,
	SidebarInset,
} from "../components/SideBar/Base/sidebarbase";
import { useRouter } from "next/navigation";
import useAuth from "../hooks/useAuth";

export default function FinancesLayout({
	children,
}: {
	children: React.ReactNode;
}) {
	const router = useRouter();
	const { authChecked, isAuthenticated } = useAuth();

	// Return early if not authenticated
	if (!authChecked || !isAuthenticated) {
		return null;
	}

	const handleNavigation = (section: string) => {
		console.log(`Navigating to ${section}`);

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
		} else if (section.startsWith("https://")) {
			window.open(section, "_blank");
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
		}
	};

	return (
		<SidebarProvider>
			<Header />
			<SidebarInset className="pt-20">{children}</SidebarInset>
			<AppSidebar onNavigate={handleNavigation} />
		</SidebarProvider>
	);
}
