import type { Metadata } from "next";
import { TrackView } from "./track-view";

export const metadata: Metadata = {
  title: "Package tracking",
  robots: { index: false, follow: false },
};

export default async function TrackCodePage({ params }: { params: Promise<{ code: string }> }) {
  const { code } = await params;
  return (
    <div className="container-page max-w-xl space-y-4 py-10 pb-28 md:pb-12">
      <h1 className="text-3xl font-black tracking-tight">Package tracking</h1>
      <TrackView code={code.toUpperCase()} />
    </div>
  );
}
