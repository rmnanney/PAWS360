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
import s from "./styles.module.css";

export default function PaymentHistoryPage() {
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
		<div className={s.pageContainer}>
			{/* Back Button */}
			<div>
				<Button variant="ghost" onClick={handleBackClick} className="mb-2">
					<ChevronLeft className="h-4 w-4 mr-2" />
					Back to Finances
				</Button>
			</div>

			{/* Page Header */}
			<div className="mb-2">
				<h1>View Payment History</h1>
				<p className="text-muted-foreground mt-2">
					Access and download your current and past billing statements.
				</p>
			</div>

			{/* Widgets Grid */}
			<div className={s.widgetsGrid}>
				{widgets.map((widget) => {
					const Icon = widget.icon;
					return (
						<Card
							key={widget.id}
							className={s.widgetCard}
							onClick={() => {
								if (widget.link) {
									window.open(widget.link, "_blank");
								}
							}}
						>
							<CardHeader>
								<div className={s.iconWrapper}>
									<Icon className="h-6 w-6 text-primary" />
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
	);
}
