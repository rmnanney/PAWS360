"use client";

import { useRouter } from "next/navigation";
import {
	Card,
	CardDescription,
	CardHeader,
	CardTitle,
} from "../../components/Card/card";
import { Button } from "../../components/Button/button";
import { ChevronLeft, FileText, Receipt } from "lucide-react";

export default function BillingStatementPage() {
	const router = useRouter();

	const handleBackClick = () => {
		router.push("/finances");
	};

	const widgets = [
		{
			id: "transaction-history",
			title: "Transaction History",
			description: "View your past transactions",
			icon: FileText,
			link: "/finances/my-account?tab=transactions",
		},
		{
			id: "workday-transactions",
			title: "Workday Transactions",
			description: "View your Workday Pays and Benefits",
			icon: Receipt,
			link: "https://www.myworkday.com/wisconsin/d/task/2998$43525.htmld#backheader=true",
		},
		{
			id: "download-statement",
			title: "Download Statements",
			description: "Download PDF copies",
			icon: FileText,
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
				<h1>View Billing Statement</h1>
				<p className="text-muted-foreground mt-2">
					Access and download your current and past billing statements.
				</p>
			</div>

			{/* Widgets Grid */}
			<div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
				{widgets.map((widget) => {
					const Icon = widget.icon;
					return (
						<Card
							key={widget.id}
							className="hover:shadow-md transition-all cursor-pointer border hover:border-primary/50"
							onClick={() => {
								if (widget.link) {
									window.open(widget.link, "_blank");
								}
							}}
						>
							<CardHeader>
								<div className="p-2 bg-primary/10 rounded-lg w-fit">
									<Icon className="h-6 w-6 text-primary" />
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
