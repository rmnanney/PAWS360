import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";

export default function useAuth() {
	const router = useRouter();
	const [authChecked, setAuthChecked] = useState(false);
	const [isAuthenticated, setIsAuthenticated] = useState(false);

	useEffect(() => {
		if (typeof window !== "undefined") {
			const authToken = localStorage.getItem("authToken");
			if (!authToken) {
				localStorage.setItem("showAuthToast", "true");
				router.push("/login");
				setAuthChecked(true);
				setIsAuthenticated(false);
			} else {
				setAuthChecked(true);
				setIsAuthenticated(true);
			}
		}
	}, [router]);

	return { authChecked, isAuthenticated };
}
