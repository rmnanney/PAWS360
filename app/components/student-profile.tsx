"use client";

import React, { useState, useEffect } from "react";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "./Card/card";
import {
	User,
	Mail,
	IdCard,
	Building,
	GraduationCap,
	Calendar,
	TrendingUp,
	AlertCircle,
	Edit,
	CheckCircle,
} from "lucide-react";

interface StudentProfile {
	user_id: number;
	firstname: string;
	lastname: string;
	preferred_name?: string;
	email: string;
	campus_id?: string;
	department?: string;
	standing?: string;
	gpa?: number;
	expected_graduation?: string;
	enrollment_status?: string;
}

interface StudentDashboardData {
	current_credits: number;
	total_credits: number;
	courses_enrolled: number;
	outstanding_balance: number;
	financial_aid_status: string;
	next_enrollment_date?: string;
	academic_holds: number;
	recent_grades?: { course: string; grade: string; credits: number }[];
}

interface StudentProfileProps {
	userId?: number;
	showEdit?: boolean;
	compact?: boolean;
}

export function StudentProfileCard({ userId, showEdit = false, compact = false }: StudentProfileProps) {
	const [profile, setProfile] = useState<StudentProfile | null>(null);
	const [dashboardData, setDashboardData] = useState<StudentDashboardData | null>(null);
	const [loading, setLoading] = useState(true);
	const [error, setError] = useState<string | null>(null);

	useEffect(() => {
		fetchStudentProfile();
		if (!compact) {
			fetchDashboardData();
		}
	}, [userId, compact]);

	const fetchStudentProfile = async () => {
		try {
			const endpoint = userId 
				? `http://localhost:8086/api/profile/student/${userId}`
				: "http://localhost:8086/api/profile/student";
			
			const response = await fetch(endpoint, {
				method: "GET",
				credentials: "include",
				headers: {
					"X-Service-Origin": "student-portal",
				},
			});

			if (response.ok) {
				const data = await response.json();
				setProfile(data);
			} else {
				setError(`Failed to load student profile: ${response.status}`);
			}
		} catch (error) {
			console.error("Error fetching student profile:", error);
			setError("Unable to connect to server");
		}
	};

	const fetchDashboardData = async () => {
		try {
			const response = await fetch("http://localhost:8086/api/profile/student/dashboard", {
				method: "GET",
				credentials: "include",
				headers: {
					"X-Service-Origin": "student-portal",
				},
			});

			if (response.ok) {
				const data = await response.json();
				setDashboardData(data);
			}
		} catch (error) {
			console.error("Error fetching dashboard data:", error);
		} finally {
			setLoading(false);
		}
	};

	const getStatusColor = (status?: string) => {
		switch (status?.toLowerCase()) {
			case "active":
			case "enrolled":
				return "bg-green-100 text-green-800 px-2 py-1 rounded text-xs font-medium";
			case "inactive":
			case "withdrawn":
				return "bg-red-100 text-red-800 px-2 py-1 rounded text-xs font-medium";
			case "on hold":
			case "hold":
				return "bg-yellow-100 text-yellow-800 px-2 py-1 rounded text-xs font-medium";
			default:
				return "bg-gray-100 text-gray-800 px-2 py-1 rounded text-xs font-medium";
		}
	};

	const getGPAColor = (gpa?: number) => {
		if (!gpa) return "text-gray-600";
		if (gpa >= 3.5) return "text-green-600";
		if (gpa >= 3.0) return "text-blue-600";
		if (gpa >= 2.5) return "text-yellow-600";
		return "text-red-600";
	};

	const getInitials = (firstname: string, lastname: string) => {
		return `${firstname.charAt(0)}${lastname.charAt(0)}`.toUpperCase();
	};

	if (loading) {
		return (
			<Card className="w-full">
				<CardHeader>
					<div className="flex items-center space-x-4">
						<div className="h-12 w-12 rounded-full bg-gray-200 animate-pulse" />
						<div className="space-y-2">
							<div className="h-4 w-[200px] bg-gray-200 animate-pulse rounded" />
							<div className="h-4 w-[160px] bg-gray-200 animate-pulse rounded" />
						</div>
					</div>
				</CardHeader>
				<CardContent>
					<div className="space-y-3">
						<div className="h-4 w-full bg-gray-200 animate-pulse rounded" />
						<div className="h-4 w-3/4 bg-gray-200 animate-pulse rounded" />
						<div className="h-4 w-1/2 bg-gray-200 animate-pulse rounded" />
					</div>
				</CardContent>
			</Card>
		);
	}

	if (error || !profile) {
		return (
			<Card className="w-full border-red-200 bg-red-50">
				<CardContent className="pt-6">
					<div className="flex items-center space-x-2 text-red-800">
						<AlertCircle className="h-4 w-4" />
						<span className="text-sm">
							{error || "Unable to load student profile"}
						</span>
					</div>
				</CardContent>
			</Card>
		);
	}

	const displayName = profile.preferred_name || `${profile.firstname} ${profile.lastname}`;

	if (compact) {
		return (
			<Card className="w-full">
				<CardHeader className="pb-3">
					<div className="flex items-center justify-between">
						<div className="flex items-center space-x-3">
							<div className="h-10 w-10 rounded-full bg-blue-100 text-blue-600 flex items-center justify-center font-semibold">
								{getInitials(profile.firstname, profile.lastname)}
							</div>
							<div>
								<CardTitle className="text-lg">{displayName}</CardTitle>
								<CardDescription>{profile.email}</CardDescription>
							</div>
						</div>
						{showEdit && (
							<button className="px-3 py-1 text-sm border border-gray-300 rounded hover:bg-gray-50 flex items-center space-x-1">
								<Edit className="h-4 w-4" />
								<span>Edit</span>
							</button>
						)}
					</div>
				</CardHeader>
				<CardContent className="pt-0">
					<div className="grid grid-cols-2 gap-4 text-sm">
						{profile.campus_id && (
							<div className="flex items-center space-x-2">
								<IdCard className="h-4 w-4 text-gray-500" />
								<span>{profile.campus_id}</span>
							</div>
						)}
						{profile.department && (
							<div className="flex items-center space-x-2">
								<Building className="h-4 w-4 text-gray-500" />
								<span>{profile.department}</span>
							</div>
						)}
						{profile.standing && (
							<div className="flex items-center space-x-2">
								<GraduationCap className="h-4 w-4 text-gray-500" />
								<span>{profile.standing}</span>
							</div>
						)}
						{profile.gpa && (
							<div className="flex items-center space-x-2">
								<TrendingUp className="h-4 w-4 text-gray-500" />
								<span className={getGPAColor(profile.gpa)}>
									{profile.gpa.toFixed(2)} GPA
								</span>
							</div>
						)}
					</div>
					{profile.enrollment_status && (
						<div className="mt-3">
							<span className={getStatusColor(profile.enrollment_status)}>
								{profile.enrollment_status}
							</span>
						</div>
					)}
				</CardContent>
			</Card>
		);
	}

	return (
		<div className="space-y-6">
			{/* Main Profile Card */}
			<Card className="w-full">
				<CardHeader>
					<div className="flex items-center justify-between">
						<div className="flex items-center space-x-4">
							<div className="h-16 w-16 rounded-full bg-blue-100 text-blue-600 flex items-center justify-center font-bold text-lg">
								{getInitials(profile.firstname, profile.lastname)}
							</div>
							<div>
								<CardTitle className="text-2xl">{displayName}</CardTitle>
								<CardDescription className="text-base mt-1">
									{profile.email}
								</CardDescription>
								{profile.enrollment_status && (
									<div className="mt-2">
										<span className={getStatusColor(profile.enrollment_status)}>
											{profile.enrollment_status}
										</span>
									</div>
								)}
							</div>
						</div>
						{showEdit && (
							<button className="px-4 py-2 border border-gray-300 rounded hover:bg-gray-50 flex items-center space-x-2">
								<Edit className="h-4 w-4" />
								<span>Edit Profile</span>
							</button>
						)}
					</div>
				</CardHeader>
				<CardContent>
					<div className="grid grid-cols-1 md:grid-cols-2 gap-6">
						<div className="space-y-4">
							<h4 className="font-semibold text-lg">Academic Information</h4>
							
							{profile.campus_id && (
								<div className="flex items-center space-x-3">
									<IdCard className="h-5 w-5 text-gray-500" />
									<div>
										<p className="font-medium">Campus ID</p>
										<p className="text-sm text-gray-600">{profile.campus_id}</p>
									</div>
								</div>
							)}

							{profile.department && (
								<div className="flex items-center space-x-3">
									<Building className="h-5 w-5 text-gray-500" />
									<div>
										<p className="font-medium">Department</p>
										<p className="text-sm text-gray-600">{profile.department}</p>
									</div>
								</div>
							)}

							{profile.standing && (
								<div className="flex items-center space-x-3">
									<GraduationCap className="h-5 w-5 text-gray-500" />
									<div>
										<p className="font-medium">Academic Standing</p>
										<p className="text-sm text-gray-600">{profile.standing}</p>
									</div>
								</div>
							)}

							{profile.expected_graduation && (
								<div className="flex items-center space-x-3">
									<Calendar className="h-5 w-5 text-gray-500" />
									<div>
										<p className="font-medium">Expected Graduation</p>
										<p className="text-sm text-gray-600">{profile.expected_graduation}</p>
									</div>
								</div>
							)}
						</div>

						<div className="space-y-4">
							<h4 className="font-semibold text-lg">Academic Performance</h4>
							
							{profile.gpa && (
								<div className="flex items-center space-x-3">
									<TrendingUp className="h-5 w-5 text-gray-500" />
									<div>
										<p className="font-medium">Cumulative GPA</p>
										<p className={`text-sm font-semibold ${getGPAColor(profile.gpa)}`}>
											{profile.gpa.toFixed(2)}
										</p>
									</div>
								</div>
							)}

							{dashboardData && (
								<>
									<div className="flex items-center space-x-3">
										<CheckCircle className="h-5 w-5 text-gray-500" />
										<div>
											<p className="font-medium">Credits Completed</p>
											<p className="text-sm text-gray-600">
												{dashboardData.total_credits} total credits
											</p>
										</div>
									</div>

									<div className="flex items-center space-x-3">
										<User className="h-5 w-5 text-gray-500" />
										<div>
											<p className="font-medium">Current Enrollment</p>
											<p className="text-sm text-gray-600">
												{dashboardData.courses_enrolled} courses, {dashboardData.current_credits} credits
											</p>
										</div>
									</div>
								</>
							)}
						</div>
					</div>
				</CardContent>
			</Card>

			{/* Dashboard Data Card */}
			{dashboardData && (
				<Card>
					<CardHeader>
						<CardTitle>Current Semester Overview</CardTitle>
					</CardHeader>
					<CardContent>
						<div className="grid grid-cols-1 md:grid-cols-3 gap-6">
							<div className="text-center">
								<div className="text-2xl font-bold text-blue-600">
									{dashboardData.courses_enrolled}
								</div>
								<div className="text-sm text-gray-600">Courses Enrolled</div>
							</div>
							<div className="text-center">
								<div className="text-2xl font-bold text-green-600">
									{dashboardData.current_credits}
								</div>
								<div className="text-sm text-gray-600">Current Credits</div>
							</div>
							<div className="text-center">
								<div className={`text-2xl font-bold ${dashboardData.academic_holds > 0 ? 'text-red-600' : 'text-green-600'}`}>
									{dashboardData.academic_holds}
								</div>
								<div className="text-sm text-gray-600">Academic Holds</div>
							</div>
						</div>

						{dashboardData.next_enrollment_date && (
							<>
								<div className="border-t border-gray-200 my-4"></div>
								<div className="text-center">
									<p className="font-medium">Next Enrollment Date</p>
									<p className="text-sm text-gray-600">{dashboardData.next_enrollment_date}</p>
								</div>
							</>
						)}

						{dashboardData.recent_grades && dashboardData.recent_grades.length > 0 && (
							<>
								<div className="border-t border-gray-200 my-4"></div>
								<div>
									<h4 className="font-medium mb-3">Recent Grades</h4>
									<div className="space-y-2">
										{dashboardData.recent_grades.map((grade, index) => (
											<div key={index} className="flex justify-between items-center py-2 px-3 bg-gray-50 rounded">
												<span className="font-medium">{grade.course}</span>
												<div className="text-right">
													<span className="font-semibold">{grade.grade}</span>
													<span className="text-sm text-gray-600 ml-2">({grade.credits} credits)</span>
												</div>
											</div>
										))}
									</div>
								</div>
							</>
						)}
					</CardContent>
				</Card>
			)}
		</div>
	);
}

export function StudentProfileSummary({ userId }: { userId?: number }) {
	return <StudentProfileCard userId={userId} compact={true} />;
}

export function StudentProfileFull({ userId, showEdit = true }: { userId?: number; showEdit?: boolean }) {
	return <StudentProfileCard userId={userId} showEdit={showEdit} compact={false} />;
}