"use client";

import { useEffect } from "react";
import { Card, CardContent } from "../../../components/Card/card";
import { Loader2 } from "lucide-react";
import { useRouter } from "next/navigation";

export function CheckoutLoading() {
	const router = useRouter();

	useEffect(() => {
		// Simulate checkout process
		const timer = setTimeout(() => {
			router.push("/quick-links/grad-package-purchase/confirmation");
		}, 3000);

		return () => clearTimeout(timer);
	}, [router]);

	return (
		<div className="flex flex-1 items-center justify-center min-h-[60vh]">
			<Card className="w-full max-w-md mx-auto" style={{ paddingTop: "20px" }}>
				<CardContent className="flex flex-col items-center justify-center py-16">
					<Loader2 className="h-16 w-16 animate-spin text-primary mb-6" />
					<h3 className="mb-2 text-center">Processing Your Order</h3>
					<p className="text-muted-foreground text-center">
						Please wait while we securely process your payment...
					</p>
				</CardContent>
			</Card>
		</div>
	);
}

export default CheckoutLoading;
