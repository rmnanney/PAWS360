"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import {
	Card,
	CardContent,
	CardDescription,
	CardHeader,
	CardTitle,
} from "../components/Card/card";
import { Button } from "../components/Button/button";
import {
	DollarSign,
	ExternalLink,
	Eye,
	EyeOff,
	ChevronDown,
	ChevronUp,
	GraduationCap,
	FileText,
	Receipt,
	Wallet,
	Gift,
	CreditCard,
} from "lucide-react";
import {
	Collapsible,
	CollapsibleContent,
	CollapsibleTrigger,
} from "../components/Collapsible/collapsible";
import { Badge } from "../components/Badge/badge";
import s from "./styles.module.css";
import { Spinner } from "../components/Others/spinner";
import React from "react";
import type { FinancesSummary, GetStudentIdResponse } from "@/lib/types";

export default function FinancesPage() {
    const router = useRouter();
    const [summaryOpen, setSummaryOpen] = useState(false);
    const [chargesDueVisible, setChargesDueVisible] = useState(false);
    const [accountBalanceVisible, setAccountBalanceVisible] = useState(false);
    const [pendingAidVisible, setPendingAidVisible] = useState(false);
    const [lastPaymentVisible, setLastPaymentVisible] = useState(false);
    const [summary, setSummary] = useState<FinancesSummary | null>(null);
    const [loading, setLoading] = useState<boolean>(true);
    const { toast } = require("@/hooks/useToast");
    const { API_BASE } = require("@/lib/api");

    useEffect(() => {
        const load = async () => {
            try {
                const email = typeof window !== "undefined"
                    ? (sessionStorage.getItem("userEmail") || localStorage.getItem("userEmail"))
                    : null;
                if (!email) return;
                const sidRes = await fetch(`${API_BASE}/users/student-id?email=${encodeURIComponent(email)}`);
                const sidData: GetStudentIdResponse = await sidRes.json();
                if (!sidRes.ok || typeof sidData.student_id !== "number" || sidData.student_id < 0) {
                    if (sidRes.status === 400) {
                        toast({ variant: "destructive", title: "User not found", description: "Please verify your account." });
                    }
                    return;
                }
                const res = await fetch(`${API_BASE}/finances/student/${sidData.student_id}/summary`);
                if (!res.ok) throw new Error("Failed to load summary");
                const data: FinancesSummary = await res.json();
                setSummary(data);
            } catch (e: any) {
                toast({ variant: "destructive", title: "Failed to load finances", description: e?.message || "Try again later." });
            } finally {
                setLoading(false);
            }
        };
        load();
    }, [toast]);

	const financialWidgets = [
		{
			id: "my-account",
			title: "My Account",
			description: "Account overview and statements",
			icon: Wallet,
			link: "my-account",
		},
		{
			id: "payment-history",
			title: "View Payment History",
			description: "Access current and past statements",
			icon: Receipt,
			link: "payment-history",
		},
		{
			id: "financial-aid",
			title: "Financial Aid",
			description: "View and manage your financial aid",
			icon: GraduationCap,
			badge: "New",
			link: "financial-aid",
		},
		{
			id: "scholarships",
			title: "Scholarship/Other Aids",
			description: "View scholarships and grants",
			icon: Gift,
			link: "scholarships",
		},
	];

	return (
		<div className="flex-1 space-y-6 p-4 md:p-8 pt-6">
			<div className="flex items-center justify-between space-y-2">
				<h2 className="text-3xl font-bold tracking-tight">Finances</h2>
			</div>
			{/* Account Summary - Collapsible */}
			<Collapsible open={summaryOpen} onOpenChange={setSummaryOpen}>
				<Card className={s.summaryCard}>
					<CollapsibleTrigger asChild>
						<CardHeader className={s.collapsibleHeader}>
							<div className={s.headerContent}>
								<div className={s.headerLeft}>
									<div className={s.iconWrapper}>
										<DollarSign className="h-6 w-6 text-primary" />
									</div>
									<div>
										<CardTitle>Account Summary</CardTitle>
										<CardDescription>
											Your current financial status
										</CardDescription>
									</div>
								</div>
								{summaryOpen ? (
									<ChevronUp className="h-5 w-5 text-muted-foreground" />
								) : (
									<ChevronDown className="h-5 w-5 text-muted-foreground" />
								)}
							</div>
						</CardHeader>
					</CollapsibleTrigger>
                <CollapsibleContent>
                    {loading ? (
                        <CardContent className={s.cardContent}>
                            <div className="flex items-center justify-center text-sm text-muted-foreground" style={{ minHeight: 120 }}>
                                <span className="inline-flex items-center gap-2"><Spinner size="sm" /> Loading account summary…</span>
                            </div>
                        </CardContent>
                    ) : (
                    <CardContent className={s.cardContent}>
							{/* Charges Due Section */}
							<div className={s.contentSpacing}>
								<div className={s.chargesSection}>
									<div className={s.chargesDueContainer}>
										<div className={s.chargesDueLeft}>
											<p className="text-sm text-muted-foreground">
												Charges Due
											</p>
											<div className={s.chargesAmount}>
												<div
													className={s.amountDisplay}
													onClick={() =>
														setChargesDueVisible(!chargesDueVisible)
													}
												>
                            {chargesDueVisible ? (
                                <p className={`text-2xl font-semibold ${summary && Number(summary.chargesDue || 0) <= 0 ? 'text-green-600' : ''}`}>{summary ? `$${Number(summary.chargesDue || 0).toLocaleString()}` : "--"}</p>
                            ) : (
														<div className={s.dotsContainer}>
															<div className={s.dot}></div>
															<div className={s.dot}></div>
															<div className={s.dot}></div>
															<div className={s.dot}></div>
															<div className={s.dot}></div>
														</div>
													)}
												</div>
											</div>
										</div>
                            {summary && Number(summary.chargesDue || 0) <= 0 ? (
                                <Badge variant="secondary">Paid in Full</Badge>
                            ) : (
                                <Badge variant="destructive">{summary?.dueDate ? `Due ${new Date(summary.dueDate).toLocaleDateString()}`: "Due Soon"}</Badge>
                            )}
									</div>

									{/* Payment Center Link */}
									<Button
										className={s.fullWidthButton}
										size="lg"
										onClick={() =>
											window.open("/finances/my-account?tab=overview", "_blank")
										}
									>
										<CreditCard className="mr-2 h-5 w-5" />
										Go to Account Summary
										<ExternalLink className="ml-2 h-4 w-4" />
									</Button>
								</div>

								{/* Quick Stats */}
								<div className={s.quickStats}>
									<div className={s.statItem}>
										<p className="text-xs text-muted-foreground">
											Account Balance
										</p>
										<div
											className={s.statValue}
											onClick={() =>
												setAccountBalanceVisible(!accountBalanceVisible)
											}
										>
                                {accountBalanceVisible ? (
                                    <p className={`text-lg font-semibold ${summary && Number(summary.accountBalance || 0) <= 0 ? 'text-green-600' : ''}`}>{summary ? `$${Number(summary.accountBalance || 0).toLocaleString()}` : "--"}</p>
                                ) : (
												<div className={s.dotsContainer}>
													<div className={s.dot}></div>
													<div className={s.dot}></div>
													<div className={s.dot}></div>
													<div className={s.dot}></div>
												</div>
											)}
										</div>
									</div>
									<div className={s.statItem}>
										<p className="text-xs text-muted-foreground">Pending Aid</p>
										<div
											className={s.statValue}
											onClick={() => setPendingAidVisible(!pendingAidVisible)}
										>
                                {pendingAidVisible ? (
                                    <p className="text-lg font-semibold text-green-600">{summary ? `$${Number(summary.pendingAid || 0).toLocaleString()}` : "--"}</p>
                                ) : (
												<div className={s.dotsContainer}>
													<div className={s.dot}></div>
													<div className={s.dot}></div>
													<div className={s.dot}></div>
													<div className={s.dot}></div>
												</div>
											)}
										</div>
									</div>
									<div className={s.statItem}>
										<p className="text-xs text-muted-foreground">
											Last Payment
										</p>
										<div
											className={s.statValue}
											onClick={() => setLastPaymentVisible(!lastPaymentVisible)}
										>
                                {lastPaymentVisible ? (
                                    <p className="text-lg font-semibold">{summary && summary.lastPaymentAmount ? `$${Number(summary.lastPaymentAmount).toLocaleString()}` : "--"}</p>
                                ) : (
												<div className={s.dotsContainer}>
													<div className={s.dot}></div>
													<div className={s.dot}></div>
													<div className={s.dot}></div>
													<div className={s.dot}></div>
												</div>
											)}
										</div>
									</div>
								</div>
							</div>
                    </CardContent>
                    )}
                </CollapsibleContent>
				</Card>
			</Collapsible>

			{/* Financial Services Grid */}
			<div>
				<h2 className={s.servicesSection}>Financial Services</h2>
				<div className={s.servicesGrid}>
					{financialWidgets.map((widget) => {
						const Icon = widget.icon;
						return (
							<Card
								key={widget.id}
								className={s.widgetCard}
								onClick={() => router.push(`/finances/${widget.link}`)}
							>
								<CardHeader>
									<div className={s.widgetHeader}>
										<div className={s.iconWrapper}>
											<Icon className="h-6 w-6 text-primary" />
										</div>
										{widget.badge && (
											<Badge variant="secondary">{widget.badge}</Badge>
										)}
									</div>
									<CardTitle className={s.widgetTitleMargin}>
										{widget.title}
									</CardTitle>
									<CardDescription>{widget.description}</CardDescription>
								</CardHeader>
							</Card>
						);
					})}
				</div>
			</div>
		</div>
	);
}
