import React, { Suspense } from "react";
import MyAccountClient from "./MyAccountClient";

export default function MyAccountPage() {
  return (
    <Suspense fallback={<div className="p-8">Loading account…</div>}>
      <MyAccountClient />
    </Suspense>
  );
}
