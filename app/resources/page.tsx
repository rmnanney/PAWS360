"use client";

// Avoid Next.js prerender-time client-router hook errors (useSearchParams) by
// forcing dynamic rendering for this page.
export const dynamic = 'force-dynamic';

import React from "react";
import {
	Card,
	CardContent,
	CardDescription,
	CardHeader,
	CardTitle,
} from "../components/Card/card";
import {
	Tabs,
	TabsContent,
	TabsList,
	TabsTrigger,
} from "../components/Others/tabs";
import { Button } from "../components/Others/button";
import {
	BookOpen,
	Users,
	Calendar,
	MapPin,
	Search,
	Filter,
} from "lucide-react";
import { PaginatedTable } from "../components/PaginateTable/paginatedTable";
import {
	libraryResources,
	tutoringServices,
	campusServices,
	studySpaces,
	upcomingEvents,
} from "./mockResourcesData";
import {
	libraryColumns,
	tutoringColumns,
	servicesColumns,
	studySpacesColumns,
	eventsColumns,
	libraryFilters,
	tutoringFilters,
	servicesFilters,
	studySpacesFilters,
	eventsFilters,
} from "./column";
import { useSearchParams } from "next/navigation";

export default function ResourcesPage() {
	const searchParams = useSearchParams();
	const tab = searchParams.get("tab") || "libraries";

	return (
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
						<CardTitle className="text-sm font-medium">
							Tutoring Services
						</CardTitle>
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
						<p className="text-xs text-muted-foreground">Locations available</p>
					</CardContent>
				</Card>

				<Card>
					<CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
						<CardTitle className="text-sm font-medium">
							Events This Week
						</CardTitle>
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
			<Tabs defaultValue={tab} className="space-y-4">
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
							<PaginatedTable
								columns={libraryColumns}
								data={libraryResources}
								itemsPerPage={10}
								height="600px"
								searchPlaceholder="Search libraries by name, description, or location..."
								filterOptions={libraryFilters}
							/>
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
							<PaginatedTable
								columns={tutoringColumns}
								data={tutoringServices}
								itemsPerPage={10}
								height="600px"
								searchPlaceholder="Search tutoring services by subject, description, or location..."
								filterOptions={tutoringFilters}
							/>
						</CardContent>
					</Card>
				</TabsContent>

				<TabsContent value="services" className="space-y-4">
					<Card>
						<CardHeader>
							<CardTitle>Campus Services</CardTitle>
							<CardDescription>
								Health, wellness, career, and support services available to
								students
							</CardDescription>
						</CardHeader>
						<CardContent>
							<PaginatedTable
								columns={servicesColumns}
								data={campusServices}
								itemsPerPage={10}
								height="600px"
								searchPlaceholder="Search services by name, category, or description..."
								filterOptions={servicesFilters}
							/>
						</CardContent>
					</Card>
				</TabsContent>

				<TabsContent value="study" className="space-y-4">
					<Card>
						<CardHeader>
							<CardTitle>Study Spaces</CardTitle>
							<CardDescription>
								Find quiet places to study, meet with groups, or work on
								assignments
							</CardDescription>
						</CardHeader>
						<CardContent>
							<PaginatedTable
								columns={studySpacesColumns}
								data={studySpaces}
								itemsPerPage={10}
								height="600px"
								searchPlaceholder="Search study spaces by name, location, or amenities..."
								filterOptions={studySpacesFilters}
							/>
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
							<PaginatedTable
								columns={eventsColumns}
								data={upcomingEvents}
								itemsPerPage={10}
								height="600px"
								searchPlaceholder="Search events by name, category, or description..."
								filterOptions={eventsFilters}
							/>
						</CardContent>
					</Card>
				</TabsContent>
			</Tabs>
		</div>
	);
}
