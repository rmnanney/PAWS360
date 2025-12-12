"use client";

import React, { useEffect, useMemo, useState } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import s from "./styles.module.css";
import {
	Card,
	CardContent,
	CardDescription,
	CardHeader,
	CardTitle,
} from "../../components/Card/card";
import {
	Tabs,
	TabsContent,
	TabsList,
	TabsTrigger,
} from "../../components/Others/tabs";
import { Badge } from "../../components/Others/badge";
import { Button } from "../../components/Others/button";
import {
    ChevronLeft,
    CreditCard,
    DollarSign,
    Receipt,
    TrendingUp,
    TrendingDown,
    AlertTriangle,
    CheckCircle,
    Calendar,
    Download,
    Mail,
    Loader2,
} from "lucide-react";
import type {
  FinancesSummary,
  Transaction as Tx,
  AidOverview,
  PaymentPlan,
  GetStudentIdResponse,
} from "@/lib/types";
import { API_BASE } from "@/lib/api";
import { useToast } from "@/hooks/useToast";
import {
  Table,
  TableBody,
  TableCaption,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "../../components/Others/table";
import { Spinner } from "../../components/Others/spinner";

export default function MyAccountPage() {
	const router = useRouter();
	const searchParams = useSearchParams();
	const [activeTab, setActiveTab] = useState("overview");

	// Remote data
	const [summary, setSummary] = useState<FinancesSummary | null>(null);
	const [transactions, setTransactions] = useState<Tx[]>([]);
	const [aid, setAid] = useState<AidOverview | null>(null);
	const [plans, setPlans] = useState<PaymentPlan[]>([]);
	const [loading, setLoading] = useState<boolean>(true);
	const [studentId, setStudentId] = useState<number | null>(null);
	const [paying, setPaying] = useState<boolean>(false);
	const { toast } = useToast();

	useEffect(() => {
		const load = async () => {
			setLoading(true);
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
				const studentId = sidData.student_id;
				setStudentId(studentId);

				const [sumRes, txRes, aidRes, planRes] = await Promise.all([
					fetch(`${API_BASE}/finances/student/${studentId}/summary`).catch(() => null),
					fetch(`${API_BASE}/finances/student/${studentId}/transactions`).catch(() => null),
					fetch(`${API_BASE}/finances/student/${studentId}/aid`).catch(() => null),
					fetch(`${API_BASE}/finances/student/${studentId}/payment-plans`).catch(() => null),
				]);

				if (sumRes && sumRes.ok) setSummary(await sumRes.json());
				if (txRes && txRes.ok) setTransactions(await txRes.json());
				if (aidRes && aidRes.ok) setAid(await aidRes.json());
				if (planRes && planRes.ok) setPlans(await planRes.json());
			} catch (e: any) {
				toast({ variant: "destructive", title: "Failed to load account", description: e?.message || "Try again later." });
			} finally {
				setLoading(false);
			}
		};
		load();
	}, [toast]);

	// Read tab from URL on mount and when URL changes
	useEffect(() => {
		const tab = searchParams.get("tab");
		if (tab && ["overview", "transactions", "aid", "payments"].includes(tab)) {
			setActiveTab(tab);
		}
	}, [searchParams]);

	// Update URL when tab changes
	const handleTabChange = (value: string) => {
		setActiveTab(value);
		router.push(`/finances/my-account?tab=${value}`, { scroll: false });
	};

	// React.useEffect(() => {
	// 	if (typeof window !== "undefined") {
	// 		const loggedIn = localStorage.getItem("loggedIn");
	// 		if (!loggedIn) {
	// 			localStorage.setItem("showAuthToast", "true");
	// 			router.push("/login");
	// 		}
	// 	}
	// }, [router]);

	// const handleNavigation = (section: string) => {
	// 	console.log(`Navigating to ${section}`);
	// };

	const handleBackClick = () => {
		console.log("Back button clicked, navigating to finances");
		router.push("/finances");
	};

	const getAmountColor = (amount: number) => {
		return amount >= 0 ? s.amountPositive : s.amountNegative;
	};

	const getBalanceColor = (balance?: number | null) => {
		const v = typeof balance === 'number' ? balance : 0;
		return v <= 0 ? s.amountPositive : s.amountNegative;
	};

	const getTransactionIcon = (type: string) => {
		switch (type) {
			case "Payment":
			case "Credit":
				return <TrendingUp className={s.iconGreen} />;
			case "Charge":
				return <TrendingDown className={s.iconRed} />;
			default:
				return <Receipt className={s.iconGray} />;
		}
	};

	const getStatusColor = (status: string) => {
		switch (status) {
			case "Posted":
				return s.statusPosted;
			case "Pending":
				return s.statusPending;
			case "Active":
				return s.statusActive;
			default:
				return s.statusDefault;
		}
	};

	const upcomingCharges = useMemo(() => {
		const list = (transactions || []).filter((t) => {
			const type = (t.type || "").toUpperCase();
			return type === "CHARGE" || (typeof t.amount === "number" && t.amount < 0);
		});
		return list.slice(0, 5);
	}, [transactions]);

	const formatMoney = (v?: number | null) =>
		typeof v === "number" ? `$${v.toFixed(2)}` : "-";

	return (
		<div className={s.pageContainer}>
			<div className={s.header}>
				<div>
					<Button variant="ghost" onClick={handleBackClick} className="mb-2">
						<ChevronLeft className="h-4 w-4 mr-2" />
						Back to Finances
					</Button>
				</div>

				<div className={s.headerActions}>
					<Button variant="outline" size="sm">
						<Download className="mr-2 h-4 w-4" />
						Download Statement
					</Button>
					<a href="https://uwm.edu/finances/finances/billing-and-payment/">
						<Button variant="outline" size="sm">
							<Mail className="mr-2 h-4 w-4" />
							Contact Billing
						</Button>
					</a>
				</div>
			</div>

			{/* Financial Overview Cards */}
			<div className={s.overviewCardsGrid}>
				<Card>
					<CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
						<CardTitle className="text-sm font-medium">
							Current Balance
						</CardTitle>
						<DollarSign className="h-4 w-4 text-muted-foreground" />
					</CardHeader>
					<CardContent>
						<div className={`${s.balanceAmount} ${getBalanceColor(summary?.accountBalance)}`}>
							{formatMoney(summary?.accountBalance ?? null)}
						</div>
						{summary && Number(summary.chargesDue || 0) <= 0 && (
							<Badge variant="secondary">Paid in Full</Badge>
						)}
						<p className="text-xs text-muted-foreground">
							Due: {summary?.dueDate || "-"}
						</p>
					</CardContent>
				</Card>

				<Card>
					<CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
						<CardTitle className="text-sm font-medium">Total Charges</CardTitle>
						<Receipt className="h-4 w-4 text-muted-foreground" />
					</CardHeader>
					<CardContent>
						<div className={`${s.balanceAmount} ${s.amountNegative}`}>
							{formatMoney((transactions || []).filter(t => (t.type || "").toUpperCase() === "CHARGE").reduce((sum, t) => sum + (t.amount || 0), 0))}
						</div>
						<p className="text-xs text-muted-foreground">Recent charges total</p>
					</CardContent>
				</Card>

				<Card>
					<CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
						<CardTitle className="text-sm font-medium">Financial Aid</CardTitle>
						<CheckCircle className="h-4 w-4 text-muted-foreground" />
					</CardHeader>
					<CardContent>
						<div className={`${s.balanceAmount} ${s.amountPositive}`}>
							{formatMoney(aid?.totalAccepted ?? null)}
						</div>
						<p className="text-xs text-muted-foreground">Aid accepted</p>
					</CardContent>
				</Card>

				<Card>
					<CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
						<CardTitle className="text-sm font-medium">
							Payment Status
						</CardTitle>
						<CreditCard className="h-4 w-4 text-muted-foreground" />
					</CardHeader>
					<CardContent>
						<div className={`${s.balanceAmount} ${s.amountYellow}`}>
							{(plans && plans.length > 0) ? (plans[0].name || "Payment Plan") : "Payment Plan"}
						</div>
						<p className="text-xs text-muted-foreground">
							{(plans && plans.length > 0 && typeof plans[0].remainingPayments === 'number') ? `${plans[0].remainingPayments} payments remaining` : '—'}
						</p>
					</CardContent>
				</Card>
			</div>

			{/* Main Content Tabs */}
			<Tabs
				value={activeTab}
				onValueChange={handleTabChange}
				className="space-y-4"
			>
				<TabsList>
					<TabsTrigger value="overview">Account Overview</TabsTrigger>
					<TabsTrigger value="transactions">Transaction History</TabsTrigger>
					<TabsTrigger value="aid">Financial Aid</TabsTrigger>
					<TabsTrigger value="payments">Make Payment</TabsTrigger>
				</TabsList>

				<TabsContent value="overview" className="space-y-4">
					{loading ? (
						<div className="flex items-center justify-center text-sm text-muted-foreground" style={{ minHeight: 120 }}>
							<span className="inline-flex items-center gap-2"><Spinner size="sm" /> Loading overview…</span>
						</div>
					) : (
					<div className={s.twoColumnGrid}>
						<Card>
						<CardHeader>
							<CardTitle>Account Summary</CardTitle>
							<CardDescription>
								Your current financial standing
							</CardDescription>
						</CardHeader>
						<CardContent className="space-y-4">
							<div className={s.summaryItem}>
								<span>Total Charges:</span>
								<span className={s.amountNegative}>{formatMoney((transactions || []).filter(t => (t.type || "").toUpperCase() === "CHARGE").reduce((sum, t) => sum + (t.amount || 0), 0))}</span>
							</div>
							<div className={s.summaryItem}>
								<span>Total Payments:</span>
								<span className={s.amountPositive}>{formatMoney((transactions || []).filter(t => (t.type || "").toUpperCase() !== "CHARGE").reduce((sum, t) => sum + (t.amount || 0), 0))}</span>
							</div>
							<div className={s.summaryItem}>
								<span>Financial Aid:</span>
								<span className={s.amountPositive}>{formatMoney(aid?.totalDisbursed ?? null)}</span>
							</div>
							<div className={s.summaryTotal}>
								<span>Current Balance:</span>
								<span className={getAmountColor(Number(summary?.accountBalance || 0))}>{formatMoney(summary?.accountBalance ?? null)}</span>
							</div>
						</CardContent>
					</Card>

						<Card>
						<CardHeader>
							<CardTitle>Recent Charges</CardTitle>
							<CardDescription>Latest posted or pending charges</CardDescription>
						</CardHeader>
						<CardContent>
							<div className="space-y-4">
								{upcomingCharges.map((t, index) => (
									<div key={index} className={s.chargeItem}>
										<div>
											<p className={s.mediumText}>{t.description || "Charge"}</p>
											<p className="text-sm text-muted-foreground">Due: {t.dueDate || "-"}</p>
										</div>
										<div className={s.chargeDetails}>
											<p className={`${s.semiboldText} ${s.amountNegative}`}>{formatMoney(t.amount ?? null)}</p>
											<Badge className={getStatusColor(String(t.status || ""))}>{String(t.status || "")}</Badge>
										</div>
									</div>
								))}
								{upcomingCharges.length === 0 && (
									<p className="text-sm text-muted-foreground">No recent charges.</p>
								)}
							</div>
						</CardContent>
					</Card>
					</div>
					)}

					<Card>
						<CardHeader>
							<CardTitle>Payment Plans</CardTitle>
							<CardDescription>
								Your current payment arrangements
							</CardDescription>
						</CardHeader>
						<CardContent>
							<div className="space-y-4">
								{plans.map((plan, index) => (
									<div key={index} className={s.paymentPlanCard}>
										<div className={s.paymentPlanHeader}>
											<h3 className={s.semiboldText}>{plan.name}</h3>
											<Badge className={getStatusColor(String(plan.status || ""))}>{String(plan.status || "")}</Badge>
										</div>
										<div className={s.fourColumnGrid}>
											<div>
												<p className="text-muted-foreground">Total Amount</p>
												<p className={s.semiboldText}>{formatMoney(plan.totalAmount)}</p>
											</div>
											<div>
												<p className="text-muted-foreground">Monthly Payment</p>
												<p className={s.semiboldText}>{formatMoney(plan.monthlyPayment)}</p>
											</div>
											<div>
												<p className="text-muted-foreground">Payments Left</p>
												<p className={s.semiboldText}>{plan.remainingPayments ?? "-"}</p>
											</div>
											<div>
												<p className="text-muted-foreground">Next Payment</p>
												<p className={s.semiboldText}>{plan.nextPaymentDate || "-"}</p>
											</div>
										</div>
									</div>
								))}
								{plans.length === 0 && (
									<p className="text-sm text-muted-foreground">No active payment plans.</p>
								)}
							</div>
						</CardContent>
					</Card>
				</TabsContent>

				<TabsContent value="transactions" className="space-y-4">
					{loading ? (
						<div className="flex items-center justify-center text-sm text-muted-foreground" style={{ minHeight: 120 }}>
							<span className="inline-flex items-center gap-2"><Spinner size="sm" /> Loading transactions…</span>
						</div>
					) : (
					<Card>
						<CardHeader>
							<CardTitle>Transaction History</CardTitle>
							<CardDescription>Your recent financial transactions</CardDescription>
						</CardHeader>
						<CardContent>
							<Table>
								<TableHeader>
									<TableRow>
										<TableHead>Date</TableHead>
										<TableHead>Description</TableHead>
										<TableHead>Type</TableHead>
										<TableHead className="text-right">Amount</TableHead>
										<TableHead>Status</TableHead>
										<TableHead>Due Date</TableHead>
									</TableRow>
								</TableHeader>
								<TableBody>
									{transactions.map((t, idx) => {
										const date = t.postedAt ? new Date(t.postedAt) : null;
										const due = t.dueDate ? new Date(t.dueDate) : null;
										const amt = typeof t.amount === 'number' ? t.amount : 0;
										return (
											<TableRow key={idx}>
												<TableCell>{date ? date.toLocaleDateString() : '-'}</TableCell>
												<TableCell>{t.description || '-'}</TableCell>
												<TableCell>{t.type || '-'}</TableCell>
												<TableCell className={`text-right ${getAmountColor(amt)}`}>{amt >= 0 ? '+' : ''}{formatMoney(amt)}</TableCell>
                                        <TableCell>
                                            <Badge className={getStatusColor(String(t.status || ''))}>{String(t.status || '')}</Badge>
                                        </TableCell>
												<TableCell>{due ? due.toLocaleDateString() : '-'}</TableCell>
											</TableRow>
										);
									})}
								</TableBody>
								{transactions.length === 0 && (
									<TableCaption>No transactions found.</TableCaption>
								)}
							</Table>
						</CardContent>
					</Card>
					)}
				</TabsContent>

				<TabsContent value="aid" className="space-y-4">
					{loading ? (
						<div className="flex items-center justify-center text-sm text-muted-foreground" style={{ minHeight: 120 }}>
							<span className="inline-flex items-center gap-2"><Spinner size="sm" /> Loading financial aid…</span>
						</div>
					) : (
					<Card>
						<CardHeader>
							<CardTitle>Financial Aid Awards</CardTitle>
							<CardDescription>
								Your current financial aid packages
							</CardDescription>
						</CardHeader>
						<CardContent>
							<div className="space-y-4">
								{(aid?.awards || []).map((aw, index) => (
									<div key={index} className={s.aidCard}>
									<div className={s.aidHeader}>
										<h3 className={s.semiboldText}>{aw.type}</h3>
										<Badge className={getStatusColor(String(aw.status || ""))}>
											{aw.status}
										</Badge>
									</div>
									<div className={s.fourColumnGrid}>
										<div>
											<p className="text-muted-foreground">Awarded</p>
											<p className={`${s.semiboldText} ${s.amountPositive}`}>{formatMoney(aw.amountOffered)}</p>
										</div>
										<div>
											<p className="text-muted-foreground">Disbursed</p>
											<p className={`${s.semiboldText} ${s.amountBlue}`}>{formatMoney(aw.amountDisbursed)}</p>
										</div>
										<div>
											<p className="text-muted-foreground">Remaining</p>
											<p className={`${s.semiboldText} ${s.amountOrange}`}>{formatMoney((aw.amountOffered || 0) - (aw.amountAccepted || 0))}</p>
										</div>
										<div>
											<p className="text-muted-foreground">Total Aid</p>
											<p className={s.semiboldText}>{formatMoney(aw.amountAccepted)}</p>
										</div>
									</div>
								</div>
							))}
							{(!aid || (aid.awards || []).length === 0) && (
								<p className="text-sm text-muted-foreground">No awards found.</p>
							)}
						</div>
					</CardContent>
					</Card>
					)}
				</TabsContent>

				<TabsContent value="payments" className="space-y-4">
					{loading ? (
						<div className="flex items-center justify-center text-sm text-muted-foreground" style={{ minHeight: 120 }}>
							<span className="inline-flex items-center gap-2"><Spinner size="sm" /> Loading payments…</span>
						</div>
					) : (
					<Card>
						<CardHeader>
							<CardTitle>Make a Payment</CardTitle>
							<CardDescription>
								Pay your tuition and fees online
							</CardDescription>
						</CardHeader>
						<CardContent>
							<div className="space-y-6">
								<div className={s.paymentAlert}>
									<div className={s.alertHeader}>
										<AlertTriangle className={s.iconBlue} />
										<h3 className={s.alertTitle}>Current Balance</h3>
									</div>
									<p className={s.alertText}>
										Your current balance is{" "}
										<span className={s.semiboldText}>
											{formatMoney(summary?.accountBalance ?? null)}
										</span>
									</p>
									<p className={s.alertSubtext}>
										Due date: {summary?.dueDate || "-"}
									</p>
									{summary && Number(summary.chargesDue || 0) <= 0 && (
										<Badge variant="secondary">Paid in Full</Badge>
									)}
								</div>
								<div className={s.paymentButtons}>
									<Button className={s.paymentButton} size="lg" disabled={paying}
										onClick={async () => {
											try {
												if (!studentId) return;
												const due = Number(summary?.accountBalance || 0);
												if (!(due > 0)) { toast({ title: "No balance due" }); return; }
												setPaying(true);
												const res = await fetch(`${API_BASE}/finances/admin/students/${studentId}/transactions`, {
													method: "POST",
													headers: { "Content-Type": "application/json" },
													body: JSON.stringify({ amount: due, type: "PAYMENT", status: "POSTED", description: "Credit Card payment" })
												});
												if (!res.ok) throw new Error("Payment failed");
												toast({ title: "Payment successful", description: `Paid ${formatMoney(due)}` });
												// Reload account data
												const [sumRes, txRes] = await Promise.all([
													fetch(`${API_BASE}/finances/student/${studentId}/summary`).catch(() => null),
													fetch(`${API_BASE}/finances/student/${studentId}/transactions`).catch(() => null),
												]);
												if (sumRes && sumRes.ok) setSummary(await sumRes.json());
												if (txRes && txRes.ok) setTransactions(await txRes.json());
											} catch (e: any) {
												toast({ variant: "destructive", title: "Payment failed", description: e?.message || "Try again later." });
											} finally {
												setPaying(false);
											}
										}}
									>
										{paying ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : <CreditCard className="mr-2 h-5 w-5" />}
										Pay with Credit Card
									</Button>
									<Button
										variant="outline"
										size="lg"
										className={s.paymentButton}
										onClick={() =>
											window.open(
												"https://quikpayasp.com/uwmil/qp/messageboard/index.do?dm=student_accounts_payer",
												"_blank"
											)
										}
									>
										<DollarSign className="mr-2 h-5 w-5" />
										Bank Transfer (ACH)
									</Button>
								</div>{" "}
								<div className={s.paymentInfo}>
									<p className="text-sm text-muted-foreground mb-4">
										For questions about payments, contact Student Accounts at
										(414) 229-4000
									</p>
									<a
										href="https://quikpayasp.com/uwmil/qp/messageboard/index.do?dm=student_accounts_payer"
										target="_blank"
										rel="noopener noreferrer"
									>
										<Button variant="outline">
											<Calendar className="mr-2 h-4 w-4" />
											Set Up Payment Plan
										</Button>
									</a>
								</div>
							</div>
						</CardContent>
					</Card>
					)}
				</TabsContent>
			</Tabs>
		</div>
	);
}
