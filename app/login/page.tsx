import { PlaceHolderImages } from "../lib/placeholder-img";
import Logo from "@/components/Others/logo";
import LoginForm from "@/components/LoginForm/login";

import {
	Card,
	CardContent,
	CardDescription,
	CardHeader,
	CardTitle,
} from "@/components/Card/card";
``;
import s from "./styles.module.css";

export default function Login() {
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
							<div className="text-center">
								<CardTitle className={s.title}>Welcome Back</CardTitle>
								<CardDescription className="pt-2">
									Sign in to your UWM account
								</CardDescription>
							</div>
						</CardHeader>
						<CardContent>
							<LoginForm />
						</CardContent>
					</Card>
				</div>
			</div>
		</main>
	);
}
