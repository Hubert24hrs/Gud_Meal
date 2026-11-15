import type { Metadata } from "next";
import { RequireAuth } from "@/components/require-auth";
import { PlusView } from "./plus-view";

export const metadata: Metadata = {
  title: "Gud Meal Plus",
  description: "Free delivery on Food and Beauty orders, half-price service fees and double Gud points.",
  alternates: { canonical: "/plus" },
  robots: { index: false },
};

export default function PlusPage() {
  return (
    <RequireAuth reason="Sign in to join Gud Meal Plus.">
      <PlusView />
    </RequireAuth>
  );
}
