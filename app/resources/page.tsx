import React, { Suspense } from "react";
import ResourcesClient from "./ResourcesClient";

export default function ResourcesPage() {
  return (
    <Suspense fallback={<div className="p-8">Loading resources…</div>}>
      <ResourcesClient />
    </Suspense>
  );
}
