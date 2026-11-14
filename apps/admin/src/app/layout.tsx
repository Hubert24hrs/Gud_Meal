import type { Metadata } from "next";
import { Fraunces, Plus_Jakarta_Sans } from "next/font/google";
import type { ReactNode } from "react";
import { Providers } from "@/components/providers";
import "./globals.css";

const display = Fraunces({ subsets: ["latin"], variable: "--font-fraunces", display: "swap", weight: ["500", "600", "700"] });
const sans = Plus_Jakarta_Sans({ subsets: ["latin"], variable: "--font-jakarta", display: "swap" });

export const metadata: Metadata = {
  title: { default: "Gud Meal Command Centre", template: "%s · Gud Meal Command Centre" },
  description: "Operations, finance and AI oversight for Gud Meal.",
  robots: { index: false },
};

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="en-NG" className={`${display.variable} ${sans.variable}`}>
      <body className="min-h-dvh"><Providers>{children}</Providers></body>
    </html>
  );
}
