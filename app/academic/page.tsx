"use client";

import React from "react";
import { useRouter } from "next/navigation";
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
import { Progress } from "../components/Others/progress";
import {
	GraduationCap,
	Download,
	TrendingUp,
	TrendingDown,
	BookOpen,
	Calendar,
	Award,
	AlertTriangle,
	CheckCircle,
	Clock,
} from "lucide-react";

// Mock data for demonstration
const currentGrades = [
	{
		course: "CS 351 - Data Structures",
		grade: "A-",
		credits: 3,
		percentage: 92,
		status: "In Progress",
		lastUpdated: "2025-10-08",
	},
	{
		course: "MATH 231 - Calculus II",
		grade: "B+",
		credits: 4,
		percentage: 88,
		status: "In Progress",
		lastUpdated: "2025-10-08",
	},
	{
		course: "ENGL 102 - Composition II",
		grade: "A",
		credits: 3,
		percentage: 96,
		status: "In Progress",
		lastUpdated: "2025-10-07",
	},
];

const transcriptData = [
	{
		term: "Fall 2025",
		courses: [
			{ course: "CS 351", title: "Data Structures", grade: "A-", credits: 3 },
			{ course: "MATH 231", title: "Calculus II", grade: "B+", credits: 4 },
			{ course: "ENGL 102", title: "Composition II", grade: "A", credits: 3 },
		],
		gpa: 3.67,
		credits: 10,
	},
	{
		term: "Spring 2025",
		courses: [
			{
				course: "CS 250",
				title: "Intro to Computer Science",
				grade: "A",
				credits: 3,
			},
			{ course: "MATH 230", title: "Calculus I", grade: "B", credits: 4 },
			{ course: "HIST 101", title: "World History", grade: "A-", credits: 3 },
		],
		gpa: 3.78,
		credits: 10,
	},
	{
		term: "Fall 2024",
		courses: [
			{
				course: "CS 150",
				title: "Programming Fundamentals",
				grade: "A",
				credits: 3,
			},
			{
				course: "MATH 208",
				title: "Discrete Mathematics",
				grade: "B+",
				credits: 4,
			},
			{ course: "COMM 101", title: "Public Speaking", grade: "A", credits: 3 },
		],
		gpa: 3.83,
		credits: 10,
	},
];

const academicStats = {
	cumulativeGPA: 3.76,
	totalCredits: 30,
	semestersCompleted: 3,
	academicStanding: "Good Standing",
	graduationProgress: 45, // percentage
	expectedGraduation: "Spring 2027",
};

export default function Academic() {
	const getGradeColor = (grade: string) => {
		if (grade.startsWith("A")) return "bg-green-100 text-green-800";
		if (grade.startsWith("B")) return "bg-blue-100 text-blue-800";
		if (grade.startsWith("C")) return "bg-yellow-100 text-yellow-800";
		if (grade.startsWith("D")) return "bg-orange-100 text-orange-800";
		return "bg-red-100 text-red-800";
	};

	const getStatusIcon = (status: string) => {
		switch (status) {
			case "Completed":
				return <CheckCircle className="h-4 w-4 text-green-600" />;
			case "In Progress":
				return <Clock className="h-4 w-4 text-blue-600" />;
			default:
				return <AlertTriangle className="h-4 w-4 text-yellow-600" />;
		}
	};

	return (
		<div className="flex-1 space-y-4 p-4 md:p-8 pt-6">
			<div className="flex items-center justify-between space-y-2">
				<h2 className="text-3xl font-bold tracking-tight">Academic Records</h2>
				<div className="flex items-center space-x-2">
					<Button variant="outline" size="sm">
						<Download className="mr-2 h-4 w-4" />
						Download Transcript
					</Button>
				</div>
			</div>

			{/* Academic Overview Cards */}
			<div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
				<Card>
					<CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
						<CardTitle className="text-sm font-medium">
							Cumulative GPA
						</CardTitle>
						<GraduationCap className="h-4 w-4 text-muted-foreground" />
					</CardHeader>
					<CardContent>
						<div className="text-2xl font-bold">
							{academicStats.cumulativeGPA}
						</div>
						<p className="text-xs text-muted-foreground">
							{academicStats.totalCredits} credits completed
						</p>
					</CardContent>
				</Card>

				<Card>
					<CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
						<CardTitle className="text-sm font-medium">
							Academic Standing
						</CardTitle>
						<Award className="h-4 w-4 text-muted-foreground" />
					</CardHeader>
					<CardContent>
						<div className="text-2xl font-bold text-green-600">
							Good Standing
						</div>
						<p className="text-xs text-muted-foreground">
							{academicStats.semestersCompleted} semesters completed
						</p>
					</CardContent>
				</Card>

				<Card>
					<CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
						<CardTitle className="text-sm font-medium">
							Graduation Progress
						</CardTitle>
						<BookOpen className="h-4 w-4 text-muted-foreground" />
					</CardHeader>
					<CardContent>
						<div className="text-2xl font-bold">
							{academicStats.graduationProgress}%
						</div>
						<Progress
							value={academicStats.graduationProgress}
							className="mt-2"
						/>
						<p className="text-xs text-muted-foreground mt-1">
							Expected: {academicStats.expectedGraduation}
						</p>
					</CardContent>
				</Card>

				<Card>
					<CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
						<CardTitle className="text-sm font-medium">
							Current Semester
						</CardTitle>
						<Calendar className="h-4 w-4 text-muted-foreground" />
					</CardHeader>
					<CardContent>
						<div className="text-2xl font-bold">3.67</div>
						<p className="text-xs text-muted-foreground">Fall 2025 GPA</p>
					</CardContent>
				</Card>
			</div>

			{/* Main Content Tabs */}
			<Tabs defaultValue="current" className="space-y-4">
				<TabsList>
					<TabsTrigger value="current">Current Grades</TabsTrigger>
					<TabsTrigger value="transcript">Transcript</TabsTrigger>
					<TabsTrigger value="gpa">GPA History</TabsTrigger>
				</TabsList>

				<TabsContent value="current" className="space-y-4">
					<Card>
						<CardHeader>
							<CardTitle>Fall 2025 Grades</CardTitle>
							<CardDescription>
								Your current semester grades and progress
							</CardDescription>
						</CardHeader>
						<CardContent>
							<div className="space-y-4">
								{currentGrades.map((course, index) => (
									<div
										key={index}
										className="flex items-center justify-between p-4 border rounded-lg"
									>
										<div className="flex items-center space-x-4">
											{getStatusIcon(course.status)}
											<div>
												<p className="font-medium">{course.course}</p>
												<p className="text-sm text-muted-foreground">
													{course.credits} credits • Last updated:{" "}
													{course.lastUpdated}
												</p>
											</div>
										</div>
										<div className="flex items-center space-x-4">
											<div className="text-right">
												<Badge className={getGradeColor(course.grade)}>
													{course.grade}
												</Badge>
												<p className="text-sm text-muted-foreground mt-1">
													{course.percentage}%
												</p>
											</div>
											<Badge variant="outline">{course.status}</Badge>
										</div>
									</div>
								))}
							</div>
						</CardContent>
					</Card>
				</TabsContent>

				<TabsContent value="transcript" className="space-y-4">
					<Card>
						<CardHeader>
							<CardTitle>Academic Transcript</CardTitle>
							<CardDescription>
								Complete record of your academic history
							</CardDescription>
						</CardHeader>
						<CardContent>
							<div className="space-y-6">
								{transcriptData.map((term, termIndex) => (
									<div key={termIndex} className="border rounded-lg p-4">
										<div className="flex items-center justify-between mb-4">
											<h3 className="text-lg font-semibold">{term.term}</h3>
											<div className="text-right">
												<p className="font-medium">GPA: {term.gpa}</p>
												<p className="text-sm text-muted-foreground">
													{term.credits} credits
												</p>
											</div>
										</div>
										<div className="space-y-2">
											{term.courses.map((course, courseIndex) => (
												<div
													key={courseIndex}
													className="flex items-center justify-between py-2 border-b last:border-b-0"
												>
													<div>
														<p className="font-medium">
															{course.course}: {course.title}
														</p>
													</div>
													<div className="flex items-center space-x-4">
														<Badge className={getGradeColor(course.grade)}>
															{course.grade}
														</Badge>
														<span className="text-sm text-muted-foreground">
															{course.credits} credits
														</span>
													</div>
												</div>
											))}
										</div>
									</div>
								))}
							</div>
						</CardContent>
					</Card>
				</TabsContent>

				<TabsContent value="gpa" className="space-y-4">
					<Card>
						<CardHeader>
							<CardTitle>GPA History</CardTitle>
							<CardDescription>
								Track your academic performance over time
							</CardDescription>
						</CardHeader>
						<CardContent>
							<div className="space-y-4">
								{transcriptData.map((term, index) => (
									<div
										key={index}
										className="flex items-center justify-between p-4 border rounded-lg"
									>
										<div>
											<p className="font-medium">{term.term}</p>
											<p className="text-sm text-muted-foreground">
												{term.credits} credits
											</p>
										</div>
										<div className="flex items-center space-x-4">
											<div className="text-right">
												<p className="text-2xl font-bold">{term.gpa}</p>
												{index > 0 && (
													<div className="flex items-center text-sm">
														{term.gpa > transcriptData[index - 1].gpa ? (
															<>
																<TrendingUp className="h-4 w-4 text-green-600 mr-1" />
																<span className="text-green-600">
																	+
																	{(
																		term.gpa - transcriptData[index - 1].gpa
																	).toFixed(2)}
																</span>
															</>
														) : term.gpa < transcriptData[index - 1].gpa ? (
															<>
																<TrendingDown className="h-4 w-4 text-red-600 mr-1" />
																<span className="text-red-600">
																	{(
																		term.gpa - transcriptData[index - 1].gpa
																	).toFixed(2)}
																</span>
															</>
														) : (
															<span className="text-muted-foreground">
																No change
															</span>
														)}
													</div>
												)}
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
	);
}
