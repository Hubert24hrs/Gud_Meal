"use client";

import { Button, Field, Input } from "@gudmeal/ui";
import { useRouter } from "next/navigation";
import { useState } from "react";

export const TRACKING_PATTERN = /^GMW[2-9A-HJ-NP-Z]{8}$/;

/** Normalises what people type or paste: spaces, dashes and lower case. */
export function normaliseTrackingCode(raw: string): string {
  return raw.toUpperCase().replace(/[\s-]/g, "");
}

export function TrackForm({ initial = "" }: { initial?: string }) {
  const router = useRouter();
  const [code, setCode] = useState(initial);
  const [error, setError] = useState<string | null>(null);
  return (
    <form
      className="flex flex-wrap items-end gap-3"
      onSubmit={(e) => {
        e.preventDefault();
        const value = normaliseTrackingCode(code);
        if (!TRACKING_PATTERN.test(value)) return setError("Tracking numbers look like GMW followed by 8 letters and numbers");
        setError(null);
        router.push(`/track/${value}`);
      }}
    >
      <div className="min-w-56 flex-1">
        <Field label="Tracking number" htmlFor="track-code">
          <Input id="track-code" value={code} onChange={(e) => setCode(e.target.value)} placeholder="GMW7K3P9Q2X" autoCapitalize="characters" />
        </Field>
      </div>
      <Button type="submit" size="lg">Track</Button>
      {error && <p role="alert" className="w-full text-sm font-semibold text-danger">{error}</p>}
    </form>
  );
}
