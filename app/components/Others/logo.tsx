import { cn } from "../../lib/utils";

const UWMIcon = (props: React.ImgHTMLAttributes<HTMLImageElement>) => (
	<img
		src="/uwmLogo.png"
		alt="UWM Logo"
		className="h-10 w-10 object-contain"
		{...props}
	/>
);

const Logo = ({ className }: { className?: string }) => {
	return (
		<div className={cn("flex items-center gap-3", className)}>
			<div>
				<UWMIcon className="h-10 w-10 text-primary-foreground" />
			</div>
			<span className="text-l font-bold text-primary font-headline">
				University of Wisconsin, Milwaukee
			</span>
		</div>
	);
};

export default Logo;
