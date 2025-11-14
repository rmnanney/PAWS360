import { createContext, useContext, useState, ReactNode } from "react";

export interface CartItem {
	id: string;
	name: string;
	price: number;
	quantity: number;
	image: string;
	graduationDetails?: {
		term: string;
		school: string;
		major: string;
		degreeType: string;
		deliveryMethod: string;
	};
}

interface CartContextType {
	items: CartItem[];
	addToCart: (item: CartItem) => void;
	removeFromCart: (id: string) => void;
	updateQuantity: (id: string, quantity: number) => void;
	clearCart: () => void;
	totalItems: number;
	totalPrice: number;
}

const CartContext = createContext<CartContextType | undefined>(undefined);

export function CartProvider({ children }: { children: ReactNode }) {
	const [items, setItems] = useState<CartItem[]>([]);

	const addToCart = (item: CartItem) => {
		setItems((prevItems) => {
			const existingItem = prevItems.find((i) => i.id === item.id);
			if (existingItem) {
				return prevItems.map((i) =>
					i.id === item.id ? { ...i, quantity: i.quantity + item.quantity } : i
				);
			}
			return [...prevItems, item];
		});
	};

	const removeFromCart = (id: string) => {
		setItems((prevItems) => prevItems.filter((item) => item.id !== id));
	};

	const updateQuantity = (id: string, quantity: number) => {
		if (quantity <= 0) {
			removeFromCart(id);
			return;
		}
		setItems((prevItems) =>
			prevItems.map((item) => (item.id === id ? { ...item, quantity } : item))
		);
	};

	const clearCart = () => {
		setItems([]);
	};

	const totalItems = items.reduce((sum, item) => sum + item.quantity, 0);
	const totalPrice = items.reduce(
		(sum, item) => sum + item.price * item.quantity,
		0
	);

	return (
		<CartContext.Provider
			value={{
				items,
				addToCart,
				removeFromCart,
				updateQuantity,
				clearCart,
				totalItems,
				totalPrice,
			}}
		>
			{children}
		</CartContext.Provider>
	);
}

export function useCart() {
	const context = useContext(CartContext);
	if (context === undefined) {
		throw new Error("useCart must be used within a CartProvider");
	}
	return context;
}
