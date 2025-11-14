"use client";

import {
	Card,
	CardContent,
	CardDescription,
	CardHeader,
	CardTitle,
} from "../components/Card/card";
import {
	GraduationCap,
	FileText,
	Calendar,
	Mail,
	MapPin,
	HelpCircle,
	User,
} from "lucide-react";
import { Button } from "../components/Button/button";
import { useRouter } from "next/navigation";

const quickLinks = [
	{
		id: "graduation",
		title: "Graduation Packages",
		description: "Order your graduation regalia and packages",
		icon: GraduationCap,
		color: "bg-blue-500",
	},
	{
		id: "forms",
		title: "Student Forms",
		description: "Access common forms and documents",
		icon: FileText,
		color: "bg-green-500",
	},
	{
		id: "events",
		title: "Campus Events",
		description: "View upcoming university events",
		icon: Calendar,
		color: "bg-purple-500",
	},
	{
		id: "personal",
		title: "Personal Info",
		description: "Access your personal information",
		icon: User,
		color: "bg-red-500",
	},
	{
		id: "maps",
		title: "Campus Maps",
		description: "Navigate the campus with interactive maps",
		icon: MapPin,
		color: "bg-orange-500",
	},
	{
		id: "support",
		title: "IT Support",
		description: "Get help with technical issues",
		icon: HelpCircle,
		color: "bg-teal-500",
	},
];

export function QuickLinksPage() {
	const router = useRouter();

	const handleLinkClick = (id: string) => {
		if (id === "graduation") {
			router.push("/quick-links/grad-package-purchase/graduation-form");
		} else if (id === "forms") {
			window.open("https://uwm.edu/registrar/forms-tools/", "_blank");
		} else if (id === "events") {
			router.push("/resources?tab=events");
		} else if (id === "personal") {
			router.push("/personal?tab=personal");
		} else if (id === "maps") {
			window.open("https://apps.uwm.edu/map/", "_blank");
		} else if (id === "support") {
			window.open("https://uwm.edu/information-technology/help/", "_blank");
		}
	};

	return (
		<div className="flex flex-1 flex-col space-y-6 p-4 md:p-8 pt-6">
			<div className="mb-2">
				<p className="text-muted-foreground">
					Quick access to frequently used tools and resources.
				</p>
			</div>

			<div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
				{quickLinks.map((link) => {
					const Icon = link.icon;
					return (
						<Card
							key={link.id}
							className="cursor-pointer hover:shadow-lg transition-shadow"
							onClick={() => handleLinkClick(link.id)}
						>
							<CardHeader>
								<div className="flex items-start gap-4">
									<div className={`${link.color} p-3 rounded-lg`}>
										<Icon className="w-6 h-6 text-white" />
									</div>
									<div className="flex-1">
										<CardTitle>{link.title}</CardTitle>
										<CardDescription className="mt-2">
											{link.description}
										</CardDescription>
									</div>
								</div>
							</CardHeader>
							<CardContent>
								<Button variant="outline" className="w-full">
									Access
								</Button>
							</CardContent>
						</Card>
					);
				})}
			</div>
		</div>
	);
}

export default QuickLinksPage;
