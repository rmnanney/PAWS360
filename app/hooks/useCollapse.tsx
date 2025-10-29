import { useState } from "react";

export default function useCollapse(initialState: boolean = false) {
	const [isOpen, setIsOpen] = useState(initialState);

	const toggle = () => setIsOpen((prev) => !prev);
	const open = () => setIsOpen(true);
	const close = () => setIsOpen(false);

	return {
		isOpen,
		setIsOpen,
		toggle,
		open,
		close,
	};
}
