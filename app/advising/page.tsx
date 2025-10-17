"use client";

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
import { Badge } from "../components/Others/badge";
import { Button } from "../components/Others/button";
import {
	Calendar,
	Clock,
	User,
	MessageSquare,
	CheckCircle,
	AlertCircle,
	BookOpen,
	GraduationCap,
	Mail,
	Phone,
} from "lucide-react";

// Mock data for advising
const upcomingAppointments = [
	{
		id: 1,
		date: "2025-10-15",
		time: "2:00 PM",
		advisor: "Dr. Sarah Johnson",
		type: "Academic Advising",
		location: "Virtual",
		status: "Confirmed",
		notes: "Discuss course selection for Spring 2026",
	},
	{
		id: 2,
		date: "2025-10-22",
		time: "10:00 AM",
		advisor: "Prof. Michael Chen",
		type: "Degree Planning",
		location: "Student Services Building, Room 204",
		status: "Confirmed",
		notes: "Review graduation requirements",
	},
];

const advisorDirectory = [
	{
		id: 1,
		name: "Dr. Sarah Johnson",
		title: "Academic Advisor",
		department: "College of Arts & Sciences",
		email: "sarah.johnson@uwm.edu",
		phone: "(414) 229-1234",
		office: "Student Services Building, Room 201",
		specialties: [
			"General Education",
			"Transfer Students",
			"Academic Planning",
		],
		availability: "Mon-Fri 9AM-5PM",
	},
	{
		id: 2,
		name: "Prof. Michael Chen",
		title: "Degree Advisor",
		department: "College of Engineering",
		email: "michael.chen@uwm.edu",
		phone: "(414) 229-5678",
		office: "Engineering Building, Room 305",
		specialties: ["Computer Science", "Engineering", "Graduation Planning"],
		availability: "Tue-Thu 10AM-4PM",
	},
	{
		id: 3,
		name: "Ms. Jennifer Davis",
		title: "Career Advisor",
		department: "Career Services",
		email: "jennifer.davis@uwm.edu",
		phone: "(414) 229-9012",
		office: "Career Center, Room 101",
		specialties: ["Career Planning", "Internships", "Job Search"],
		availability: "Mon-Fri 8AM-6PM",
	},
];

const degreeProgress = {
	overallProgress: 78,
	totalCredits: 120,
	completedCredits: 94,
	requiredCredits: 45,
	electiveCredits: 30,
	generalEducationCredits: 45,
	majorCredits: 60,
	minorCredits: 21,
	gpa: 3.45,
	expectedGraduation: "Spring 2027",
};

const degreeRequirements = [
	{
		category: "General Education",
		required: 45,
		completed: 42,
		remaining: 3,
		status: "Almost Complete",
	},
	{
		category: "Major Requirements",
		required: 60,
		completed: 48,
		remaining: 12,
		status: "In Progress",
	},
	{
		category: "Electives",
		required: 30,
		completed: 24,
		remaining: 6,
		status: "In Progress",
	},
	{
		category: "Minor Requirements",
		required: 21,
		completed: 18,
		remaining: 3,
		status: "Almost Complete",
	},
];

export default function AdvisingPage() {
	const getStatusColor = (status: string) => {
		switch (status) {
			case "Confirmed":
				return "bg-green-100 text-green-800";
			case "Pending":
				return "bg-yellow-100 text-yellow-800";
			case "Cancelled":
				return "bg-red-100 text-red-800";
			default:
				return "bg-gray-100 text-gray-800";
		}
	};

	const getProgressColor = (progress: number) => {
		if (progress >= 90) return "bg-green-500";
		if (progress >= 70) return "bg-blue-500";
		if (progress >= 50) return "bg-yellow-500";
		return "bg-red-500";
	};

	return (
		<div className="flex-1 space-y-4 p-4 md:p-8 pt-6">
			<div className="flex items-center justify-between space-y-2">
				<h2 className="text-3xl font-bold tracking-tight">Academic Advising</h2>
				<div className="flex items-center space-x-2">
					<Button variant="outline" size="sm">
						<Calendar className="mr-2 h-4 w-4" />
						Schedule Appointment
					</Button>
				</div>
			</div>

			{/* Advising Overview Cards */}
			<div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
				<Card>
					<CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
						<CardTitle className="text-sm font-medium">
							Degree Progress
						</CardTitle>
						<GraduationCap className="h-4 w-4 text-muted-foreground" />
					</CardHeader>
					<CardContent>
						<div className="text-2xl font-bold">
							{degreeProgress.overallProgress}%
						</div>
						<p className="text-xs text-muted-foreground">
							{degreeProgress.completedCredits} of {degreeProgress.totalCredits}{" "}
							credits
						</p>
					</CardContent>
				</Card>

				<Card>
					<CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
						<CardTitle className="text-sm font-medium">Academic GPA</CardTitle>
						<BookOpen className="h-4 w-4 text-muted-foreground" />
					</CardHeader>
					<CardContent>
						<div className="text-2xl font-bold">{degreeProgress.gpa}</div>
						<p className="text-xs text-muted-foreground">Cumulative GPA</p>
					</CardContent>
				</Card>

				<Card>
					<CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
						<CardTitle className="text-sm font-medium">
							Next Appointment
						</CardTitle>
						<Calendar className="h-4 w-4 text-muted-foreground" />
					</CardHeader>
					<CardContent>
						<div className="text-2xl font-bold">Oct 15</div>
						<p className="text-xs text-muted-foreground">
							With Dr. Sarah Johnson
						</p>
					</CardContent>
				</Card>

				<Card>
					<CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
						<CardTitle className="text-sm font-medium">Advisor</CardTitle>
						<User className="h-4 w-4 text-muted-foreground" />
					</CardHeader>
					<CardContent>
						<div className="text-2xl font-bold">Dr. Johnson</div>
						<p className="text-xs text-muted-foreground">Academic Advisor</p>
					</CardContent>
				</Card>
			</div>

			{/* Main Content Tabs */}
			<Tabs defaultValue="appointments" className="space-y-4">
				<TabsList>
					<TabsTrigger value="appointments">Appointments</TabsTrigger>
					<TabsTrigger value="advisors">Advisor Directory</TabsTrigger>
					<TabsTrigger value="degree">Degree Planning</TabsTrigger>
					<TabsTrigger value="messages">Messages</TabsTrigger>
				</TabsList>

				<TabsContent value="appointments" className="space-y-4">
					<Card>
						<CardHeader>
							<CardTitle>Upcoming Appointments</CardTitle>
							<CardDescription>
								Your scheduled advising appointments
							</CardDescription>
						</CardHeader>
						<CardContent>
							<div className="space-y-4">
								{upcomingAppointments.map((appointment, index) => (
									<div
										key={index}
										className="flex items-center justify-between p-4 border rounded-lg"
									>
										<div className="flex items-center space-x-4">
											<div className="flex items-center space-x-2">
												<Calendar className="h-5 w-5 text-blue-600" />
												<div>
													<p className="font-medium">{appointment.date}</p>
													<p className="text-sm text-muted-foreground">
														{appointment.time}
													</p>
												</div>
											</div>
											<div className="border-l pl-4">
												<p className="font-medium">{appointment.advisor}</p>
												<p className="text-sm text-muted-foreground">
													{appointment.type}
												</p>
												<p className="text-sm text-muted-foreground">
													{appointment.location}
												</p>
											</div>
										</div>
										<div className="flex items-center space-x-4">
											<div className="text-right">
												<Badge className={getStatusColor(appointment.status)}>
													{appointment.status}
												</Badge>
												<p className="text-sm text-muted-foreground mt-1">
													{appointment.notes}
												</p>
											</div>
											<Button variant="outline" size="sm">
												<MessageSquare className="h-4 w-4 mr-2" />
												Message
											</Button>
										</div>
									</div>
								))}
							</div>
						</CardContent>
					</Card>
				</TabsContent>

				<TabsContent value="advisors" className="space-y-4">
					<Card>
						<CardHeader>
							<CardTitle>Advisor Directory</CardTitle>
							<CardDescription>
								Find and contact your academic advisors
							</CardDescription>
						</CardHeader>
						<CardContent>
							<div className="space-y-4">
								{advisorDirectory.map((advisor, index) => (
									<div key={index} className="border rounded-lg p-4">
										<div className="flex items-start justify-between">
											<div className="flex-1">
												<div className="flex items-center space-x-3 mb-2">
													<User className="h-8 w-8 text-blue-600" />
													<div>
														<h3 className="font-semibold">{advisor.name}</h3>
														<p className="text-sm text-muted-foreground">
															{advisor.title}
														</p>
														<p className="text-sm text-muted-foreground">
															{advisor.department}
														</p>
													</div>
												</div>
												<div className="grid grid-cols-1 md:grid-cols-2 gap-4 mt-4">
													<div className="space-y-2">
														<div className="flex items-center space-x-2">
															<Mail className="h-4 w-4 text-muted-foreground" />
															<span className="text-sm">{advisor.email}</span>
														</div>
														<div className="flex items-center space-x-2">
															<Phone className="h-4 w-4 text-muted-foreground" />
															<span className="text-sm">{advisor.phone}</span>
														</div>
														<div className="flex items-center space-x-2">
															<Clock className="h-4 w-4 text-muted-foreground" />
															<span className="text-sm">
																{advisor.availability}
															</span>
														</div>
													</div>
													<div>
														<p className="text-sm font-medium mb-1">
															Specialties:
														</p>
														<div className="flex flex-wrap gap-1">
															{advisor.specialties.map((specialty, idx) => (
																<Badge
																	key={idx}
																	variant="secondary"
																	className="text-xs"
																>
																	{specialty}
																</Badge>
															))}
														</div>
													</div>
												</div>
											</div>
											<div className="flex space-x-2">
												<Button variant="outline" size="sm">
													<Mail className="h-4 w-4 mr-2" />
													Email
												</Button>
												<Button variant="outline" size="sm">
													<Calendar className="h-4 w-4 mr-2" />
													Schedule
												</Button>
											</div>
										</div>
									</div>
								))}
							</div>
						</CardContent>
					</Card>
				</TabsContent>

				<TabsContent value="degree" className="space-y-4">
					<div className="grid gap-4 md:grid-cols-2">
						<Card>
							<CardHeader>
								<CardTitle>Degree Progress</CardTitle>
								<CardDescription>
									Your progress toward graduation
								</CardDescription>
							</CardHeader>
							<CardContent>
								<div className="space-y-4">
									<div className="flex items-center justify-between">
										<span className="text-sm font-medium">
											Overall Progress
										</span>
										<span className="text-sm font-bold">
											{degreeProgress.overallProgress}%
										</span>
									</div>
									<div className="w-full bg-gray-200 rounded-full h-2">
										<div
											className={`h-2 rounded-full ${getProgressColor(
												degreeProgress.overallProgress
											)}`}
											style={{
												width: `${degreeProgress.overallProgress}%`,
											}}
										></div>
									</div>
									<div className="grid grid-cols-2 gap-4 text-sm">
										<div>
											<p className="text-muted-foreground">Credits Completed</p>
											<p className="font-semibold">
												{degreeProgress.completedCredits}/
												{degreeProgress.totalCredits}
											</p>
										</div>
										<div>
											<p className="text-muted-foreground">
												Expected Graduation
											</p>
											<p className="font-semibold">
												{degreeProgress.expectedGraduation}
											</p>
										</div>
									</div>
								</div>
							</CardContent>
						</Card>

						<Card>
							<CardHeader>
								<CardTitle>Requirements Breakdown</CardTitle>
								<CardDescription>
									Detailed view of degree requirements
								</CardDescription>
							</CardHeader>
							<CardContent>
								<div className="space-y-4">
									{degreeRequirements.map((req, index) => (
										<div key={index} className="space-y-2">
											<div className="flex items-center justify-between">
												<span className="text-sm font-medium">
													{req.category}
												</span>
												<Badge
													variant={
														req.status === "Almost Complete"
															? "default"
															: "secondary"
													}
												>
													{req.status}
												</Badge>
											</div>
											<div className="flex items-center justify-between text-sm">
												<span>
													{req.completed}/{req.required} credits
												</span>
												<span>{req.remaining} remaining</span>
											</div>
											<div className="w-full bg-gray-200 rounded-full h-1">
												<div
													className="bg-blue-500 h-1 rounded-full"
													style={{
														width: `${(req.completed / req.required) * 100}%`,
													}}
												></div>
											</div>
										</div>
									))}
								</div>
							</CardContent>
						</Card>
					</div>
				</TabsContent>

				<TabsContent value="messages" className="space-y-4">
					<Card>
						<CardHeader>
							<CardTitle>Advisor Messages</CardTitle>
							<CardDescription>
								Communications with your academic advisors
							</CardDescription>
						</CardHeader>
						<CardContent>
							<div className="space-y-4">
								<div className="text-center py-8">
									<MessageSquare className="h-12 w-12 text-muted-foreground mx-auto mb-4" />
									<h3 className="text-lg font-medium mb-2">No Messages Yet</h3>
									<p className="text-muted-foreground mb-4">
										Your advisor communications will appear here.
									</p>
									<Button>
										<MessageSquare className="h-4 w-4 mr-2" />
										Start a Conversation
									</Button>
								</div>
							</div>
						</CardContent>
					</Card>
				</TabsContent>
			</Tabs>
		</div>
	);
}
