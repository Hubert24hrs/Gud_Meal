import type { Metadata, Viewport } from "next";
import { Fraunces, Plus_Jakarta_Sans } from "next/font/google";
import type { ReactNode } from "react";
import { BottomNav } from "@/components/bottom-nav";
import { Footer } from "@/components/footer";
import { GudyFab } from "@/components/gudy-fab";
import { Header } from "@/components/header";
import { Providers } from "@/components/providers";
import "./globals.css";

const display = Fraunces({ subsets: ["latin"], variable: "--font-fraunces", display: "swap", weight: ["500", "600", "700"] });
const sans = Plus_Jakarta_Sans({ subsets: ["latin"], variable: "--font-jakarta", display: "swap" });

const site = process.env.NEXT_PUBLIC_SITE_URL ?? "http://localhost:3000";

export const metadata: Metadata = {
  metadataBase: new URL(site),
  title: { default: "Gud Meal: food, supplements & skin care and package delivery", template: "%s · Gud Meal" },
  description:
    "Order food from the best restaurants, supplements and skin care from partner shops, and send packages across Lagos and Enugu. Ask Gudy, our AI assistant, in English, Pidgin, Igbo, Yoruba or Hausa.",
  openGraph: { type: "website", siteName: "Gud Meal", locale: "en_NG" },
  alternates: { canonical: "/" },
};

export const viewport: Viewport = {
  themeColor: [{ media: "(prefers-color-scheme: light)", color: "#FFF9F3" }, { media: "(prefers-color-scheme: dark)", color: "#121513" }],
  width: "device-width",
  initialScale: 1,
};

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="en-NG" className={`${display.variable} ${sans.variable}`}>
      <body className="min-h-dvh">
        <Providers>
          <a href="#main" className="sr-only focus:not-sr-only focus:absolute focus:left-4 focus:top-4 focus:z-50 focus:rounded-md focus:bg-surface focus:px-3 focus:py-2">
            Skip to content
          </a>
          <Header />
          <main id="main" className="min-h-[60vh]">{children}</main>
          <Footer />
          <BottomNav />
          <GudyFab />
        </Providers>
      </body>
    </html>
  );
}
