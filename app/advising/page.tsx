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
import { Input } from "../components/Others/input";
import { Textarea } from "../components/Others/textarea";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "../components/Others/select";
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from "../components/Others/dialog";
import {
    Calendar,
    Clock,
    User,
    MessageSquare,
    Loader2,
    RefreshCw,
    CheckCircle,
    AlertCircle,
    BookOpen,
    GraduationCap,
    Mail,
    Phone,
} from "lucide-react";
const { API_BASE } = require("@/lib/api");

type AdvisorDTO = {
    advisorId: number;
    name: string;
    title: string;
    department?: string;
    email?: string;
    phone?: string;
    officeLocation?: string;
    availability?: string;
};

type AppointmentDTO = {
    id: number;
    scheduledAt: string;
    advisorName: string;
    type: string;
    location?: string;
    status: string;
    notes?: string;
};

type DegreeProgress = {
    overallProgress: number;
    totalCredits: number;
    completedCredits: number;
    gpa: number;
    expectedGraduation: string;
};

type AdvisorMessage = {
    id: number;
    advisorId: number;
    advisorName: string;
    sender: string;
    content: string;
    sentAt: string;
};

type Conversation = {
    advisorId: number;
    advisorName: string;
    unreadCount?: number;
    messages: AdvisorMessage[];
};

export default function AdvisingPage() {
    const { toast } = require("@/hooks/useToast");
    const [upcomingAppointments, setUpcomingAppointments] = React.useState<Array<{
        id: number;
        date: string;
        time: string;
        advisor: string;
        type: string;
        location?: string;
        status: string;
        notes?: string;
    }>>([]);
    const [advisorDirectory, setAdvisorDirectory] = React.useState<Array<AdvisorDTO & { specialties?: string[] }>>([]);
    const [degreeProgress, setDegreeProgress] = React.useState<DegreeProgress>({
        overallProgress: 0,
        totalCredits: 120,
        completedCredits: 0,
        gpa: 0,
        expectedGraduation: "",
    });
    const [degreeRequirements, setDegreeRequirements] = React.useState<Array<{ category: string; required: number; completed: number; remaining: number; status: string }>>([]);
    const [requirementItems, setRequirementItems] = React.useState<Array<{ courseId: number; courseCode: string; courseName: string; credits: number; required: boolean; completed: boolean; finalLetter?: string | null; termLabel?: string | null }>>([]);
    const [primaryAdvisor, setPrimaryAdvisor] = React.useState<AdvisorDTO | null>(null);
    const [loading, setLoading] = React.useState(true);
    const [conversations, setConversations] = React.useState<Conversation[]>([]);
    const [messagesLastUpdated, setMessagesLastUpdated] = React.useState<Date | null>(null);
    const [convRefreshing, setConvRefreshing] = React.useState<Record<number, boolean>>({});

    // Schedule modal state
    const [scheduleOpen, setScheduleOpen] = React.useState(false);
    const [scheduleAdvisorId, setScheduleAdvisorId] = React.useState<number | null>(null);
    const [scheduleWhen, setScheduleWhen] = React.useState<string>(""); // datetime-local value
    const [scheduleType, setScheduleType] = React.useState<string>("ACADEMIC_ADVISING");
    const [scheduleLocation, setScheduleLocation] = React.useState<string>("");
    const [scheduleNotes, setScheduleNotes] = React.useState<string>("");

    // Message modal state
    const [messageOpen, setMessageOpen] = React.useState(false);
    const [messageAdvisorId, setMessageAdvisorId] = React.useState<number | null>(null);
    const [messageBody, setMessageBody] = React.useState<string>("");
    const [refreshingMsgs, setRefreshingMsgs] = React.useState(false);
    const [sendingMessage, setSendingMessage] = React.useState(false);

    // Derived total unread across conversations
    const unreadTotal = React.useMemo(() => {
        try {
            return conversations.reduce((sum, c) => sum + (c.unreadCount || 0), 0);
        } catch { return 0; }
    }, [conversations]);

    React.useEffect(() => {
        const load = async () => {
            try {
                const email = typeof window !== "undefined" ? localStorage.getItem("userEmail") : null;
                if (!email) { setLoading(false); return; }
                const sidRes = await fetch(`${API_BASE}/users/student-id?email=${encodeURIComponent(email)}`);
                const sidData = await sidRes.json();
                if (!sidRes.ok || typeof sidData.student_id !== "number" || sidData.student_id < 0) {
                    throw new Error("Unable to resolve student ID");
                }
                const studentId = sidData.student_id;

                const [advisorRes, apptRes, dirRes, summaryRes, msgRes] = await Promise.all([
                    fetch(`${API_BASE}/advising/student/${studentId}/advisor`).catch(() => null),
                    fetch(`${API_BASE}/advising/student/${studentId}/appointments`).catch(() => null),
                    fetch(`${API_BASE}/advising/advisors`).catch(() => null),
                    fetch(`${API_BASE}/academics/student/${studentId}/summary`).catch(() => null),
                    fetch(`${API_BASE}/advising/student/${studentId}/messages`).catch(() => null),
                ]);

                if (summaryRes && summaryRes.ok) {
                    const s = await summaryRes.json();
                    setDegreeProgress({
                        overallProgress: s.graduationProgress ?? 0,
                        totalCredits: 120, // fallback displayed denominator
                        completedCredits: s.totalCredits ?? 0,
                        gpa: s.cumulativeGPA ?? 0,
                        expectedGraduation: s.expectedGraduation ?? "",
                    });
                }

                if (dirRes && dirRes.ok) {
                    const list: AdvisorDTO[] = await dirRes.json();
                    setAdvisorDirectory(list.map(a => ({ ...a })));
                }

                // Load primary advisor details
                if (advisorRes && advisorRes.ok) {
                    const adv: AdvisorDTO = await advisorRes.json();
                    setPrimaryAdvisor(adv);
                }

                // Load requirements breakdown
                const reqRes = await fetch(`${API_BASE}/academics/student/${studentId}/requirements`).catch(() => null);
                if (reqRes && reqRes.ok) {
                    const body = await reqRes.json();
                    const cats = (body.categories || []).map((c: any) => ({
                        category: c.category,
                        required: Number(c.required || 0),
                        completed: Number(c.completed || 0),
                        remaining: Number(c.remaining || 0),
                        status: c.status || "",
                    }));
                    setDegreeRequirements(cats);
                }

                // Load requirement items table
                const itemsRes = await fetch(`${API_BASE}/academics/student/${studentId}/requirements/items`).catch(() => null);
                if (itemsRes && itemsRes.ok) {
                    const list = await itemsRes.json();
                    setRequirementItems(list || []);
                }

                // Build upcoming appointments list
                if (apptRes && apptRes.ok) {
                    const items: AppointmentDTO[] = await apptRes.json();
                    const mapped = items.map(it => {
                        const d = new Date(it.scheduledAt);
                        const date = isNaN(d.getTime()) ? "" : d.toLocaleDateString();
                        const time = isNaN(d.getTime()) ? "" : d.toLocaleTimeString([], { hour: 'numeric', minute: '2-digit' });
                        const status = humanize(it.status);
                        const type = humanize(it.type);
                        return {
                            id: it.id,
                            date,
                            time,
                            advisor: it.advisorName,
                            type,
                            location: it.location,
                            status,
                            notes: it.notes,
                        };
                    });
                    setUpcomingAppointments(mapped);
                }

                // Messages (grouped by advisor)
                if (msgRes && msgRes.ok) {
                    const list = await msgRes.json();
                    const msgs: AdvisorMessage[] = (list || []).map((m: any) => ({
                        id: m.id,
                        advisorId: m.advisorId,
                        advisorName: m.advisorName,
                        sender: m.sender,
                        content: m.content,
                        sentAt: m.sentAt,
                    }));
                    const grouped = new Map<number, { advisorName: string; messages: AdvisorMessage[] }>();
                    for (const m of msgs) {
                        const g = grouped.get(m.advisorId) || { advisorName: m.advisorName, messages: [] };
                        g.messages.push(m);
                        grouped.set(m.advisorId, g);
                    }
                    const withUnread: Conversation[] = Array.from(grouped.entries())
                        .map(([advisorId, g]) => ({ advisorId, advisorName: g.advisorName, messages: g.messages }))
                        .map(addUnreadCount);
                    setConversations(withUnread);
                    setMessagesLastUpdated(new Date());
                }
            } catch (e: any) {
                toast({ variant: "destructive", title: "Failed to load advising data", description: e?.message || "Try again later." });
            } finally {
                setLoading(false);
            }
        };
        load();
    }, [toast]);

    if (loading) {
        return (
            <div className="flex-1 space-y-4 p-4 md:p-8 pt-6">
                <p className="text-sm text-muted-foreground">Loading advising data...</p>
            </div>
        );
    }

    function humanize(v?: string) {
        if (!v) return "";
        return v.toLowerCase().split("_").map(s => s ? s[0].toUpperCase() + s.slice(1) : s).join(" ");
    }
    
    function getStatusColor(status: string) {
        const s = (status || "").toLowerCase();
        if (s.includes("confirm")) return "bg-green-100 text-green-800";
        if (s.includes("pending")) return "bg-yellow-100 text-yellow-800";
        if (s.includes("cancel")) return "bg-red-100 text-red-800";
        return "bg-gray-100 text-gray-800";
    }

    function getProgressColor(progress: number) {
        if (progress >= 90) return "bg-green-500";
        if (progress >= 70) return "bg-blue-500";
        if (progress >= 50) return "bg-yellow-500";
        return "bg-red-500";
    }

    async function openSchedule(advisorId?: number | null) {
        const fallbackAdvisorId = advisorDirectory.length > 0 ? advisorDirectory[0].advisorId : null;
        setScheduleAdvisorId(advisorId ?? (primaryAdvisor?.advisorId ?? fallbackAdvisorId));
        setScheduleWhen("");
        setScheduleType("ACADEMIC_ADVISING");
        setScheduleLocation("");
        setScheduleNotes("");
        setScheduleOpen(true);
    }

    async function submitSchedule() {
        try {
            const email = typeof window !== "undefined" ? localStorage.getItem("userEmail") : null;
            if (!email) return;
            const sidRes = await fetch(`${API_BASE}/users/student-id?email=${encodeURIComponent(email)}`);
            const sidData = await sidRes.json();
            if (!sidRes.ok || typeof sidData.student_id !== "number" || sidData.student_id < 0) return;
            const studentId = sidData.student_id;
            const scheduledAtIso = scheduleWhen ? new Date(scheduleWhen).toISOString() : null;
            if (!scheduleAdvisorId || !scheduledAtIso) {
                toast({ variant: "destructive", title: "Missing details", description: "Please choose an advisor and date/time." });
                return;
            }
            const res = await fetch(`${API_BASE}/advising/admin/students/${studentId}/appointments`, {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({
                    advisorId: scheduleAdvisorId,
                    scheduledAt: scheduledAtIso,
                    type: scheduleType,
                    location: scheduleLocation || null,
                    status: "PENDING",
                    notes: scheduleNotes || null,
                }),
            });
            if (!res.ok) throw new Error("Unable to create appointment");
            const appt = await res.json();
            const d = new Date(appt.scheduledAt);
            const mapped = {
                id: appt.id,
                date: isNaN(d.getTime()) ? "" : d.toLocaleDateString(),
                time: isNaN(d.getTime()) ? "" : d.toLocaleTimeString([], { hour: 'numeric', minute: '2-digit' }),
                advisor: appt.advisorName,
                type: humanize(appt.type),
                location: appt.location,
                status: humanize(appt.status),
                notes: appt.notes,
            };
            setUpcomingAppointments(prev => [...prev, mapped].sort((a,b) => new Date(a.date + " " + a.time).getTime() - new Date(b.date + " " + b.time).getTime()));
            setScheduleOpen(false);
            toast({ title: "Appointment requested", description: "Your appointment was scheduled." });
        } catch (e: any) {
            toast({ variant: "destructive", title: "Failed to schedule", description: e?.message || "Try again later." });
        }
    }

    function emailAdvisor(email?: string, subject?: string) {
        if (!email) return;
        const s = encodeURIComponent(subject || "Advising Appointment");
        window.location.href = `mailto:${email}?subject=${s}`;
    }

    async function openMessage(advisorId?: number | null) {
        const fallbackAdvisorId = advisorDirectory.length > 0 ? advisorDirectory[0].advisorId : null;
        const chosen = advisorId ?? (primaryAdvisor?.advisorId ?? fallbackAdvisorId);
        if (chosen != null) markConversationRead(chosen);
        setMessageAdvisorId(chosen);
        setMessageBody("");
        setMessageOpen(true);
    }

    async function submitMessage() {
        try {
            setSendingMessage(true);
            const email = typeof window !== "undefined" ? localStorage.getItem("userEmail") : null;
            if (!email) return;
            const sidRes = await fetch(`${API_BASE}/users/student-id?email=${encodeURIComponent(email)}`);
            const sidData = await sidRes.json();
            if (!sidRes.ok || typeof sidData.student_id !== "number" || sidData.student_id < 0) return;
            const studentId = sidData.student_id;
            if (!messageAdvisorId || !messageBody.trim()) {
                toast({ variant: "destructive", title: "Missing details", description: "Please choose an advisor and enter a message." });
                return;
            }
            const res = await fetch(`${API_BASE}/advising/student/${studentId}/messages`, {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({ advisorId: messageAdvisorId, content: messageBody.trim() }),
            });
            if (!res.ok) throw new Error("Unable to send message");
            const saved = await res.json();
            setConversations(prev => {
                const next = [...prev];
                const idx = next.findIndex(c => c.advisorId === saved.advisorId);
                const item = { id: saved.id, advisorId: saved.advisorId, advisorName: saved.advisorName, sender: saved.sender, content: saved.content, sentAt: saved.sentAt };
                if (idx >= 0) {
                    next[idx] = { ...next[idx], advisorName: saved.advisorName, messages: [...next[idx].messages, item] };
                } else {
                    next.push({ advisorId: saved.advisorId, advisorName: saved.advisorName, messages: [item] });
                }
                return next;
            });
            setMessageOpen(false);
            toast({ title: "Message sent" });
        } catch (e: any) {
            toast({ variant: "destructive", title: "Failed to send", description: e?.message || "Try again later." });
        } finally {
            setSendingMessage(false);
        }
    }

    function lastReadKey(advisorId: number) { return `advisorConvLastRead_${advisorId}`; }
    function getLastRead(advisorId: number): Date | null {
        try {
            const v = typeof window !== "undefined" ? localStorage.getItem(lastReadKey(advisorId)) : null;
            return v ? new Date(v) : null;
        } catch { return null; }
    }
    function setLastReadNow(advisorId: number) {
        try { if (typeof window !== "undefined") localStorage.setItem(lastReadKey(advisorId), new Date().toISOString()); } catch {}
    }
    function addUnreadCount(conv: Conversation): Conversation {
        const lr = getLastRead(conv.advisorId);
        const unread = conv.messages.filter(m => m.sender !== 'STUDENT' && (!lr || new Date(m.sentAt) > lr)).length;
        return { ...conv, unreadCount: unread };
    }

    async function refreshMessages() {
        try {
            setRefreshingMsgs(true);
            const email = typeof window !== "undefined" ? localStorage.getItem("userEmail") : null;
            if (!email) return;
            const sidRes = await fetch(`${API_BASE}/users/student-id?email=${encodeURIComponent(email)}`);
            const sidData = await sidRes.json();
            if (!sidRes.ok || typeof sidData.student_id !== "number" || sidData.student_id < 0) return;
            const studentId = sidData.student_id;
            const msgRes = await fetch(`${API_BASE}/advising/student/${studentId}/messages`);
            if (!msgRes.ok) throw new Error("Unable to load messages");
            const list = await msgRes.json();
            const msgs: AdvisorMessage[] = (list || []).map((m: any) => ({
                id: m.id,
                advisorId: m.advisorId,
                advisorName: m.advisorName,
                sender: m.sender,
                content: m.content,
                sentAt: m.sentAt,
            }));
            const grouped = new Map<number, { advisorName: string; messages: AdvisorMessage[] }>();
            for (const m of msgs) {
                const g = grouped.get(m.advisorId) || { advisorName: m.advisorName, messages: [] };
                g.messages.push(m);
                grouped.set(m.advisorId, g);
            }
            const withUnread: Conversation[] = Array.from(grouped.entries())
                .map(([advisorId, g]) => ({ advisorId, advisorName: g.advisorName, messages: g.messages }))
                .map(addUnreadCount);
            setConversations(withUnread);
            setMessagesLastUpdated(new Date());
        } catch (e: any) {
            toast({ variant: "destructive", title: "Failed to refresh", description: e?.message || "Try again later." });
        } finally {
            setRefreshingMsgs(false);
        }
    }

    async function refreshConversation(advisorId: number) {
        try {
            setConvRefreshing(prev => ({ ...prev, [advisorId]: true }));
            const email = typeof window !== "undefined" ? localStorage.getItem("userEmail") : null;
            if (!email) return;
            const sidRes = await fetch(`${API_BASE}/users/student-id?email=${encodeURIComponent(email)}`);
            const sidData = await sidRes.json();
            if (!sidRes.ok || typeof sidData.student_id !== "number" || sidData.student_id < 0) return;
            const studentId = sidData.student_id;
            const msgRes = await fetch(`${API_BASE}/advising/student/${studentId}/messages`);
            if (!msgRes.ok) throw new Error("Unable to load messages");
            const list = await msgRes.json();
            const msgs: AdvisorMessage[] = (list || []).filter((m:any) => m.advisorId === advisorId).map((m: any) => ({
                id: m.id,
                advisorId: m.advisorId,
                advisorName: m.advisorName,
                sender: m.sender,
                content: m.content,
                sentAt: m.sentAt,
            }));
            setConversations(prev => prev.map(c => c.advisorId === advisorId ? addUnreadCount({ ...c, messages: msgs }) : c));
            setMessagesLastUpdated(new Date());
        } catch (e: any) {
            toast({ variant: "destructive", title: "Failed to refresh", description: e?.message || "Try again later." });
        } finally {
            setConvRefreshing(prev => ({ ...prev, [advisorId]: false }));
        }
    }

    function markConversationRead(advisorId: number) {
        setLastReadNow(advisorId);
        setConversations(prev => prev.map(c => c.advisorId === advisorId ? ({ ...c, unreadCount: 0 }) : c));
    }


	return (
		<div className="flex-1 space-y-4 p-4 md:p-8 pt-6">
			<div className="flex items-center justify-between space-y-2">
				<h2 className="text-3xl font-bold tracking-tight">Academic Advising</h2>
				<div className="flex items-center space-x-2">
					<Button variant="outline" size="sm" onClick={() => openSchedule()}>
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
                        {upcomingAppointments.length > 0 ? (
                            <>
                                <div className="text-2xl font-bold">{upcomingAppointments[0].date}</div>
                                <p className="text-xs text-muted-foreground">
                                    With {upcomingAppointments[0].advisor} - {upcomingAppointments[0].time}
                                </p>
                            </>
                        ) : (
                            <p className="text-sm text-muted-foreground">No upcoming appointments</p>
                        )}
                    </CardContent>
                </Card>

				<Card>
					<CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
						<CardTitle className="text-sm font-medium">Advisor</CardTitle>
						<User className="h-4 w-4 text-muted-foreground" />
					</CardHeader>
                    <CardContent>
                        <div className="text-2xl font-bold">{primaryAdvisor?.name || "-"}</div>
                        <p className="text-xs text-muted-foreground">{primaryAdvisor?.title || "Academic Advisor"}</p>
                    </CardContent>
                </Card>
			</div>

			{/* Main Content Tabs */}
			<Tabs defaultValue="appointments" className="space-y-4">
                <TabsList>
                    <TabsTrigger value="appointments">Appointments</TabsTrigger>
                    <TabsTrigger value="advisors">Advisor Directory</TabsTrigger>
                    <TabsTrigger value="degree">Degree Planning</TabsTrigger>
                    <TabsTrigger value="messages">
                        <span className="relative inline-flex items-center gap-1">
                            <span key={unreadTotal} className={unreadTotal > 0 ? "animate-fade-in-up" : ""}>
                                {`Messages${unreadTotal > 0 ? ` (${unreadTotal})` : ''}`}
                            </span>
                            {unreadTotal > 0 && (
                                <span
                                    aria-label="unread messages"
                                    className="ml-1 inline-block h-2 w-2 rounded-full bg-red-600 animate-pulse"
                                />
                            )}
                        </span>
                    </TabsTrigger>
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
											<Button variant="outline" size="sm" onClick={() => openMessage(appointment?.advisor ? advisorDirectory.find(a=>a.name===appointment.advisor)?.advisorId || primaryAdvisor?.advisorId || null : primaryAdvisor?.advisorId || null)}>
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
                                                {advisor.specialties?.length ? (
                                                    <div>
                                                        <p className="text-sm font-medium mb-1">
                                                            Specialties:
                                                        </p>
                                                        <div className="flex flex-wrap gap-1">
                                                            {advisor.specialties?.map((specialty: string, idx: number) => (
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
                                                ) : null}
												</div>
											</div>
											<div className="flex space-x-2">
												<Button variant="outline" size="sm" onClick={() => emailAdvisor(advisor.email, `Advising Inquiry - ${advisor.name}`)}>
													<Mail className="h-4 w-4 mr-2" />
													Email
												</Button>
												<Button variant="outline" size="sm" onClick={() => openSchedule(advisor.advisorId)}>
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
                                                    variant={req.status?.toLowerCase().includes("complete") ? "default" : "secondary"}
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
                                                        width: `${req.required > 0 ? (req.completed / req.required) * 100 : 0}%`,
                                                    }}
                                                ></div>
                                            </div>
                                        </div>
                                    ))}
                                    {degreeRequirements.length === 0 && (
                                        <div className="text-sm text-muted-foreground">No degree requirements available.</div>
                                    )}
                                </div>
							</CardContent>
                    </Card>

                    <Card>
                        <CardHeader>
                            <CardTitle>Required Courses</CardTitle>
                            <CardDescription>Core courses for your program and completion status</CardDescription>
                        </CardHeader>
                        <CardContent>
                            <div className="overflow-x-auto">
                                <table className="min-w-full text-sm">
                                    <thead>
                                        <tr className="text-left text-muted-foreground border-b">
                                            <th className="py-2 pr-4">Course</th>
                                            <th className="py-2 pr-4">Title</th>
                                            <th className="py-2 pr-4">Credits</th>
                                            <th className="py-2 pr-4">Status</th>
                                            <th className="py-2 pr-4">Term</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        {requirementItems.map((it, idx) => (
                                            <tr key={idx} className="border-b last:border-0">
                                                <td className="py-2 pr-4 font-medium">{it.courseCode}</td>
                                                <td className="py-2 pr-4">{it.courseName}</td>
                                                <td className="py-2 pr-4">{it.credits ?? 0}</td>
                                                <td className="py-2 pr-4">
                                                    {it.completed ? (
                                                        <Badge className="bg-green-100 text-green-800">Completed {it.finalLetter || ''}</Badge>
                                                    ) : (
                                                        <Badge variant="secondary">Required</Badge>
                                                    )}
                                                </td>
                                                <td className="py-2 pr-4">{it.termLabel || '-'}</td>
                                            </tr>
                                        ))}
                                        {requirementItems.length === 0 && (
                                            <tr>
                                                <td className="py-3 text-muted-foreground" colSpan={5}>No requirement items available.</td>
                                            </tr>
                                        )}
                                    </tbody>
                                </table>
                            </div>
                        </CardContent>
                    </Card>
                </div>
            </TabsContent>

				<TabsContent value="messages" className="space-y-4">
					<Card>
						<CardHeader>
                            <div className="flex items-center justify-between">
                                <div>
                                    <CardTitle>Advisor Messages</CardTitle>
                                    <CardDescription>Communications with your academic advisors</CardDescription>
                                    <div className="text-xs text-muted-foreground mt-1">Last updated: {messagesLastUpdated ? new Date(messagesLastUpdated).toLocaleString() : '-'}</div>
                                </div>
                                <div className="flex items-center gap-2">
                                    {refreshingMsgs && <Loader2 className="h-4 w-4 animate-spin text-muted-foreground" />}
                                    <Button variant="outline" size="sm" onClick={refreshMessages} disabled={refreshingMsgs}>Refresh</Button>
                                </div>
                            </div>
						</CardHeader>
						<CardContent>
                            {conversations.length === 0 ? (
                                <div className="text-center py-8">
                                    <MessageSquare className="h-12 w-12 text-muted-foreground mx-auto mb-4" />
                                    <h3 className="text-lg font-medium mb-2">No Messages Yet</h3>
                                    <p className="text-muted-foreground mb-4">Your advisor communications will appear here.</p>
                                    <Button onClick={() => openMessage()}>
                                        <MessageSquare className="h-4 w-4 mr-2" />
                                        Start a Conversation
                                    </Button>
                                </div>
                            ) : (
                                <div className="space-y-4">
                                    {conversations.map((conv) => (
                                        <div key={conv.advisorId} className="border rounded-lg">
                                            <div className="flex items-center justify-between p-4 border-b">
                                                <div>
                                                    <p className="font-semibold">Conversation with {conv.advisorName}</p>
                                                    <p className="text-xs text-muted-foreground">{conv.messages.length} message{conv.messages.length === 1 ? '' : 's'}</p>
                                                </div>
                                                <div className="flex items-center gap-2">
                                                    {typeof conv.unreadCount === 'number' && conv.unreadCount > 0 && (
                                                        <Badge variant="destructive">Unread {conv.unreadCount}</Badge>
                                                    )}
                                                    <Button variant="outline" size="sm" onClick={() => refreshConversation(conv.advisorId)} disabled={!!convRefreshing[conv.advisorId]}>
                                                        {convRefreshing[conv.advisorId] ? <Loader2 className="h-4 w-4 animate-spin mr-2" /> : <RefreshCw className="h-4 w-4 mr-2" />}
                                                        Refresh
                                                    </Button>
                                                    <Button variant="outline" size="sm" onClick={() => markConversationRead(conv.advisorId)}>
                                                        Mark as Read
                                                    </Button>
                                                    <Button variant="outline" size="sm" onClick={() => openMessage(conv.advisorId)}>
                                                        <MessageSquare className="h-4 w-4 mr-2" /> New Message
                                                    </Button>
                                                </div>
                                            </div>
                                            <div className="p-4 space-y-3">
                                                {conv.messages.map((m) => (
                                                    <div key={m.id} className={`flex ${m.sender === 'STUDENT' ? 'justify-end' : 'justify-start'}`}>
                                                        <div className={`max-w-[70%] p-3 rounded-lg ${m.sender === 'STUDENT' ? 'bg-blue-600 text-white' : 'bg-gray-100'}`}>
                                                            <div className="text-xs opacity-80 mb-1">{m.sender === 'STUDENT' ? 'You' : conv.advisorName}                 {new Date(m.sentAt).toLocaleString()}</div>
                                                            <div className="whitespace-pre-wrap text-sm">{m.content}</div>
                                                        </div>
                                                    </div>
                                                ))}
                                            </div>
                                        </div>
                                    ))}
                                    <div className="pt-2">
                                        <Button variant="outline" onClick={() => openMessage()}>
                                            <MessageSquare className="h-4 w-4 mr-2" />
                                            Start New Conversation
                                        </Button>
                                    </div>
                                </div>
                            )}
                        </CardContent>
                    </Card>
                </TabsContent>

            {/* Schedule Appointment Dialog */}
            <Dialog open={scheduleOpen} onOpenChange={setScheduleOpen}>
                <DialogContent>
                    <DialogHeader>
                        <DialogTitle>Schedule Appointment</DialogTitle>
                        <DialogDescription>
                            Choose an advisor, date/time, and appointment details.
                        </DialogDescription>
                    </DialogHeader>
                    <div className="space-y-3">
                        <div>
                            <label className="text-sm">Advisor</label>
                            <Select value={scheduleAdvisorId ? String(scheduleAdvisorId) : undefined} onValueChange={(v) => setScheduleAdvisorId(Number(v))}>
                                <SelectTrigger className="w-full mt-1"><SelectValue placeholder="Select advisor" /></SelectTrigger>
                                <SelectContent>
                                    {primaryAdvisor ? (
                                        <SelectItem value={String(primaryAdvisor.advisorId)}>Primary: {primaryAdvisor.name}</SelectItem>
                                    ) : null}
                                    {advisorDirectory.map(a => (
                                        <SelectItem key={a.advisorId} value={String(a.advisorId)}>{a.name}</SelectItem>
                                    ))}
                                </SelectContent>
                            </Select>
                        </div>
                        <div>
                            <label className="text-sm">Date & Time</label>
                            <Input type="datetime-local" value={scheduleWhen} onChange={(e:any) => setScheduleWhen(e.target.value)} className="mt-1" />
                        </div>
                        <div>
                            <label className="text-sm">Type</label>
                            <Select value={scheduleType} onValueChange={setScheduleType}>
                                <SelectTrigger className="w-full mt-1"><SelectValue /></SelectTrigger>
                                <SelectContent>
                                    <SelectItem value="ACADEMIC_ADVISING">Academic Advising</SelectItem>
                                    <SelectItem value="DEGREE_PLANNING">Degree Planning</SelectItem>
                                    <SelectItem value="CAREER_ADVISEMENT">Career Advisement</SelectItem>
                                </SelectContent>
                            </Select>
                        </div>
                        <div>
                            <label className="text-sm">Location (optional)</label>
                            <Input value={scheduleLocation} onChange={(e:any) => setScheduleLocation(e.target.value)} className="mt-1" placeholder="e.g., Bolton Hall 123 or Zoom" />
                        </div>
                        <div>
                            <label className="text-sm">Notes (optional)</label>
                            <Textarea value={scheduleNotes} onChange={(e:any) => setScheduleNotes(e.target.value)} className="mt-1" rows={3} />
                        </div>
                        <div className="flex justify-end gap-2 pt-2">
                            <Button variant="outline" onClick={() => setScheduleOpen(false)}>Cancel</Button>
                            <Button onClick={submitSchedule}>Schedule</Button>
                        </div>
                    </div>
                </DialogContent>
            </Dialog>

            {/* Message Dialog */}
            <Dialog open={messageOpen} onOpenChange={setMessageOpen}>
                <DialogContent>
                    <DialogHeader>
                        <DialogTitle>New Message</DialogTitle>
                        <DialogDescription>Send a message to your advisor.</DialogDescription>
                    </DialogHeader>
                    <div className="space-y-3">
                        <div>
                            <label className="text-sm">Advisor</label>
                            <Select value={messageAdvisorId ? String(messageAdvisorId) : undefined} onValueChange={(v) => setMessageAdvisorId(Number(v))}>
                                <SelectTrigger className="w-full mt-1"><SelectValue placeholder="Select advisor" /></SelectTrigger>
                                <SelectContent>
                                    {primaryAdvisor ? (
                                        <SelectItem value={String(primaryAdvisor.advisorId)}>Primary: {primaryAdvisor.name}</SelectItem>
                                    ) : null}
                                    {advisorDirectory.map(a => (
                                        <SelectItem key={a.advisorId} value={String(a.advisorId)}>{a.name}</SelectItem>
                                    ))}
                                </SelectContent>
                            </Select>
                        </div>
                        <div>
                            <label className="text-sm">Message</label>
                            <Textarea rows={5} value={messageBody} onChange={(e:any) => setMessageBody(e.target.value)} className="mt-1" placeholder="Type your message..." />
                        </div>
                        <div className="flex items-center justify-between pt-2">
                            <div className="text-xs text-muted-foreground h-5">
                                {messageBody.trim().length > 0 ? (
                                    <span className="inline-flex items-center gap-1"><Loader2 className="h-3 w-3 animate-spin" /> Typing               </span>
                                ) : null}
                            </div>
                            <div className="flex gap-2">
                                <Button variant="outline" onClick={() => setMessageOpen(false)} disabled={sendingMessage}>Cancel</Button>
                                <Button onClick={submitMessage} disabled={sendingMessage || !messageBody.trim()}>
                                    {sendingMessage && <Loader2 className="h-4 w-4 animate-spin mr-2" />}
                                    Send
                                </Button>
                            </div>
                        </div>
                    </div>
                </DialogContent>
            </Dialog>
			</Tabs>
		</div>
	);
}

