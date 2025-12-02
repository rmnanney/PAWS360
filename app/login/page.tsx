"use client";
import React from "react";
import { PlaceHolderImages } from "../lib/placeholder-img";
import Logo from "@/components/Others/logo";
import LoginForm from "@/components/LoginForm/login";
import useAuth from "@/hooks/useAuth";
import { useRouter } from "next/navigation";

import {
    Card,
    CardContent,
    CardDescription,
    CardHeader,
    CardTitle,
} from "@/components/Card/card";
import s from "./styles.module.css";

export default function Login() {
	const bgImage = PlaceHolderImages.find((img) => img.id === "uwm-building");
	const { toast } = require("@/hooks/useToast");
	const { authChecked, isAuthenticated } = useAuth();
	const router = useRouter();

	// Handle toast notification for unauthenticated access
	React.useEffect(() => {
		if (typeof window !== "undefined") {
			if (localStorage.getItem("showAuthToast") === "true") {
				toast({
					variant: "destructive",
					title: "You are not logged in",
					description: "Please log in to access this page.",
				});
				localStorage.removeItem("showAuthToast");
			}
		}
	}, [toast]);

	// Redirect authenticated users to homepage
	React.useEffect(() => {
		if (authChecked && isAuthenticated) {
			router.push("/homepage");
		}
	}, [authChecked, isAuthenticated, router]);

	// Show loading state while checking authentication
	if (!authChecked) {
		return (
			<main style={{ position: "relative", minHeight: "100vh" }}>
				<div className="flex items-center justify-center h-screen">
					<div>Loading...</div>
				</div>
			</main>
		);
	}

	// Don't render login form if user is authenticated (will redirect)
	if (isAuthenticated) {
		return null;
	}

	return (
		<main style={{ position: "relative", minHeight: "100vh" }}>
			{bgImage && (
				<img
					src={bgImage.imageUrl}
					alt={bgImage.description}
					className={s.bgImage}
				/>
			)}

			<div className={s.overlay} />

			<div className={s.card}>
				<div className={s.container}>
					<Card className={s.cardCustom}>
						<CardHeader className={s.headerSpace}>
							<Logo className="justify-center" />
							<div className="text-center">
								<CardTitle className={s.title}>Welcome Back</CardTitle>
								<CardDescription className="pt-2">
									Sign in to your UWM account
								</CardDescription>
							</div>
						</CardHeader>
						<CardContent>
							<LoginForm />
						</CardContent>
					</Card>
				</div>
			</div>
		</main>
	);
}
