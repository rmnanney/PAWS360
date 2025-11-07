import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";

interface UserInfo {
	userId: number;
	email: string;
	firstname: string;
	lastname: string;
	role: string;
	status: string;
}

interface AuthState {
	authChecked: boolean;
	isAuthenticated: boolean;
	user: UserInfo | null;
	sessionId: string | null;
	isLoading: boolean;
}

/**
 * SSO-aware authentication hook for repository unification.
 * Validates sessions using HTTP-only cookies and backend SSO validation.
 */
export default function useAuth() {
	const router = useRouter();
	const [authState, setAuthState] = useState<AuthState>({
		authChecked: false,
		isAuthenticated: false,
		user: null,
		sessionId: null,
		isLoading: true,
	});

	/**
	 * Validate SSO session with backend
	 */
	const validateSession = async (): Promise<boolean> => {
		try {
			const response = await fetch("http://localhost:8081/auth/validate", {
				method: "GET",
				credentials: "include", // Include HTTP-only cookies
				headers: {
					"X-Service-Origin": "student-portal",
				},
			});

			if (response.ok) {
				const data = await response.json();
				if (data.valid) {
					setAuthState({
						authChecked: true,
						isAuthenticated: true,
						user: {
							userId: data.user_id,
							email: data.email,
							firstname: data.firstname,
							lastname: data.lastname,
							role: data.role,
							status: data.status,
						},
						sessionId: data.session_id,
						isLoading: false,
					});

					// Store minimal user info in sessionStorage for UI purposes only
					sessionStorage.setItem("userEmail", data.email);
					sessionStorage.setItem("userFirstName", data.firstname);
					sessionStorage.setItem("userRole", data.role);

					return true;
				}
			}

			// Session invalid or expired
			return false;
		} catch (error) {
			console.error("Session validation failed:", error);
			return false;
		}
	};

	/**
	 * Logout and clean up session
	 */
	const logout = async (): Promise<void> => {
		try {
			await fetch("http://localhost:8081/auth/logout", {
				method: "POST",
				credentials: "include",
				headers: {
					"X-Service-Origin": "student-portal",
				},
			});
		} catch (error) {
			console.error("Logout request failed:", error);
		} finally {
			// Clear local state and sessionStorage
			setAuthState({
				authChecked: true,
				isAuthenticated: false,
				user: null,
				sessionId: null,
				isLoading: false,
			});

			sessionStorage.removeItem("userEmail");
			sessionStorage.removeItem("userFirstName");
			sessionStorage.removeItem("userRole");
			sessionStorage.setItem("showAuthToast", "true");

			router.push("/login");
		}
	};

	/**
	 * Extend current session
	 */
	const extendSession = async (): Promise<boolean> => {
		try {
			const response = await fetch("http://localhost:8081/auth/extend", {
				method: "POST",
				credentials: "include",
				headers: {
					"X-Service-Origin": "student-portal",
				},
			});

			return response.ok;
		} catch (error) {
			console.error("Session extension failed:", error);
			return false;
		}
	};

	/**
	 * Check if user has specific role
	 */
	const hasRole = (role: string): boolean => {
		return authState.user?.role === role;
	};

	/**
	 * Check if user is admin (any admin role)
	 */
	const isAdmin = (): boolean => {
		return authState.user?.role === "ADMIN" || 
			   authState.user?.role === "FACULTY" || 
			   authState.user?.role === "ADVISOR";
	};

	useEffect(() => {
		if (typeof window !== "undefined") {
			validateSession().then((isValid) => {
				if (!isValid) {
					// No valid session found
					setAuthState({
						authChecked: true,
						isAuthenticated: false,
						user: null,
						sessionId: null,
						isLoading: false,
					});

					sessionStorage.setItem("showAuthToast", "true");
					router.push("/login");
				}
			});
		}
	}, [router]);

	// Auto-extend session periodically for active users
	useEffect(() => {
		if (authState.isAuthenticated) {
			const interval = setInterval(() => {
				extendSession();
			}, 30 * 60 * 1000); // Extend every 30 minutes

			return () => clearInterval(interval);
		}
	}, [authState.isAuthenticated]);

	return {
		...authState,
		validateSession,
		logout,
		extendSession,
		hasRole,
		isAdmin,
	};
}
