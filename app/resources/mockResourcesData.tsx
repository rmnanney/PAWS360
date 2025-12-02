import React from "react";
import { Badge } from "../components/Others/badge";
import { Button } from "../components/Others/button";
import {
	BookOpen,
	Calendar,
	MapPin,
	ExternalLink,
	Phone,
	Mail,
	FileText,
	Video,
	Link as LinkIcon,
} from "lucide-react";
import { TableData } from "../components/PaginateTable/paginatedTable";

// Sample data - converted to TableData format
// Libraries
export const libraryResources: TableData[] = [
	{
		id: 1,
		name: "Golda Meir Library",
		typeRaw: "Library",
		type: (
			<Badge variant="secondary">
				<BookOpen className="w-3 h-3 mr-1" />
				Library
			</Badge>
		),
		description: "Main university library with extensive collections",
		location: "Golda Meir Library Building",
		hours: "24/7 during semester",
		services: "Books, Journals, Study Rooms, Computers, Research Help",
		rating: "4.5",
		statusRaw: "Available",
		status: <Badge>Available</Badge>,
		action: (
			<div className="flex gap-1">
				<Button variant="ghost" size="sm" title="Directions">
					<MapPin className="w-4 h-4" />
				</Button>
				<Button variant="ghost" size="sm" title="Website">
					<ExternalLink className="w-4 h-4" />
				</Button>
			</div>
		),
	},
	{
		id: 2,
		name: "Curtin Library",
		typeRaw: "Library",
		type: (
			<Badge variant="secondary">
				<BookOpen className="w-3 h-3 mr-1" />
				Library
			</Badge>
		),
		description: "Specialized business and economics library",
		location: "Lubar Hall",
		hours: "Mon-Fri 8AM-10PM",
		services: "Business Databases, Study Spaces, Group Rooms",
		rating: "4.2",
		statusRaw: "Available",
		status: <Badge>Available</Badge>,
		action: (
			<div className="flex gap-1">
				<Button variant="ghost" size="sm" title="Directions">
					<MapPin className="w-4 h-4" />
				</Button>
				<Button variant="ghost" size="sm" title="Website">
					<ExternalLink className="w-4 h-4" />
				</Button>
			</div>
		),
	},
	{
		id: 26,
		name: "University Library Database",
		typeRaw: "Library",
		type: (
			<Badge variant="secondary">
				<BookOpen className="w-3 h-3 mr-1" />
				Library
			</Badge>
		),
		description: "Access to thousands of academic journals and publications",
		location: "Online",
		hours: "24/7",
		services: "Journals, Research Papers, Digital Archives",
		rating: "4.8",
		statusRaw: "Available",
		status: <Badge>Available</Badge>,
		action: (
			<Button variant="ghost" size="sm">
				<LinkIcon className="w-4 h-4" />
			</Button>
		),
	},
];

// Tutoring Services
export const tutoringServices: TableData[] = [
	{
		id: 1,
		name: "Mathematics",
		typeRaw: "Tutorial",
		type: (
			<Badge variant="secondary">
				<FileText className="w-3 h-3 mr-1" />
				Tutorial
			</Badge>
		),
		description: "One-on-one and group tutoring for all math courses",
		location: "Multiple locations",
		hours: "Mon-Fri 9AM-9PM, Sat 10AM-4PM",
		contact: "(414) 229-1234",
		availability: "Drop-in and appointment",
		rating: "4.7",
		statusRaw: "Available",
		status: <Badge>Available</Badge>,
		action: (
			<div className="flex gap-1">
				<Button variant="ghost" size="sm" title="Schedule">
					<Calendar className="w-4 h-4" />
				</Button>
				<Button variant="ghost" size="sm" title="Call">
					<Phone className="w-4 h-4" />
				</Button>
			</div>
		),
	},
	{
		id: 2,
		name: "Writing Center Services",
		typeRaw: "Tutorial",
		type: (
			<Badge variant="secondary">
				<FileText className="w-3 h-3 mr-1" />
				Tutorial
			</Badge>
		),
		description:
			"Free tutoring for essays, research papers, and writing skills",
		location: "English Building, Room 234",
		hours: "Mon-Thu 9AM-8PM, Fri 9AM-4PM",
		contact: "(414) 229-5678",
		availability: "Appointment required",
		rating: "4.8",
		statusRaw: "Available",
		status: <Badge>Available</Badge>,
		action: (
			<div className="flex gap-1">
				<Button variant="ghost" size="sm" title="Schedule">
					<Calendar className="w-4 h-4" />
				</Button>
				<Button variant="ghost" size="sm" title="Call">
					<Phone className="w-4 h-4" />
				</Button>
			</div>
		),
	},
	{
		id: 3,
		name: "Computer Science",
		typeRaw: "Tutorial",
		type: (
			<Badge variant="secondary">
				<FileText className="w-3 h-3 mr-1" />
				Tutorial
			</Badge>
		),
		description: "Programming help and computer science concepts",
		location: "EMS Building, Room 180",
		hours: "Mon-Fri 10AM-6PM",
		contact: "(414) 229-9012",
		availability: "Drop-in available",
		rating: "4.6",
		statusRaw: "Available",
		status: <Badge>Available</Badge>,
		action: (
			<div className="flex gap-1">
				<Button variant="ghost" size="sm" title="Schedule">
					<Calendar className="w-4 h-4" />
				</Button>
				<Button variant="ghost" size="sm" title="Call">
					<Phone className="w-4 h-4" />
				</Button>
			</div>
		),
	},
	{
		id: 27,
		name: "Math Tutoring Center",
		typeRaw: "Tutorial",
		type: (
			<Badge variant="secondary">
				<FileText className="w-3 h-3 mr-1" />
				Tutorial
			</Badge>
		),
		description: "Drop-in tutoring for calculus, algebra, and statistics",
		location: "Math Building",
		hours: "Mon-Fri 10AM-6PM",
		contact: "(414) 229-5555",
		availability: "Drop-in",
		rating: "4.5",
		statusRaw: "Available",
		status: <Badge>Available</Badge>,
		action: (
			<Button variant="ghost" size="sm">
				<LinkIcon className="w-4 h-4" />
			</Button>
		),
	},
];

// Campus Services
export const campusServices: TableData[] = [
	{
		id: 1,
		name: "Counseling Center",
		typeRaw: "Service",
		type: (
			<Badge variant="secondary">
				<BookOpen className="w-3 h-3 mr-1" />
				Service
			</Badge>
		),
		category: "Health & Wellness",
		description: "Mental health support and counseling services",
		location: "Student Services Building",
		phone: "(414) 229-1122",
		email: "counseling@uwm.edu",
		hours: "Mon-Fri 8AM-5PM",
		emergency: "24/7 Crisis Line: (414) 229-HELP",
		confidential: "Yes",
		statusRaw: "Available",
		status: <Badge>Available</Badge>,
		action: (
			<div className="flex gap-1">
				<Button variant="ghost" size="sm" title="Call">
					<Phone className="w-4 h-4" />
				</Button>
				<Button variant="ghost" size="sm" title="Email">
					<Mail className="w-4 h-4" />
				</Button>
			</div>
		),
	},
	{
		id: 2,
		name: "Health Services",
		typeRaw: "Service",
		type: (
			<Badge variant="secondary">
				<BookOpen className="w-3 h-3 mr-1" />
				Service
			</Badge>
		),
		category: "Health & Wellness",
		description: "Medical care, immunizations, and health consultations",
		location: "Engelmann Hall",
		phone: "(414) 229-2233",
		email: "health@uwm.edu",
		hours: "Mon-Fri 8AM-4:30PM",
		emergency: "After hours: Urgent Care",
		confidential: "Yes",
		statusRaw: "Available",
		status: <Badge>Available</Badge>,
		action: (
			<div className="flex gap-1">
				<Button variant="ghost" size="sm" title="Call">
					<Phone className="w-4 h-4" />
				</Button>
				<Button variant="ghost" size="sm" title="Email">
					<Mail className="w-4 h-4" />
				</Button>
			</div>
		),
	},
	{
		id: 3,
		name: "Career Services",
		typeRaw: "Service",
		type: (
			<Badge variant="secondary">
				<BookOpen className="w-3 h-3 mr-1" />
				Service
			</Badge>
		),
		category: "Career Support",
		description: "Resume help, job search assistance, and career counseling",
		location: "Career Center",
		phone: "(414) 229-3344",
		email: "career@uwm.edu",
		hours: "Mon-Fri 8AM-5PM",
		emergency: "N/A",
		confidential: "No",
		statusRaw: "Available",
		status: <Badge>Available</Badge>,
		action: (
			<div className="flex gap-1">
				<Button variant="ghost" size="sm" title="Call">
					<Phone className="w-4 h-4" />
				</Button>
				<Button variant="ghost" size="sm" title="Email">
					<Mail className="w-4 h-4" />
				</Button>
			</div>
		),
	},
	{
		id: 4,
		name: "Disability Services",
		typeRaw: "Service",
		type: (
			<Badge variant="secondary">
				<BookOpen className="w-3 h-3 mr-1" />
				Service
			</Badge>
		),
		category: "Accessibility",
		description: "Support services for students with disabilities",
		location: "Student Services Building, Room 200",
		phone: "(414) 229-4455",
		email: "disability@uwm.edu",
		hours: "Mon-Fri 8AM-5PM",
		emergency: "N/A",
		confidential: "Yes",
		statusRaw: "Available",
		status: <Badge>Available</Badge>,
		action: (
			<div className="flex gap-1">
				<Button variant="ghost" size="sm" title="Call">
					<Phone className="w-4 h-4" />
				</Button>
				<Button variant="ghost" size="sm" title="Email">
					<Mail className="w-4 h-4" />
				</Button>
			</div>
		),
	},
	{
		id: 28,
		name: "IT Help Desk Portal",
		typeRaw: "Support",
		type: (
			<Badge variant="secondary">
				<BookOpen className="w-3 h-3 mr-1" />
				Support
			</Badge>
		),
		category: "Technology",
		description: "Technical support for software, hardware, and network issues",
		location: "IT Building",
		phone: "(414) 229-7777",
		email: "helpdesk@uwm.edu",
		hours: "24/7",
		emergency: "N/A",
		confidential: "No",
		statusRaw: "Available",
		status: <Badge>Available</Badge>,
		action: (
			<Button variant="ghost" size="sm">
				<LinkIcon className="w-4 h-4" />
			</Button>
		),
	},
	{
		id: 29,
		name: "Campus Safety Resources",
		typeRaw: "Service",
		type: (
			<Badge variant="secondary">
				<BookOpen className="w-3 h-3 mr-1" />
				Service
			</Badge>
		),
		category: "Safety",
		description: "Emergency contacts, safety escorts, and campus alerts",
		location: "Campus-wide",
		phone: "(414) 229-9999",
		email: "safety@uwm.edu",
		hours: "24/7",
		emergency: "911 or (414) 229-9999",
		confidential: "No",
		statusRaw: "Available",
		status: <Badge>Available</Badge>,
		action: (
			<Button variant="ghost" size="sm">
				<LinkIcon className="w-4 h-4" />
			</Button>
		),
	},
];

// Study Spaces
export const studySpaces: TableData[] = [
	{
		id: 1,
		name: "Library Study Rooms",
		typeRaw: "Facility",
		type: (
			<Badge variant="secondary">
				<BookOpen className="w-3 h-3 mr-1" />
				Facility
			</Badge>
		),
		description: "Private study rooms for individual or group work",
		location: "Golda Meir Library",
		capacity: "2-8 people",
		amenities: "Whiteboard, Power outlets, WiFi",
		booking: "Library website or app",
		availability: "24/7 during semester",
		statusRaw: "Available",
		status: <Badge>Available</Badge>,
		action: (
			<div className="flex gap-1">
				<Button variant="ghost" size="sm" title="Directions">
					<MapPin className="w-4 h-4" />
				</Button>
				<Button variant="ghost" size="sm" title="Reserve">
					<Calendar className="w-4 h-4" />
				</Button>
			</div>
		),
	},
	{
		id: 2,
		name: "Student Commons",
		typeRaw: "Facility",
		type: (
			<Badge variant="secondary">
				<BookOpen className="w-3 h-3 mr-1" />
				Facility
			</Badge>
		),
		description: "Open study areas with computers and printing",
		location: "Student Union",
		capacity: "Individual study",
		amenities: "Computers, Printers, Coffee shop",
		booking: "First come, first served",
		availability: "Mon-Sun 6AM-2AM",
		statusRaw: "Available",
		status: <Badge>Available</Badge>,
		action: (
			<div className="flex gap-1">
				<Button variant="ghost" size="sm" title="Directions">
					<MapPin className="w-4 h-4" />
				</Button>
				<Button variant="ghost" size="sm" title="Reserve">
					<Calendar className="w-4 h-4" />
				</Button>
			</div>
		),
	},
	{
		id: 3,
		name: "Quiet Study Area",
		typeRaw: "Facility",
		type: (
			<Badge variant="secondary">
				<BookOpen className="w-3 h-3 mr-1" />
				Facility
			</Badge>
		),
		description: "Silent study environment for focused work",
		location: "English Building, 3rd Floor",
		capacity: "Individual study",
		amenities: "Individual desks, Natural light",
		booking: "No reservation needed",
		availability: "Mon-Fri 7AM-10PM",
		statusRaw: "Available",
		status: <Badge>Available</Badge>,
		action: (
			<div className="flex gap-1">
				<Button variant="ghost" size="sm" title="Directions">
					<MapPin className="w-4 h-4" />
				</Button>
				<Button variant="ghost" size="sm" title="Reserve">
					<Calendar className="w-4 h-4" />
				</Button>
			</div>
		),
	},
	{
		id: 30,
		name: "STEM Lab Booking System",
		typeRaw: "Facility",
		type: (
			<Badge variant="secondary">
				<BookOpen className="w-3 h-3 mr-1" />
				Facility
			</Badge>
		),
		description: "Reserve lab space for science and engineering projects",
		location: "STEM Building",
		capacity: "Varies by lab",
		amenities: "Lab equipment, Safety gear, Workstations",
		booking: "Online reservation system",
		availability: "Mon-Fri 8AM-10PM",
		statusRaw: "Available",
		status: <Badge>Available</Badge>,
		action: (
			<Button variant="ghost" size="sm">
				<LinkIcon className="w-4 h-4" />
			</Button>
		),
	},
	{
		id: 31,
		name: "3D Printing & Maker Space",
		typeRaw: "Facility",
		type: (
			<Badge variant="secondary">
				<BookOpen className="w-3 h-3 mr-1" />
				Facility
			</Badge>
		),
		description: "Access 3D printers, laser cutters, and prototyping tools",
		location: "Innovation Center",
		capacity: "10-15 people",
		amenities: "3D Printers, Laser Cutters, Tools",
		booking: "Online booking",
		availability: "Mon-Fri 9AM-9PM",
		statusRaw: "Available",
		status: <Badge>Available</Badge>,
		action: (
			<Button variant="ghost" size="sm">
				<LinkIcon className="w-4 h-4" />
			</Button>
		),
	},
];

// Events
export const upcomingEvents: TableData[] = [
	{
		id: 1,
		name: "Resume Workshop",
		typeRaw: "Workshop",
		type: (
			<Badge variant="secondary">
				<Video className="w-3 h-3 mr-1" />
				Workshop
			</Badge>
		),
		category: "Career",
		description: "Learn how to create an effective resume for job applications",
		date: "2025-10-18",
		time: "2:00 PM - 4:00 PM",
		location: "Career Center",
		registration: "Required",
		statusRaw: "Registration Open",
		status: <Badge variant="outline">Registration Open</Badge>,
		action: (
			<div className="flex gap-1">
				<Button variant="ghost" size="sm" title="Add to Calendar">
					<Calendar className="w-4 h-4" />
				</Button>
				<Button size="sm">Register</Button>
			</div>
		),
	},
	{
		id: 2,
		name: "Mental Health Awareness Week",
		typeRaw: "Program",
		type: (
			<Badge variant="secondary">
				<FileText className="w-3 h-3 mr-1" />
				Program
			</Badge>
		),
		category: "Wellness",
		description: "Various events and resources for mental health awareness",
		date: "2025-10-20",
		time: "All day",
		location: "Campus-wide",
		registration: "Optional",
		statusRaw: "Available",
		status: <Badge>Available</Badge>,
		action: (
			<div className="flex gap-1">
				<Button variant="ghost" size="sm" title="Add to Calendar">
					<Calendar className="w-4 h-4" />
				</Button>
				<Button size="sm">Register</Button>
			</div>
		),
	},
	{
		id: 3,
		name: "Study Skills Seminar",
		typeRaw: "Workshop",
		type: (
			<Badge variant="secondary">
				<Video className="w-3 h-3 mr-1" />
				Workshop
			</Badge>
		),
		category: "Academic",
		description: "Improve your study techniques and time management skills",
		date: "2025-10-22",
		time: "11:00 AM - 12:30 PM",
		location: "Library Conference Room A",
		registration: "Required",
		statusRaw: "Registration Open",
		status: <Badge variant="outline">Registration Open</Badge>,
		action: (
			<div className="flex gap-1">
				<Button variant="ghost" size="sm" title="Add to Calendar">
					<Calendar className="w-4 h-4" />
				</Button>
				<Button size="sm">Register</Button>
			</div>
		),
	},
	{
		id: 32,
		name: "Career Development Workshops",
		typeRaw: "Workshop",
		type: (
			<Badge variant="secondary">
				<Video className="w-3 h-3 mr-1" />
				Workshop
			</Badge>
		),
		category: "Career",
		description: "Resume building, interview prep, and networking skills",
		date: "2025-11-15",
		time: "1:00 PM - 3:00 PM",
		location: "Career Services Building",
		registration: "Required",
		statusRaw: "Registration Open",
		status: <Badge variant="outline">Registration Open</Badge>,
		action: (
			<Button variant="ghost" size="sm">
				<LinkIcon className="w-4 h-4" />
			</Button>
		),
	},
	{
		id: 33,
		name: "Financial Literacy Workshops",
		typeRaw: "Workshop",
		type: (
			<Badge variant="secondary">
				<Video className="w-3 h-3 mr-1" />
				Workshop
			</Badge>
		),
		category: "Life Skills",
		description: "Learn budgeting, credit management, and financial planning",
		date: "2025-11-20",
		time: "3:00 PM - 5:00 PM",
		location: "Student Union",
		registration: "Required",
		statusRaw: "Registration Open",
		status: <Badge variant="outline">Registration Open</Badge>,
		action: (
			<Button variant="ghost" size="sm">
				<LinkIcon className="w-4 h-4" />
			</Button>
		),
	},
];
