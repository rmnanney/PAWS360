"use client";

import { useRouter } from "next/navigation";
import {
	Card,
	CardDescription,
	CardHeader,
	CardTitle,
} from "../../components/Card/card";
import { Button } from "../../components/Button/button";
import { ChevronLeft, DollarSign, CreditCard, Wallet } from "lucide-react";

export default function UniversityPaymentsPage() {
	const router = useRouter();

	const handleBackClick = () => {
		router.push("/finances");
	};

	const widgets = [
		{
			id: "refund-status",
			title: "Refund Status",
			description: "Check refund processing",
			icon: DollarSign,
		},
		{
			id: "disbursements",
			title: "Disbursements",
			description: "View aid disbursements",
			icon: CreditCard,
		},
		{
			id: "payment-method",
			title: "Payment Method",
			description: "Set up direct deposit",
			icon: Wallet,
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
				<h1>Payments from University</h1>
				<p className="text-muted-foreground mt-2">
					View refunds, disbursements, and other payments from the university.
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
