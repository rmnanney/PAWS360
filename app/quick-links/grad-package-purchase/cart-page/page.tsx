"use client";

import {
	Card,
	CardContent,
	CardHeader,
	CardTitle,
} from "../../../components/Card/card";
import { Button } from "../../../components/Button/button";
import { Input } from "../../../components/Others/input";
import { useCart } from "../../../../contexts/graduation-cart/cart-context";
import { Trash2, ShoppingBag, ArrowLeft } from "lucide-react";
import { Separator } from "../../../components/Others/separator";
import { useRouter } from "next/navigation";

export function CartPage() {
	const { items, removeFromCart, updateQuantity, totalPrice } = useCart();
	const router = useRouter();

	const handleCheckout = () => {
		if (items.length > 0) {
			router.push("/quick-links/grad-package-purchase/loading");
		}
	};

	if (items.length === 0) {
		return (
			<div className="flex flex-1 items-center justify-center min-h-[60vh]">
				<Card className="w-full max-w-md mx-auto">
					<CardContent className="flex flex-col items-center justify-center py-16">
						<ShoppingBag
							className="h-16 w-16 text-muted-foreground mb-4"
							style={{ paddingTop: "20px" }}
						/>
						<h3 className="mb-2 text-center">Your cart is empty</h3>
						<p className="text-muted-foreground mb-6 text-center">
							Add some graduation packages to get started
						</p>
						<Button
							onClick={() =>
								router.push(
									"/quick-links/grad-package-purchase/graduation-packages"
								)
							}
							className="w-full sm:w-auto"
						>
							<ArrowLeft className="mr-2 h-4 w-4" />
							Continue Shopping
						</Button>
					</CardContent>
				</Card>
			</div>
		);
	}

	return (
		<div className="flex flex-1 flex-col gap-4 p-4 pt-0">
			<div className="mb-2">
				<p className="text-muted-foreground">
					Review your items and proceed to checkout
				</p>
			</div>

			<div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
				{/* Cart Items */}
				<div className="lg:col-span-2 space-y-4">
					<Card>
						<CardHeader>
							<CardTitle>Shopping Cart ({items.length} items)</CardTitle>
						</CardHeader>
						<CardContent className="space-y-4">
							{items.map((item) => (
								<div key={item.id}>
									<div className="flex gap-4">
										{/* Details */}
										<div className="flex-1 space-y-2">
											<div className="flex justify-between items-start">
												<div>
													<h4>{item.name}</h4>
													<p className="text-muted-foreground">
														${item.price.toFixed(2)}
													</p>
												</div>
												<Button
													variant="ghost"
													size="icon"
													onClick={() => removeFromCart(item.id)}
													className="text-destructive hover:text-destructive"
												>
													<Trash2 className="h-4 w-4" />
												</Button>
											</div>

											{/* Graduation Details */}
											{item.graduationDetails && (
												<div className="text-sm text-muted-foreground space-y-1">
													<p>
														<span className="font-medium">Term:</span>{" "}
														{item.graduationDetails.term}
													</p>
													<p>
														<span className="font-medium">School:</span>{" "}
														{item.graduationDetails.school}
													</p>
													<p>
														<span className="font-medium">Major:</span>{" "}
														{item.graduationDetails.degreeType} in{" "}
														{item.graduationDetails.major}
													</p>
													<p>
														<span className="font-medium">Delivery:</span>{" "}
														{item.graduationDetails.deliveryMethod === "pickup"
															? "Pick up in person"
															: "Ship to address"}
													</p>
												</div>
											)}

											{/* Quantity Controls */}
											<div className="flex items-center gap-2">
												<span className="text-sm text-muted-foreground">
													Quantity:
												</span>
												<div className="flex items-center gap-2">
													<Button
														variant="outline"
														size="sm"
														onClick={() =>
															updateQuantity(item.id, item.quantity - 1)
														}
													>
														-
													</Button>
													<Input
														type="number"
														value={item.quantity}
														onChange={(e) =>
															updateQuantity(
																item.id,
																parseInt(e.target.value) || 1
															)
														}
														className="w-16 text-center"
														min="1"
													/>
													<Button
														variant="outline"
														size="sm"
														onClick={() =>
															updateQuantity(item.id, item.quantity + 1)
														}
													>
														+
													</Button>
												</div>
											</div>

											{/* Subtotal */}
											<div>
												<p>
													Subtotal: ${(item.price * item.quantity).toFixed(2)}
												</p>
											</div>
										</div>
									</div>
									<Separator className="mt-4" />
								</div>
							))}
						</CardContent>
					</Card>
				</div>

				{/* Order Summary */}
				<div className="lg:col-span-1">
					<Card className="sticky top-4">
						<CardHeader>
							<CardTitle>Order Summary</CardTitle>
						</CardHeader>
						<CardContent className="space-y-4">
							<div className="space-y-2">
								<div className="flex justify-between">
									<span className="text-muted-foreground">Subtotal</span>
									<span>${totalPrice.toFixed(2)}</span>
								</div>
								<div className="flex justify-between">
									<span className="text-muted-foreground">Shipping</span>
									<span>
										{items.some(
											(item) =>
												item.graduationDetails?.deliveryMethod === "shipping"
										)
											? "$9.99"
											: "FREE"}
									</span>
								</div>
								<div className="flex justify-between">
									<span className="text-muted-foreground">Tax</span>
									<span>${(totalPrice * 0.08).toFixed(2)}</span>
								</div>
								<Separator />
								<div className="flex justify-between">
									<span>Total</span>
									<span>
										$
										{(
											totalPrice +
											(items.some(
												(item) =>
													item.graduationDetails?.deliveryMethod === "shipping"
											)
												? 9.99
												: 0) +
											totalPrice * 0.08
										).toFixed(2)}
									</span>
								</div>
							</div>

							<Button onClick={handleCheckout} className="w-full" size="lg">
								Proceed to Checkout
							</Button>

							<Button
								onClick={() =>
									router.push(
										"/quick-links/grad-package-purchase/graduation-packages"
									)
								}
								variant="outline"
								className="w-full"
							>
								Continue Shopping
							</Button>
						</CardContent>
					</Card>
				</div>
			</div>
		</div>
	);
}

export default CartPage;
