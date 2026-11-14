"use client";

import { Button } from "@gudmeal/ui";
import { Sparkles } from "lucide-react";
import { useRouter } from "next/navigation";
import { useState } from "react";

const EXAMPLES = [
  "I have ₦10,000 — best meal for two before 8pm",
  "Spicy suya for 4 under ₦20,000",
  "Something vegetarian and filling near Lekki",
];

export function AskBox() {
  const router = useRouter();
  const [text, setText] = useState("");
  const go = (q: string) => router.push(`/assistant?q=${encodeURIComponent(q)}`);
  return (
    <div className="space-y-2">
      <form onSubmit={(e) => { e.preventDefault(); if (text.trim()) go(text.trim()); }}
        className="flex items-center gap-2 rounded-full border border-border bg-surface p-1.5 pl-4 shadow-card focus-within:ring-2 focus-within:ring-primary/30">
        <Sparkles className="size-5 shrink-0 text-secondary" aria-hidden="true" />
        <label htmlFor="ask" className="sr-only">Ask Gud Meal</label>
        <input id="ask" value={text} onChange={(e) => setText(e.target.value)} maxLength={300}
          placeholder="Tell Gud Meal what you're craving and your budget…"
          className="min-w-0 flex-1 bg-transparent py-2 text-sm outline-none placeholder:text-muted" />
        <Button type="submit" disabled={!text.trim()}>Ask</Button>
      </form>
      <div className="flex flex-wrap gap-2 text-xs">
        {EXAMPLES.map((e) => (
          <button key={e} onClick={() => go(e)} className="rounded-full bg-surface-muted px-3 py-1 text-muted hover:text-text">{e}</button>
        ))}
      </div>
    </div>
  );
}
