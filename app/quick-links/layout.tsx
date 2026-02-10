// /app/quick-links/grad-package-purchase/layout.tsx
"use client";
import { CartProvider } from "../../contexts/graduation-cart/cart-context";

export default function GradPackagePurchaseLayout({
	children,
}: {
	children: React.ReactNode;
}) {
	return (
		<div>
			<main className="space-y-6 p-4 md:p-8 pt-6">
				<CartProvider>{children}</CartProvider>
			</main>
		</div>
	);
}
