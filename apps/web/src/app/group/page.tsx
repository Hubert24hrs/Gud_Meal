import type { Metadata } from "next";
import { Suspense } from "react";
import { RequireAuth } from "@/components/require-auth";
import { GroupHub } from "./group-hub";

export const metadata: Metadata = {
  title: "Group orders",
  description: "Order together from one store, and everyone pays their own share.",
  alternates: { canonical: "/group" },
  robots: { index: false },
};

export default function GroupOrdersPage() {
  return (
    <RequireAuth reason="Sign in to join or start a group order.">
      <Suspense>
        <GroupHub />
      </Suspense>
    </RequireAuth>
  );
}
