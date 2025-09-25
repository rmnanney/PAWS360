import type { Metadata } from "next";
import "./global.css";
import { Toaster } from "./components/Toaster/toaster";

export const metadata: Metadata = {
	title: "University of Wisconsin, Milwaukee Login",
	description: "Login page for University of Wisconsin, Milwaukee",
};

export default function RootLayout({
	children,
}: Readonly<{
	children: React.ReactNode;
}>) {
	return (
		<html lang="en">
			<body className="font-body antialiased">
				{children}
				<Toaster />
			</body>
		</html>
	);
}
