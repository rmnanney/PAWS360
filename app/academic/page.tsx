"use client";

import React from "react";
import { Spinner } from "../components/Others/spinner";
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

type CurrentGrade = {
    course: string;
    grade: string;
    credits: number;
    percentage: number | null;
    status: string;
    lastUpdated: string | null;
};

type TranscriptCourse = {
    course: string;
    title: string;
    grade: string;
    credits: number;
};

type TranscriptTerm = {
    term: string;
    courses: TranscriptCourse[];
    gpa: number;
    credits: number;
};

type AcademicStats = {
    cumulativeGPA: number;
    totalCredits: number;
    semestersCompleted: number;
    academicStanding: string;
    graduationProgress: number;
    expectedGraduation: string;
    currentTermGPA?: number;
    currentTermLabel?: string;
};

const { API_BASE } = require("@/lib/api");
import type {
    AcademicSummary,
    Transcript as TranscriptResponse,
    CurrentGradesResponse,
} from "@/lib/types";

export default function Academic() {
    const [stats, setStats] = React.useState<AcademicStats | null>(null);
    const [currentGrades, setCurrentGrades] = React.useState<CurrentGrade[]>([]);
    const [transcriptData, setTranscriptData] = React.useState<TranscriptTerm[]>([]);
    const [loading, setLoading] = React.useState(true);
    const { toast } = require("@/hooks/useToast");

    React.useEffect(() => {
        const init = async () => {
            try {
                const email = typeof window !== "undefined" ? localStorage.getItem("userEmail") : null;
                if (!email) {
                    setLoading(false);
                    return;
                }
                const sidRes = await fetch(`${API_BASE}/users/student-id?email=${encodeURIComponent(email)}`);
                const sidData = await sidRes.json();
                if (!sidRes.ok || typeof sidData.student_id !== "number" || sidData.student_id < 0) {
                    throw new Error("Unable to resolve student ID");
                }
                const studentId = sidData.student_id;

                const [summaryRes, transcriptRes, gradesRes] = await Promise.all([
                    fetch(`${API_BASE}/academics/student/${studentId}/summary`),
                    fetch(`${API_BASE}/academics/student/${studentId}/transcript`),
                    fetch(`${API_BASE}/academics/student/${studentId}/current-grades`),
                ]);

                if (summaryRes.ok) {
                    const s: AcademicSummary = await summaryRes.json();
                    setStats({
                        cumulativeGPA: s.cumulativeGPA ?? 0,
                        totalCredits: s.totalCredits ?? 0,
                        semestersCompleted: s.semestersCompleted ?? 0,
                        academicStanding: s.academicStanding ?? "",
                        graduationProgress: s.graduationProgress ?? 0,
                        expectedGraduation: s.expectedGraduation ?? "",
                        currentTermGPA: s.currentTermGPA ?? undefined,
                        currentTermLabel: s.currentTermLabel ?? undefined,
                    });
                }

                if (transcriptRes.ok) {
                    const t: TranscriptResponse = await transcriptRes.json();
                    const terms: TranscriptTerm[] = (t.terms ?? []).map((term) => ({
                        term: term.termLabel,
                        gpa: term.gpa,
                        credits: term.credits,
                        courses: (term.courses ?? []).map((c) => ({
                            course: c.courseCode,
                            title: c.title,
                            grade: c.grade,
                            credits: c.credits,
                        })),
                    }));
                    setTranscriptData(terms);
                }

                if (gradesRes.ok) {
                    const g: CurrentGradesResponse = await gradesRes.json();
                    const list: CurrentGrade[] = (g.grades ?? []).map((x) => ({
                        course: `${x.courseCode} - ${x.title}`,
                        grade: x.letter ?? "IP",
                        credits: x.credits ?? 0,
                        percentage: x.percentage ?? null,
                        status: x.status ?? "",
                        lastUpdated: x.lastUpdated ?? null,
                    }));
                    setCurrentGrades(list);
                }
            } catch (e: any) {
                toast({
                    variant: "destructive",
                    title: "Failed to load academics",
                    description: e?.message || "Please try again later.",
                });
            } finally {
                setLoading(false);
            }
        };
        init();
    }, [toast]);

    const handleDownloadTranscript = async () => {
        const { toast } = require("@/hooks/useToast");
        try {
            const email = typeof window !== "undefined" ? localStorage.getItem("userEmail") : null;
            if (!email) throw new Error("Missing user email");

            const sidRes = await fetch(`${API_BASE}/users/student-id?email=${encodeURIComponent(email)}`);
            const sidData = await sidRes.json();
            if (!sidRes.ok || typeof sidData.student_id !== "number" || sidData.student_id < 0) {
                throw new Error("Unable to resolve student ID");
            }
            const studentId = sidData.student_id;

            const [summaryRes, transcriptRes, userRes, advisorRes, programRes] = await Promise.all([
                fetch(`${API_BASE}/academics/student/${studentId}/summary`).catch(() => null),
                fetch(`${API_BASE}/academics/student/${studentId}/transcript`).catch(() => null),
                fetch(`${API_BASE}/users/get?email=${encodeURIComponent(email)}`).catch(() => null),
                fetch(`${API_BASE}/advising/student/${studentId}/advisor`).catch(() => null),
                fetch(`${API_BASE}/academics/student/${studentId}/program`).catch(() => null),
            ]);

            if (!transcriptRes || !transcriptRes.ok) throw new Error("Transcript unavailable");
            const transcript = await transcriptRes.json();
            const summary = summaryRes && summaryRes.ok ? await summaryRes.json() : {};
            const student = userRes && userRes.ok ? await userRes.json() : {};
            const advisor = advisorRes && advisorRes.ok ? await advisorRes.json() : null;
            const program = programRes && programRes.ok ? await programRes.json() : { code: null, name: null, department: null };

            const { generateTranscriptPdf } = await import("@/lib/transcript-pdf");
            await generateTranscriptPdf({
                universityName: "University of Wisconsin, Milwaukee",
                student,
                studentId,
                summary,
                transcript,
                program,
                advisor,
            });

            toast({ title: "Transcript Generated", description: "Saved as transcript.pdf" });
        } catch (e: any) {
            toast({ variant: "destructive", title: "Failed to generate transcript", description: e?.message || "Please try again later." });
        }
    };
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

    if (loading) {
        return (
            <div className="flex-1 p-4 md:p-8 pt-6">
                <div className="flex items-center justify-center text-sm text-muted-foreground" style={{ minHeight: 160 }}>
                    <span className="inline-flex items-center gap-2"><Spinner size="sm" /> Loading academic records...</span>
                </div>
            </div>
        );
    }

    return (
        <div className="flex-1 space-y-4 p-4 md:p-8 pt-6">
			<div className="flex items-center justify-between space-y-2">
				<h2 className="text-3xl font-bold tracking-tight">Academic Records</h2>
				<div className="flex items-center space-x-2">
                    <Button variant="outline" size="sm" onClick={handleDownloadTranscript}>
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
                    {stats?.cumulativeGPA ?? 0}
                </div>
                <p className="text-xs text-muted-foreground">
                    {stats?.totalCredits ?? 0} credits completed
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
                    {stats?.academicStanding || ""}
                </div>
                <p className="text-xs text-muted-foreground">
                    {stats?.semestersCompleted ?? 0} semesters completed
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
                    {stats?.graduationProgress ?? 0}%
                </div>
                <Progress
                    value={stats?.graduationProgress ?? 0}
                    className="mt-2"
                />
                <p className="text-xs text-muted-foreground mt-1">
                    Expected: {stats?.expectedGraduation || ""}
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
                <div className="text-2xl font-bold">{stats?.currentTermLabel || "Current Term"}</div>
                <p className="text-xs text-muted-foreground">GPA: {typeof stats?.currentTermGPA === "number" ? stats?.currentTermGPA : "N/A"}</p>
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
                            <CardTitle>{stats?.currentTermLabel || "Current Grades"}</CardTitle>
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
