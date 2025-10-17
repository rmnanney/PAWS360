// "use client";

// import { useRouter } from "next/navigation";
// import {
// 	Card,
// 	CardDescription,
// 	CardHeader,
// 	CardTitle,
// } from "../../components/Card/card";
// import { Button } from "../../components/Button/button";
// import { ChevronLeft, Wallet, FileText, User } from "lucide-react";

// export default function MyAccountPage() {
// 	const router = useRouter();

// 	const handleBackClick = () => {
// 		console.log("Back button clicked, navigating to finances");
// 		router.push("/finances");
// 	};

// 	const widgets = [
// 		{
// 			id: "account-overview",
// 			title: "Account Overview",
// 			description: "Summary of your account",
// 			icon: Wallet,
// 		},
// 		{
// 			id: "transaction-history",
// 			title: "Transaction History",
// 			description: "View all transactions",
// 			icon: FileText,
// 		},
// 		{
// 			id: "account-settings",
// 			title: "Account Settings",
// 			description: "Manage account preferences",
// 			icon: User,
// 		},
// 	];

// 	return (
// 		<div className="flex flex-1 flex-col gap-6 p-4 pt-20">
// 			{/* Back Button */}
// 			<div>
// 				<Button variant="ghost" onClick={handleBackClick} className="mb-2">
// 					<ChevronLeft className="h-4 w-4 mr-2" />
// 					Back to Finances
// 				</Button>
// 			</div>

// 			{/* Page Header */}
// 			<div className="mb-2">
// 				<h1>My Account</h1>
// 				<p className="text-muted-foreground mt-2">
// 					View your account overview, balances, and transaction history.
// 				</p>
// 			</div>

// 			{/* Widgets Grid */}
// 			<div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
// 				{widgets.map((widget) => {
// 					const Icon = widget.icon;
// 					return (
// 						<Card
// 							key={widget.id}
// 							className="hover:shadow-md transition-all cursor-pointer border hover:border-primary/50"
// 						>
// 							<CardHeader>
// 								<div className="p-2 bg-primary/10 rounded-lg w-fit">
// 									<Icon className="h-6 w-6 text-primary" />
// 								</div>
// 								<CardTitle className="mt-4">{widget.title}</CardTitle>
// 								<CardDescription>{widget.description}</CardDescription>
// 							</CardHeader>
// 						</Card>
// 					);
// 				})}
// 			</div>
// 		</div>
// 	);
// }
"use client";

import React, { useEffect, useState } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import styles from "./styles.module.css";
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
} from "lucide-react";

// Mock data for finances
const accountSummary = {
	currentBalance: 2450.75,
	totalCharges: 8750.0,
	totalPayments: 6299.25,
	financialAid: 3200.0,
	refundAmount: 0.0,
	dueDate: "2025-10-15",
};

const recentTransactions = [
	{
		id: 1,
		date: "2025-10-01",
		description: "Tuition - Fall 2025",
		amount: -4250.0,
		type: "Charge",
		status: "Posted",
	},
	{
		id: 2,
		date: "2025-09-28",
		description: "Financial Aid Disbursement",
		amount: 1600.0,
		type: "Credit",
		status: "Posted",
	},
	{
		id: 3,
		date: "2025-09-15",
		description: "Housing Deposit",
		amount: -1200.0,
		type: "Charge",
		status: "Posted",
	},
	{
		id: 4,
		date: "2025-09-10",
		description: "Meal Plan - Semester",
		amount: -850.0,
		type: "Charge",
		status: "Posted",
	},
	{
		id: 5,
		date: "2025-09-05",
		description: "Payment Received",
		amount: 2000.0,
		type: "Payment",
		status: "Posted",
	},
];

const upcomingCharges = [
	{
		description: "Tuition - Spring 2026",
		amount: 4250.0,
		dueDate: "2026-01-15",
		status: "Pending",
	},
	{
		description: "Housing - Spring 2026",
		amount: 2400.0,
		dueDate: "2026-01-10",
		status: "Pending",
	},
];

const financialAid = [
	{
		type: "Federal Pell Grant",
		amount: 1800.0,
		awarded: 1800.0,
		disbursed: 900.0,
		remaining: 900.0,
		status: "Active",
	},
	{
		type: "Federal Work Study",
		amount: 2400.0,
		awarded: 2400.0,
		disbursed: 1200.0,
		remaining: 1200.0,
		status: "Active",
	},
	{
		type: "State Grant",
		amount: 800.0,
		awarded: 800.0,
		disbursed: 400.0,
		remaining: 400.0,
		status: "Active",
	},
];

const paymentPlans = [
	{
		name: "Monthly Payment Plan",
		totalAmount: 2450.75,
		monthlyPayment: 245.08,
		remainingPayments: 10,
		nextPaymentDate: "2025-11-01",
		status: "Active",
	},
];

export default function MyAccountPage() {
	const router = useRouter();
	const searchParams = useSearchParams();
	const [activeTab, setActiveTab] = useState("overview");

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
		return amount >= 0 ? styles.amountPositive : styles.amountNegative;
	};

	const getTransactionIcon = (type: string) => {
		switch (type) {
			case "Payment":
			case "Credit":
				return <TrendingUp className={styles.iconGreen} />;
			case "Charge":
				return <TrendingDown className={styles.iconRed} />;
			default:
				return <Receipt className={styles.iconGray} />;
		}
	};

	const getStatusColor = (status: string) => {
		switch (status) {
			case "Posted":
				return styles.statusPosted;
			case "Pending":
				return styles.statusPending;
			case "Active":
				return styles.statusActive;
			default:
				return styles.statusDefault;
		}
	};

	return (
		<div className={styles.pageContainer}>
			<div className={styles.header}>
				<div>
					<Button variant="ghost" onClick={handleBackClick} className="mb-2">
						<ChevronLeft className="h-4 w-4 mr-2" />
						Back to Finances
					</Button>
				</div>

				<div className={styles.headerActions}>
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
			<div className={styles.overviewCardsGrid}>
				<Card>
					<CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
						<CardTitle className="text-sm font-medium">
							Current Balance
						</CardTitle>
						<DollarSign className="h-4 w-4 text-muted-foreground" />
					</CardHeader>
					<CardContent>
						<div
							className={`${styles.balanceAmount} ${getAmountColor(
								accountSummary.currentBalance
							)}`}
						>
							${accountSummary.currentBalance.toFixed(2)}
						</div>
						<p className="text-xs text-muted-foreground">
							Due: {accountSummary.dueDate}
						</p>
					</CardContent>
				</Card>

				<Card>
					<CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
						<CardTitle className="text-sm font-medium">Total Charges</CardTitle>
						<Receipt className="h-4 w-4 text-muted-foreground" />
					</CardHeader>
					<CardContent>
						<div className={`${styles.balanceAmount} ${styles.amountNegative}`}>
							${accountSummary.totalCharges.toFixed(2)}
						</div>
						<p className="text-xs text-muted-foreground">This semester</p>
					</CardContent>
				</Card>

				<Card>
					<CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
						<CardTitle className="text-sm font-medium">Financial Aid</CardTitle>
						<CheckCircle className="h-4 w-4 text-muted-foreground" />
					</CardHeader>
					<CardContent>
						<div className={`${styles.balanceAmount} ${styles.amountPositive}`}>
							${accountSummary.financialAid.toFixed(2)}
						</div>
						<p className="text-xs text-muted-foreground">Awarded this year</p>
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
						<div className={`${styles.balanceAmount} ${styles.amountYellow}`}>
							Payment Plan
						</div>
						<p className="text-xs text-muted-foreground">
							10 payments remaining
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
					<div className={styles.twoColumnGrid}>
						<Card>
							<CardHeader>
								<CardTitle>Account Summary</CardTitle>
								<CardDescription>
									Your current financial standing
								</CardDescription>
							</CardHeader>
							<CardContent className="space-y-4">
								<div className={styles.summaryItem}>
									<span>Total Charges:</span>
									<span className={styles.amountNegative}>
										${accountSummary.totalCharges.toFixed(2)}
									</span>
								</div>
								<div className={styles.summaryItem}>
									<span>Total Payments:</span>
									<span className={styles.amountPositive}>
										${accountSummary.totalPayments.toFixed(2)}
									</span>
								</div>
								<div className={styles.summaryItem}>
									<span>Financial Aid:</span>
									<span className={styles.amountPositive}>
										${accountSummary.financialAid.toFixed(2)}
									</span>
								</div>
								<div className={styles.summaryTotal}>
									<span>Current Balance:</span>
									<span
										className={getAmountColor(accountSummary.currentBalance)}
									>
										${accountSummary.currentBalance.toFixed(2)}
									</span>
								</div>
							</CardContent>
						</Card>

						<Card>
							<CardHeader>
								<CardTitle>Upcoming Charges</CardTitle>
								<CardDescription>Pending charges and due dates</CardDescription>
							</CardHeader>
							<CardContent>
								<div className="space-y-4">
									{upcomingCharges.map((charge, index) => (
										<div key={index} className={styles.chargeItem}>
											<div>
												<p className={styles.mediumText}>
													{charge.description}
												</p>
												<p className="text-sm text-muted-foreground">
													Due: {charge.dueDate}
												</p>
											</div>
											<div className={styles.chargeDetails}>
												<p
													className={`${styles.semiboldText} ${styles.amountNegative}`}
												>
													${charge.amount.toFixed(2)}
												</p>
												<Badge className={getStatusColor(charge.status)}>
													{charge.status}
												</Badge>
											</div>
										</div>
									))}
								</div>
							</CardContent>
						</Card>
					</div>

					<Card>
						<CardHeader>
							<CardTitle>Payment Plans</CardTitle>
							<CardDescription>
								Your current payment arrangements
							</CardDescription>
						</CardHeader>
						<CardContent>
							<div className="space-y-4">
								{paymentPlans.map((plan, index) => (
									<div key={index} className={styles.paymentPlanCard}>
										<div className={styles.paymentPlanHeader}>
											<h3 className={styles.semiboldText}>{plan.name}</h3>
											<Badge className={getStatusColor(plan.status)}>
												{plan.status}
											</Badge>
										</div>
										<div className={styles.fourColumnGrid}>
											<div>
												<p className="text-muted-foreground">Total Amount</p>
												<p className={styles.semiboldText}>
													${plan.totalAmount.toFixed(2)}
												</p>
											</div>
											<div>
												<p className="text-muted-foreground">Monthly Payment</p>
												<p className={styles.semiboldText}>
													${plan.monthlyPayment.toFixed(2)}
												</p>
											</div>
											<div>
												<p className="text-muted-foreground">Payments Left</p>
												<p className={styles.semiboldText}>
													{plan.remainingPayments}
												</p>
											</div>
											<div>
												<p className="text-muted-foreground">Next Payment</p>
												<p className={styles.semiboldText}>
													{plan.nextPaymentDate}
												</p>
											</div>
										</div>
									</div>
								))}
							</div>
						</CardContent>
					</Card>
				</TabsContent>

				<TabsContent value="transactions" className="space-y-4">
					<Card>
						<CardHeader>
							<CardTitle>Transaction History</CardTitle>
							<CardDescription>
								Your recent financial transactions
							</CardDescription>
						</CardHeader>
						<CardContent>
							<div className="space-y-4">
								{recentTransactions.map((transaction, index) => (
									<div key={index} className={styles.transactionItem}>
										<div className={styles.transactionLeft}>
											{getTransactionIcon(transaction.type)}
											<div>
												<p className={styles.mediumText}>
													{transaction.description}
												</p>
												<p className="text-sm text-muted-foreground">
													{transaction.date}
												</p>
											</div>
										</div>
										<div className={styles.transactionRight}>
											<div className={styles.transactionDetails}>
												<p
													className={`${styles.semiboldText} ${getAmountColor(
														transaction.amount
													)}`}
												>
													{transaction.amount >= 0 ? "+" : ""}$
													{transaction.amount.toFixed(2)}
												</p>
												<Badge className={getStatusColor(transaction.status)}>
													{transaction.status}
												</Badge>
											</div>
										</div>
									</div>
								))}
							</div>
						</CardContent>
					</Card>
				</TabsContent>

				<TabsContent value="aid" className="space-y-4">
					<Card>
						<CardHeader>
							<CardTitle>Financial Aid Awards</CardTitle>
							<CardDescription>
								Your current financial aid packages
							</CardDescription>
						</CardHeader>
						<CardContent>
							<div className="space-y-4">
								{financialAid.map((aid, index) => (
									<div key={index} className={styles.aidCard}>
										<div className={styles.aidHeader}>
											<h3 className={styles.semiboldText}>{aid.type}</h3>
											<Badge className={getStatusColor(aid.status)}>
												{aid.status}
											</Badge>
										</div>
										<div className={styles.fourColumnGrid}>
											<div>
												<p className="text-muted-foreground">Awarded</p>
												<p
													className={`${styles.semiboldText} ${styles.amountPositive}`}
												>
													${aid.awarded.toFixed(2)}
												</p>
											</div>
											<div>
												<p className="text-muted-foreground">Disbursed</p>
												<p
													className={`${styles.semiboldText} ${styles.amountBlue}`}
												>
													${aid.disbursed.toFixed(2)}
												</p>
											</div>
											<div>
												<p className="text-muted-foreground">Remaining</p>
												<p
													className={`${styles.semiboldText} ${styles.amountOrange}`}
												>
													${aid.remaining.toFixed(2)}
												</p>
											</div>
											<div>
												<p className="text-muted-foreground">Total Aid</p>
												<p className={styles.semiboldText}>
													${aid.amount.toFixed(2)}
												</p>
											</div>
										</div>
									</div>
								))}
							</div>
						</CardContent>
					</Card>
				</TabsContent>

				<TabsContent value="payments" className="space-y-4">
					<Card>
						<CardHeader>
							<CardTitle>Make a Payment</CardTitle>
							<CardDescription>
								Pay your tuition and fees online
							</CardDescription>
						</CardHeader>
						<CardContent>
							<div className="space-y-6">
								<div className={styles.paymentAlert}>
									<div className={styles.alertHeader}>
										<AlertTriangle className={styles.iconBlue} />
										<h3 className={styles.alertTitle}>Current Balance</h3>
									</div>
									<p className={styles.alertText}>
										Your current balance is{" "}
										<span className={styles.semiboldText}>
											${accountSummary.currentBalance.toFixed(2)}
										</span>
									</p>
									<p className={styles.alertSubtext}>
										Due date: {accountSummary.dueDate}
									</p>
								</div>
								<div className={styles.paymentButtons}>
									<Button className={styles.paymentButton} size="lg">
										<CreditCard className="mr-2 h-5 w-5" />
										Pay with Credit Card
									</Button>
									<a
										href="https://quikpayasp.com/uwmil/qp/messageboard/index.do?dm=student_accounts_payer"
										target="_blank"
										rel="noopener noreferrer"
										className={styles.paymentLink}
									>
										<Button
											variant="outline"
											size="lg"
											className={styles.paymentLinkButton}
										>
											<DollarSign className="mr-2 h-5 w-5" />
											Bank Transfer (ACH)
										</Button>
									</a>
								</div>{" "}
								<div className={styles.paymentInfo}>
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
				</TabsContent>
			</Tabs>
		</div>
	);
}
