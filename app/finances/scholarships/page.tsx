"use client";

import { useRouter } from "next/navigation";
import {
	Card,
	CardDescription,
	CardHeader,
	CardTitle,
} from "../../components/Card/card";
import { Button } from "../../components/Button/button";
import { Badge } from "../../components/Badge/badge";
import { ChevronLeft, Gift, FileText, Search, AlertCircle } from "lucide-react";

export default function ScholarshipsPage() {
	const router = useRouter();

	const handleBackClick = () => {
		router.push("/finances");
	};

	const widgets = [
		{
			id: "about-scholarships",
			title: "About Scholarships",
			description: "View scholarships information with common Q&As",
			icon: FileText,
			link: "https://uwm.edu/finances/scholarships/portal/",
		},
		{
			id: "apply-scholarship",
			title: "Apply for scholarships from our Scholarship Portal",
			description: "Maintain eligibility",
			icon: Gift,
			link: "https://uwm.academicworks.com/opportunities",
		},
		{
			id: "accept-scholarships",
			title: "Accept Scholarships",
			description: "Review and accept your scholarship offers",
			icon: AlertCircle,
			status: "Urgent",
			badge: "1 Required",
		},
	];

	return (
		<div className="flex flex-1 flex-col gap-6 p-4 ">
			{/* Back Button */}
			<div>
				<Button variant="ghost" onClick={handleBackClick} className="mb-2">
					<ChevronLeft className="h-4 w-4 mr-2" />
					Back to Finances
				</Button>
			</div>

			{/* Page Header */}
			<div className="mb-2">
				<h1>Scholarship/Other Aids</h1>
				<p className="text-muted-foreground mt-2">
					View and manage your scholarships, grants, and other financial
					assistance.
				</p>
			</div>

			{/* Widgets Grid */}
			<div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
				{widgets.map((widget) => {
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
	);
}
