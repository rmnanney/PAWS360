"use client";

import React from "react";
import { useRouter } from "next/navigation";
import { ArrowLeft, AlertCircle, CheckCircle, ShoppingCart } from "lucide-react";
import s from "../../homepage/styles.module.css";
import cardStyles from "../../components/Card/styles.module.css";
import { API_BASE } from "@/lib/api";

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

type ValidationResult = {
    valid: boolean;
    errors?: string[];
    warnings?: string[];
    courseDetails?: any;
};

type EnrollmentStatus = {
    [key: string]: {
        validating: boolean;
        enrolling: boolean;
        validation: ValidationResult | null;
        enrolled: boolean;
        error: string | null;
    };
};

export default function EnrollmentPage() {
    const router = useRouter();
    const { toast } = require("@/hooks/useToast");
    const [cart, setCart] = React.useState<CourseResult[]>([]);
    const [studentId, setStudentId] = React.useState<number>(1); // TODO: Get from session
    const [enrollmentStatus, setEnrollmentStatus] = React.useState<EnrollmentStatus>({});
    const [validatingAll, setValidatingAll] = React.useState(false);

    React.useEffect(() => {
        // Load cart from localStorage
        const cartKey = "enrollment_cart";
        const existingCart = localStorage.getItem(cartKey);
        if (existingCart) {
            const cartItems: CourseResult[] = JSON.parse(existingCart);
            setCart(cartItems);
            
            // Initialize status for each course
            const initialStatus: EnrollmentStatus = {};
            cartItems.forEach((course) => {
                const key = getCourseKey(course);
                initialStatus[key] = {
                    validating: false,
                    enrolling: false,
                    validation: null,
                    enrolled: false,
                    error: null,
                };
            });
            setEnrollmentStatus(initialStatus);
        }
    }, []);

    const getCourseKey = (course: CourseResult) => 
        `${course.course_code}-${course.instructor || 'TBD'}-${course.meeting_pattern || 'TBD'}`;

    const validateCourse = async (course: CourseResult) => {
        const key = getCourseKey(course);
        
        setEnrollmentStatus(prev => ({
            ...prev,
            [key]: { ...prev[key], validating: true, error: null }
        }));

        try {
            const response = await fetch(`${API_BASE}/api/enrollment/validate`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    studentId,
                    courseCode: course.course_code,
                    instructor: course.instructor,
                    meetingPattern: course.meeting_pattern,
                }),
            });

            const result: ValidationResult = await response.json();
            
            setEnrollmentStatus(prev => ({
                ...prev,
                [key]: { ...prev[key], validating: false, validation: result }
            }));

            return result;
        } catch (error) {
            const errorMsg = "Failed to validate course";
            setEnrollmentStatus(prev => ({
                ...prev,
                [key]: { ...prev[key], validating: false, error: errorMsg }
            }));
            return null;
        }
    };

    const validateAll = async () => {
        setValidatingAll(true);
        
        for (const course of cart) {
            await validateCourse(course);
        }
        
        setValidatingAll(false);
        toast({ title: "Validation complete", description: "Check each course for enrollment eligibility" });
    };

    const enrollInCourse = async (course: CourseResult) => {
        const key = getCourseKey(course);
        
        // Validate first if not already validated
        if (!enrollmentStatus[key]?.validation) {
            const validation = await validateCourse(course);
            if (!validation?.valid) {
                toast({ 
                    variant: "destructive", 
                    title: "Cannot enroll", 
                    description: "Course did not pass validation checks" 
                });
                return;
            }
        }

        setEnrollmentStatus(prev => ({
            ...prev,
            [key]: { ...prev[key], enrolling: true, error: null }
        }));

        try {
            const response = await fetch(`${API_BASE}/api/enrollment/enroll`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    studentId,
                    courseCode: course.course_code,
                    instructor: course.instructor,
                    meetingPattern: course.meeting_pattern,
                }),
            });

            const result = await response.json();
            
            if (result.success) {
                setEnrollmentStatus(prev => ({
                    ...prev,
                    [key]: { ...prev[key], enrolling: false, enrolled: true }
                }));
                
                toast({ 
                    title: "Enrollment successful", 
                    description: `Successfully enrolled in ${course.course_code}` 
                });

                // Remove from cart
                removeFromCart(course);
            } else {
                setEnrollmentStatus(prev => ({
                    ...prev,
                    [key]: { ...prev[key], enrolling: false, error: result.error }
                }));
                
                toast({ 
                    variant: "destructive", 
                    title: "Enrollment failed", 
                    description: result.error 
                });
            }
        } catch (error) {
            const errorMsg = "Failed to enroll in course";
            setEnrollmentStatus(prev => ({
                ...prev,
                [key]: { ...prev[key], enrolling: false, error: errorMsg }
            }));
            
            toast({ variant: "destructive", title: "Error", description: errorMsg });
        }
    };

    const removeFromCart = (course: CourseResult) => {
        const key = getCourseKey(course);
        const updatedCart = cart.filter(c => getCourseKey(c) !== key);
        setCart(updatedCart);
        localStorage.setItem("enrollment_cart", JSON.stringify(updatedCart));
        
        // Remove from status
        setEnrollmentStatus(prev => {
            const updated = { ...prev };
            delete updated[key];
            return updated;
        });
    };

    if (cart.length === 0) {
        return (
            <div className={s.contentWrapper}>
                <div className={s.mainGrid}>
                    <div className={s.scheduleCard}>
                        <button 
                            onClick={() => router.push('/courses')}
                            className="flex items-center gap-1 text-sm text-primary hover:underline mb-4"
                        >
                            <ArrowLeft className="h-4 w-4" />
                            Back to Courses
                        </button>
                        
                        <div className="text-center py-8">
                            <ShoppingCart className="h-12 w-12 mx-auto text-muted-foreground mb-4" />
                            <p className="text-muted-foreground">Your enrollment cart is empty</p>
                            <button
                                onClick={() => router.push('/courses/search')}
                                className="mt-4 px-4 py-2 bg-primary text-primary-foreground rounded-md hover:bg-primary/90"
                            >
                                Search for Courses
                            </button>
                        </div>
                    </div>
                </div>
            </div>
        );
    }

    return (
        <div className={s.contentWrapper}>
            <div className={s.mainGrid}>
                <div className={s.scheduleCard}>
                    <div className="flex items-center justify-between mb-6">
                        <div>
                            <button 
                                onClick={() => router.push('/courses')}
                                className="flex items-center gap-1 text-sm text-primary hover:underline mb-2"
                            >
                                <ArrowLeft className="h-4 w-4" />
                                Back to Courses
                            </button>
                            <h2 className={cardStyles.scheduleTitle}>Enrollment Review</h2>
                            <p className="text-sm text-muted-foreground mt-1">
                                Review and validate courses before enrolling
                            </p>
                        </div>
                        
                        <button
                            onClick={validateAll}
                            disabled={validatingAll}
                            className="px-4 py-2 bg-secondary text-secondary-foreground rounded-md hover:bg-secondary/80 disabled:opacity-50"
                        >
                            {validatingAll ? "Validating..." : "Validate All"}
                        </button>
                    </div>

                    <div className="space-y-4">
                        {cart.map((course) => {
                            const key = getCourseKey(course);
                            const status = enrollmentStatus[key];
                            const validation = status?.validation;

                            return (
                                <div 
                                    key={key} 
                                    className="border rounded-lg p-4 bg-card"
                                >
                                    <div className="flex justify-between items-start mb-3">
                                        <div>
                                            <h3 className="font-semibold text-lg">{course.course_code}</h3>
                                            <p className="text-sm text-muted-foreground">{course.title}</p>
                                            <div className="text-sm text-muted-foreground mt-1">
                                                <div>Instructor: {course.instructor}</div>
                                                <div>Schedule: {course.meeting_pattern}</div>
                                                <div>{course.credits} credits • {course.term}</div>
                                            </div>
                                        </div>
                                        
                                        <div className="flex gap-2">
                                            {!status?.enrolled && (
                                                <>
                                                    <button
                                                        onClick={() => validateCourse(course)}
                                                        disabled={status?.validating}
                                                        className="px-3 py-1 text-sm bg-secondary text-secondary-foreground rounded hover:bg-secondary/80 disabled:opacity-50"
                                                    >
                                                        {status?.validating ? "Checking..." : "Validate"}
                                                    </button>
                                                    
                                                    <button
                                                        onClick={() => enrollInCourse(course)}
                                                        disabled={status?.enrolling || status?.validating || (validation ? !validation.valid : false)}
                                                        className="px-3 py-1 text-sm bg-primary text-primary-foreground rounded hover:bg-primary/90 disabled:opacity-50"
                                                    >
                                                        {status?.enrolling ? "Enrolling..." : "Enroll"}
                                                    </button>
                                                    
                                                    <button
                                                        onClick={() => removeFromCart(course)}
                                                        className="px-3 py-1 text-sm border rounded hover:bg-secondary/50"
                                                    >
                                                        Remove
                                                    </button>
                                                </>
                                            )}
                                            
                                            {status?.enrolled && (
                                                <div className="flex items-center gap-2 text-sm text-green-600">
                                                    <CheckCircle className="h-4 w-4" />
                                                    Enrolled
                                                </div>
                                            )}
                                        </div>
                                    </div>

                                    {/* Validation Results */}
                                    {validation && (
                                        <div className="mt-3 pt-3 border-t">
                                            {validation.valid ? (
                                                <div className="flex items-start gap-2 text-sm text-green-600">
                                                    <CheckCircle className="h-4 w-4 mt-0.5" />
                                                    <div>
                                                        <div className="font-medium">Eligible to enroll</div>
                                                        {validation.warnings && validation.warnings.length > 0 && (
                                                            <ul className="mt-1 text-yellow-600 list-disc list-inside">
                                                                {validation.warnings.map((warning, idx) => (
                                                                    <li key={idx}>{warning}</li>
                                                                ))}
                                                            </ul>
                                                        )}
                                                    </div>
                                                </div>
                                            ) : (
                                                <div className="flex items-start gap-2 text-sm text-destructive">
                                                    <AlertCircle className="h-4 w-4 mt-0.5 flex-shrink-0" />
                                                    <div>
                                                        <div className="font-medium">Cannot enroll - requirements not met:</div>
                                                        <ul className="mt-1 list-disc list-inside">
                                                            {validation.errors?.map((error, idx) => (
                                                                <li key={idx}>{error}</li>
                                                            ))}
                                                        </ul>
                                                    </div>
                                                </div>
                                            )}
                                        </div>
                                    )}

                                    {/* Error Display */}
                                    {status?.error && (
                                        <div className="mt-3 pt-3 border-t">
                                            <div className="flex items-start gap-2 text-sm text-destructive">
                                                <AlertCircle className="h-4 w-4 mt-0.5" />
                                                <span>{status.error}</span>
                                            </div>
                                        </div>
                                    )}
                                </div>
                            );
                        })}
                    </div>

                    {cart.length > 0 && (
                        <div className="mt-6 pt-6 border-t">
                            <div className="flex justify-between items-center">
                                <div className="text-sm text-muted-foreground">
                                    Total Credits: {cart.reduce((sum, c) => sum + c.credits, 0)}
                                </div>
                                <div className="text-sm text-muted-foreground">
                                    {cart.length} course{cart.length !== 1 ? 's' : ''} in cart
                                </div>
                            </div>
                        </div>
                    )}
                </div>
            </div>
        </div>
    );
}
