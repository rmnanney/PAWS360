import { PlaceHolderImages } from '../lib/placeholder-img';
import Logo from '@/components/logo';
import LoginForm from '@/components/login-form';

import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from '../components/card';

export default function Login() {
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

      <div className="relative z-10 flex min-h-screen items-center justify-center p-4 lg:justify-end lg:pr-[10vw]">
        <div className="w-full max-w-md">
          <Card className="bg-card/90 backdrop-blur-sm animate-fade-in-up">
            <CardHeader className="space-y-4">
              <Logo className="justify-center" />
              <div className="text-center">
                <CardTitle className="text-3xl font-bold font-headline">
                  Welcome Back
                </CardTitle>
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
