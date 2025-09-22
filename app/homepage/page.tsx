"use client";

import Link from "next/link";
import { Button } from "../components/button";
import { Card, CardContent, CardHeader, CardTitle } from "../components/card";
import Logo from "@/components/logo";

export default function Homepage() {
  return (
    <div className="flex min-h-screen flex-col items-center justify-center bg-background p-4">
      <Card className="w-full max-w-lg">
        <CardHeader>
          <Logo className="justify-center" />
          <CardTitle className="text-center text-2xl font-headline pt-4">Homepage</CardTitle>
        </CardHeader>
        <CardContent className="text-center">
          <p className="text-muted-foreground mb-6">
            Welcome to UWM University! You have successfully logged in.
          </p>
          <Button asChild>
            <Link href="/">Log Out</Link>
          </Button>
        </CardContent>
      </Card>
    </div>
  );
}
