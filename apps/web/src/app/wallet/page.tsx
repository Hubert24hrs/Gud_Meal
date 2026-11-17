import type { Metadata } from "next";
import { RequireAuth } from "@/components/require-auth";
import { WalletView } from "./wallet-view";

export const metadata: Metadata = {
  title: "Gud Meal wallet",
  description: "Top up once and pay for food, groceries, pharmacy, market shopping, beauty and package deliveries in one tap. Refunds land instantly.",
  alternates: { canonical: "/wallet" },
  robots: { index: false },
};

export default function WalletPage() {
  return (
    <RequireAuth reason="Sign in to see your Gud Meal wallet.">
      <WalletView />
    </RequireAuth>
  );
}
