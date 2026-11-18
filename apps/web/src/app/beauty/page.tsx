import type { Metadata } from "next";
import { VerticalPage } from "@/components/vertical-page";

export const metadata: Metadata = {
  title: "Supplements & skin care delivery",
  description: "Vitamins, supplements and skin care from partner shops in Lagos and Enugu, delivered fast.",
  alternates: { canonical: "/beauty" },
};

export default async function BeautyPage({ searchParams }: { searchParams: Promise<{ category?: string }> }) {
  const { category } = await searchParams;
  return <VerticalPage vertical="beauty" initialCategory={category} />;
}
