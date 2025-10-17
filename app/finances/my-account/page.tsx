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
		return amount >= 0 ? "text-green-600" : "text-red-600";
	};

	const getTransactionIcon = (type: string) => {
		switch (type) {
			case "Payment":
			case "Credit":
				return <TrendingUp className="h-4 w-4 text-green-600" />;
			case "Charge":
				return <TrendingDown className="h-4 w-4 text-red-600" />;
			default:
				return <Receipt className="h-4 w-4 text-gray-600" />;
		}
	};

	const getStatusColor = (status: string) => {
		switch (status) {
			case "Posted":
				return "bg-green-100 text-green-800";
			case "Pending":
				return "bg-yellow-100 text-yellow-800";
			case "Active":
				return "bg-blue-100 text-blue-800";
			default:
				return "bg-gray-100 text-gray-800";
		}
	};

	return (
		<div className="flex-1 space-y-4 p-4 md:p-8 pt-6">
			<div className="flex items-center justify-between space-y-2">
				<div>
					<Button variant="ghost" onClick={handleBackClick} className="mb-2">
						<ChevronLeft className="h-4 w-4 mr-2" />
						Back to Finances
					</Button>
				</div>

				{/* <h2 className="text-3xl font-bold tracking-tight">
					Financial Information
				</h2> */}

				<div className="flex items-center space-x-2">
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
			<div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
				<Card>
					<CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
						<CardTitle className="text-sm font-medium">
							Current Balance
						</CardTitle>
						<DollarSign className="h-4 w-4 text-muted-foreground" />
					</CardHeader>
					<CardContent>
						<div
							className={`text-2xl font-bold ${getAmountColor(
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
						<div className="text-2xl font-bold text-red-600">
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
						<div className="text-2xl font-bold text-green-600">
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
						<div className="text-2xl font-bold text-yellow-600">
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
					<div className="grid gap-4 md:grid-cols-2">
						<Card>
							<CardHeader>
								<CardTitle>Account Summary</CardTitle>
								<CardDescription>
									Your current financial standing
								</CardDescription>
							</CardHeader>
							<CardContent className="space-y-4">
								<div className="flex justify-between">
									<span>Total Charges:</span>
									<span className="text-red-600">
										${accountSummary.totalCharges.toFixed(2)}
									</span>
								</div>
								<div className="flex justify-between">
									<span>Total Payments:</span>
									<span className="text-green-600">
										${accountSummary.totalPayments.toFixed(2)}
									</span>
								</div>
								<div className="flex justify-between">
									<span>Financial Aid:</span>
									<span className="text-green-600">
										${accountSummary.financialAid.toFixed(2)}
									</span>
								</div>
								<div className="border-t pt-2 flex justify-between font-semibold">
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
										<div
											key={index}
											className="flex items-center justify-between p-3 border rounded-lg"
										>
											<div>
												<p className="font-medium">{charge.description}</p>
												<p className="text-sm text-muted-foreground">
													Due: {charge.dueDate}
												</p>
											</div>
											<div className="text-right">
												<p className="font-semibold text-red-600">
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
									<div key={index} className="border rounded-lg p-4">
										<div className="flex items-center justify-between mb-4">
											<h3 className="font-semibold">{plan.name}</h3>
											<Badge className={getStatusColor(plan.status)}>
												{plan.status}
											</Badge>
										</div>
										<div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-sm">
											<div>
												<p className="text-muted-foreground">Total Amount</p>
												<p className="font-semibold">
													${plan.totalAmount.toFixed(2)}
												</p>
											</div>
											<div>
												<p className="text-muted-foreground">Monthly Payment</p>
												<p className="font-semibold">
													${plan.monthlyPayment.toFixed(2)}
												</p>
											</div>
											<div>
												<p className="text-muted-foreground">Payments Left</p>
												<p className="font-semibold">
													{plan.remainingPayments}
												</p>
											</div>
											<div>
												<p className="text-muted-foreground">Next Payment</p>
												<p className="font-semibold">{plan.nextPaymentDate}</p>
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
									<div
										key={index}
										className="flex items-center justify-between p-4 border rounded-lg"
									>
										<div className="flex items-center space-x-4">
											{getTransactionIcon(transaction.type)}
											<div>
												<p className="font-medium">{transaction.description}</p>
												<p className="text-sm text-muted-foreground">
													{transaction.date}
												</p>
											</div>
										</div>
										<div className="flex items-center space-x-4">
											<div className="text-right">
												<p
													className={`font-semibold ${getAmountColor(
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
									<div key={index} className="border rounded-lg p-4">
										<div className="flex items-center justify-between mb-4">
											<h3 className="font-semibold">{aid.type}</h3>
											<Badge className={getStatusColor(aid.status)}>
												{aid.status}
											</Badge>
										</div>
										<div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-sm">
											<div>
												<p className="text-muted-foreground">Awarded</p>
												<p className="font-semibold text-green-600">
													${aid.awarded.toFixed(2)}
												</p>
											</div>
											<div>
												<p className="text-muted-foreground">Disbursed</p>
												<p className="font-semibold text-blue-600">
													${aid.disbursed.toFixed(2)}
												</p>
											</div>
											<div>
												<p className="text-muted-foreground">Remaining</p>
												<p className="font-semibold text-orange-600">
													${aid.remaining.toFixed(2)}
												</p>
											</div>
											<div>
												<p className="text-muted-foreground">Total Aid</p>
												<p className="font-semibold">
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
								<div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
									<div className="flex items-center space-x-2 mb-2">
										<AlertTriangle className="h-5 w-5 text-blue-600" />
										<h3 className="font-semibold text-blue-900">
											Current Balance
										</h3>
									</div>
									<p className="text-blue-800">
										Your current balance is{" "}
										<span className="font-semibold">
											${accountSummary.currentBalance.toFixed(2)}
										</span>
									</p>
									<p className="text-sm text-blue-700 mt-1">
										Due date: {accountSummary.dueDate}
									</p>
								</div>
								<div className="grid gap-4 md:grid-cols-2">
									<Button className="h-16" size="lg">
										<CreditCard className="mr-2 h-5 w-5" />
										Pay with Credit Card
									</Button>
									<a
										href="https://quikpayasp.com/uwmil/qp/messageboard/index.do?dm=student_accounts_payer"
										target="_blank"
										rel="noopener noreferrer"
										className="h-16 inline-block"
									>
										<Button variant="outline" size="lg" className="h-16 w-full">
											<DollarSign className="mr-2 h-5 w-5" />
											Bank Transfer (ACH)
										</Button>
									</a>
								</div>{" "}
								<div className="text-center">
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
