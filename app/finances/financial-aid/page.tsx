"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import {
	Card,
	CardContent,
	CardDescription,
	CardHeader,
	CardTitle,
} from "../../components/Card/card";
import { Button } from "../../components/Button/button";
import {
	ChevronLeft,
	ChevronDown,
	ChevronUp,
	GraduationCap,
	FileText,
	DollarSign,
	Calendar,
	CheckCircle,
	AlertCircle,
} from "lucide-react";
import { Badge } from "../../components/Badge/badge";
import { Progress } from "../../components/Progress/progress";
import {
	Collapsible,
	CollapsibleContent,
	CollapsibleTrigger,
} from "../../components/Collapsible/collapsible";
import s from "./styles.module.css";
import { Spinner } from "../../components/Others/spinner";
import type { AidOverview, GetStudentIdResponse } from "@/lib/types";

export default function FinancialAidPage() {
    const router = useRouter();
    const [overviewOpen, setOverviewOpen] = useState(false);
    const [aid, setAid] = useState<AidOverview | null>(null);
    const [loading, setLoading] = useState<boolean>(true);
    const { API_BASE } = require("@/lib/api");
    const { toast } = require("@/hooks/useToast");

    useEffect(() => {
        const load = async () => {
            try {
                const email = typeof window !== "undefined" ? localStorage.getItem("userEmail") : null;
                if (!email) return;
                const sidRes = await fetch(`${API_BASE}/users/student-id?email=${encodeURIComponent(email)}`);
                const sidData: GetStudentIdResponse = await sidRes.json();
                if (!sidRes.ok || typeof sidData.student_id !== "number" || sidData.student_id < 0) {
                    if (sidRes.status === 400) {
                        toast({ variant: "destructive", title: "User not found", description: "Please verify your account." });
                    }
                    return;
                }
                const res = await fetch(`${API_BASE}/finances/student/${sidData.student_id}/aid`);
                if (!res.ok) throw new Error("Failed to load aid overview");
                const data: AidOverview = await res.json();
                setAid(data);
            } catch (e: any) {
                toast({ variant: "destructive", title: "Failed to load financial aid", description: e?.message || "Try again later." });
            } finally {
                setLoading(false);
            }
        };
        load();
    }, [toast]);
	const aidWidgets = [
		{
			id: "apply-financial-aid",
			title: "Apply for Financial Aid",
			description:
				"The first step to determining if you are eligible for state and federal financial aid.",
			icon: FileText,
			link: "https://studentaid.gov/h/apply-for-aid/fafsa",
			status: "Available",
		},
		// {
		// 	id: "financial-aid-summary",
		// 	title: "Financial Aid Summary",
		// 	description: "Overview of your financial aid package",
		// 	icon: GraduationCap,
		// 	status: "Active",
		// },
		{
			id: "aid-history",
			title: "Aid History",
			description: "View past financial aid awards",
			icon: Calendar,
			status: "Available",
			link: "/finances/my-account?tab=aid",
		},
		{
			id: "accept-decline-aid",
			title: "Accept/Decline Aid",
			description: "Manage your aid offers",
			icon: CheckCircle,
			status: "Action Required",
			badge: "2 Pending",
		},
		// {
		// 	id: "loan-information",
		// 	title: "Loan Information",
		// 	description: "View loan details and requirements",
		// 	icon: DollarSign,
		// 	status: "Available",
		// },
		{
			id: "missing-documents",
			title: "Missing Documents",
			description: "Upload required documents",
			icon: AlertCircle,
			status: "Urgent",
			badge: "1 Required",
		},
	];

	const handleBackClick = () => {
		console.log("Back button clicked, navigating to finances");
		router.push("/finances");
	};

	return (
		<div className={s.pageContainer}>
			<div className={s.header}>
				{/* Back Button */}
				<div>
					<Button variant="ghost" onClick={handleBackClick}>
						<ChevronLeft className="h-4 w-4 mr-2" />
						Back to Finances
					</Button>
				</div>
			</div>
			{/* Aid Overview Card */}
			<Collapsible open={overviewOpen} onOpenChange={setOverviewOpen}>
				<Card className={s.overviewCard}>
					<CollapsibleTrigger asChild>
						<CardHeader className={s.collapsibleHeader}>
							<div className={s.headerContent}>
								<div className={s.headerLeft}>
									<div className={s.iconWrapperLarge}>
										<GraduationCap className="h-8 w-8 text-primary" />
									</div>
									<div>
                    <CardTitle className="text-2xl">Financial Aid Overview</CardTitle>
                    <CardDescription>Academic Year</CardDescription>
									</div>
								</div>
								{overviewOpen ? (
									<ChevronUp className="h-5 w-5 text-muted-foreground" />
								) : (
									<ChevronDown className="h-5 w-5 text-muted-foreground" />
								)}
							</div>
						</CardHeader>
					</CollapsibleTrigger>
                <CollapsibleContent>
                    {loading ? (
                        <CardContent className={s.cardContentSpacing}>
                            <div className="flex items-center justify-center text-sm text-muted-foreground" style={{ minHeight: 120 }}>
                                <span className="inline-flex items-center gap-2"><Spinner size="sm" /> Loading aid overview…</span>
                            </div>
                        </CardContent>
                    ) : (
                    <CardContent className={s.cardContentSpacing}>
							{/* Total Aid */}
							<div className={s.totalAidGrid}>
								<div className={s.aidItem}>
									<p className="text-sm text-muted-foreground">
										Total Aid Offered
									</p>
                            <p className="text-3xl font-semibold">{aid ? `$${Number(aid.totalOffered || 0).toLocaleString()}` : "--"}</p>
								</div>
								<div className={s.aidItem}>
									<p className="text-sm text-muted-foreground">Aid Accepted</p>
                            <p className="text-3xl font-semibold text-green-600">{aid ? `$${Number(aid.totalAccepted || 0).toLocaleString()}` : "--"}</p>
								</div>
								<div className={s.aidItem}>
									<p className="text-sm text-muted-foreground">
										Pending Decision
									</p>
                            <p className="text-3xl font-semibold text-orange-600">{aid ? `$${Number(((aid.totalOffered || 0) - (aid.totalAccepted || 0))).toLocaleString()}` : "--"}</p>
								</div>
							</div>

							{/* Aid Breakdown */}
							<div className={s.aidBreakdown}>
                        <h4>Aid Breakdown</h4>

                        <div className={s.breakdownList}>
                            {(aid?.awards || []).map((w: any, idx: number) => (
                                <div key={idx} className={s.breakdownItem}>
                                    <div>
                                        <p className="font-medium">{w.type}</p>
                                        <p className="text-sm text-muted-foreground">{w.description}</p>
                                    </div>
                                    <Badge variant="secondary">${'{'}Number(w.amountAccepted || w.amountOffered || 0).toLocaleString(){'}'}</Badge>
                                </div>
                            ))}
                            {(!aid || (aid.awards || []).length === 0) && (
                                <p className="text-sm text-muted-foreground">No awards found.</p>
                            )}
                        </div>
							</div>

							{/* Progress */}
							<div className={s.progressSection}>
                        <div className={s.progressHeader}>
                            <span>Aid Acceptance Progress</span>
                            <span className="text-muted-foreground">{aid ? Math.round(((aid.totalAccepted || 0) / Math.max(1, (aid.totalOffered || 0))) * 100) : 0}%</span>
                        </div>
                        <Progress value={aid ? Math.round(((aid.totalAccepted || 0) / Math.max(1, (aid.totalOffered || 0))) * 100) : 0} />
							</div>
                    </CardContent>
                    )}
                </CollapsibleContent>
				</Card>
			</Collapsible>{" "}
			{/* Financial Aid Services */}
			<div>
				<div className={s.servicesGrid}>
					{aidWidgets.map((widget) => {
						const Icon = widget.icon;
						const isUrgent = widget.status === "Urgent";
						const isActionRequired = widget.status === "Action Required";

						return (
							<Card
								key={widget.id}
								className={`${s.widgetCard} ${
									isUrgent
										? s.widgetCardUrgent
										: isActionRequired
										? s.widgetCardAction
										: ""
								}`}
								onClick={() => {
									if (widget.link) {
										window.open(widget.link, "_blank");
									}
								}}
							>
								<CardHeader>
									<div className={s.widgetHeader}>
										<div
											className={`${s.iconWrapper} ${
												isUrgent
													? s.iconWrapperUrgent
													: isActionRequired
													? s.iconWrapperAction
													: ""
											}`}
										>
											<Icon
												className={`h-6 w-6 ${
													isUrgent
														? "text-destructive"
														: isActionRequired
														? "text-orange-600"
														: "text-primary"
												}`}
											/>
										</div>
										{widget.badge && (
											<Badge
												variant={
													isUrgent || isActionRequired
														? "destructive"
														: "secondary"
												}
											>
												{widget.badge}
											</Badge>
										)}
									</div>
									<CardTitle className={s.widgetTitleMargin}>
										{widget.title}
									</CardTitle>
									<CardDescription>{widget.description}</CardDescription>
								</CardHeader>
							</Card>
						);
					})}
				</div>
			</div>
		</div>
	);
}
