import type {Metadata} from 'next';
import './global.css';
import { Toaster } from './components/toaster';

export const metadata: Metadata = {
  title: 'University of Wisconsin, Milwaukee Login',
  description: 'Login page for University of Wisconsin, Milwaukee',
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      {/* <head>
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="anonymous" />
        <link href="https://fonts.googleapis.com/css2?family=PT+Sans:ital,wght@0,400;0,700;1,400;1,700&display=swap" rel="stylesheet" />
      </head> */}
      <body className="font-body antialiased">
        {children}
        <Toaster />
      </body>
    </html>
  );
}
