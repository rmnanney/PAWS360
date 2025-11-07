"use client";

import React from "react";
import s from "../../homepage/styles.module.css";
import cardStyles from "../../components/Card/styles.module.css";
import { API_BASE } from "@/lib/api";
import { Clock } from "lucide-react";

type CourseDTO = {
    courseId: number;
    courseCode: string;
    courseName: string;
    department: string;
    sections: Array<{
        sectionId: number;
        sectionCode: string;
        meetingDays?: string[];
        startTime?: string | null;
        endTime?: string | null;
    }>;
};

export default function CourseSearchPage() {
    const [courses, setCourses] = React.useState<CourseDTO[]>([]);
    const [loading, setLoading] = React.useState(false);
    const [query, setQuery] = React.useState({ department: "", courseCode: "", courseName: "", meetingDay: "" });
    const [results, setResults] = React.useState<CourseDTO[]>([]);

    React.useEffect(() => {
        setLoading(true);
        fetch(`${API_BASE}/courses`)
            .then((r) => r.ok ? r.json() : Promise.reject(r))
            .then((data) => {
                setCourses(data || []);
            })
            .catch(() => setCourses([]))
            .finally(() => setLoading(false));
    }, []);

    const normalize = (s?: string) => (s || "").toLowerCase().replace(/[^a-z0-9]/g, "");

    const doSearch = (e?: React.FormEvent) => {
        e?.preventDefault();
        const d = (query.department || "").trim().toLowerCase();
        const code = (query.courseCode || "").trim();
        const name = (query.courseName || "").trim().toLowerCase();
        const day = (query.meetingDay || "").trim().toUpperCase();

        const filtered = courses.filter((c) => {
            if (d && (!c.department || c.department.toLowerCase().indexOf(d) === -1)) return false;
            if (code) {
                // normalize both stored courseCode and the input to ignore spaces/punctuation
                const stored = normalize(c.courseCode);
                const qcode = normalize(code);
                if (!stored || stored.indexOf(qcode) === -1) return false;
            }
            if (name && (!c.courseName || c.courseName.toLowerCase().indexOf(name) === -1)) return false;
            if (day) {
                // match if any section contains the meeting day
                const has = (c.sections || []).some((s) => (s.meetingDays || []).some((md) => (md || "").toUpperCase() === day));
                if (!has) return false;
            }
            return true;
        });
        setResults(filtered);
    };

    return (
        <div className={s.contentWrapper}>
            <div className={s.mainGrid}>
                <div className={s.leftCards}>
                    <div className={cardStyles.scheduleCard}>
                        <h2 className={cardStyles.scheduleTitle}>Course Search</h2>
                        <form onSubmit={doSearch} className="space-y-3 mt-4">
                            <div>
                                <label className="block text-sm font-medium text-muted-foreground">School / Department code</label>
                                <input className="w-full rounded-md border p-2" value={query.department}
                                       onChange={(e) => setQuery({ ...query, department: e.target.value })}
                                       placeholder="e.g. ENGLISH, ELECTRICAL_ENGINEERING, EDUC" />
                            </div>

                            <div>
                                <label className="block text-sm font-medium text-muted-foreground">Course code / id</label>
                                <input className="w-full rounded-md border p-2" value={query.courseCode}
                                       onChange={(e) => setQuery({ ...query, courseCode: e.target.value })}
                                       placeholder="e.g. ELECENG101 or 25618" />
                            </div>

                            <div>
                                <label className="block text-sm font-medium text-muted-foreground">Course name</label>
                                <input className="w-full rounded-md border p-2" value={query.courseName}
                                       onChange={(e) => setQuery({ ...query, courseName: e.target.value })}
                                       placeholder="Partial course title" />
                            </div>

                            <div>
                                <label className="block text-sm font-medium text-muted-foreground">Meeting day</label>
                                <input className="w-full rounded-md border p-2" value={query.meetingDay}
                                       onChange={(e) => setQuery({ ...query, meetingDay: e.target.value })}
                                       placeholder="MONDAY, TUESDAY, etc. (optional)" />
                            </div>

                            <div className="flex gap-2">
                                <button type="submit" className={cardStyles.scheduleViewButton}>Search</button>
                                <button type="button" className={cardStyles.scheduleViewButton} onClick={() => { setQuery({ department: "", courseCode: "", courseName: "", meetingDay: "" }); setResults([]); }}>Clear</button>
                            </div>
                        </form>
                    </div>
                </div>

                <div className={s.scheduleCard}>
                    <div className={cardStyles.scheduleHeader}>
                        <h3 className={cardStyles.scheduleTitle}>Results</h3>
                    </div>

                    <div className="space-y-3">
                        {loading && <div className="text-sm text-muted-foreground">Loading courses…</div>}
                        {!loading && courses.length === 0 && <div className="text-sm text-destructive">No course data loaded from backend — check the API (GET {API_BASE}/courses).</div>}
                        {!loading && courses.length > 0 && results.length === 0 && <div className="text-sm text-muted-foreground">No results. Try broadening your search or click Search to filter.</div>}

                        {results.map((c) => (
                            <div key={c.courseId} className={cardStyles.scheduleClass}>
                                <div className={cardStyles.scheduleClassInfo}>
                                    <div className={cardStyles.scheduleClassTime}>
                                        <Clock className="h-4 w-4" />
                                    </div>
                                    <div>
                                        <p className="font-medium text-card-foreground">{c.courseCode} — {c.courseName}</p>
                                        <p className="text-sm text-muted-foreground">Dept: {c.department}</p>
                                        <div className="text-sm text-muted-foreground">
                                            { (c.sections || []).slice(0,3).map(sec => (
                                                <div key={sec.sectionId}>{sec.sectionCode} — {(sec.meetingDays||[]).join(', ')} {sec.startTime?` ${sec.startTime}-${sec.endTime}`:''}</div>
                                            ))}
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
