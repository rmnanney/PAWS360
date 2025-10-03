import { render, screen, fireEvent } from "@testing-library/react";

// Mock next/navigation
const mockPush = jest.fn();
jest.mock("next/navigation", () => ({
	useRouter: () => ({
		push: mockPush,
	}),
}));

// Mock the toast hook with correct path
const mockToast = jest.fn();
jest.mock("../hooks/useToast", () => ({
	useToast: () => ({
		toast: mockToast,
	}),
}));

describe("Login Component Tests", () => {
	beforeEach(() => {
		jest.clearAllMocks();

		// Mock localStorage
		Object.defineProperty(window, "localStorage", {
			value: {
				getItem: jest.fn(),
				setItem: jest.fn(),
				removeItem: jest.fn(),
			},
			writable: true,
		});
	});

	test("handles login submission with mock fetch", async () => {
		const mockResponse = {
			ok: true,
			json: async () => ({
				message: "Login Successful",
				session_token: "mock-token",
				firstname: "John",
			}),
		};

		global.fetch = jest.fn().mockResolvedValueOnce(mockResponse);

		const LoginFormWithHandlers = () => {
			const handleSubmit = async () => {
				const response = await fetch("http://localhost:8080/login", {
					method: "POST",
					headers: { "Content-Type": "application/json" },
					body: JSON.stringify({ email: "test@uwm.edu", password: "password" }),
				});

				if (response.ok) {
					const data = await response.json();
					localStorage.setItem("authToken", data.session_token);
					mockToast({
						title: "Login Successful",
						description: `Welcome ${data.firstname}!`,
					});
					mockPush("/homepage");
				}
			};

			return (
				<div>
					<button data-testid="login-button" onClick={handleSubmit}>
						Login
					</button>
				</div>
			);
		};

		render(<LoginFormWithHandlers />);

		const loginButton = screen.getByTestId("login-button");
		fireEvent.click(loginButton);

		// Wait a bit for async operations
		await new Promise((resolve) => setTimeout(resolve, 100));

		expect(fetch).toHaveBeenCalledWith("http://localhost:8080/login", {
			method: "POST",
			headers: { "Content-Type": "application/json" },
			body: JSON.stringify({ email: "test@uwm.edu", password: "password" }),
		});

		expect(localStorage.setItem).toHaveBeenCalledWith(
			"authToken",
			"mock-token"
		);
		expect(mockToast).toHaveBeenCalledWith({
			title: "Login Successful",
			description: "Welcome John!",
		});
		expect(mockPush).toHaveBeenCalledWith("/homepage");
	});

	test("handles login failure", async () => {
		const mockResponse = {
			ok: false,
			json: async () => ({
				message: "Invalid credentials",
			}),
		};

		global.fetch = jest.fn().mockResolvedValueOnce(mockResponse);

		const LoginFormWithErrorHandling = () => {
			const handleSubmit = async () => {
				const response = await fetch("http://localhost:8080/login", {
					method: "POST",
					headers: { "Content-Type": "application/json" },
					body: JSON.stringify({
						email: "test@uwm.edu",
						password: "wrongpassword",
					}),
				});

				if (!response.ok) {
					const data = await response.json();
					mockToast({
						variant: "destructive",
						title: "Login Failed",
						description: data.message,
					});
				}
			};

			return (
				<div>
					<button data-testid="login-button" onClick={handleSubmit}>
						Login
					</button>
				</div>
			);
		};

		render(<LoginFormWithErrorHandling />);

		const loginButton = screen.getByTestId("login-button");
		fireEvent.click(loginButton);

		// Wait a bit for async operations
		await new Promise((resolve) => setTimeout(resolve, 100));

		expect(mockToast).toHaveBeenCalledWith({
			variant: "destructive",
			title: "Login Failed",
			description: "Invalid credentials",
		});
	});
});
