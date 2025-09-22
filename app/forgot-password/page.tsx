import Link from "next/link";
import { Button } from "../components/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "../components/card";
import { Input } from "../components/input";
import { Label } from "../components/label";
import Logo from "../components/logo";
import { PlaceHolderImages } from '../lib/placeholder-img';

export default function ForgotPasswordPage() {
  const bgImage = PlaceHolderImages.find(
    (img) => img.id === 'uwm-building',
  );
  
  return (
    <main className="relative min-h-screen">
      {bgImage && (
        <img
          src={bgImage.imageUrl}
          alt={bgImage.description}
          className="absolute inset-0 w-full h-full object-cover"
        />
      )}
        
      <div className="absolute inset-0 bg-white/50" />

      <div className="relative z-10 flex min-h-screen flex-col items-center justify-center p-4">
        <Card className="mx-auto max-w-sm">
          <CardHeader>
            <Logo className="justify-center" />
            <CardTitle className="text-2xl text-center font-headline pt-4">Forgot Password</CardTitle>
            <CardDescription className="text-center">
              Enter your email below to reset your password. We'll send you a link.
            </CardDescription>
          </CardHeader>
          <CardContent>
            <form className="grid gap-4">
              <div className="grid gap-2">
                <Label htmlFor="email">Email</Label>
                <Input
                  id="email"
                  type="email"
                  placeholder="epantherID@uwm.edu"
                  required
                />
              </div>
              <Button type="submit" className="w-full">
                Send Reset Link
              </Button>
              <Button variant="outline" className="w-full" asChild>
                <Link href="/">Cancel</Link>
              </Button>
            </form>
          </CardContent>
        </Card>
      </div>
    </main>
  );
}
