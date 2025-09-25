import Link from "next/link";
import { Button } from "../components/Others/button";
import {
	Card,
	CardContent,
	CardDescription,
	CardHeader,
	CardTitle,
} from "../components/Card/card";
import { Input } from "../components/Others/input";
import { Label } from "../components/Others/label";
import Logo from "../components/Others/logo";
import { PlaceHolderImages } from "../lib/placeholder-img";
import s from "./styles.module.css";

export default function ForgotPasswordPage() {
	const bgImage = PlaceHolderImages.find((img) => img.id === "uwm-building");

	return (
		<main style={{ position: "relative", minHeight: "100vh" }}>
			{bgImage && (
				<img
					src={bgImage.imageUrl}
					alt={bgImage.description}
					className={s.bgImage}
				/>
			)}

			<div className={s.overlay} />

			<div className={s.card}>
				<div className={s.container}>
					<Card className={s.cardCustom}>
						<CardHeader className={s.headerSpace}>
							<Logo className="justify-center" />

							<div style={{ textAlign: "center" }}>
								<CardTitle className={s.title}>Forgot Password</CardTitle>

								<CardDescription style={{ paddingTop: "0.5rem" }}>
									Enter your email below to reset your password. We'll send you
									a link.
								</CardDescription>
							</div>
						</CardHeader>

						<CardContent>
							<form className={s.form}>
								<div className={s.formGroup}>
									<Label htmlFor="email">Email</Label>
									<Input
										id="email"
										type="email"
										placeholder="epantherID@uwm.edu"
										required
									/>
								</div>

								<Button type="submit" className={s.fullWidth}>
									Send Reset Link
								</Button>

								<Button variant="outline" className={s.fullWidth} asChild>
									<Link href="/">Cancel</Link>
								</Button>
							</form>
						</CardContent>
					</Card>
				</div>
			</div>
		</main>
	);
}
