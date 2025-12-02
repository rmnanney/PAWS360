"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import * as z from "zod";
import Link from "next/link";
import { Loader2 } from "lucide-react";

import { Button } from "../Others/button";
import {
	Form,
	FormControl,
	FormField,
	FormItem,
	FormLabel,
	FormMessage,
} from "../Others/form";
import { Input } from "../Others/input";
import { useToast } from "../../hooks/useToast";
import { API_BASE } from "@/lib/api";
import { useAuthMonitoring } from "../../hooks/useMonitoring";
import useAuth from "../../hooks/useAuth";
import s from "./styles.module.css";

const formSchema = z.object({
	email: z
		.string()
		.email({ message: "Please enter a valid email." })
		.refine((val) => val.toLowerCase().endsWith("@uwm.edu"), {
			message: "Must be a valid University Email Address.",
		}),
	password: z.string().min(1, { message: "Password is required." }),
});

export default function LoginForm() {
	const [isLoading, setIsLoading] = useState(false);
	const router = useRouter();
	const { toast } = useToast();
	const { monitorLogin, recordAuthEvent, setUserId } = useAuthMonitoring();
	const { refreshAuth } = useAuth();

	const form = useForm<z.infer<typeof formSchema>>({
		resolver: zodResolver(formSchema),
		defaultValues: {
			email: "",
			password: "",
		},
	});

	async function onSubmit(values: z.infer<typeof formSchema>) {
		setIsLoading(true);
		
		// Wrap login with monitoring
	const result = await monitorLogin(async () => {
		// Use relative path so Next.js rewrites proxy to backend and cookies are first-party
		const res = await fetch(`/auth/login`, {
				method: "POST",
				headers: {
					"Content-Type": "application/json",
					"X-Service-Origin": "student-portal",
				},
				body: JSON.stringify(values),
				credentials: "include",
			});

			const data = await res.json();

			if (res.ok && data.message === "Login Successful") {
				// SSO authentication successful - session cookie is automatically set
				// Store minimal user info for UI purposes only (not for authentication)
				if (data.email) sessionStorage.setItem("userEmail", data.email);
				if (data.firstname) sessionStorage.setItem("userFirstName", data.firstname);
				if (data.role) sessionStorage.setItem("userRole", data.role);

				// Set user ID for monitoring
				setUserId(data.email);

				toast({
					title: "Login Successful",
					description: `Welcome ${data.firstname}! SSO session established.`,
					duration: 1500,
				});

				// Refresh auth state to ensure useAuth hook recognizes the new session
				await refreshAuth();

				// Navigate to homepage
				router.push("/homepage");

				return { success: true, data };
			} else if (res.status === 423) {
				// Account locked
				toast({
					variant: "destructive",
					title: "Account Locked",
					description: data.message || "Your account has been temporarily locked due to too many failed attempts.",
				});
				form.reset({ ...values, password: "" });
				return { success: false, error: "account_locked", data };
			} else {
				toast({
					variant: "destructive",
					title: "Login Failed",
					description: data.message || "Sorry, something went wrong. Please try again.",
				});
				form.reset({ ...values, password: "" });
				return { success: false, error: "invalid_credentials", data };
			}
		}, values.email);

		// Handle monitoring result
		if (!result.success) {
			if (result.error === "network_error") {
				// Align wording with E2E expectations
				toast({
					variant: "destructive",
					title: "Service unavailable",
					description: "Unable to connect to the server. Try again later.",
				});
			}
		}

		setIsLoading(false);
	}

	return (
		<Form {...form}>
			<form onSubmit={form.handleSubmit(onSubmit)} className={s.form}>
				<div className={s.formFields}>
					<FormField
						control={form.control}
						name="email"
						render={({ field }) => (
							<FormItem>
								<FormLabel>University Email Address</FormLabel>
								<FormControl>
									<Input
										placeholder="epantherID@uwm.edu"
										{...field}
										disabled={isLoading}
										autoComplete="email"
									/>
								</FormControl>
								<FormMessage />
							</FormItem>
						)}
					/>
					<FormField
						control={form.control}
						name="password"
						render={({ field }) => (
							<FormItem>
								<div className={s.passwordFieldHeader}>
									<FormLabel>Password</FormLabel>
									<Link
										href="/forgot-password"
										className={s.forgotPasswordLink}
									>
										Forgot password?
									</Link>
								</div>
								<FormControl>
									<Input
										type="password"
										{...field}
										disabled={isLoading}
										autoComplete="current-password"
										placeholder="••••••••"
									/>
								</FormControl>
								<FormMessage />
							</FormItem>
						)}
					/>
				</div>
				<Button type="submit" className={s.submitButton} disabled={isLoading}>
					{isLoading && <Loader2 className={s.loadingIcon + " animate-spin"} />}
					Sign In
				</Button>
			</form>
		</Form>
	);
}
