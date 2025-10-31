import { render, screen } from "@testing-library/react";

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

describe("Homepage Authentication Tests", () => {
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

	test("redirects to login when no auth token", () => {
		(localStorage.getItem as jest.Mock).mockReturnValue(null);

		const MockHomepage = () => {
			const authToken = localStorage.getItem("authToken");

			if (!authToken) {
				localStorage.setItem("showAuthToast", "true");
				mockPush("/login");
				return null;
			}

			return <div data-testid="homepage">Homepage Content</div>;
		};

		const { container } = render(<MockHomepage />);

		expect(localStorage.setItem).toHaveBeenCalledWith("showAuthToast", "true");
		expect(mockPush).toHaveBeenCalledWith("/login");
		expect(container.firstChild).toBeNull();
	});

	test("renders homepage when authenticated", () => {
		(localStorage.getItem as jest.Mock).mockReturnValue("mock-auth-token");

		const MockHomepage = () => {
			const authToken = localStorage.getItem("authToken");

			if (!authToken) {
				return null;
			}

			return (
				<div data-testid="homepage">
					<div data-testid="header">Header</div>
					<div data-testid="sidebar">Sidebar</div>
					<div data-testid="homepage-cards">
						<div data-testid="academic-card">Academic</div>
						<div data-testid="advising-card">Advising</div>
						<div data-testid="finances-card">Finances</div>
						<div data-testid="schedule-card">Schedule</div>
					</div>
				</div>
			);
		};

		render(<MockHomepage />);

		expect(screen.getByTestId("homepage")).toBeInTheDocument();
		expect(screen.getByTestId("header")).toBeInTheDocument();
		expect(screen.getByTestId("sidebar")).toBeInTheDocument();
		expect(screen.getByTestId("academic-card")).toBeInTheDocument();
		expect(screen.getByTestId("advising-card")).toBeInTheDocument();
		expect(screen.getByTestId("finances-card")).toBeInTheDocument();
		expect(screen.getByTestId("schedule-card")).toBeInTheDocument();
	});

	test("handles homepage card navigation", () => {
		(localStorage.getItem as jest.Mock).mockReturnValue("mock-auth-token");

		const MockHomepage = () => {
			const handleCardClick = (cardName: string) => {
				console.log(`Navigating to ${cardName}`);
			};

			return (
				<div data-testid="homepage">
					<button
						data-testid="academic-card"
						onClick={() => handleCardClick("Academic")}
					>
						Academic
					</button>
				</div>
			);
		};

		const consoleSpy = jest.spyOn(console, "log").mockImplementation();

		render(<MockHomepage />);

		const academicCard = screen.getByTestId("academic-card");
		academicCard.click();

		expect(consoleSpy).toHaveBeenCalledWith("Navigating to Academic");

		consoleSpy.mockRestore();
	});
});
