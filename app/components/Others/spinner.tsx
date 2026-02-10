"use client";

import React from "react";
import { Loader2 } from "lucide-react";

type SpinnerProps = {
  size?: "sm" | "md" | "lg";
  className?: string;
  "aria-label"?: string;
};

export function Spinner({ size = "md", className = "", ...rest }: SpinnerProps) {
  const sizeClass = size === "sm" ? "h-4 w-4" : size === "lg" ? "h-8 w-8" : "h-6 w-6";
  return (
    <Loader2
      className={`${sizeClass} animate-spin text-muted-foreground ${className}`}
      aria-label={rest["aria-label"] || "Loading"}
    />
  );
}

