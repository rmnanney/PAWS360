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
import { Button } from "../components/Others/button";
import {
	User,
	Mail,
	Phone,
	MapPin,
	Shield,
	Edit,
	Save,
	Eye,
	EyeOff,
	AlertTriangle,
} from "lucide-react";
const { API_BASE } = require("@/lib/api");

// Values are loaded from backend domain endpoints

function labelFor(value: string | null | undefined, list: {value:string;label:string}[]) {
    if (!value) return "";
    const f = list.find((x) => x.value === value);
    if (f) return f.label;
    // Fallback to prettify
    return String(value).toLowerCase().replace(/_/g, " ").replace(/\b\w/g, (m) => m.toUpperCase());
}

export default function PersonalPage() {
	const [isEditing, setIsEditing] = React.useState(false);
	const [showSSN, setShowSSN] = React.useState(false);
	const [user, setUser] = React.useState<any | null>(null);
	const [studentId, setStudentId] = React.useState<number | null>(null);
	const [homeAddress, setHomeAddress] = React.useState<any | null>(null);
	const [mailingAddress, setMailingAddress] = React.useState<any | null>(null);
	const [phoneEdit, setPhoneEdit] = React.useState<string>("");
	const [homeAddrEdit, setHomeAddrEdit] = React.useState<any | null>(null);
	const [mailingAddrEdit, setMailingAddrEdit] = React.useState<any | null>(null);
	const [firstNameEdit, setFirstNameEdit] = React.useState<string>("");
	const [lastNameEdit, setLastNameEdit] = React.useState<string>("");
	const [middleNameEdit, setMiddleNameEdit] = React.useState<string>("");
	const [preferredNameEdit, setPreferredNameEdit] = React.useState<string>("");
	const [genderEdit, setGenderEdit] = React.useState<string>("");
	const [ethnicityEdit, setEthnicityEdit] = React.useState<string>("");
	const [nationalityEdit, setNationalityEdit] = React.useState<string>("");
	const [dobEdit, setDobEdit] = React.useState<string>("");
	const [ssnEdit, setSsnEdit] = React.useState<string>("");
    const [genders, setGenders] = React.useState<Array<{value:string;label:string}>>([]);
	const [ethnicities, setEthnicities] = React.useState<Array<{value:string;label:string}>>([]);
	const [nationalities, setNationalities] = React.useState<Array<{value:string;label:string}>>([]);
	const [preferences, setPreferences] = React.useState<any>({
		ferpa_compliance: "RESTRICTED",
		ferpaDirectory: false,
		photoRelease: false,
		contactByPhone: true,
		contactByEmail: true,
		contactByMail: false,
	});
	const [emergencyContacts, setEmergencyContacts] = React.useState<any[]>([]);
    const [ssnMasked, setSsnMasked] = React.useState<string>("***-**-****");
    const [primaryEmailEdit, setPrimaryEmailEdit] = React.useState<string>("");
    const [altEmailEdit, setAltEmailEdit] = React.useState<string>("");
	const [altPhoneEdit, setAltPhoneEdit] = React.useState<string>("");
	const [profilePicEdit, setProfilePicEdit] = React.useState<string>("");
	const [profilePicFile, setProfilePicFile] = React.useState<File | null>(null);
	const { toast } = require("@/hooks/useToast");
    const [loading, setLoading] = React.useState<boolean>(true);

	// Resolve image URL to absolute when needed
	const resolveImg = (u: string) => {
		if (!u) return "";
		if (/^(https?:|blob:|data:)/.test(u)) return u;
		return `${API_BASE}${u}`;
	};

	React.useEffect(() => {
		const load = async () => {
			try {
				const email = typeof window !== "undefined" ? localStorage.getItem("userEmail") : null;
				if (!email) return;
					const [userRes, sidRes, prefRes, emgRes, genRes, ethRes, natRes] = await Promise.all([
						fetch(`${API_BASE}/users/get?email=${encodeURIComponent(email)}`),
						fetch(`${API_BASE}/users/student-id?email=${encodeURIComponent(email)}`),
						fetch(`${API_BASE}/users/preferences?email=${encodeURIComponent(email)}`),
						fetch(`${API_BASE}/users/emergency-contacts?email=${encodeURIComponent(email)}`),
						fetch(`${API_BASE}/domains/genders`),
						fetch(`${API_BASE}/domains/ethnicities`),
						fetch(`${API_BASE}/domains/nationalities`),
					]);
                if (userRes.ok) {
                    const u = await userRes.json();
                    setUser(u);
					const addrs = Array.isArray(u.addresses) ? u.addresses : [];
					const home = addrs.find((a: any) => (a.address_type || "").toUpperCase() === "HOME");
					const mail = addrs.find((a: any) => (a.address_type || "").toUpperCase() === "MAILING") || addrs.find((a: any) => (a.address_type || "").toUpperCase() === "BILLING");
					setHomeAddress(home || null);
					setMailingAddress(mail || null);
					setPhoneEdit(u?.phone || "");
					setHomeAddrEdit(home ? { ...home } : null);
					setMailingAddrEdit(mail ? { ...mail } : null);
					setFirstNameEdit(u?.firstname || "");
					setLastNameEdit(u?.lastname || "");
					setMiddleNameEdit(u?.middlename || "");
					setPreferredNameEdit(u?.preferred_name || u?.firstname || "");
					setGenderEdit(u?.gender || "");
					setEthnicityEdit(u?.ethnicity || "");
					setNationalityEdit(u?.nationality || "");
                    setDobEdit(u?.dob || "");
                    setPrimaryEmailEdit(u?.email || "");
                    setAltEmailEdit(u?.alternate_email || "");
                    setAltPhoneEdit(u?.alternate_phone || "");
                    setProfilePicEdit(u?.profile_picture_url || "");
                }
				if (sidRes.ok) {
					const sid = await sidRes.json();
					if (typeof sid.student_id === "number" && sid.student_id >= 0) setStudentId(sid.student_id);
				}
				if (prefRes.ok) {
					const p = await prefRes.json();
					setPreferences(p);
				}
				if (emgRes.ok) {
					const list = await emgRes.json();
					setEmergencyContacts(Array.isArray(list) ? list : []);
				}
				if (genRes.ok) setGenders(await genRes.json());
				if (ethRes.ok) setEthnicities(await ethRes.json());
				if (natRes.ok) setNationalities(await natRes.json());
			} catch (e: any) {
				toast({ variant: "destructive", title: "Failed to load profile", description: e?.message || "Try again later." });
			} finally {
				setLoading(false);
			}
		};
		load();
	}, [toast]);

    const personalInfo = {
        studentId: studentId ? String(studentId) : "-",
        firstName: user?.firstname || "",
        lastName: user?.lastname || "",
        preferredName: user?.preferred_name || user?.firstname || "",
        dateOfBirth: user?.dob || "",
        gender: user?.gender || "",
        ethnicity: user?.ethnicity || "",
        citizenship: user?.nationality || "",
        ssn: ssnMasked,
        profilePictureUrl: user?.profile_picture_url || "",
    };

    const contactInfo: any = {
        email: user?.email || "",
        alternateEmail: user?.alternate_email || "",
        phone: user?.phone || "",
        alternatePhone: user?.alternate_phone || "",
        address: homeAddress
			? {
				street: homeAddress.street_address_1,
				city: homeAddress.city,
				state: homeAddress.us_states,
				zipCode: homeAddress.zipcode,
				country: "United States",
			}
			: null,
		permanentAddress: mailingAddress
			? {
				street: mailingAddress.street_address_1,
				city: mailingAddress.city,
				state: mailingAddress.us_states,
				zipCode: mailingAddress.zipcode,
				country: "United States",
			}
			: null,
	};

const privacySettings = {
	ferpaDirectory: preferences.ferpaDirectory,
	photoRelease: preferences.photoRelease,
	infoRelease: String(preferences.ferpa_compliance || 'RESTRICTED').toLowerCase(),
	contactByPhone: preferences.contactByPhone,
	contactByEmail: preferences.contactByEmail,
	contactByMail: preferences.contactByMail,
};

const securityInfo = {
	lastPasswordChange: "2025-09-01",
	twoFactorEnabled: true,
	loginAttempts: 0,
	accountStatus: "Active",
	securityQuestions: true,
};

    // component continues

    const getPrivacyLevelColor = (level: string) => {
        switch (level) {
            case "public":
                return "bg-green-100 text-green-800";
            case "restricted":
                return "bg-yellow-100 text-yellow-800";
            case "private":
                return "bg-red-100 text-red-800";
            default:
                return "bg-gray-100 text-gray-800";
        }
    };

    // Text-only color (no background) for inline privacy labels
    const getPrivacyTextColor = (level: string) => {
        switch (level) {
            case "public":
                return "text-green-800";
            case "restricted":
                return "text-yellow-800";
            case "private":
                return "text-red-800";
            default:
                return "text-gray-800";
        }
    };

	const getStatusColor = (status: string) => {
		switch (status) {
			case "Active":
				return "bg-green-100 text-green-800";
			case "Inactive":
				return "bg-red-100 text-red-800";
			case "Suspended":
				return "bg-orange-100 text-orange-800";
			default:
				return "bg-gray-100 text-gray-800";
		}
	};

	if (loading) {
		return (
			<div className="flex-1 space-y-4 p-4 md:p-8 pt-6">
				<div className="flex items-center justify-center text-sm text-muted-foreground" style={{ minHeight: 160 }}>
					<span className="inline-flex items-center gap-2"><Spinner size="sm" /> Loading profile…</span>
				</div>
			</div>
		);
	}

	return (
		<div className="flex-1 space-y-4 p-4 md:p-8 pt-6">
			<div className="flex items-center justify-between space-y-2">
				<h2 className="text-3xl font-bold tracking-tight">
					Personal Information
				</h2>
				<div className="flex items-center space-x-2">
					<Button
						variant={isEditing ? "default" : "outline"}
						size="sm"
						onClick={async () => {
							if (!isEditing) { setIsEditing(true); return; }
							try {
								const email = typeof window !== "undefined" ? localStorage.getItem("userEmail") : null;
								if (!email) return;
								// Basic validation
                                if (!firstNameEdit || !lastNameEdit) {
                                    toast({ variant: "destructive", title: "Missing required fields", description: "First and last name are required." });
                                    return;
                                }
                                if (phoneEdit && !/^\+?[0-9\-\s]{7,20}$/.test(phoneEdit)) {
                                    toast({ variant: "destructive", title: "Invalid phone", description: "Enter a valid phone number." });
                                    return;
                                }
                                if (dobEdit) {
                                    const d = new Date(dobEdit);
                                    const min = new Date('1900-01-01');
                                    const now = new Date();
                                    if (!(d instanceof Date) || isNaN(d.getTime()) || d < min || d > now) {
                                        toast({ variant: "destructive", title: "Invalid date of birth", description: "Enter a valid date between 1900 and today." });
                                        return;
                                    }
                                }
                                const checkAddr = (a: any) => {
									if (!a) return true;
									const f = [a.street_address_1, a.city, a.us_states, a.zipcode];
									const any = f.some((x) => !!x);
									const all = f.every((x) => x !== undefined && x !== null && String(x).trim() !== "");
									return !any || all;
								};
								if (!checkAddr(homeAddrEdit) || !checkAddr(mailingAddrEdit)) {
									toast({ variant: "destructive", title: "Incomplete address", description: "Street, city, state, and zip are required for addresses." });
									return;
								}

								// Update personal details first
								const ssnDigits = ssnEdit ? ssnEdit.replace(/\D/g, "") : null;
                                // If a new profile picture file is selected, upload it first
                                if (profilePicFile) {
                                    const form = new FormData();
                                    form.append("email", email);
                                    form.append("file", profilePicFile);
                                    const upRes = await fetch(`${API_BASE}/users/profile-picture`, { method: "POST", body: form });
                                    if (!upRes.ok) {
                                        toast({ variant: "destructive", title: "Failed to upload profile picture", description: "Please choose a valid image (png, jpg, webp) under 5MB." });
                                        return;
                                    }
                                    const up = await upRes.json();
                                    if (up?.url) {
                                        setProfilePicEdit(up.url);
                                    }
                                }

                                const personalRes = await fetch(`${API_BASE}/users/personal`, { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ email, firstname: firstNameEdit, middlename: middleNameEdit || null, lastname: lastNameEdit, preferredName: preferredNameEdit || null, gender: genderEdit || null, ethnicity: ethnicityEdit || null, nationality: nationalityEdit || null, dob: dobEdit || null, ssn: ssnDigits }) });
								if (!personalRes.ok) {
									toast({ variant: "destructive", title: "Failed to update name", description: "Please check inputs and try again." });
									return;
								}
								await fetch(`${API_BASE}/users/preferences`, { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ email, ...preferences }) });
								// Upsert HOME address
								if (homeAddrEdit && homeAddrEdit.street_address_1) {
									const payload = {
										id: homeAddrEdit.id || null,
										address_type: "HOME",
										street_address_1: homeAddrEdit.street_address_1,
										street_address_2: homeAddrEdit.street_address_2 || null,
										po_box: homeAddrEdit.po_box || null,
										city: homeAddrEdit.city,
										us_states: homeAddrEdit.us_states,
										zipcode: homeAddrEdit.zipcode,
									};
									if (homeAddrEdit.id) {
										await fetch(`${API_BASE}/users/addresses/edit`, { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ address_id: homeAddrEdit.id, address: payload }) });
									} else {
										await fetch(`${API_BASE}/users/addresses/add`, { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ email, address: payload }) });
									}
								}
								// Upsert MAILING address
								if (mailingAddrEdit && mailingAddrEdit.street_address_1) {
									const payload = {
										id: mailingAddrEdit.id || null,
										address_type: "MAILING",
										street_address_1: mailingAddrEdit.street_address_1,
										street_address_2: mailingAddrEdit.street_address_2 || null,
										po_box: mailingAddrEdit.po_box || null,
										city: mailingAddrEdit.city,
										us_states: mailingAddrEdit.us_states,
										zipcode: mailingAddrEdit.zipcode,
									};
									if (mailingAddrEdit.id) {
										await fetch(`${API_BASE}/users/addresses/edit`, { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ address_id: mailingAddrEdit.id, address: payload }) });
									} else {
										await fetch(`${API_BASE}/users/addresses/add`, { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ email, address: payload }) });
									}
								}
								for (const c of emergencyContacts) {
									const body = { email, contact_id: c.id || null, name: c.name, relationship: c.relationship || null, contact_email: c.email || null, phone: c.phone || null, street_address_1: c.street_address_1 || null, street_address_2: c.street_address_2 || null, city: c.city || null, us_states: c.us_states || null, zipcode: c.zipcode || null };
									await fetch(`${API_BASE}/users/emergency-contacts`, { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(body) });
								}
                                // Now update contact info (do this last so earlier updates still find user by email)
                                const contactRes = await fetch(`${API_BASE}/users/contact`, { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ email, phone: phoneEdit || null, newEmail: primaryEmailEdit || null, alternateEmail: altEmailEdit || null, alternatePhone: altPhoneEdit || null }) });
                                if (contactRes && contactRes.ok && primaryEmailEdit && primaryEmailEdit !== email) {
                                    try { if (typeof window !== 'undefined') localStorage.setItem('userEmail', primaryEmailEdit); } catch {}
                                }
                                // Reflect changes locally
                                setUser((prev: any) => ({ ...(prev || {}), firstname: firstNameEdit, middlename: middleNameEdit, lastname: lastNameEdit, preferred_name: preferredNameEdit, profile_picture_url: profilePicEdit, gender: genderEdit, ethnicity: ethnicityEdit, nationality: nationalityEdit, dob: dobEdit || prev?.dob, email: primaryEmailEdit || prev?.email, phone: phoneEdit, alternate_email: altEmailEdit, alternate_phone: altPhoneEdit }));
								setHomeAddress(homeAddrEdit);
								setMailingAddress(mailingAddrEdit);
								toast({ title: "Profile Updated", description: "Your changes have been saved." });
								setIsEditing(false);
							} catch (e: any) {
								toast({ variant: "destructive", title: "Update failed", description: e?.message || "Try again later." });
							}
						}}
					>
						{isEditing ? (
							<>
								<Save className="mr-2 h-4 w-4" />
								Save Changes
							</>
						) : (
							<>
								<Edit className="mr-2 h-4 w-4" />
								Edit Profile
							</>
						)}
					</Button>
				</div>
			</div>

			{/* Personal Overview Cards */}
			<div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
				<Card>
					<CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
						<CardTitle className="text-sm font-medium">Student ID</CardTitle>
						<User className="h-4 w-4 text-muted-foreground" />
					</CardHeader>
					<CardContent>
						<div className="text-2xl font-bold">{personalInfo.studentId}</div>
						<p className="text-xs text-muted-foreground">Active Student</p>
					</CardContent>
				</Card>

				<Card>
					<CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
						<CardTitle className="text-sm font-medium">Full Name</CardTitle>
						<User className="h-4 w-4 text-muted-foreground" />
					</CardHeader>
					<CardContent>
						<div className="flex items-center gap-4">
							<div className="w-16 h-16 rounded-full bg-gray-100 overflow-hidden flex items-center justify-center">
								{personalInfo.profilePictureUrl ? (
									// eslint-disable-next-line @next/next/no-img-element
									<img src={resolveImg(personalInfo.profilePictureUrl)} alt="Profile" className="w-full h-full object-cover" />
								) : (
									<span className="text-lg text-muted-foreground">
										{(personalInfo.firstName || "").charAt(0)}{(personalInfo.lastName || "").charAt(0)}
									</span>
								)}
							</div>
							<div className="text-2xl font-bold">
								{personalInfo.firstName} {personalInfo.lastName}
							</div>
						</div>
						<p className="text-xs text-muted-foreground">
							Preferred: {personalInfo.preferredName}
						</p>
					</CardContent>
				</Card>

				<Card>
					<CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
						<CardTitle className="text-sm font-medium">Contact</CardTitle>
						<Mail className="h-4 w-4 text-muted-foreground" />
					</CardHeader>
					<CardContent>
                        <div className="text-2xl font-bold">
                            {contactInfo.email ? String(contactInfo.email).split("@")[0] : ""}
                        </div>
                        <p className="text-xs text-muted-foreground">{contactInfo.email ? `@${String(contactInfo.email).split("@")[1]}` : ""}</p>
					</CardContent>
				</Card>

				<Card>
					<CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
						<CardTitle className="text-sm font-medium">Privacy Level</CardTitle>
						<Shield className="h-4 w-4 text-muted-foreground" />
					</CardHeader>
                    <CardContent>
                        <div className={`text-2xl font-bold ${getPrivacyTextColor(privacySettings.infoRelease)}`}>
                            {(() => {
                                const lvl = privacySettings.infoRelease || 'restricted';
                                return lvl.charAt(0).toUpperCase() + lvl.slice(1);
                            })()}
                        </div>
                        <p className="text-xs text-muted-foreground">FERPA Privacy</p>
                    </CardContent>
                </Card>
			</div>

			{/* Main Content Tabs */}
			<Tabs defaultValue="personal" className="space-y-4">
				<TabsList>
					<TabsTrigger value="personal">Personal Details</TabsTrigger>
					<TabsTrigger value="contact">Contact Information</TabsTrigger>
					<TabsTrigger value="emergency">Emergency Contacts</TabsTrigger>
					<TabsTrigger value="privacy">Privacy & Security</TabsTrigger>
				</TabsList>

				<TabsContent value="personal" className="space-y-4">
					<Card>
						<CardHeader>
							<CardTitle>Personal Information</CardTitle>
							<CardDescription>
								Your basic personal and demographic information
							</CardDescription>
						</CardHeader>
						<CardContent className="space-y-6">
                        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                            <div className="space-y-4">
                                <div>
                                    <label className="text-sm font-medium">Profile Picture</label>
                                    <div className="flex items-center gap-4 mt-2">
                                        <div className="w-16 h-16 rounded-full bg-gray-100 overflow-hidden flex items-center justify-center">
                                            { (isEditing ? profilePicEdit : personalInfo.profilePictureUrl) ? (
                                                // eslint-disable-next-line @next/next/no-img-element
                                                <img src={resolveImg((isEditing ? profilePicEdit : personalInfo.profilePictureUrl) || '')} alt="Profile" className="w-full h-full object-cover" />
                                            ) : (
                                                <span className="text-xs text-muted-foreground">No image</span>
                                            )}
                                        </div>
                                        {isEditing && (
                                            <input
                                                type="file"
                                                accept="image/png,image/jpeg,image/jpg,image/webp"
                                                className="flex-1 border rounded-md p-2"
                                                onChange={(e) => {
                                                    const f = e.target.files?.[0] || null;
                                                    setProfilePicFile(f);
                                                    if (f) {
                                                        try { setProfilePicEdit(URL.createObjectURL(f)); } catch {}
                                                    }
                                                }}
                                            />
                                        )}
                                    </div>
                                </div>
                                <div>
                                    <label className="text-sm font-medium">Student ID</label>
                                    <p className="text-lg font-semibold">
                                        {personalInfo.studentId}
                                    </p>
                                </div>
                            <div>
                                <label className="text-sm font-medium">First Name</label>
                                {isEditing ? (
                                    <input className="w-full border rounded-md p-2" value={firstNameEdit} onChange={(e) => setFirstNameEdit(e.target.value)} />
                                ) : (
                                    <p className="text-lg">{personalInfo.firstName}</p>
                                )}
                            </div>
                            <div>
                                <label className="text-sm font-medium">Last Name</label>
                                {isEditing ? (
                                    <input className="w-full border rounded-md p-2" value={lastNameEdit} onChange={(e) => setLastNameEdit(e.target.value)} />
                                ) : (
                                    <p className="text-lg">{personalInfo.lastName}</p>
                                )}
                            </div>
                            <div>
                                <label className="text-sm font-medium">Preferred Name</label>
                                {isEditing ? (
                                    <input className="w-full border rounded-md p-2" value={preferredNameEdit} onChange={(e) => setPreferredNameEdit(e.target.value)} />
                                ) : (
                                    <p className="text-lg">{personalInfo.preferredName}</p>
                                )}
                            </div>
								</div>
								<div className="space-y-4">
                            <div>
                                <label className="text-sm font-medium">Date of Birth</label>
                                {isEditing ? (
                                    <input type="date" className="w-full border rounded-md p-2" value={dobEdit || ""} onChange={(e) => setDobEdit(e.target.value)} />
                                ) : (
                                    <p className="text-lg">{personalInfo.dateOfBirth}</p>
                                )}
                            </div>
                            <div>
                                <label className="text-sm font-medium">Gender</label>
                                {isEditing ? (
                                    <select className="w-full border rounded-md p-2" value={genderEdit || ""} onChange={(e) => setGenderEdit(e.target.value)}>
                                        <option value="">Select...</option>
                                        {genders.map((g) => (
                                            <option key={g.value} value={g.value}>{g.label}</option>
                                        ))}
                                    </select>
                                ) : (
                                    <p className="text-lg">{labelFor(user?.gender, genders)}</p>
                                )}
                            </div>
                            <div>
                                <label className="text-sm font-medium">Ethnicity</label>
                                {isEditing ? (
                                    <select className="w-full border rounded-md p-2" value={ethnicityEdit || ""} onChange={(e) => setEthnicityEdit(e.target.value)}>
                                        <option value="">Select...</option>
                                        {ethnicities.map((e1) => (
                                            <option key={e1.value} value={e1.value}>{e1.label}</option>
                                        ))}
                                    </select>
                                ) : (
                                    <p className="text-lg">{labelFor(user?.ethnicity, ethnicities)}</p>
                                )}
                            </div>
                            <div>
                                <label className="text-sm font-medium">Citizenship</label>
                                {isEditing ? (
                                    <select className="w-full border rounded-md p-2" value={nationalityEdit || ""} onChange={(e) => setNationalityEdit(e.target.value)}>
                                        <option value="">Select...</option>
                                        {nationalities.map((n) => (
                                            <option key={n.value} value={n.value}>{n.label}</option>
                                        ))}
                                    </select>
                                ) : (
                                    <p className="text-lg">{labelFor(user?.nationality, nationalities)}</p>
                                )}
                            </div>
                            {/* SSN display with last 4 when unhidden; input when editing */}
                            <div>
                                <label className="text-sm font-medium">Social Security Number</label>
                                {isEditing ? (
                                    <input
                                        className="w-full border rounded-md p-2 font-mono"
                                        placeholder="123-45-6789"
                                        value={ssnEdit}
                                        onChange={(e) => setSsnEdit(e.target.value)}
                                    />
                                ) : (
                                    <div className="flex items-center gap-2">
                                        <p className="text-lg font-mono">{showSSN ? personalInfo.ssn : "XXX-XX-XXXX"}</p>
                                        {showSSN ? (
                                            <EyeOff className="h-4 w-4 cursor-pointer" onClick={() => setShowSSN(false)} />
                                        ) : (
                                            <Eye className="h-4 w-4 cursor-pointer" onClick={async () => {
                                                try {
                                                    const email = typeof window !== "undefined" ? localStorage.getItem("userEmail") : null;
                                                    if (!email) { setShowSSN(true); return; }
                                                    const res = await fetch(`${API_BASE}/users/ssn-last4?email=${encodeURIComponent(email)}`);
                                                    if (res.ok) {
                                                        const data = await res.json();
                                                        const last4 = data?.last4 || "XXXX";
                                                        setSsnMasked(`XXX-XX-${last4}`);
                                                    }
                                                } catch {}
                                                setShowSSN(true);
                                            }} />
                                        )}
                                    </div>
                                )}
                            </div>
								</div>
                        </div>
						</CardContent>
					</Card>
				</TabsContent>

				<TabsContent value="contact" className="space-y-4">
					<div className="grid gap-4 md:grid-cols-2">
						<Card>
							<CardHeader>
								<CardTitle>Campus Contact Information</CardTitle>
								<CardDescription>
									Your primary contact details for university communications
								</CardDescription>
							</CardHeader>
							<CardContent className="space-y-4">
                            <div className="flex items-center space-x-3">
                                <Mail className="h-5 w-5 text-blue-600" />
                                <div className="w-full">
                                    <p className="font-medium">Primary Email</p>
                                    {isEditing ? (
                                        <input className="w-full border rounded-md p-2" value={primaryEmailEdit} onChange={(e) => setPrimaryEmailEdit(e.target.value)} />
                                    ) : (
                                        <p className="text-sm text-muted-foreground">{contactInfo.email}</p>
                                    )}
                                </div>
                            </div>
                            <div className="flex items-center space-x-3">
                                <Mail className="h-5 w-5 text-gray-600" />
                                <div className="w-full">
                                    <p className="font-medium">Alternate Email</p>
                                    {isEditing ? (
                                        <input className="w-full border rounded-md p-2" value={altEmailEdit} onChange={(e) => setAltEmailEdit(e.target.value)} />
                                    ) : (
                                        <p className="text-sm text-muted-foreground">{contactInfo.alternateEmail}</p>
                                    )}
                                </div>
                            </div>
								<div className="flex items-center space-x-3">
									<Phone className="h-5 w-5 text-green-600" />
                            <div className="w-full">
                                <p className="font-medium">Primary Phone</p>
                                {isEditing ? (
                                    <input className="w-full border rounded-md p-2" value={phoneEdit} onChange={(e) => setPhoneEdit(e.target.value)} />
                                ) : (
                                    <p className="text-sm text-muted-foreground">{contactInfo.phone}</p>
                                )}
                            </div>
                        </div>
                        <div className="flex items-center space-x-3">
                            <Phone className="h-5 w-5 text-gray-600" />
                            <div className="w-full">
                                <p className="font-medium">Alternate Phone</p>
                                {isEditing ? (
                                    <input className="w-full border rounded-md p-2" value={altPhoneEdit} onChange={(e) => setAltPhoneEdit(e.target.value)} />
                                ) : (
                                    <p className="text-sm text-muted-foreground">{contactInfo.alternatePhone}</p>
                                )}
                            </div>
                        </div>
							</CardContent>
						</Card>

						<Card>
							<CardHeader>
								<CardTitle>Addresses</CardTitle>
								<CardDescription>
									Your current and permanent addresses
								</CardDescription>
							</CardHeader>
							<CardContent className="space-y-6">
								<div>
									<h3 className="font-semibold mb-2">Campus Address</h3>
									<div className="flex items-start space-x-3">
										<MapPin className="h-5 w-5 text-blue-600 mt-0.5" />
                                <div className="text-sm">
                                    {isEditing ? (
                                        <div className="space-y-2 w-full">
                                            <input className="w-full border rounded-md p-2" placeholder="Street" value={homeAddrEdit?.street_address_1 || ""} onChange={(e) => setHomeAddrEdit({ ...(homeAddrEdit||{}), street_address_1: e.target.value })} />
                                            <input className="w-full border rounded-md p-2" placeholder="Street 2" value={homeAddrEdit?.street_address_2 || ""} onChange={(e) => setHomeAddrEdit({ ...(homeAddrEdit||{}), street_address_2: e.target.value })} />
                                            <div className="grid grid-cols-3 gap-2">
                                                <input className="border rounded-md p-2" placeholder="City" value={homeAddrEdit?.city || ""} onChange={(e) => setHomeAddrEdit({ ...(homeAddrEdit||{}), city: e.target.value })} />
                                                <input className="border rounded-md p-2" placeholder="State" value={homeAddrEdit?.us_states || ""} onChange={(e) => setHomeAddrEdit({ ...(homeAddrEdit||{}), us_states: e.target.value })} />
                                                <input className="border rounded-md p-2" placeholder="Zip" value={homeAddrEdit?.zipcode || ""} onChange={(e) => setHomeAddrEdit({ ...(homeAddrEdit||{}), zipcode: e.target.value })} />
                                            </div>
                                        </div>
                                    ) : contactInfo.address ? (
                                        <>
                                            <p>{contactInfo.address.street}</p>
                                            <p>
                                                {contactInfo.address.city}, {contactInfo.address.state} {contactInfo.address.zipCode}
                                            </p>
                                            <p>{contactInfo.address.country}</p>
                                        </>
                                    ) : (
                                        <p className="text-muted-foreground">No campus address on file</p>
                                    )}
                                </div>
									</div>
								</div>
								<div>
									<h3 className="font-semibold mb-2">Permanent Address</h3>
									<div className="flex items-start space-x-3">
										<MapPin className="h-5 w-5 text-green-600 mt-0.5" />
                                <div className="text-sm">
                                    {isEditing ? (
                                        <div className="space-y-2 w-full">
                                            <input className="w-full border rounded-md p-2" placeholder="Street" value={mailingAddrEdit?.street_address_1 || ""} onChange={(e) => setMailingAddrEdit({ ...(mailingAddrEdit||{}), street_address_1: e.target.value })} />
                                            <input className="w-full border rounded-md p-2" placeholder="Street 2" value={mailingAddrEdit?.street_address_2 || ""} onChange={(e) => setMailingAddrEdit({ ...(mailingAddrEdit||{}), street_address_2: e.target.value })} />
                                            <div className="grid grid-cols-3 gap-2">
                                                <input className="border rounded-md p-2" placeholder="City" value={mailingAddrEdit?.city || ""} onChange={(e) => setMailingAddrEdit({ ...(mailingAddrEdit||{}), city: e.target.value })} />
                                                <input className="border rounded-md p-2" placeholder="State" value={mailingAddrEdit?.us_states || ""} onChange={(e) => setMailingAddrEdit({ ...(mailingAddrEdit||{}), us_states: e.target.value })} />
                                                <input className="border rounded-md p-2" placeholder="Zip" value={mailingAddrEdit?.zipcode || ""} onChange={(e) => setMailingAddrEdit({ ...(mailingAddrEdit||{}), zipcode: e.target.value })} />
                                            </div>
                                        </div>
                                    ) : contactInfo.permanentAddress ? (
                                        <>
                                            <p>{contactInfo.permanentAddress.street}</p>
                                            <p>
                                                {contactInfo.permanentAddress.city}, {contactInfo.permanentAddress.state} {contactInfo.permanentAddress.zipCode}
                                            </p>
                                            <p>{contactInfo.permanentAddress.country}</p>
                                        </>
                                    ) : (
                                        <p className="text-muted-foreground">No permanent address on file</p>
                                    )}
                                </div>
									</div>
								</div>
							</CardContent>
						</Card>
					</div>
				</TabsContent>

				<TabsContent value="emergency" className="space-y-4">
					<Card>
						<CardHeader>
							<CardTitle>Emergency Contacts</CardTitle>
							<CardDescription>
								Important contacts for emergency situations
							</CardDescription>
						</CardHeader>
						<CardContent>
							<div className="space-y-6">
								{emergencyContacts.map((contact, index) => (
									<div key={index} className="border rounded-lg p-4">
										<div className="flex justify-end mb-2">
											{isEditing ? (
												<button
													className="text-sm text-red-600"
													onClick={async () => {
														if (contact.id) {
															try {
																await fetch(`${API_BASE}/users/emergency-contacts/delete`, { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ contact_id: contact.id }) });
															} catch {}
														}
														setEmergencyContacts((prev) => prev.filter((_, i) => i !== index));
													}}
												>
													Delete
												</button>
											) : null}
										</div>
										<div className="grid grid-cols-1 md:grid-cols-2 gap-4">
											<div>
												<label className="text-sm font-medium">Name</label>
												{isEditing ? (
													<input className="w-full border rounded-md p-2" value={contact.name || ""} onChange={(e) => { const u=[...emergencyContacts]; u[index] = { ...u[index], name: e.target.value }; setEmergencyContacts(u);} } />
												) : (
													<p className="text-lg">{contact.name}</p>
												)}
											</div>
											<div>
												<label className="text-sm font-medium">Relationship</label>
												{isEditing ? (
													<input className="w-full border rounded-md p-2" value={contact.relationship || ""} onChange={(e) => { const u=[...emergencyContacts]; u[index] = { ...u[index], relationship: e.target.value }; setEmergencyContacts(u);} } />
												) : (
													<p className="text-lg">{contact.relationship}</p>
												)}
											</div>
											<div>
												<label className="text-sm font-medium">Phone</label>
												{isEditing ? (
													<input className="w-full border rounded-md p-2" value={contact.phone || ""} onChange={(e) => { const u=[...emergencyContacts]; u[index] = { ...u[index], phone: e.target.value }; setEmergencyContacts(u);} } />
												) : (
													<p className="text-lg">{contact.phone}</p>
												)}
											</div>
											<div>
												<label className="text-sm font-medium">Email</label>
												{isEditing ? (
													<input className="w-full border rounded-md p-2" value={contact.email || ""} onChange={(e) => { const u=[...emergencyContacts]; u[index] = { ...u[index], email: e.target.value }; setEmergencyContacts(u);} } />
												) : (
													<p className="text-lg">{contact.email}</p>
												)}
											</div>
											<div className="md:col-span-2">
												<label className="text-sm font-medium">Address</label>
												{isEditing ? (
													<div className="space-y-2">
														<input className="w-full border rounded-md p-2" placeholder="Street" value={contact.street_address_1 || ""} onChange={(e) => { const u=[...emergencyContacts]; u[index] = { ...u[index], street_address_1: e.target.value }; setEmergencyContacts(u);} } />
														<input className="w-full border rounded-md p-2" placeholder="Street 2" value={contact.street_address_2 || ""} onChange={(e) => { const u=[...emergencyContacts]; u[index] = { ...u[index], street_address_2: e.target.value }; setEmergencyContacts(u);} } />
														<div className="grid grid-cols-3 gap-2">
															<input className="border rounded-md p-2" placeholder="City" value={contact.city || ""} onChange={(e) => { const u=[...emergencyContacts]; u[index] = { ...u[index], city: e.target.value }; setEmergencyContacts(u);} } />
															<input className="border rounded-md p-2" placeholder="State" value={contact.us_states || ""} onChange={(e) => { const u=[...emergencyContacts]; u[index] = { ...u[index], us_states: e.target.value }; setEmergencyContacts(u);} } />
															<input className="border rounded-md p-2" placeholder="Zip" value={contact.zipcode || ""} onChange={(e) => { const u=[...emergencyContacts]; u[index] = { ...u[index], zipcode: e.target.value }; setEmergencyContacts(u);} } />
														</div>
													</div>
												) : (
													<p className="text-sm text-muted-foreground">{[contact.street_address_1, contact.street_address_2, contact.city, contact.us_states, contact.zipcode].filter(Boolean).join(", ")}</p>
												)}
											</div>
										</div>
									</div>
								))}
								{isEditing ? (
									<button className="text-sm border rounded px-3 py-1" onClick={() => setEmergencyContacts([...emergencyContacts, { name: "", relationship: "", phone: "", email: "" }])}>Add Contact</button>
								) : null}
							</div>
						</CardContent>
					</Card>
				</TabsContent>

				<TabsContent value="privacy" className="space-y-4">
					<div className="grid gap-4 md:grid-cols-2">
						<Card>
							<CardHeader>
								<CardTitle>FERPA Privacy Settings</CardTitle>
								<CardDescription>
									Control who can access your educational records
								</CardDescription>
							</CardHeader>
							<CardContent className="space-y-4">
								<div className="flex items-center justify-between">
									<div>
										<p className="font-medium">Directory Information Release</p>
										<p className="text-sm text-muted-foreground">
											Allow basic info in student directory
										</p>
									</div>
									{isEditing ? (
										<input type="checkbox" checked={!!privacySettings.ferpaDirectory} onChange={(e) => setPreferences({ ...preferences, ferpaDirectory: e.target.checked })} />
									) : (
										<Badge
											className={
												privacySettings.ferpaDirectory
													? "bg-green-100 text-green-800"
													: "bg-red-100 text-red-800"
											}
										>
											{privacySettings.ferpaDirectory ? "Allowed" : "Restricted"}
										</Badge>
									)}
								</div>
								<div className="flex items-center justify-between">
									<div>
										<p className="font-medium">Photo Release</p>
										<p className="text-sm text-muted-foreground">
											Allow use of photos in publications
										</p>
									</div>
									{isEditing ? (
										<input type="checkbox" checked={!!privacySettings.photoRelease} onChange={(e) => setPreferences({ ...preferences, photoRelease: e.target.checked })} />
									) : (
										<Badge
											className={
												privacySettings.photoRelease
													? "bg-green-100 text-green-800"
													: "bg-red-100 text-red-800"
											}
										>
											{privacySettings.photoRelease ? "Allowed" : "Restricted"}
										</Badge>
									)}
								</div>
								<div className="flex items-center justify-between">
									<div>
										<p className="font-medium">Information Release Level</p>
										<p className="text-sm text-muted-foreground">
											Overall privacy setting
										</p>
									</div>
									{isEditing ? (
										<select className="border rounded-md p-2" value={preferences.ferpa_compliance} onChange={(e) => setPreferences({ ...preferences, ferpa_compliance: e.target.value })}>
											<option value="PUBLIC">PUBLIC</option>
											<option value="DIRECTORY">DIRECTORY</option>
											<option value="RESTRICTED">RESTRICTED</option>
											<option value="CONFIDENTIAL">CONFIDENTIAL</option>
										</select>
									) : (
										<Badge
											className={getPrivacyLevelColor(
												privacySettings.infoRelease
											)}
										>
											{privacySettings.infoRelease}
										</Badge>
									)}
								</div>
							</CardContent>
						</Card>

						<Card>
							<CardHeader>
								<CardTitle>Communication Preferences</CardTitle>
								<CardDescription>
									Choose how you&apos;d like to be contacted
								</CardDescription>
							</CardHeader>
							<CardContent className="space-y-4">
								<div className="flex items-center justify-between">
									<div>
										<p className="font-medium">Contact by Phone</p>
										<p className="text-sm text-muted-foreground">
											Allow phone communications
										</p>
									</div>
									{isEditing ? (
										<input type="checkbox" checked={!!privacySettings.contactByPhone} onChange={(e) => setPreferences({ ...preferences, contactByPhone: e.target.checked })} />
									) : (
										<Badge
											className={
												privacySettings.contactByPhone
													? "bg-green-100 text-green-800"
													: "bg-red-100 text-red-800"
											}
										>
											{privacySettings.contactByPhone ? "Enabled" : "Disabled"}
										</Badge>
									)}
								</div>
								<div className="flex items-center justify-between">
									<div>
										<p className="font-medium">Contact by Email</p>
										<p className="text-sm text-muted-foreground">
											Allow email communications
										</p>
									</div>
									{isEditing ? (
										<input type="checkbox" checked={!!privacySettings.contactByEmail} onChange={(e) => setPreferences({ ...preferences, contactByEmail: e.target.checked })} />
									) : (
										<Badge
											className={
												privacySettings.contactByEmail
													? "bg-green-100 text-green-800"
													: "bg-red-100 text-red-800"
											}
										>
											{privacySettings.contactByEmail ? "Enabled" : "Disabled"}
										</Badge>
									)}
								</div>
								<div className="flex items-center justify-between">
									<div>
										<p className="font-medium">Contact by Mail</p>
										<p className="text-sm text-muted-foreground">
											Allow postal mail communications
										</p>
									</div>
									{isEditing ? (
										<input type="checkbox" checked={!!privacySettings.contactByMail} onChange={(e) => setPreferences({ ...preferences, contactByMail: e.target.checked })} />
									) : (
										<Badge
											className={
												privacySettings.contactByMail
													? "bg-green-100 text-green-800"
													: "bg-red-100 text-red-800"
											}
										>
											{privacySettings.contactByMail ? "Enabled" : "Disabled"}
										</Badge>
									)}
								</div>
							</CardContent>
						</Card>
					</div>

					<Card>
						<CardHeader>
							<CardTitle>Account Security</CardTitle>
							<CardDescription>
								Your account security status and settings
							</CardDescription>
						</CardHeader>
						<CardContent>
							<div className="grid grid-cols-1 md:grid-cols-3 gap-6">
								<div className="text-center">
									<div className="flex items-center justify-center mb-2">
										<Shield className="h-8 w-8 text-green-600" />
									</div>
									<h3 className="font-semibold">Account Status</h3>
									<Badge
										className={`${getStatusColor(
											securityInfo.accountStatus
										)} mt-1`}
									>
										{securityInfo.accountStatus}
									</Badge>
								</div>
								<div className="text-center">
									<div className="flex items-center justify-center mb-2">
										{securityInfo.twoFactorEnabled ? (
											<Shield className="h-8 w-8 text-green-600" />
										) : (
											<AlertTriangle className="h-8 w-8 text-yellow-600" />
										)}
									</div>
									<h3 className="font-semibold">Two-Factor Auth</h3>
									<Badge
										className={`${
											securityInfo.twoFactorEnabled
												? "bg-green-100 text-green-800"
												: "bg-yellow-100 text-yellow-800"
										} mt-1`}
									>
										{securityInfo.twoFactorEnabled ? "Enabled" : "Disabled"}
									</Badge>
								</div>
								<div className="text-center">
									<div className="flex items-center justify-center mb-2">
										<User className="h-8 w-8 text-blue-600" />
									</div>
									<h3 className="font-semibold">Security Questions</h3>
									<Badge
										className={`${
											securityInfo.securityQuestions
												? "bg-green-100 text-green-800"
												: "bg-red-100 text-red-800"
										} mt-1`}
									>
										{securityInfo.securityQuestions ? "Set" : "Not Set"}
									</Badge>
								</div>
							</div>
							<div className="border-t pt-4 mt-6">
								<p className="text-sm text-muted-foreground">
									Last password change: {securityInfo.lastPasswordChange}
								</p>
								<p className="text-sm text-muted-foreground">
									Recent login attempts: {securityInfo.loginAttempts}
								</p>
							</div>
						</CardContent>
					</Card>
				</TabsContent>
			</Tabs>
		</div>
	);
}

