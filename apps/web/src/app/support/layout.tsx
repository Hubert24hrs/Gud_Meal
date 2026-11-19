import type { Metadata } from "next";
import type { ReactNode } from "react";

export const metadata: Metadata = {
  title: "Support",
  description: "Chat with Yummy, talk to a person, or reach Yummy Chops support. Answers about refunds, payments and delivery codes.",
  alternates: { canonical: "/support" },
};

export default function SupportLayout({ children }: { children: ReactNode }) {
  return children;
}
