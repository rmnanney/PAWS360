"use client";

import React from "react";
import { Spinner } from "../components/Others/spinner";
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
import {
    CheckCircle2,
    AlertCircle,
    ListChecks,
    ClipboardList,
} from "lucide-react";

export default function HoldsTasks() {
    const [loading, setLoading] = React.useState(true);

    React.useEffect(() => {
        // Simulate loading
        const timer = setTimeout(() => setLoading(false), 500);
        return () => clearTimeout(timer);
    }, []);

    if (loading) {
        return (
            <div className="flex-1 p-4 md:p-8 pt-6">
                <div className="flex items-center justify-center text-sm text-muted-foreground" style={{ minHeight: 160 }}>
                    <span className="inline-flex items-center gap-2"><Spinner size="sm" /> Loading holds and tasks...</span>
                </div>
            </div>
        );
    }

    return (
        <div className="flex-1 space-y-4 p-4 md:p-8 pt-6">
			<div className="flex items-center justify-between space-y-2">
				<h2 className="text-3xl font-bold tracking-tight">Holds & Tasks</h2>
			</div>

			{/* Overview Cards */}
			<div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
				<Card>
					<CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
						<CardTitle className="text-sm font-medium">
							Academic Holds
						</CardTitle>
						<AlertCircle className="h-4 w-4 text-muted-foreground" />
					</CardHeader>
					<CardContent>
                        <div className="text-2xl font-bold text-green-600">0</div>
                        <p className="text-xs text-muted-foreground">
                            No holds on your account
                        </p>
					</CardContent>
				</Card>

				<Card>
					<CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
						<CardTitle className="text-sm font-medium">
							Financial Holds
						</CardTitle>
						<AlertCircle className="h-4 w-4 text-muted-foreground" />
					</CardHeader>
					<CardContent>
                        <div className="text-2xl font-bold text-green-600">0</div>
                        <p className="text-xs text-muted-foreground">
                            No financial holds
                        </p>
					</CardContent>
				</Card>

				<Card>
					<CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
						<CardTitle className="text-sm font-medium">
							Pending Tasks
						</CardTitle>
						<ClipboardList className="h-4 w-4 text-muted-foreground" />
					</CardHeader>
					<CardContent>
                        <div className="text-2xl font-bold text-green-600">0</div>
                        <p className="text-xs text-muted-foreground">
                            All tasks completed
                        </p>
					</CardContent>
				</Card>

				<Card>
					<CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
						<CardTitle className="text-sm font-medium">
							To Do Items
						</CardTitle>
						<ListChecks className="h-4 w-4 text-muted-foreground" />
					</CardHeader>
					<CardContent>
                        <div className="text-2xl font-bold text-green-600">0</div>
                        <p className="text-xs text-muted-foreground">
                            Nothing to do
                        </p>
					</CardContent>
				</Card>
			</div>

			{/* Main Content Tabs */}
			<Tabs defaultValue="holds" className="space-y-4">
				<TabsList>
					<TabsTrigger value="holds">Holds</TabsTrigger>
					<TabsTrigger value="tasks">Tasks</TabsTrigger>
					<TabsTrigger value="completed">Completed</TabsTrigger>
				</TabsList>

				<TabsContent value="holds" className="space-y-4">
					<Card>
                        <CardHeader>
                            <CardTitle>Active Holds</CardTitle>
                            <CardDescription>
                                Holds that may prevent registration or other activities
                            </CardDescription>
                        </CardHeader>
						<CardContent>
							<div className="flex flex-col items-center justify-center py-12 text-center">
								<CheckCircle2 className="h-16 w-16 text-green-600 mb-4" />
								<h3 className="text-xl font-semibold mb-2">No Active Holds</h3>
								<p className="text-muted-foreground max-w-md">
									You currently have no holds on your account. You're all clear to register for classes and access university services.
								</p>
							</div>
						</CardContent>
					</Card>
				</TabsContent>

				<TabsContent value="tasks" className="space-y-4">
					<Card>
						<CardHeader>
							<CardTitle>Outstanding Tasks</CardTitle>
							<CardDescription>
								Important tasks and items requiring your attention
							</CardDescription>
						</CardHeader>
						<CardContent>
							<div className="flex flex-col items-center justify-center py-12 text-center">
								<CheckCircle2 className="h-16 w-16 text-green-600 mb-4" />
								<h3 className="text-xl font-semibold mb-2">All Tasks Complete</h3>
								<p className="text-muted-foreground max-w-md">
									Great job! You have no outstanding tasks at this time. Check back regularly for new assignments or requirements.
								</p>
							</div>
						</CardContent>
					</Card>
				</TabsContent>

				<TabsContent value="completed" className="space-y-4">
					<Card>
						<CardHeader>
							<CardTitle>Completed Items</CardTitle>
							<CardDescription>
								History of resolved holds and completed tasks
							</CardDescription>
						</CardHeader>
						<CardContent>
							<div className="flex flex-col items-center justify-center py-12 text-center">
								<ListChecks className="h-16 w-16 text-muted-foreground mb-4" />
								<h3 className="text-xl font-semibold mb-2">No Completed Items</h3>
								<p className="text-muted-foreground max-w-md">
									Your history of completed holds and tasks will appear here once you have items to resolve.
								</p>
							</div>
						</CardContent>
					</Card>
				</TabsContent>
			</Tabs>
		</div>
	);
}
