import type { Metadata } from "next";
import { TrackForm } from "./track-form";

export const metadata: Metadata = {
  title: "Track a package",
  description: "Track an interstate Gud Meal waybill with its tracking number.",
  alternates: { canonical: "/track" },
};

export default function TrackPage() {
  return (
    <div className="container-page max-w-xl space-y-4 py-10 pb-28 md:pb-12">
      <h1 className="text-3xl font-black tracking-tight">Track a package</h1>
      <p className="text-muted">Enter the tracking number from the sender (it starts with GMW).</p>
      <TrackForm />
    </div>
  );
}
