import React, { Suspense } from "react";
import PersonalClient from "./PersonalClient";

export default function PersonalPage() {
  return (
    <Suspense fallback={<div className="p-8">Loading personal profile…</div>}>
      <PersonalClient />
    </Suspense>
  );
}
