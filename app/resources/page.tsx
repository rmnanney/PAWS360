"use client";

import React from "react";
import { useRouter } from "next/navigation";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "../components/Card/card";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "../components/Others/tabs";
import { Badge } from "../components/Others/badge";
import { Button } from "../components/Others/button";
import { BookOpen, Users, Calendar, MapPin, Clock, Star, Search, Filter, ExternalLink, Phone, Mail } from "lucide-react";
import { SidebarInset, SidebarProvider } from "../components/SideBar/Base/sidebarbase";
import { AppSidebar } from "../components/SideBar/sidebar";
import { Header } from "../components/Header/header";

// Mock data for resources
const libraryResources = [
	{
		id: 1,
		title: "Golda Meir Library",
		type: "Library",
		description: "Main university library with extensive collections",
		location: "Golda Meir Library Building",
		hours: "24/7 during semester",
		services: ["Books", "Journals", "Study Rooms", "Computers", "Research Help"],
		rating: 4.5,
		popular: true
	},
	{
		id: 2,
		title: "Curtin Library",
		type: "Library",
		description: "Specialized business and economics library",
		location: "Lubar Hall",
		hours: "Mon-Fri 8AM-10PM",
		services: ["Business Databases", "Study Spaces", "Group Rooms"],
		rating: 4.2,
		popular: false
	}
];

const tutoringServices = [
	{
		id: 1,
		subject: "Mathematics",
		type: "Tutoring",
		description: "One-on-one and group tutoring for all math courses",
		location: "Multiple locations",
		schedule: "Mon-Fri 9AM-9PM, Sat 10AM-4PM",
		contact: "(414) 229-1234",
		availability: "Drop-in and appointment",
		rating: 4.7
	},
	{
		id: 2,
		subject: "Writing Center",
		type: "Tutoring",
		description: "Help with writing, research papers, and academic writing",
		location: "English Building, Room 234",
		schedule: "Mon-Thu 9AM-8PM, Fri 9AM-4PM",
		contact: "(414) 229-5678",
		availability: "Appointment required",
		rating: 4.8
	},
	{
		id: 3,
		subject: "Computer Science",
		type: "Tutoring",
		description: "Programming help and computer science concepts",
		location: "EMS Building, Room 180",
		schedule: "Mon-Fri 10AM-6PM",
		contact: "(414) 229-9012",
		availability: "Drop-in available",
		rating: 4.6
	}
];

const campusServices = [
	{
		id: 1,
		name: "Counseling Center",
		category: "Health & Wellness",
		description: "Mental health support and counseling services",
		location: "Student Services Building",
		phone: "(414) 229-1122",
		email: "counseling@uwm.edu",
		hours: "Mon-Fri 8AM-5PM",
		emergency: "24/7 Crisis Line: (414) 229-HELP",
		confidential: true
	},
	{
		id: 2,
		name: "Health Services",
		category: "Health & Wellness",
		description: "Medical care, immunizations, and health consultations",
		location: "Engelmann Hall",
		phone: "(414) 229-2233",
		email: "health@uwm.edu",
		hours: "Mon-Fri 8AM-4:30PM",
		emergency: "After hours: Urgent Care",
		confidential: true
	},
	{
		id: 3,
		name: "Career Services",
		category: "Career Support",
		description: "Resume help, job search assistance, and career counseling",
		location: "Career Center",
		phone: "(414) 229-3344",
		email: "career@uwm.edu",
		hours: "Mon-Fri 8AM-5PM",
		emergency: null,
		confidential: false
	},
	{
		id: 4,
		name: "Disability Services",
		category: "Accessibility",
		description: "Support services for students with disabilities",
		location: "Student Services Building, Room 200",
		phone: "(414) 229-4455",
		email: "disability@uwm.edu",
		hours: "Mon-Fri 8AM-5PM",
		emergency: null,
		confidential: true
	}
];

const studySpaces = [
	{
		id: 1,
		name: "Library Study Rooms",
		type: "Study Space",
		description: "Private study rooms for individual or group work",
		location: "Golda Meir Library",
		capacity: "2-8 people",
		amenities: ["Whiteboard", "Power outlets", "WiFi"],
		booking: "Library website or app",
		availability: "24/7 during semester"
	},
	{
		id: 2,
		name: "Student Commons",
		type: "Study Space",
		description: "Open study areas with computers and printing",
		location: "Student Union",
		capacity: "Individual study",
		amenities: ["Computers", "Printers", "Coffee shop"],
		booking: "First come, first served",
		availability: "Mon-Sun 6AM-2AM"
	},
	{
		id: 3,
		name: "Quiet Study Area",
		type: "Study Space",
		description: "Silent study environment for focused work",
		location: "English Building, 3rd Floor",
		capacity: "Individual study",
		amenities: ["Individual desks", "Natural light"],
		booking: "No reservation needed",
		availability: "Mon-Fri 7AM-10PM"
	}
];

const upcomingEvents = [
	{
		id: 1,
		title: "Resume Workshop",
		date: "2025-10-18",
		time: "2:00 PM - 4:00 PM",
		location: "Career Center",
		description: "Learn how to create an effective resume for job applications",
		category: "Career",
		registration: "Required"
	},
	{
		id: 2,
		title: "Mental Health Awareness Week",
		date: "2025-10-20",
		time: "All day",
		location: "Campus-wide",
		description: "Various events and resources for mental health awareness",
		category: "Wellness",
		registration: "Optional"
	},
	{
		id: 3,
		title: "Study Skills Seminar",
		date: "2025-10-22",
		time: "11:00 AM - 12:30 PM",
		location: "Library Conference Room A",
		description: "Improve your study techniques and time management skills",
		category: "Academic",
		registration: "Required"
	}
];

export default function ResourcesPage() {
	const router = useRouter();

	React.useEffect(() => {
		if (typeof window !== "undefined") {
			const loggedIn = localStorage.getItem("loggedIn");
			if (!loggedIn) {
				localStorage.setItem("showAuthToast", "true");
				router.push("/login");
			}
		}
	}, [router]);

	const handleNavigation = (section: string) => {
		console.log(`Navigating to ${section}`);
	};

	const getCategoryColor = (category: string) => {
		switch (category) {
			case 'Health & Wellness':
				return 'bg-green-100 text-green-800';
			case 'Career Support':
				return 'bg-blue-100 text-blue-800';
			case 'Accessibility':
				return 'bg-purple-100 text-purple-800';
			case 'Academic':
				return 'bg-orange-100 text-orange-800';
			case 'Wellness':
				return 'bg-pink-100 text-pink-800';
			case 'Career':
				return 'bg-indigo-100 text-indigo-800';
			default:
				return 'bg-gray-100 text-gray-800';
		}
	};

	const getRatingStars = (rating: number) => {
		return Array.from({ length: 5 }, (_, i) => (
			<Star
				key={i}
				className={`h-4 w-4 ${i < Math.floor(rating) ? 'text-yellow-400 fill-current' : 'text-gray-300'}`}
			/>
		));
	};

	return (
		<SidebarProvider>
			<Header />
			<SidebarInset>
				<div className="flex-1 space-y-4 p-4 md:p-8 pt-6">
					<div className="flex items-center justify-between space-y-2">
						<h2 className="text-3xl font-bold tracking-tight">Campus Resources</h2>
						<div className="flex items-center space-x-2">
							<Button variant="outline" size="sm">
								<Search className="mr-2 h-4 w-4" />
								Search Resources
							</Button>
							<Button variant="outline" size="sm">
								<Filter className="mr-2 h-4 w-4" />
								Filter
							</Button>
						</div>
					</div>

					{/* Resources Overview Cards */}
					<div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
						<Card>
							<CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
								<CardTitle className="text-sm font-medium">Libraries</CardTitle>
								<BookOpen className="h-4 w-4 text-muted-foreground" />
							</CardHeader>
							<CardContent>
								<div className="text-2xl font-bold">2</div>
								<p className="text-xs text-muted-foreground">
									Campus libraries available
								</p>
							</CardContent>
						</Card>

						<Card>
							<CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
								<CardTitle className="text-sm font-medium">Tutoring Services</CardTitle>
								<Users className="h-4 w-4 text-muted-foreground" />
							</CardHeader>
							<CardContent>
								<div className="text-2xl font-bold">15+</div>
								<p className="text-xs text-muted-foreground">
									Subjects and services
								</p>
							</CardContent>
						</Card>

						<Card>
							<CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
								<CardTitle className="text-sm font-medium">Study Spaces</CardTitle>
								<MapPin className="h-4 w-4 text-muted-foreground" />
							</CardHeader>
							<CardContent>
								<div className="text-2xl font-bold">25+</div>
								<p className="text-xs text-muted-foreground">
									Locations available
								</p>
							</CardContent>
						</Card>

						<Card>
							<CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
								<CardTitle className="text-sm font-medium">Events This Week</CardTitle>
								<Calendar className="h-4 w-4 text-muted-foreground" />
							</CardHeader>
							<CardContent>
								<div className="text-2xl font-bold">8</div>
								<p className="text-xs text-muted-foreground">
									Workshops and events
								</p>
							</CardContent>
						</Card>
					</div>

					{/* Main Content Tabs */}
					<Tabs defaultValue="libraries" className="space-y-4">
						<TabsList>
							<TabsTrigger value="libraries">Libraries</TabsTrigger>
							<TabsTrigger value="tutoring">Tutoring</TabsTrigger>
							<TabsTrigger value="services">Campus Services</TabsTrigger>
							<TabsTrigger value="study">Study Spaces</TabsTrigger>
							<TabsTrigger value="events">Events</TabsTrigger>
						</TabsList>

						<TabsContent value="libraries" className="space-y-4">
							<Card>
								<CardHeader>
									<CardTitle>Library Resources</CardTitle>
									<CardDescription>
										Access books, journals, study spaces, and research help
									</CardDescription>
								</CardHeader>
								<CardContent>
									<div className="space-y-6">
										{libraryResources.map((library, index) => (
											<div key={index} className="border rounded-lg p-4">
												<div className="flex items-start justify-between mb-4">
													<div className="flex-1">
														<div className="flex items-center space-x-3 mb-2">
															<BookOpen className="h-6 w-6 text-blue-600" />
															<div>
																<h3 className="font-semibold flex items-center">
																	{library.title}
																	{library.popular && (
																		<Badge className="ml-2 bg-yellow-100 text-yellow-800">Popular</Badge>
																	)}
																</h3>
																<p className="text-sm text-muted-foreground">{library.type}</p>
															</div>
														</div>
														<p className="text-sm mb-3">{library.description}</p>
														<div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
															<div className="space-y-2">
																<div className="flex items-center space-x-2">
																	<MapPin className="h-4 w-4 text-muted-foreground" />
																	<span>{library.location}</span>
																</div>
																<div className="flex items-center space-x-2">
																	<Clock className="h-4 w-4 text-muted-foreground" />
																	<span>{library.hours}</span>
																</div>
															</div>
															<div>
																<p className="font-medium mb-1">Services:</p>
																<div className="flex flex-wrap gap-1">
																	{library.services.slice(0, 3).map((service, idx) => (
																		<Badge key={idx} variant="secondary" className="text-xs">
																			{service}
																		</Badge>
																	))}
																</div>
															</div>
														</div>
														<div className="flex items-center space-x-2 mt-3">
															<div className="flex items-center">
																{getRatingStars(library.rating)}
																<span className="text-sm ml-1">({library.rating})</span>
															</div>
														</div>
													</div>
													<div className="flex space-x-2">
														<Button variant="outline" size="sm">
															<MapPin className="h-4 w-4 mr-2" />
															Directions
														</Button>
														<Button variant="outline" size="sm">
															<ExternalLink className="h-4 w-4 mr-2" />
															Website
														</Button>
													</div>
												</div>
											</div>
										))}
									</div>
								</CardContent>
							</Card>
						</TabsContent>

						<TabsContent value="tutoring" className="space-y-4">
							<Card>
								<CardHeader>
									<CardTitle>Tutoring Services</CardTitle>
									<CardDescription>
										Get help with coursework, writing, and academic skills
									</CardDescription>
								</CardHeader>
								<CardContent>
									<div className="space-y-6">
										{tutoringServices.map((service, index) => (
											<div key={index} className="border rounded-lg p-4">
												<div className="flex items-start justify-between">
													<div className="flex-1">
														<div className="flex items-center space-x-3 mb-2">
															<Users className="h-6 w-6 text-green-600" />
															<div>
																<h3 className="font-semibold">{service.subject}</h3>
																<p className="text-sm text-muted-foreground">{service.type}</p>
															</div>
														</div>
														<p className="text-sm mb-3">{service.description}</p>
														<div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
															<div className="space-y-2">
																<div className="flex items-center space-x-2">
																	<MapPin className="h-4 w-4 text-muted-foreground" />
																	<span>{service.location}</span>
																</div>
																<div className="flex items-center space-x-2">
																	<Clock className="h-4 w-4 text-muted-foreground" />
																	<span>{service.schedule}</span>
																</div>
																<div className="flex items-center space-x-2">
																	<Phone className="h-4 w-4 text-muted-foreground" />
																	<span>{service.contact}</span>
																</div>
															</div>
															<div>
																<p className="font-medium mb-1">Availability:</p>
																<p className="text-sm">{service.availability}</p>
																<div className="flex items-center mt-2">
																	<div className="flex items-center mr-2">
																		{getRatingStars(service.rating)}
																	</div>
																	<span className="text-sm">({service.rating})</span>
																</div>
															</div>
														</div>
													</div>
													<div className="flex space-x-2">
														<Button variant="outline" size="sm">
															<Calendar className="h-4 w-4 mr-2" />
															Schedule
														</Button>
														<Button variant="outline" size="sm">
															<Phone className="h-4 w-4 mr-2" />
															Call
														</Button>
													</div>
												</div>
											</div>
										))}
									</div>
								</CardContent>
							</Card>
						</TabsContent>

						<TabsContent value="services" className="space-y-4">
							<Card>
								<CardHeader>
									<CardTitle>Campus Services</CardTitle>
									<CardDescription>
										Health, wellness, career, and support services available to students
									</CardDescription>
								</CardHeader>
								<CardContent>
									<div className="space-y-6">
										{campusServices.map((service, index) => (
											<div key={index} className="border rounded-lg p-4">
												<div className="flex items-start justify-between">
													<div className="flex-1">
														<div className="flex items-center space-x-3 mb-2">
															<div className={`w-3 h-3 rounded-full ${
																service.category === 'Health & Wellness' ? 'bg-green-500' :
																service.category === 'Career Support' ? 'bg-blue-500' :
																service.category === 'Accessibility' ? 'bg-purple-500' : 'bg-gray-500'
															}`}></div>
															<div>
																<h3 className="font-semibold">{service.name}</h3>
																<Badge className={getCategoryColor(service.category)}>
																	{service.category}
																</Badge>
															</div>
														</div>
														<p className="text-sm mb-3">{service.description}</p>
														<div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
															<div className="space-y-2">
																<div className="flex items-center space-x-2">
																	<MapPin className="h-4 w-4 text-muted-foreground" />
																	<span>{service.location}</span>
																</div>
																<div className="flex items-center space-x-2">
																	<Clock className="h-4 w-4 text-muted-foreground" />
																	<span>{service.hours}</span>
																</div>
																{service.confidential && (
																	<div className="flex items-center space-x-2">
																		<Badge variant="secondary" className="text-xs">Confidential</Badge>
																	</div>
																)}
															</div>
															<div className="space-y-2">
																<div className="flex items-center space-x-2">
																	<Phone className="h-4 w-4 text-muted-foreground" />
																	<span>{service.phone}</span>
																</div>
																<div className="flex items-center space-x-2">
																	<Mail className="h-4 w-4 text-muted-foreground" />
																	<span>{service.email}</span>
																</div>
																{service.emergency && (
																	<div className="mt-2 p-2 bg-red-50 border border-red-200 rounded">
																		<p className="text-xs text-red-800 font-medium">Emergency: {service.emergency}</p>
																	</div>
																)}
															</div>
														</div>
													</div>
													<div className="flex space-x-2">
														<Button variant="outline" size="sm">
															<Phone className="h-4 w-4 mr-2" />
															Call
														</Button>
														<Button variant="outline" size="sm">
															<Mail className="h-4 w-4 mr-2" />
															Email
														</Button>
													</div>
												</div>
											</div>
										))}
									</div>
								</CardContent>
							</Card>
						</TabsContent>

						<TabsContent value="study" className="space-y-4">
							<Card>
								<CardHeader>
									<CardTitle>Study Spaces</CardTitle>
									<CardDescription>
										Find quiet places to study, meet with groups, or work on assignments
									</CardDescription>
								</CardHeader>
								<CardContent>
									<div className="space-y-6">
										{studySpaces.map((space, index) => (
											<div key={index} className="border rounded-lg p-4">
												<div className="flex items-start justify-between">
													<div className="flex-1">
														<div className="flex items-center space-x-3 mb-2">
															<MapPin className="h-6 w-6 text-orange-600" />
															<div>
																<h3 className="font-semibold">{space.name}</h3>
																<p className="text-sm text-muted-foreground">{space.type}</p>
															</div>
														</div>
														<p className="text-sm mb-3">{space.description}</p>
														<div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
															<div className="space-y-2">
																<div className="flex items-center space-x-2">
																	<MapPin className="h-4 w-4 text-muted-foreground" />
																	<span>{space.location}</span>
																</div>
																<div className="flex items-center space-x-2">
																	<Users className="h-4 w-4 text-muted-foreground" />
																	<span>{space.capacity}</span>
																</div>
																<div className="flex items-center space-x-2">
																	<Clock className="h-4 w-4 text-muted-foreground" />
																	<span>{space.availability}</span>
																</div>
															</div>
															<div>
																<p className="font-medium mb-1">Amenities:</p>
																<div className="flex flex-wrap gap-1">
																	{space.amenities.map((amenity, idx) => (
																		<Badge key={idx} variant="secondary" className="text-xs">
																			{amenity}
																		</Badge>
																	))}
																</div>
																<p className="text-sm mt-2">
																	<span className="font-medium">Booking:</span> {space.booking}
																</p>
															</div>
														</div>
													</div>
													<div className="flex space-x-2">
														<Button variant="outline" size="sm">
															<MapPin className="h-4 w-4 mr-2" />
															Directions
														</Button>
														<Button variant="outline" size="sm">
															<Calendar className="h-4 w-4 mr-2" />
															Reserve
														</Button>
													</div>
												</div>
											</div>
										))}
									</div>
								</CardContent>
							</Card>
						</TabsContent>

						<TabsContent value="events" className="space-y-4">
							<Card>
								<CardHeader>
									<CardTitle>Upcoming Events</CardTitle>
									<CardDescription>
										Workshops, seminars, and events to support your academic success
									</CardDescription>
								</CardHeader>
								<CardContent>
									<div className="space-y-4">
										{upcomingEvents.map((event, index) => (
											<div key={index} className="border rounded-lg p-4">
												<div className="flex items-start justify-between">
													<div className="flex-1">
														<div className="flex items-center space-x-3 mb-2">
															<Calendar className="h-6 w-6 text-purple-600" />
															<div>
																<h3 className="font-semibold">{event.title}</h3>
																<Badge className={getCategoryColor(event.category)}>
																	{event.category}
																</Badge>
															</div>
														</div>
														<p className="text-sm mb-3">{event.description}</p>
														<div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
															<div className="space-y-2">
																<div className="flex items-center space-x-2">
																	<Calendar className="h-4 w-4 text-muted-foreground" />
																	<span>{event.date}</span>
																</div>
																<div className="flex items-center space-x-2">
																	<Clock className="h-4 w-4 text-muted-foreground" />
																	<span>{event.time}</span>
																</div>
																<div className="flex items-center space-x-2">
																	<MapPin className="h-4 w-4 text-muted-foreground" />
																	<span>{event.location}</span>
																</div>
															</div>
															<div>
																<p className="font-medium mb-1">Registration:</p>
																<Badge variant={event.registration === 'Required' ? 'default' : 'secondary'}>
																	{event.registration}
																</Badge>
															</div>
														</div>
													</div>
													<div className="flex space-x-2">
														<Button variant="outline" size="sm">
															<Calendar className="h-4 w-4 mr-2" />
															Add to Calendar
														</Button>
														<Button size="sm">
															Register
														</Button>
													</div>
												</div>
											</div>
										))}
									</div>
								</CardContent>
							</Card>
						</TabsContent>
					</Tabs>
				</div>
			</SidebarInset>
			<AppSidebar onNavigate={handleNavigation} />
		</SidebarProvider>
	);
}