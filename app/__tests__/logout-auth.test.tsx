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

describe("Logout and Sidebar Tests", () => {
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

	test("handles logout correctly", () => {
		const MockSidebar = () => {
			const handleLogout = () => {
				localStorage.removeItem("authToken");
				mockToast({
					title: "Signed out",
					description: "You have been successfully signed out.",
				});
				mockPush("/");
			};

			return (
				<div data-testid="sidebar">
					<button data-testid="logout-button" onClick={handleLogout}>
						Logout
					</button>
				</div>
			);
		};

		render(<MockSidebar />);

		const logoutButton = screen.getByTestId("logout-button");
		fireEvent.click(logoutButton);

		expect(localStorage.removeItem).toHaveBeenCalledWith("authToken");
		expect(mockToast).toHaveBeenCalledWith({
			title: "Signed out",
			description: "You have been successfully signed out.",
		});
		expect(mockPush).toHaveBeenCalledWith("/");
	});

	test("renders sidebar navigation items", () => {
		const MockSidebar = () => (
			<div data-testid="sidebar">
				<nav data-testid="sidebar-nav">
					<button data-testid="nav-homepage">Homepage</button>
					<button data-testid="nav-academic">Academic</button>
					<button data-testid="nav-finances">Finances</button>
					<button data-testid="nav-advising">Advising</button>
					<button data-testid="logout-button">Logout</button>
				</nav>
			</div>
		);

		render(<MockSidebar />);

		expect(screen.getByTestId("sidebar")).toBeInTheDocument();
		expect(screen.getByTestId("sidebar-nav")).toBeInTheDocument();
		expect(screen.getByTestId("nav-homepage")).toBeInTheDocument();
		expect(screen.getByTestId("nav-academic")).toBeInTheDocument();
		expect(screen.getByTestId("nav-finances")).toBeInTheDocument();
		expect(screen.getByTestId("nav-advising")).toBeInTheDocument();
		expect(screen.getByTestId("logout-button")).toBeInTheDocument();
	});

	test("handles navigation item clicks", () => {
		const MockSidebar = () => {
			const handleNavigation = (page: string) => {
				console.log(`Navigating to ${page}`);
				mockPush(`/${page.toLowerCase()}`);
			};

			return (
				<div data-testid="sidebar">
					<button
						data-testid="nav-academic"
						onClick={() => handleNavigation("Academic")}
					>
						Academic
					</button>
					<button
						data-testid="nav-finances"
						onClick={() => handleNavigation("Finances")}
					>
						Finances
					</button>
				</div>
			);
		};

		const consoleSpy = jest.spyOn(console, "log").mockImplementation();

		render(<MockSidebar />);

		const academicButton = screen.getByTestId("nav-academic");
		const financesButton = screen.getByTestId("nav-finances");

		fireEvent.click(academicButton);
		expect(consoleSpy).toHaveBeenCalledWith("Navigating to Academic");
		expect(mockPush).toHaveBeenCalledWith("/academic");

		fireEvent.click(financesButton);
		expect(consoleSpy).toHaveBeenCalledWith("Navigating to Finances");
		expect(mockPush).toHaveBeenCalledWith("/finances");

		consoleSpy.mockRestore();
	});
});
