"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import {
	Card,
	CardContent,
	CardDescription,
	CardHeader,
	CardTitle,
} from "../../components/Card/card";
import { Button } from "../../components/Button/button";
import {
	ChevronLeft,
	ChevronDown,
	ChevronUp,
	GraduationCap,
	FileText,
	DollarSign,
	Calendar,
	CheckCircle,
	AlertCircle,
} from "lucide-react";
import { Badge } from "../../components/Badge/badge";
import { Progress } from "../../components/Progress/progress";
import {
	Collapsible,
	CollapsibleContent,
	CollapsibleTrigger,
} from "../../components/Collapsible/collapsible";

export default function FinancialAidPage() {
	const router = useRouter();
	const [overviewOpen, setOverviewOpen] = useState(false);
	const aidWidgets = [
		{
			id: "apply-financial-aid",
			title: "Apply for Financial Aid",
			description:
				"The first step to determining if you are eligible for state and federal financial aid.",
			icon: FileText,
			link: "https://studentaid.gov/h/apply-for-aid/fafsa",
			status: "Available",
		},
		// {
		// 	id: "financial-aid-summary",
		// 	title: "Financial Aid Summary",
		// 	description: "Overview of your financial aid package",
		// 	icon: GraduationCap,
		// 	status: "Active",
		// },
		{
			id: "aid-history",
			title: "Aid History",
			description: "View past financial aid awards",
			icon: Calendar,
			status: "Available",
			link: "/finances/my-account?tab=aid",
		},
		{
			id: "accept-decline-aid",
			title: "Accept/Decline Aid",
			description: "Manage your aid offers",
			icon: CheckCircle,
			status: "Action Required",
			badge: "2 Pending",
		},
		// {
		// 	id: "loan-information",
		// 	title: "Loan Information",
		// 	description: "View loan details and requirements",
		// 	icon: DollarSign,
		// 	status: "Available",
		// },
		{
			id: "missing-documents",
			title: "Missing Documents",
			description: "Upload required documents",
			icon: AlertCircle,
			status: "Urgent",
			badge: "1 Required",
		},
	];

	const handleBackClick = () => {
		console.log("Back button clicked, navigating to finances");
		router.push("/finances");
	};

	return (
		<div className="flex flex-1 flex-col gap-6 p-4 ">
			{/* Back Button */}
			<div>
				<Button variant="ghost" onClick={handleBackClick} className="mb-2">
					<ChevronLeft className="h-4 w-4 mr-2" />
					Back to Finances
				</Button>
			</div>
			{/* Aid Overview Card */}
			<Collapsible open={overviewOpen} onOpenChange={setOverviewOpen}>
				<Card className="border-2 border-primary/20">
					<CollapsibleTrigger asChild>
						<CardHeader className="cursor-pointer hover:bg-accent/50 transition-colors">
							<div className="flex items-center justify-between">
								<div className="flex items-center gap-3">
									<div className="p-2 bg-primary/10 rounded-lg">
										<GraduationCap className="h-8 w-8 text-primary" />
									</div>
									<div>
										<CardTitle className="text-2xl">
											Financial Aid Overview
										</CardTitle>
										<CardDescription>Academic Year 2024-2025</CardDescription>
									</div>
								</div>
								{overviewOpen ? (
									<ChevronUp className="h-5 w-5 text-muted-foreground" />
								) : (
									<ChevronDown className="h-5 w-5 text-muted-foreground" />
								)}
							</div>
						</CardHeader>
					</CollapsibleTrigger>
					<CollapsibleContent>
						<CardContent className="space-y-6">
							{/* Total Aid */}
							<div className="grid grid-cols-1 md:grid-cols-3 gap-6">
								<div className="space-y-2">
									<p className="text-sm text-muted-foreground">
										Total Aid Offered
									</p>
									<p className="text-3xl font-semibold">$18,750</p>
								</div>
								<div className="space-y-2">
									<p className="text-sm text-muted-foreground">Aid Accepted</p>
									<p className="text-3xl font-semibold text-green-600">
										$15,500
									</p>
								</div>
								<div className="space-y-2">
									<p className="text-sm text-muted-foreground">
										Pending Decision
									</p>
									<p className="text-3xl font-semibold text-orange-600">
										$3,250
									</p>
								</div>
							</div>

							{/* Aid Breakdown */}
							<div className="space-y-4 pt-4 border-t">
								<h4>Aid Breakdown</h4>

								<div className="space-y-3">
									<div className="flex justify-between items-center">
										<div>
											<p className="font-medium">Federal Pell Grant</p>
											<p className="text-sm text-muted-foreground">
												Grant - No repayment required
											</p>
										</div>
										<Badge variant="secondary">$6,500</Badge>
									</div>

									<div className="flex justify-between items-center">
										<div>
											<p className="font-medium">University Scholarship</p>
											<p className="text-sm text-muted-foreground">
												Scholarship - Merit based
											</p>
										</div>
										<Badge variant="secondary">$5,000</Badge>
									</div>

									<div className="flex justify-between items-center">
										<div>
											<p className="font-medium">
												Federal Direct Subsidized Loan
											</p>
											<p className="text-sm text-muted-foreground">
												Loan - 4.53% interest
											</p>
										</div>
										<Badge variant="secondary">$4,000</Badge>
									</div>

									<div className="flex justify-between items-center">
										<div>
											<p className="font-medium">Work-Study Program</p>
											<p className="text-sm text-muted-foreground">
												Need to accept by Nov 1
											</p>
										</div>
										<Badge variant="outline">$3,250</Badge>
									</div>
								</div>
							</div>

							{/* Progress */}
							<div className="space-y-2 pt-4 border-t">
								<div className="flex justify-between text-sm">
									<span>Aid Acceptance Progress</span>
									<span className="text-muted-foreground">82%</span>
								</div>
								<Progress value={82} />
							</div>
						</CardContent>
					</CollapsibleContent>
				</Card>
			</Collapsible>{" "}
			{/* Financial Aid Services */}
			<div>
				<div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-2 gap-4">
					{aidWidgets.map((widget) => {
						const Icon = widget.icon;
						const isUrgent = widget.status === "Urgent";
						const isActionRequired = widget.status === "Action Required";

						return (
							<Card
								key={widget.id}
								className={`hover:shadow-md transition-all cursor-pointer border ${
									isUrgent
										? "border-destructive/50"
										: isActionRequired
										? "border-orange-500/50"
										: "hover:border-primary/50"
								}`}
								onClick={() => {
									if (widget.link) {
										window.open(widget.link, "_blank");
									}
								}}
							>
								<CardHeader>
									<div className="flex items-start justify-between">
										<div
											className={`p-2 rounded-lg ${
												isUrgent
													? "bg-destructive/10"
													: isActionRequired
													? "bg-orange-500/10"
													: "bg-primary/10"
											}`}
										>
											<Icon
												className={`h-6 w-6 ${
													isUrgent
														? "text-destructive"
														: isActionRequired
														? "text-orange-600"
														: "text-primary"
												}`}
											/>
										</div>
										{widget.badge && (
											<Badge
												variant={
													isUrgent || isActionRequired
														? "destructive"
														: "secondary"
												}
											>
												{widget.badge}
											</Badge>
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
