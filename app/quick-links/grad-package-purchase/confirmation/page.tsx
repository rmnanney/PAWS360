"use client";

import { useEffect, useState } from "react";
import {
	Card,
	CardContent,
	CardHeader,
	CardTitle,
} from "../../../components/Card/card";
import { Button } from "../../../components/Button/button";
import { CheckCircle2, Mail } from "lucide-react";
import { useCart } from "../../../../contexts/graduation-cart/cart-context";
import { toast } from "sonner";
import { useRouter } from "next/navigation";

export function ConfirmationPage() {
	const { clearCart } = useCart();
	const [receiptNumber, setReceiptNumber] = useState("");
	const router = useRouter();

	useEffect(() => {
		// Generate receipt number
		const receipt = `GR-${Date.now()}-${Math.random()
			.toString(36)
			.substring(2, 9)
			.toUpperCase()}`;
		setReceiptNumber(receipt);

		// Clear the cart after successful purchase
		clearCart();
	}, []);

	const handleSendEmail = () => {
		toast.success("Receipt sent to your email!");
	};

	return (
		<div className="flex flex-1 flex-col items-center justify-center">
			<Card className="max-w-2xl w-full">
				<CardHeader className="text-center">
					<div className="flex justify-center mb-4">
						<div className="bg-green-100 dark:bg-green-900/20 p-4 rounded-full">
							<CheckCircle2 className="h-16 w-16 text-green-600 dark:text-green-500" />
						</div>
					</div>
					<CardTitle className="text-3xl">
						Thank You for Your Purchase!
					</CardTitle>
				</CardHeader>
				<CardContent className="space-y-6">
					<div className="text-center space-y-4">
						<p className="text-muted-foreground">
							Your order has been successfully processed.
						</p>

						<div className="bg-muted/50 p-6 rounded-lg">
							<p className="text-sm text-muted-foreground mb-2">
								Your Receipt Number
							</p>
							<p className="text-2xl font-mono tracking-wider">
								{receiptNumber}
							</p>
						</div>

						<div className="pt-4">
							<p className="text-muted-foreground mb-4">
								A confirmation email has been sent to your university email
								address.
							</p>

							<Button
								onClick={handleSendEmail}
								className="w-full md:w-auto"
								size="lg"
							>
								<Mail className="mr-2 h-4 w-4" />
								Send Receipt to Email
							</Button>
						</div>
					</div>

					<div className="bg-blue-50 dark:bg-blue-900/20 p-4 rounded-lg space-y-2">
						<h4 className="text-sm">What's Next?</h4>
						<ul className="text-sm text-muted-foreground space-y-1">
							<li>• You will receive an email confirmation shortly</li>
							<li>
								• Your graduation package will be processed within 1-2 business
								days
							</li>
							<li>
								• Pickup details or shipping information will be sent separately
							</li>
							<li>• Contact the bookstore if you have any questions</li>
						</ul>
					</div>

					<div className="flex gap-4 pt-4">
						<Button
							onClick={() => router.push("/homepage")}
							variant="outline"
							className="flex-1"
						>
							Return to Dashboard
						</Button>
						<Button
							onClick={() =>
								router.push(
									"/quick-links/grad-package-purchase/graduation-packages"
								)
							}
							className="flex-1"
						>
							Order More Items
						</Button>
					</div>
				</CardContent>
			</Card>
		</div>
	);
}

export default ConfirmationPage;
