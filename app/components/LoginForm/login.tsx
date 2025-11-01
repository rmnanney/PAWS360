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

	const form = useForm<z.infer<typeof formSchema>>({
		resolver: zodResolver(formSchema),
		defaultValues: {
			email: "",
			password: "",
		},
	});

	async function onSubmit(values: z.infer<typeof formSchema>) {
		setIsLoading(true);
		// Simulate API call
		await new Promise((resolve) => setTimeout(resolve, 1000));
        try {
            const res = await fetch(`${API_BASE}/login`, {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                },
                body: JSON.stringify(values),
            });

    const data = await res.json();

            if (res.ok && data.message === "Login Successful") {
                localStorage.setItem("authToken", data.session_token);
                // Persist minimal user info used by pages (e.g., academics)
                if (data.email) localStorage.setItem("userEmail", data.email);
                if (data.firstname) localStorage.setItem("userFirstName", data.firstname);

                toast({
                    title: "Login Successful",
                    description: `Welcome ${data.firstname}! Redirecting...`,
                    duration: 1500,
                });

				setTimeout(() => {
					router.push("/homepage");
				}, 1500);
			} else {
				toast({
					variant: "destructive",
					title: "Login Failed",
					description:
						data.message || "Sorry, something went wrong. Please try again.",
				});
				form.reset({ ...values, password: "" });
			}
		} catch (error) {
			toast({
				variant: "destructive",
				title: "Error",
				description: "Unable to connect to the server. Try again later.",
			});
		} finally {
			setIsLoading(false);
		}
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
