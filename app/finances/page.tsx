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

export default function FinancesPage() {
	const router = useRouter();
	const [summaryOpen, setSummaryOpen] = useState(false);
	const [chargesVisible, setChargesVisible] = useState(false);

	const financialWidgets = [
		{
			id: "my-account",
			title: "My Account",
			description: "Account overview and statements",
			icon: Wallet,
			link: "my-account",
		},
		// {
		// 	id: "account-inquiry",
		// 	title: "Account Inquiry",
		// 	description: "Search and review transactions",
		// 	icon: FileText,
		// 	link: "account-inquiry",
		// },
		{
			id: "payment-history",
			title: "View Billing Statement",
			description: "Access current and past statements",
			icon: Receipt,
			link: "payment-history",
		},
		// {
		// 	id: "university-payments",
		// 	title: "Payments from University",
		// 	description: "Refunds and disbursements",
		// 	icon: CreditCard,
		// 	link: "university-payments",
		// },
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
		<div className="flex flex-1 flex-col gap-6 p-4">
			{/* Account Summary - Collapsible */}
			<Collapsible open={summaryOpen} onOpenChange={setSummaryOpen}>
				<Card className="border-2 border-primary/20">
					<CollapsibleTrigger asChild>
						<CardHeader className="cursor-pointer hover:bg-accent/50 transition-colors">
							<div className="flex items-center justify-between">
								<div className="flex items-center gap-3">
									<div className="p-2 bg-primary/10 rounded-lg">
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
						<CardContent className="pt-0 space-y-6">
							{/* Charges Due Section */}
							<div className="space-y-3">
								<div className="flex items-center justify-between p-4 bg-accent rounded-lg">
									<div className="space-y-1">
										<p className="text-sm text-muted-foreground">Charges Due</p>
										<div className="flex items-center gap-3">
											{chargesVisible ? (
												<p className="text-2xl font-semibold">$4,567.89</p>
											) : (
												<div className="flex items-center gap-2">
													<div className="flex gap-1">
														<div className="w-3 h-3 bg-muted-foreground/40 rounded-full"></div>
														<div className="w-3 h-3 bg-muted-foreground/40 rounded-full"></div>
														<div className="w-3 h-3 bg-muted-foreground/40 rounded-full"></div>
														<div className="w-3 h-3 bg-muted-foreground/40 rounded-full"></div>
														<div className="w-3 h-3 bg-muted-foreground/40 rounded-full"></div>
													</div>
												</div>
											)}
											<Button
												variant="ghost"
												size="sm"
												onClick={() => setChargesVisible(!chargesVisible)}
											>
												{chargesVisible ? (
													<EyeOff className="h-4 w-4" />
												) : (
													<Eye className="h-4 w-4" />
												)}
											</Button>
										</div>
									</div>
									<Badge variant="destructive">Due Nov 15</Badge>
								</div>

								{/* Payment Center Link */}
								<Button
									className="w-full"
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
							<div className="grid grid-cols-3 gap-4 pt-4 border-t">
								<div className="space-y-1">
									<p className="text-xs text-muted-foreground">
										Account Balance
									</p>
									<p className="text-lg font-semibold">$4,567.89</p>
								</div>
								<div className="space-y-1">
									<p className="text-xs text-muted-foreground">Pending Aid</p>
									<p className="text-lg font-semibold text-green-600">
										$8,200.00
									</p>
								</div>
								<div className="space-y-1">
									<p className="text-xs text-muted-foreground">Last Payment</p>
									<p className="text-lg font-semibold">$2,500.00</p>
								</div>
							</div>
						</CardContent>
					</CollapsibleContent>
				</Card>
			</Collapsible>

			{/* Financial Services Grid */}
			<div>
				<h2 className="mb-4">Financial Services</h2>
				<div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-2 gap-4">
					{financialWidgets.map((widget) => {
						const Icon = widget.icon;
						return (
							<Card
								key={widget.id}
								className="hover:shadow-md transition-all cursor-pointer border hover:border-primary/50"
								onClick={() => router.push(`/finances/${widget.link}`)}
							>
								<CardHeader>
									<div className="flex items-start justify-between">
										<div className="p-2 bg-primary/10 rounded-lg">
											<Icon className="h-6 w-6 text-primary" />
										</div>
										{widget.badge && (
											<Badge variant="secondary">{widget.badge}</Badge>
										)}
									</div>
									<CardTitle className="mt-4">{widget.title}</CardTitle>
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
