"use client";

import { ShoppingCart } from "lucide-react";
import { Button } from "../../../components/Button/button";
import { Badge } from "../../../components/Badge/badge";
import { useCart } from "../../../../contexts/graduation-cart/cart-context";

interface CartIconProps {
	onNavigate: (section: string) => void;
}

export function CartIcon({ onNavigate }: CartIconProps) {
	const { totalItems } = useCart();

	return (
		<div className="relative">
			<Button
				variant="ghost"
				size="icon"
				onClick={() => onNavigate("cart")}
				className="relative"
			>
				<ShoppingCart className="h-5 w-5" />
				{totalItems > 0 && (
					<Badge
						className="absolute -top-1 -right-1 h-5 w-5 flex items-center justify-center p-0"
						variant="destructive"
					>
						{totalItems}
					</Badge>
				)}
			</Button>
		</div>
	);
}

export default CartIcon;
