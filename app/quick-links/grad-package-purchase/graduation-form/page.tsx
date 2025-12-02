"use client";

import { useState } from "react";
import {
	Card,
	CardContent,
	CardDescription,
	CardHeader,
	CardTitle,
} from "../../../components/Card/card";
import { Label } from "../../../components/Others/label";
import {
	Select,
	SelectContent,
	SelectItem,
	SelectTrigger,
	SelectValue,
} from "../../../components/Others/select";
import {
	RadioGroup,
	RadioGroupItem,
} from "../../../components/Others/radio-group";
import { Button } from "../../../components/Button/button";
import {
	graduationTerms,
	colleges,
	majorsByCollege,
	deliveryMethods,
} from "../../gradMockData";
import { ArrowRight } from "lucide-react";
import { useRouter } from "next/navigation";

export function GraduationForm() {
	const [term, setTerm] = useState("");
	const [school, setSchool] = useState("");
	const [degreeType, setDegreeType] = useState("");
	const [major, setMajor] = useState("");
	const [deliveryMethod, setDeliveryMethod] = useState("");
	const router = useRouter();

	const availableDegreeTypes = school
		? Object.keys(majorsByCollege[school] || {})
		: [];
	const availableMajors =
		school && degreeType ? majorsByCollege[school]?.[degreeType] || [] : [];

	const isFormValid = term && school && degreeType && major && deliveryMethod;

	const handleSubmit = () => {
		if (isFormValid) {
			const graduationData = {
				term,
				school,
				degreeType,
				major,
				deliveryMethod,
			};
			router.push("/quick-links/grad-package-purchase/graduation-packages");
		}
	};

	return (
		<div className="flex flex-1 flex-col gap-4">
			<div className="mb-2">
				<p className="text-muted-foreground">
					Select your graduation details to browse available packages.
				</p>
			</div>

			<Card className="max-w-2xl mx-auto w-full">
				<CardHeader>
					<CardTitle>Graduation Information</CardTitle>
					<CardDescription>
						Please provide your graduation details to continue
					</CardDescription>
				</CardHeader>
				<CardContent className="space-y-6">
					{/* Term Selection */}
					<div className="space-y-2">
						<Label htmlFor="term">Graduation Term *</Label>
						<Select value={term} onValueChange={setTerm}>
							<SelectTrigger id="term">
								<SelectValue placeholder="Select your graduation term" />
							</SelectTrigger>
							<SelectContent>
								{graduationTerms.map((t) => (
									<SelectItem key={t} value={t}>
										{t}
									</SelectItem>
								))}
							</SelectContent>
						</Select>
					</div>

					{/* College/School Selection */}
					<div className="space-y-2">
						<Label htmlFor="school">College/School *</Label>
						<Select
							value={school}
							onValueChange={(value) => {
								setSchool(value);
								setDegreeType("");
								setMajor("");
							}}
						>
							<SelectTrigger id="school">
								<SelectValue placeholder="Select your college/school" />
							</SelectTrigger>
							<SelectContent>
								{colleges.map((c) => (
									<SelectItem key={c} value={c}>
										{c}
									</SelectItem>
								))}
							</SelectContent>
						</Select>
					</div>

					{/* Degree Type Selection */}
					{school && (
						<div className="space-y-2">
							<Label htmlFor="degreeType">Degree Type *</Label>
							<Select
								value={degreeType}
								onValueChange={(value) => {
									setDegreeType(value);
									setMajor("");
								}}
							>
								<SelectTrigger id="degreeType">
									<SelectValue placeholder="Select your degree type" />
								</SelectTrigger>
								<SelectContent>
									{availableDegreeTypes.map((dt) => (
										<SelectItem key={dt} value={dt}>
											{dt}
										</SelectItem>
									))}
								</SelectContent>
							</Select>
						</div>
					)}

					{/* Major Selection */}
					{school && degreeType && (
						<div className="space-y-2">
							<Label htmlFor="major">Major *</Label>
							<Select value={major} onValueChange={setMajor}>
								<SelectTrigger id="major">
									<SelectValue placeholder="Select your major" />
								</SelectTrigger>
								<SelectContent>
									{availableMajors.map((m) => (
										<SelectItem key={m} value={m}>
											{m}
										</SelectItem>
									))}
								</SelectContent>
							</Select>
						</div>
					)}

					{/* Delivery Method Selection */}
					<div className="space-y-3">
						<Label>Delivery Method *</Label>
						<RadioGroup
							value={deliveryMethod}
							onValueChange={setDeliveryMethod}
						>
							{deliveryMethods.map((method) => (
								<div key={method.value} className="flex items-center space-x-2">
									<RadioGroupItem value={method.value} id={method.value} />
									<Label htmlFor={method.value} className="cursor-pointer">
										{method.label}
									</Label>
								</div>
							))}
						</RadioGroup>
					</div>

					{/* Submit Button */}
					<Button
						onClick={handleSubmit}
						disabled={!isFormValid}
						className="w-full"
						size="lg"
					>
						Continue to Packages
						<ArrowRight className="ml-2 h-4 w-4" />
					</Button>
				</CardContent>
			</Card>
		</div>
	);
}

export default GraduationForm;
