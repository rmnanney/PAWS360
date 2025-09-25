import React, { useState } from "react";
import { Input } from "../Others/input";
import { Button } from "../Others/button";
import { Search } from "lucide-react";
import s from "./styles.module.css";

interface SearchBarProps {
	items: Array<{
		title: string;
		description?: string;
		icon?: React.ElementType;
	}>;
	onResultClick?: (item: {
		title: string;
		description?: string;
		icon?: React.ElementType;
	}) => void;
}

export default function SearchBar({ items, onResultClick }: SearchBarProps) {
	const [query, setQuery] = useState("");
	const [results, setResults] = useState<typeof items>([]);
	const [showResults, setShowResults] = useState(false);

	function handleInputChange(e: React.ChangeEvent<HTMLInputElement>) {
		const value = e.target.value;
		setQuery(value);
		const q = value.trim().toLowerCase();
		if (!q) {
			setResults([]);
			setShowResults(false);
			return;
		}
		const filtered = items.filter(
			(item) =>
				item.title.toLowerCase().includes(q) ||
				(item.description && item.description.toLowerCase().includes(q))
		);
		setResults(filtered);
		setShowResults(true);
	}

	function handleResultClick(item: (typeof items)[0]) {
		setShowResults(false);
		setQuery("");
		onResultClick?.(item);
	}

	return (
		<div className={s.searchBar}>
			<div className={s.searchInputRow}>
				<div className={s.searchInputContainer}>
					<Input
						type="text"
						placeholder="Search"
						value={query}
						onChange={handleInputChange}
						className={s.searchInput}
					/>
					<Search className={s.searchIcon} />
				</div>
				{/* <Button variant="outline">
					<Search className="h-4 w-4" />
				</Button> */}
			</div>
			{showResults && results.length > 0 && (
				<div className={s.searchResults}>
					{results.map((item) => (
						<button
							key={item.title}
							className={s.searchResultItem}
							onClick={() => handleResultClick(item)}
						>
							{item.icon && <item.icon className={s.searchResultIcon} />}
							<span className={s.searchResultTitle}>{item.title}</span>
							{item.description && (
								<span className={s.searchResultDescription}>
									{item.description}
								</span>
							)}
						</button>
					))}
				</div>
			)}
			{showResults && results.length === 0 && (
				<div className={`${s.searchResults} ${s.noResults}`}>
					No results found.
				</div>
			)}
		</div>
	);
}
