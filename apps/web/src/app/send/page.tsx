import type { Metadata } from "next";
import { RequireAuth } from "@/components/require-auth";
import { SendForm } from "./send-form";

export const metadata: Metadata = {
  title: "Package delivery in Lagos and Enugu",
  description: "Send documents, clothes, electronics and more across Lagos or Enugu by bike. See the exact price before you pay.",
  alternates: { canonical: "/send" },
};

export default function SendPage() {
  return (
    <RequireAuth reason="Sign in to book a package delivery and track it to the door.">
      <SendForm />
    </RequireAuth>
  );
}
