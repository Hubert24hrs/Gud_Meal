import type { Metadata } from "next";
import { Nunito, Plus_Jakarta_Sans } from "next/font/google";
import type { ReactNode } from "react";
import { Providers } from "@/components/providers";
import "./globals.css";

// Headings: a heavy rounded face, like the lettering of the GudMeals logo.
const display = Nunito({ subsets: ["latin"], variable: "--font-nunito", display: "swap", weight: ["600", "700", "800", "900"] });
const sans = Plus_Jakarta_Sans({ subsets: ["latin"], variable: "--font-jakarta", display: "swap" });

export const metadata: Metadata = {
  title: { default: "GudMeals Partner", template: "%s · GudMeals Partner" },
  description: "Manage orders, menus and earnings for your restaurant on GudMeals.",
  robots: { index: false },
};

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="en-NG" className={`${display.variable} ${sans.variable}`}>
      <body className="min-h-dvh"><Providers>{children}</Providers></body>
    </html>
  );
}
