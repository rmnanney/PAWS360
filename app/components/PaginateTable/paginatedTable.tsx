import { useState, useMemo } from "react";
import {
	Table,
	TableBody,
	TableCell,
	TableHead,
	TableHeader,
	TableRow,
} from "../Others/table";
import {
	Pagination,
	PaginationContent,
	PaginationEllipsis,
	PaginationItem,
	PaginationLink,
	PaginationNext,
	PaginationPrevious,
} from "../Others/pagination";
import { ScrollArea } from "../Others/scroll-area";
import { Input } from "../Others/input";
import {
	Select,
	SelectContent,
	SelectItem,
	SelectTrigger,
	SelectValue,
} from "../Others/select";
import { Search, X } from "lucide-react";
import { Button } from "../Others/button";

export interface TableColumn {
	key: string;
	label: string;
	width?: string;
	filterable?: boolean;
	searchable?: boolean;
}

export interface TableData {
	[key: string]: string | number | React.ReactNode;
}

export interface FilterOption {
	key: string;
	label: string;
	options: string[];
}

interface PaginatedTableProps {
	columns: TableColumn[];
	data: TableData[];
	itemsPerPage?: number;
	height?: string;
	searchPlaceholder?: string;
	filterOptions?: FilterOption[];
}

export function PaginatedTable({
	columns,
	data,
	itemsPerPage = 10,
	height = "600px",
	searchPlaceholder = "Search...",
	filterOptions = [],
}: PaginatedTableProps) {
	const [currentPage, setCurrentPage] = useState(1);
	const [searchQuery, setSearchQuery] = useState("");
	const [filters, setFilters] = useState<Record<string, string>>({});

	// Get searchable column keys
	const searchableColumns = useMemo(
		() =>
			columns.filter((col) => col.searchable !== false).map((col) => col.key),
		[columns]
	);

	// Filter and search data
	const filteredData = useMemo(() => {
		let result = [...data];

		// Apply search
		if (searchQuery.trim()) {
			const query = searchQuery.toLowerCase();
			result = result.filter((row) =>
				searchableColumns.some((key) => {
					const value = row[key];
					if (typeof value === "string" || typeof value === "number") {
						return String(value).toLowerCase().includes(query);
					}
					return false;
				})
			);
		}

		// Apply filters
		Object.entries(filters).forEach(([filterKey, filterValue]) => {
			if (filterValue && filterValue !== "all") {
				result = result.filter((row) => {
					const value = row[filterKey];
					if (typeof value === "string") {
						return value.toLowerCase() === filterValue.toLowerCase();
					}
					return false;
				});
			}
		});

		return result;
	}, [data, searchQuery, filters, searchableColumns]);

	// Pagination
	const totalPages = Math.ceil(filteredData.length / itemsPerPage);
	const startIndex = (currentPage - 1) * itemsPerPage;
	const endIndex = startIndex + itemsPerPage;
	const currentData = filteredData.slice(startIndex, endIndex);

	// Reset to page 1 when filters change
	useMemo(() => {
		setCurrentPage(1);
	}, [searchQuery, filters]);

	const handlePageChange = (page: number) => {
		if (page >= 1 && page <= totalPages) {
			setCurrentPage(page);
		}
	};

	const handleFilterChange = (key: string, value: string) => {
		setFilters((prev) => ({
			...prev,
			[key]: value,
		}));
	};

	const clearAllFilters = () => {
		setSearchQuery("");
		setFilters({});
	};

	const hasActiveFilters =
		searchQuery.trim() !== "" ||
		Object.values(filters).some((value) => value && value !== "all");

	const getPageNumbers = () => {
		const pages: (number | string)[] = [];
		const maxVisible = 5;

		if (totalPages <= maxVisible) {
			for (let i = 1; i <= totalPages; i++) {
				pages.push(i);
			}
		} else {
			if (currentPage <= 3) {
				for (let i = 1; i <= 4; i++) {
					pages.push(i);
				}
				pages.push("ellipsis");
				pages.push(totalPages);
			} else if (currentPage >= totalPages - 2) {
				pages.push(1);
				pages.push("ellipsis");
				for (let i = totalPages - 3; i <= totalPages; i++) {
					pages.push(i);
				}
			} else {
				pages.push(1);
				pages.push("ellipsis");
				for (let i = currentPage - 1; i <= currentPage + 1; i++) {
					pages.push(i);
				}
				pages.push("ellipsis");
				pages.push(totalPages);
			}
		}

		return pages;
	};

	return (
		<div className="space-y-4">
			{/* Search and Filters */}
			<div className="flex flex-col gap-4">
				<div className="flex flex-wrap gap-3 items-center">
					{/* Search Input */}
					<div className="relative flex-1 min-w-[250px]">
						<Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
						<Input
							placeholder={searchPlaceholder}
							value={searchQuery}
							onChange={(e) => setSearchQuery(e.target.value)}
							className="pl-9"
						/>
					</div>

					{/* Filter Dropdowns */}
					{filterOptions.map((filterOption) => (
						<Select
							key={filterOption.key}
							value={filters[filterOption.key] || "all"}
							onValueChange={(value) =>
								handleFilterChange(filterOption.key, value)
							}
						>
							<SelectTrigger className="w-[180px]">
								<SelectValue placeholder={filterOption.label} />
							</SelectTrigger>
							<SelectContent>
								<SelectItem value="all">All {filterOption.label}</SelectItem>
								{filterOption.options.map((option) => (
									<SelectItem key={option} value={option}>
										{option}
									</SelectItem>
								))}
							</SelectContent>
						</Select>
					))}

					{/* Clear Filters Button */}
					{hasActiveFilters && (
						<Button
							variant="outline"
							size="sm"
							onClick={clearAllFilters}
							className="gap-2"
						>
							<X className="h-4 w-4" />
							Clear Filters
						</Button>
					)}
				</div>

				{/* Results Count */}
				{hasActiveFilters && (
					<p className="text-muted-foreground">
						Showing {filteredData.length} of {data.length} results
					</p>
				)}
			</div>

			{/* Table */}
			<ScrollArea className="rounded-md border" style={{ height }}>
				<Table>
					<TableHeader>
						<TableRow>
							{columns.map((column) => (
								<TableHead key={column.key} style={{ width: column.width }}>
									{column.label}
								</TableHead>
							))}
						</TableRow>
					</TableHeader>
					<TableBody>
						{currentData.length > 0 ? (
							currentData.map((row, index) => (
								<TableRow key={index}>
									{columns.map((column) => (
										<TableCell key={column.key}>{row[column.key]}</TableCell>
									))}
								</TableRow>
							))
						) : (
							<TableRow>
								<TableCell
									colSpan={columns.length}
									className="h-24 text-center text-muted-foreground"
								>
									{hasActiveFilters
										? "No results found. Try adjusting your filters."
										: "No results found."}
								</TableCell>
							</TableRow>
						)}
					</TableBody>
				</Table>
			</ScrollArea>

			{/* Pagination */}
			{totalPages > 1 && (
				<div className="flex items-center justify-between">
					<p className="text-muted-foreground">
						Showing {filteredData.length > 0 ? startIndex + 1 : 0} to{" "}
						{Math.min(endIndex, filteredData.length)} of {filteredData.length}{" "}
						{hasActiveFilters ? "filtered" : ""} entries
					</p>
					<Pagination>
						<PaginationContent>
							<PaginationItem>
								<PaginationPrevious
									onClick={() => handlePageChange(currentPage - 1)}
									className={
										currentPage === 1
											? "pointer-events-none opacity-50"
											: "cursor-pointer"
									}
								/>
							</PaginationItem>

							{getPageNumbers().map((page, index) => (
								<PaginationItem key={index}>
									{page === "ellipsis" ? (
										<PaginationEllipsis />
									) : (
										<PaginationLink
											onClick={() => handlePageChange(page as number)}
											isActive={currentPage === page}
											className="cursor-pointer"
										>
											{page}
										</PaginationLink>
									)}
								</PaginationItem>
							))}

							<PaginationItem>
								<PaginationNext
									onClick={() => handlePageChange(currentPage + 1)}
									className={
										currentPage === totalPages
											? "pointer-events-none opacity-50"
											: "cursor-pointer"
									}
								/>
							</PaginationItem>
						</PaginationContent>
					</Pagination>
				</div>
			)}
		</div>
	);
}
