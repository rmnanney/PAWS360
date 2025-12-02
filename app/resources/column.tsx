import {
	TableColumn,
	FilterOption,
} from "../components/PaginateTable/paginatedTable";

// Column definitions for each table
export const libraryColumns: TableColumn[] = [
	{ key: "id", label: "ID", width: "60px", searchable: false },
	{ key: "name", label: "Library Name", width: "200px" },
	{ key: "type", label: "Type", width: "120px", searchable: false },
	{ key: "description", label: "Description" },
	{ key: "location", label: "Location", width: "200px" },
	{ key: "hours", label: "Hours", width: "150px" },
	{ key: "services", label: "Services", width: "250px" },
	{ key: "rating", label: "Rating", width: "80px", searchable: false },
	{ key: "status", label: "Status", width: "120px", searchable: false },
	{ key: "action", label: "Action", width: "120px", searchable: false },
];

export const tutoringColumns: TableColumn[] = [
	{ key: "id", label: "ID", width: "60px", searchable: false },
	{ key: "name", label: "Subject", width: "180px" },
	{ key: "type", label: "Type", width: "120px", searchable: false },
	{ key: "description", label: "Description" },
	{ key: "location", label: "Location", width: "200px" },
	{ key: "hours", label: "Hours", width: "180px" },
	{ key: "contact", label: "Contact", width: "140px" },
	{ key: "availability", label: "Availability", width: "150px" },
	{ key: "rating", label: "Rating", width: "80px", searchable: false },
	{ key: "status", label: "Status", width: "120px", searchable: false },
	{ key: "action", label: "Action", width: "120px", searchable: false },
];

export const servicesColumns: TableColumn[] = [
	{ key: "id", label: "ID", width: "60px", searchable: false },
	{ key: "name", label: "Service Name", width: "200px" },
	{ key: "type", label: "Type", width: "120px", searchable: false },
	{ key: "category", label: "Category", width: "150px" },
	{ key: "description", label: "Description" },
	{ key: "location", label: "Location", width: "200px" },
	{ key: "phone", label: "Phone", width: "140px" },
	{ key: "email", label: "Email", width: "180px" },
	{ key: "hours", label: "Hours", width: "150px" },
	{
		key: "confidential",
		label: "Confidential",
		width: "100px",
		searchable: false,
	},
	{ key: "status", label: "Status", width: "120px", searchable: false },
	{ key: "action", label: "Action", width: "120px", searchable: false },
];

export const studySpacesColumns: TableColumn[] = [
	{ key: "id", label: "ID", width: "60px", searchable: false },
	{ key: "name", label: "Space Name", width: "200px" },
	{ key: "type", label: "Type", width: "120px", searchable: false },
	{ key: "description", label: "Description" },
	{ key: "location", label: "Location", width: "200px" },
	{ key: "capacity", label: "Capacity", width: "120px" },
	{ key: "amenities", label: "Amenities", width: "250px" },
	{ key: "booking", label: "Booking", width: "180px" },
	{ key: "availability", label: "Availability", width: "180px" },
	{ key: "status", label: "Status", width: "120px", searchable: false },
	{ key: "action", label: "Action", width: "120px", searchable: false },
];

export const eventsColumns: TableColumn[] = [
	{ key: "id", label: "ID", width: "60px", searchable: false },
	{ key: "name", label: "Event Name", width: "250px" },
	{ key: "type", label: "Type", width: "120px", searchable: false },
	{ key: "category", label: "Category", width: "120px" },
	{ key: "description", label: "Description" },
	{ key: "date", label: "Date", width: "120px" },
	{ key: "time", label: "Time", width: "150px" },
	{ key: "location", label: "Location", width: "200px" },
	{ key: "registration", label: "Registration", width: "120px" },
	{ key: "status", label: "Status", width: "140px", searchable: false },
	{ key: "action", label: "Action", width: "180px", searchable: false },
];

// Filter options
export const libraryFilters: FilterOption[] = [
	{ key: "typeRaw", label: "Type", options: ["Library"] },
	{ key: "statusRaw", label: "Status", options: ["Available"] },
];

export const tutoringFilters: FilterOption[] = [
	{ key: "typeRaw", label: "Type", options: ["Tutorial"] },
	{
		key: "availability",
		label: "Availability",
		options: [
			"Drop-in and appointment",
			"Appointment required",
			"Drop-in available",
			"Drop-in",
		],
	},
	{ key: "statusRaw", label: "Status", options: ["Available"] },
];

export const servicesFilters: FilterOption[] = [
	{ key: "typeRaw", label: "Type", options: ["Service", "Support"] },
	{
		key: "category",
		label: "Category",
		options: [
			"Health & Wellness",
			"Career Support",
			"Accessibility",
			"Technology",
			"Safety",
		],
	},
	{ key: "statusRaw", label: "Status", options: ["Available"] },
];

export const studySpacesFilters: FilterOption[] = [
	{ key: "typeRaw", label: "Type", options: ["Facility"] },
	{ key: "statusRaw", label: "Status", options: ["Available"] },
];

export const eventsFilters: FilterOption[] = [
	{ key: "typeRaw", label: "Type", options: ["Workshop", "Program"] },
	{
		key: "category",
		label: "Category",
		options: ["Career", "Wellness", "Academic", "Life Skills"],
	},
	{
		key: "registration",
		label: "Registration",
		options: ["Required", "Optional"],
	},
	{
		key: "statusRaw",
		label: "Status",
		options: ["Registration Open", "Available"],
	},
];
