"use client";

import {
	Card,
	CardContent,
	CardDescription,
	CardHeader,
	CardTitle,
} from "../../../components/Card/card";
import { Button } from "../../../components/Button/button";
import { Badge } from "../../../components/Others/badge";
import { Check } from "lucide-react";
import { useCart } from "../../../../contexts/graduation-cart/cart-context";
import { packages } from "./packages";
import CartIcon from "../cart-icon/page";
import { toast } from "sonner";

interface GraduationPackagesPageProps {
	onNavigate: (section: string) => void;
	graduationData?: {
		term: string;
		school: string;
		degreeType: string;
		major: string;
		deliveryMethod: string;
	};
}

export function GraduationPackagesPage({
	graduationData,
}: GraduationPackagesPageProps) {
	const { addToCart } = useCart();
	const router = require("next/navigation").useRouter();

	const handleAddToCart = (pkg: (typeof packages)[0]) => {
		addToCart({
			id: `${pkg.id}-${Date.now()}`,
			name: pkg.name,
			price: pkg.price,
			quantity: 1,
			image: pkg.image,
			graduationDetails: graduationData,
		});
		toast.success(`${pkg.name} added to cart!`);
	};

	const handleNavigation = (section: string) => {
		if (section === "cart") {
			router.push("/quick-links/grad-package-purchase/cart-page");
		}
	};

	return (
		<div className="flex flex-1 flex-col gap-4">
			{/* Graduation Details Summary */}
			{graduationData && (
				<Card className="bg-muted/50">
					<CardContent className="pt-6">
						<div className="grid grid-cols-2 md:grid-cols-5 gap-4">
							<div>
								<p className="text-muted-foreground">Term</p>
								<p>{graduationData.term}</p>
							</div>
							<div>
								<p className="text-muted-foreground">School</p>
								<p>{graduationData.school}</p>
							</div>
							<div>
								<p className="text-muted-foreground">Degree</p>
								<p>{graduationData.degreeType}</p>
							</div>
							<div>
								<p className="text-muted-foreground">Major</p>
								<p>{graduationData.major}</p>
							</div>
							<div>
								<p className="text-muted-foreground">Delivery</p>
								<p>
									{graduationData.deliveryMethod === "pickup"
										? "Pick up in person"
										: "Ship to address"}
								</p>
							</div>
						</div>
					</CardContent>
				</Card>
			)}

			<div className="mb-3 flex items-center justify-between">
				<div>
					<h2>Select Your Graduation Package</h2>
					<p className="text-muted-foreground">
						Choose the perfect package for your graduation celebration
					</p>
				</div>
				<div className="ml-4">
					<CartIcon onNavigate={handleNavigation} />
				</div>
			</div>

			{/* Packages Grid */}
			<div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
				{packages.map((pkg) => (
					<Card
						key={pkg.id}
						className="relative overflow-hidden transition-all hover:shadow-lg"
					>
						{pkg.popular && (
							<Badge className="absolute top-16 right-4 z-10" variant="default">
								Most Popular
							</Badge>
						)}

						<CardHeader>
							<CardTitle className="flex items-center justify-between">
								{pkg.name}
								<span className="text-primary">${pkg.price}</span>
							</CardTitle>
							<CardDescription>{pkg.description}</CardDescription>
						</CardHeader>

						<CardContent style={{ paddingBottom: "56px" }}>
							<ul className="space-y-2 mb-4">
								{pkg.features.map((feature, index) => (
									<li key={index} className="flex items-start gap-2 text-sm">
										<Check className="h-4 w-4 text-primary shrink-0 mt-0.5" />
										<span>{feature}</span>
									</li>
								))}
							</ul>
							{/* Button is absolutely positioned 10px from bottom, always visible */}
							<div
								style={{
									position: "absolute",
									left: 0,
									right: 0,
									bottom: "1.5rem",
									padding: "0 16px",
								}}
							>
								<Button
									onClick={() => handleAddToCart(pkg)}
									className="w-full"
									variant="default"
								>
									Add to Cart
								</Button>
							</div>
						</CardContent>
					</Card>
				))}
			</div>
		</div>
	);
}

export default GraduationPackagesPage;
