"use client";

import { useState } from "react";
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

export default function FinancesPage() {
	const router = useRouter();
	const [summaryOpen, setSummaryOpen] = useState(false);
	const [chargesDueVisible, setChargesDueVisible] = useState(false);
	const [accountBalanceVisible, setAccountBalanceVisible] = useState(false);
	const [pendingAidVisible, setPendingAidVisible] = useState(false);
	const [lastPaymentVisible, setLastPaymentVisible] = useState(false);

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
														<p className="text-2xl font-semibold">$4,567.89</p>
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
										<Badge variant="destructive">Due Nov 15</Badge>
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
												<p className="text-lg font-semibold">$4,567.89</p>
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
												<p className="text-lg font-semibold text-green-600">
													$8,200.00
												</p>
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
												<p className="text-lg font-semibold">$2,500.00</p>
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
