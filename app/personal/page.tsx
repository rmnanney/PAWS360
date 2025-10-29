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

// Mock data for personal information
const personalInfo = {
	studentId: "123456789",
	firstName: "John",
	lastName: "Doe",
	preferredName: "Johnny",
	dateOfBirth: "2000-05-15",
	gender: "Male",
	ethnicity: "Caucasian",
	citizenship: "United States",
	ssn: "XXX-XX-1234",
};

const contactInfo = {
	email: "john.doe@uwm.edu",
	alternateEmail: "johnny.doe@gmail.com",
	phone: "(414) 555-0123",
	alternatePhone: "(414) 555-0456",
	address: {
		street: "123 University Drive",
		city: "Milwaukee",
		state: "WI",
		zipCode: "53211",
		country: "United States",
	},
	permanentAddress: {
		street: "456 Home Street",
		city: "Madison",
		state: "WI",
		zipCode: "53703",
		country: "United States",
	},
};

const emergencyContacts = [
	{
		name: "Jane Doe",
		relationship: "Mother",
		phone: "(608) 555-0123",
		email: "jane.doe@email.com",
		address: "456 Home Street, Madison, WI 53703",
	},
	{
		name: "Bob Doe",
		relationship: "Father",
		phone: "(608) 555-0456",
		email: "bob.doe@email.com",
		address: "456 Home Street, Madison, WI 53703",
	},
];

const privacySettings = {
	ferpaDirectory: true,
	photoRelease: false,
	infoRelease: "restricted",
	contactByPhone: true,
	contactByEmail: true,
	contactByMail: false,
};

const securityInfo = {
	lastPasswordChange: "2025-09-01",
	twoFactorEnabled: true,
	loginAttempts: 0,
	accountStatus: "Active",
	securityQuestions: true,
};

export default function PersonalPage() {
	const [isEditing, setIsEditing] = React.useState(false);
	const [showSSN, setShowSSN] = React.useState(false);

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
						onClick={() => setIsEditing(!isEditing)}
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
						<div className="text-2xl font-bold">
							{personalInfo.firstName} {personalInfo.lastName}
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
							{contactInfo.email.split("@")[0]}
						</div>
						<p className="text-xs text-muted-foreground">@uwm.edu</p>
					</CardContent>
				</Card>

				<Card>
					<CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
						<CardTitle className="text-sm font-medium">Privacy Level</CardTitle>
						<Shield className="h-4 w-4 text-muted-foreground" />
					</CardHeader>
					<CardContent>
						<div className="text-2xl font-bold">Restricted</div>
						<p className="text-xs text-muted-foreground">FERPA Protected</p>
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
										<label className="text-sm font-medium">Student ID</label>
										<p className="text-lg font-semibold">
											{personalInfo.studentId}
										</p>
									</div>
									<div>
										<label className="text-sm font-medium">First Name</label>
										<p className="text-lg">{personalInfo.firstName}</p>
									</div>
									<div>
										<label className="text-sm font-medium">Last Name</label>
										<p className="text-lg">{personalInfo.lastName}</p>
									</div>
									<div>
										<label className="text-sm font-medium">
											Preferred Name
										</label>
										<p className="text-lg">{personalInfo.preferredName}</p>
									</div>
								</div>
								<div className="space-y-4">
									<div>
										<label className="text-sm font-medium">Date of Birth</label>
										<p className="text-lg">{personalInfo.dateOfBirth}</p>
									</div>
									<div>
										<label className="text-sm font-medium">Gender</label>
										<p className="text-lg">{personalInfo.gender}</p>
									</div>
									<div>
										<label className="text-sm font-medium">Ethnicity</label>
										<p className="text-lg">{personalInfo.ethnicity}</p>
									</div>
									<div>
										<label className="text-sm font-medium">Citizenship</label>
										<p className="text-lg">{personalInfo.citizenship}</p>
									</div>
								</div>
							</div>
							<div className="border-t pt-4">
								<div className="flex items-center space-x-2">
									<Shield className="h-4 w-4 text-muted-foreground" />
									<label className="text-sm font-medium">
										Social Security Number
									</label>
									<Button
										variant="ghost"
										size="sm"
										onClick={() => setShowSSN(!showSSN)}
									>
										{showSSN ? (
											<EyeOff className="h-4 w-4" />
										) : (
											<Eye className="h-4 w-4" />
										)}
									</Button>
								</div>
								<p className="text-lg font-mono">
									{showSSN ? personalInfo.ssn : "XXX-XX-XXXX"}
								</p>
								<p className="text-xs text-muted-foreground mt-1">
									This information is protected under FERPA and only visible to
									you.
								</p>
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
									<div>
										<p className="font-medium">Primary Email</p>
										<p className="text-sm text-muted-foreground">
											{contactInfo.email}
										</p>
									</div>
								</div>
								<div className="flex items-center space-x-3">
									<Mail className="h-5 w-5 text-gray-600" />
									<div>
										<p className="font-medium">Alternate Email</p>
										<p className="text-sm text-muted-foreground">
											{contactInfo.alternateEmail}
										</p>
									</div>
								</div>
								<div className="flex items-center space-x-3">
									<Phone className="h-5 w-5 text-green-600" />
									<div>
										<p className="font-medium">Primary Phone</p>
										<p className="text-sm text-muted-foreground">
											{contactInfo.phone}
										</p>
									</div>
								</div>
								<div className="flex items-center space-x-3">
									<Phone className="h-5 w-5 text-gray-600" />
									<div>
										<p className="font-medium">Alternate Phone</p>
										<p className="text-sm text-muted-foreground">
											{contactInfo.alternatePhone}
										</p>
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
											<p>{contactInfo.address.street}</p>
											<p>
												{contactInfo.address.city}, {contactInfo.address.state}{" "}
												{contactInfo.address.zipCode}
											</p>
											<p>{contactInfo.address.country}</p>
										</div>
									</div>
								</div>
								<div>
									<h3 className="font-semibold mb-2">Permanent Address</h3>
									<div className="flex items-start space-x-3">
										<MapPin className="h-5 w-5 text-green-600 mt-0.5" />
										<div className="text-sm">
											<p>{contactInfo.permanentAddress.street}</p>
											<p>
												{contactInfo.permanentAddress.city},{" "}
												{contactInfo.permanentAddress.state}{" "}
												{contactInfo.permanentAddress.zipCode}
											</p>
											<p>{contactInfo.permanentAddress.country}</p>
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
										<div className="flex items-start justify-between">
											<div className="flex-1">
												<div className="flex items-center space-x-3 mb-3">
													<User className="h-6 w-6 text-blue-600" />
													<div>
														<h3 className="font-semibold">{contact.name}</h3>
														<p className="text-sm text-muted-foreground">
															{contact.relationship}
														</p>
													</div>
												</div>
												<div className="grid grid-cols-1 md:grid-cols-2 gap-4">
													<div className="space-y-2">
														<div className="flex items-center space-x-2">
															<Phone className="h-4 w-4 text-muted-foreground" />
															<span className="text-sm">{contact.phone}</span>
														</div>
														<div className="flex items-center space-x-2">
															<Mail className="h-4 w-4 text-muted-foreground" />
															<span className="text-sm">{contact.email}</span>
														</div>
													</div>
													<div>
														<p className="text-sm font-medium mb-1">Address:</p>
														<p className="text-sm text-muted-foreground">
															{contact.address}
														</p>
													</div>
												</div>
											</div>
											<Button variant="outline" size="sm">
												<Edit className="h-4 w-4 mr-2" />
												Edit
											</Button>
										</div>
									</div>
								))}
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
									<Badge
										className={
											privacySettings.ferpaDirectory
												? "bg-green-100 text-green-800"
												: "bg-red-100 text-red-800"
										}
									>
										{privacySettings.ferpaDirectory ? "Allowed" : "Restricted"}
									</Badge>
								</div>
								<div className="flex items-center justify-between">
									<div>
										<p className="font-medium">Photo Release</p>
										<p className="text-sm text-muted-foreground">
											Allow use of photos in publications
										</p>
									</div>
									<Badge
										className={
											privacySettings.photoRelease
												? "bg-green-100 text-green-800"
												: "bg-red-100 text-red-800"
										}
									>
										{privacySettings.photoRelease ? "Allowed" : "Restricted"}
									</Badge>
								</div>
								<div className="flex items-center justify-between">
									<div>
										<p className="font-medium">Information Release Level</p>
										<p className="text-sm text-muted-foreground">
											Overall privacy setting
										</p>
									</div>
									<Badge
										className={getPrivacyLevelColor(
											privacySettings.infoRelease
										)}
									>
										{privacySettings.infoRelease}
									</Badge>
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
									<Badge
										className={
											privacySettings.contactByPhone
												? "bg-green-100 text-green-800"
												: "bg-red-100 text-red-800"
										}
									>
										{privacySettings.contactByPhone ? "Enabled" : "Disabled"}
									</Badge>
								</div>
								<div className="flex items-center justify-between">
									<div>
										<p className="font-medium">Contact by Email</p>
										<p className="text-sm text-muted-foreground">
											Allow email communications
										</p>
									</div>
									<Badge
										className={
											privacySettings.contactByEmail
												? "bg-green-100 text-green-800"
												: "bg-red-100 text-red-800"
										}
									>
										{privacySettings.contactByEmail ? "Enabled" : "Disabled"}
									</Badge>
								</div>
								<div className="flex items-center justify-between">
									<div>
										<p className="font-medium">Contact by Mail</p>
										<p className="text-sm text-muted-foreground">
											Allow postal mail communications
										</p>
									</div>
									<Badge
										className={
											privacySettings.contactByMail
												? "bg-green-100 text-green-800"
												: "bg-red-100 text-red-800"
										}
									>
										{privacySettings.contactByMail ? "Enabled" : "Disabled"}
									</Badge>
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
