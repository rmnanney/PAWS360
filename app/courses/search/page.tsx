"use client";

import React from "react";
import s from "../../homepage/styles.module.css";
import cardStyles from "../../components/Card/styles.module.css";
import { API_BASE } from "@/lib/api";
import { Clock, ArrowLeft, ShoppingCart } from "lucide-react";
import { useRouter } from "next/navigation";

type CourseResult = {
    course_code: string;
    subject: string;
    course_number: string;
    title: string;
    meeting_pattern: string;
    instructor: string;
    credits: number;
    term: string;
    status: string;
};

export default function CourseSearchPage() {
    const router = useRouter();
    const { toast } = require("@/hooks/useToast");
    const [loading, setLoading] = React.useState(false);
    const [query, setQuery] = React.useState({ subject: "", courseCode: "", title: "", meetingPattern: "" });
    const [results, setResults] = React.useState<CourseResult[]>([]);
    const [selectedCourse, setSelectedCourse] = React.useState<CourseResult | null>(null);

    const doSearch = (e?: React.FormEvent) => {
        e?.preventDefault();
        setLoading(true);
        
        const params = new URLSearchParams();
        if (query.subject.trim()) params.append("subject", query.subject.trim());
        if (query.courseCode.trim()) params.append("courseCode", query.courseCode.trim());
        if (query.title.trim()) params.append("title", query.title.trim());
        if (query.meetingPattern.trim()) params.append("meetingPattern", query.meetingPattern.trim());
        
        fetch(`${API_BASE}/api/course-search?${params.toString()}`)
            .then((r) => r.ok ? r.json() : Promise.reject(r))
            .then((data) => setResults(data || []))
            .catch((err) => {
                console.error("Search failed:", err);
                setResults([]);
            })
            .finally(() => setLoading(false));
    };

    const addToCart = () => {
        if (!selectedCourse) {
            toast({ variant: "destructive", title: "No course selected", description: "Please select a course first." });
            return;
        }

        try {
            const cartKey = "enrollment_cart";
            const existingCart = localStorage.getItem(cartKey);
            const cart: CourseResult[] = existingCart ? JSON.parse(existingCart) : [];
            
            // Check if already in cart
            const alreadyExists = cart.some(c => c.course_code === selectedCourse.course_code);
            if (alreadyExists) {
                toast({ variant: "destructive", title: "Already in cart", description: `${selectedCourse.course_code} is already in your enrollment cart.` });
                return;
            }

            cart.push(selectedCourse);
            localStorage.setItem(cartKey, JSON.stringify(cart));
            
            toast({ 
                title: "Added to cart", 
                description: `${selectedCourse.course_code} - ${selectedCourse.title} has been added to your enrollment cart.` 
            });
            
            setSelectedCourse(null);
        } catch (err) {
            toast({ variant: "destructive", title: "Failed to add to cart", description: "Please try again." });
        }
    };

    return (
        <div className={s.contentWrapper}>
            <div className={s.mainGrid}>
                <div className={s.leftCards}>
                    <div className={cardStyles.scheduleCard}>
                        <div className="flex items-center gap-2 mb-4">
                            <button 
                                onClick={() => router.push('/courses')}
                                className="flex items-center gap-1 text-sm text-primary hover:underline"
                            >
                                <ArrowLeft className="h-4 w-4" />
                                Back to Courses
                            </button>
                        </div>
                        <h2 className={cardStyles.scheduleTitle}>Course Search</h2>
                        <form onSubmit={doSearch} className="space-y-3 mt-4">
                            <div>
                                <label className="block text-sm font-medium text-muted-foreground">Subject / Department</label>
                                <input className="w-full rounded-md border p-2" value={query.subject}
                                       onChange={(e) => setQuery({ ...query, subject: e.target.value })}
                                       placeholder="e.g. ENGLISH, ELECENG, EDUC" />
                            </div>

                            <div>
                                <label className="block text-sm font-medium text-muted-foreground">Course code</label>
                                <input className="w-full rounded-md border p-2" value={query.courseCode}
                                       onChange={(e) => setQuery({ ...query, courseCode: e.target.value })}
                                       placeholder="e.g. ENGLISH 100" />
                            </div>

                            <div>
                                <label className="block text-sm font-medium text-muted-foreground">Course title</label>
                                <input className="w-full rounded-md border p-2" value={query.title}
                                       onChange={(e) => setQuery({ ...query, title: e.target.value })}
                                       placeholder="Partial course title" />
                            </div>

                            <div>
                                <label className="block text-sm font-medium text-muted-foreground">Meeting pattern</label>
                                <input className="w-full rounded-md border p-2" value={query.meetingPattern}
                                       onChange={(e) => setQuery({ ...query, meetingPattern: e.target.value })}
                                       placeholder="e.g. MW, TR (optional)" />
                            </div>

                            <div className="flex gap-2">
                                <button type="submit" className={cardStyles.scheduleViewButton}>Search</button>
                                <button type="button" className={cardStyles.scheduleViewButton} onClick={() => { setQuery({ subject: "", courseCode: "", title: "", meetingPattern: "" }); setResults([]); }}>Clear</button>
                            </div>
                        </form>
                    </div>
                </div>

                <div className={s.scheduleCard}>
                    <div className={cardStyles.scheduleHeader}>
                        <h3 className={cardStyles.scheduleTitle}>Results</h3>
                        {selectedCourse && (
                            <button
                                onClick={addToCart}
                                className="flex items-center gap-2 px-4 py-2 bg-primary text-primary-foreground rounded-md hover:bg-primary/90"
                            >
                                <ShoppingCart className="h-4 w-4" />
                                Add to Cart
                            </button>
                        )}
                    </div>

                    <div className="space-y-3">
                        {loading && <div className="text-sm text-muted-foreground">Loading courses…</div>}
                        {!loading && results.length === 0 && <div className="text-sm text-muted-foreground">No results. Enter search criteria and click Search.</div>}

                        {results.map((c, idx) => (
                            <div 
                                key={idx} 
                                className={`${cardStyles.scheduleClass} cursor-pointer transition-all ${
                                    selectedCourse?.course_code === c.course_code 
                                        ? 'ring-2 ring-primary bg-primary/10' 
                                        : 'hover:bg-secondary/70'
                                }`}
                                onClick={() => setSelectedCourse(c)}
                            >
                                <div className={cardStyles.scheduleClassInfo}>
                                    <div className={cardStyles.scheduleClassTime}>
                                        <Clock className="h-4 w-4" />
                                    </div>
                                    <div>
                                        <p className="font-medium text-card-foreground">{c.course_code}</p>
                                        <p className="text-sm text-muted-foreground">{c.title}</p>
                                        <div className="text-sm text-muted-foreground mt-1">
                                            {c.meeting_pattern && <div>Schedule: {c.meeting_pattern}</div>}
                                            {c.instructor && <div>Instructor: {c.instructor}</div>}
                                            <div>{c.credits} credits • {c.term} • Status: {c.status}</div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        ))}
                    </div>
                </div>
            </div>
        </div>
    );
}
