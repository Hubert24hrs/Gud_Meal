"use client";

import { ApiError, type ChatApproval, type ChatCard, type ChatResponse } from "@gudmeal/api-client";
import { Badge, Button, Card, Spinner, cn } from "@gudmeal/ui";
import { useQuery } from "@tanstack/react-query";
import { CreditCard, Mic, Send, ShieldCheck, Sparkles } from "lucide-react";
import Link from "next/link";
import { useSearchParams } from "next/navigation";
import { useEffect, useRef, useState } from "react";
import { RequireAuth } from "@/components/require-auth";
import { useAgentsApi, useApi } from "@/lib/api";
import { useLocation } from "@/lib/location";

interface Turn { role: "user" | "assistant"; text: string; cards?: ChatCard[]; approval?: ChatApproval | null }

export function Chat() {
  return (
    <RequireAuth reason="Sign in so Gud Meal can use your saved address, preferences and orders.">
      <ChatInner />
    </RequireAuth>
  );
}

type SpeechRecognitionLike = { lang: string; interimResults: boolean; start: () => void; onresult: ((e: { results: { 0: { transcript: string } }[] }) => void) | null; onend: (() => void) | null };

function ChatInner() {
  const agents = useAgentsApi();
  const api = useApi();
  const { area } = useLocation();
  const params = useSearchParams();
  const [turns, setTurns] = useState<Turn[]>([]);
  const [threadId, setThreadId] = useState<string | null>(null);
  const [text, setText] = useState("");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [listening, setListening] = useState(false);
  const started = useRef(false);
  const bottom = useRef<HTMLDivElement>(null);
  const addresses = useQuery({ queryKey: ["addresses"], queryFn: () => api.me.addresses() });

  useEffect(() => bottom.current?.scrollIntoView({ behavior: "smooth" }), [turns, busy]);

  function apply(res: ChatResponse) {
    setThreadId(res.thread_id);
    setTurns((t) => [...t, {
      role: "assistant",
      text: res.status === "approval_required" ? "Please review and approve:" : (res.reply ?? ""),
      cards: res.cards, approval: res.approval,
    }]);
  }

  async function send(message: string) {
    if (!message.trim() || busy) return;
    setError(null);
    setTurns((t) => [...t, { role: "user", text: message }]);
    setText("");
    setBusy(true);
    try {
      const saved = addresses.data?.[0];
      const delivery_address = saved ?? { label: area.name, line1: `${area.name}, Lagos`, area: area.name, location: area.location };
      apply(await agents.chat({ message, thread_id: threadId, channel: "web", delivery_address: threadId ? undefined : delivery_address }));
    } catch (e) {
      setError(e instanceof ApiError ? e.message : "The assistant is unavailable right now.");
    } finally {
      setBusy(false);
    }
  }

  async function decide(approval: ChatApproval, approved: boolean) {
    if (!threadId) return;
    setBusy(true);
    setTurns((t) => t.map((turn) => (turn.approval === approval ? { ...turn, approval: null, text: approved ? "Approved ✓" : "Declined" } : turn)));
    try {
      apply(await agents.approve(threadId, approved, approval.tool_call_id));
    } catch (e) {
      setError(e instanceof ApiError ? e.message : "Could not send your decision.");
    } finally {
      setBusy(false);
    }
  }

  function listen() {
    const W = window as unknown as { SpeechRecognition?: new () => SpeechRecognitionLike; webkitSpeechRecognition?: new () => SpeechRecognitionLike };
    const Ctor = W.SpeechRecognition ?? W.webkitSpeechRecognition;
    if (!Ctor) { setError("Voice input isn't supported in this browser."); return; }
    const rec = new Ctor();
    rec.lang = "en-NG";
    rec.interimResults = false;
    rec.onresult = (e) => setText(e.results[0]?.[0]?.transcript ?? "");
    rec.onend = () => setListening(false);
    setListening(true);
    rec.start();
  }

  useEffect(() => {
    const q = params.get("q");
    if (q && !started.current && !addresses.isLoading) {
      started.current = true;
      void send(q);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [params, addresses.isLoading]);

  return (
    <div className="container-page flex max-w-3xl flex-col py-6" style={{ minHeight: "calc(100dvh - 4rem)" }}>
      <div className="mb-4 flex items-center gap-3">
        <span className="grid size-10 place-items-center rounded-full bg-secondary text-on-secondary"><Sparkles className="size-5" /></span>
        <div>
          <h1 className="font-display text-2xl">Ask Gud Meal</h1>
          <p className="text-xs text-muted">Delivering to {addresses.data?.[0]?.line1 ?? area.name} · you approve every order before paying</p>
        </div>
      </div>

      <div className="flex-1 space-y-4" aria-live="polite">
        {turns.length === 0 && (
          <Card className="space-y-2 p-5 text-sm">
            <p className="font-semibold">Try asking:</p>
            {["I have ₦10,000. Find me the best meal for two people, order it, and deliver before 8pm.",
              "What's the status of my last order?", "Something vegetarian under ₦6,000"].map((s) => (
              <button key={s} onClick={() => send(s)} className="block w-full rounded-md bg-surface-muted px-3 py-2 text-left hover:bg-primary-soft">{s}</button>
            ))}
          </Card>
        )}
        {turns.map((turn, i) => (
          <div key={i} className={cn("flex", turn.role === "user" ? "justify-end" : "justify-start")}>
            <div className={cn("max-w-[88%] space-y-3 rounded-lg px-4 py-3 text-sm",
              turn.role === "user" ? "rounded-br-sm bg-primary text-on-primary" : "rounded-bl-sm border border-border bg-surface")}>
              {turn.text && <p className="whitespace-pre-wrap">{turn.text}</p>}
              {turn.cards?.map((card, j) => <CardView key={j} card={card} />)}
              {turn.approval && <ApprovalCard approval={turn.approval} onDecide={(ok) => decide(turn.approval!, ok)} busy={busy} />}
            </div>
          </div>
        ))}
        {busy && <div className="flex items-center gap-2 text-sm text-muted"><Spinner className="size-4" /> Gud Meal is thinking…</div>}
        {error && <p role="alert" className="rounded-md bg-accent-soft p-3 text-sm">{error}</p>}
        <div ref={bottom} />
      </div>

      <form onSubmit={(e) => { e.preventDefault(); void send(text); }}
        className="sticky bottom-4 mt-4 flex items-center gap-2 rounded-full border border-border bg-surface p-1.5 pl-4 shadow-raised">
        <label htmlFor="msg" className="sr-only">Message</label>
        <input id="msg" value={text} onChange={(e) => setText(e.target.value)} maxLength={2000} placeholder="What are you craving?"
          className="min-w-0 flex-1 bg-transparent py-2 text-sm outline-none" disabled={busy} />
        <button type="button" onClick={listen} aria-label="Speak" className={cn("rounded-full p-2 hover:bg-surface-muted", listening && "text-primary")}>
          <Mic className="size-5" />
        </button>
        <Button type="submit" disabled={!text.trim() || busy} aria-label="Send"><Send className="size-4" /></Button>
      </form>
    </div>
  );
}

function CardView({ card }: { card: ChatCard }) {
  if (card.type === "meal_plans") {
    const plans = (card.plans as { plan_ref: string; restaurant: string; items: string[]; total: string; arrives_around: string | null }[]) ?? [];
    return (
      <div className="grid gap-2">
        {plans.map((p) => (
          <div key={p.plan_ref} className="rounded-md border border-border bg-background p-3">
            <div className="flex items-center justify-between gap-2"><p className="font-semibold">{p.restaurant}</p><Badge tone="success">{p.total}</Badge></div>
            <p className="text-xs text-muted">{p.items.join(" · ")}{p.arrives_around ? ` · arrives ~${p.arrives_around}` : ""}</p>
          </div>
        ))}
      </div>
    );
  }
  if (card.type === "payment_link") {
    return (
      <a href={String(card.url)} className="flex items-center justify-between gap-2 rounded-md bg-secondary px-4 py-3 font-semibold text-on-secondary">
        <span className="flex items-center gap-2"><CreditCard className="size-4" /> Pay {String(card.amount)} securely</span><span>→</span>
      </a>
    );
  }
  if (card.type === "order_status" || card.type === "order_draft") {
    const o = card.order as { order_id: string; status_label?: string; total?: string; restaurant?: string };
    return (
      <Link href={`/orders/${o.order_id}`} className="block rounded-md border border-border bg-background p-3 text-xs hover:border-primary">
        <span className="font-semibold">{o.restaurant}</span> · {o.status_label} · {o.total}
      </Link>
    );
  }
  return null;
}

function ApprovalCard({ approval, onDecide, busy }: { approval: ChatApproval; onDecide: (ok: boolean) => void; busy: boolean }) {
  const order = approval.preview.order as undefined | { items: string[]; subtotal: string; delivery_fee: string; service_fee: string; vat: string; discount: string | null; total: string; estimated_arrival: string | null };
  return (
    <div className="space-y-3 rounded-md border-2 border-primary/40 bg-background p-4">
      <p className="flex items-center gap-2 font-semibold"><ShieldCheck className="size-4 text-secondary" /> {approval.preview.title}</p>
      {order && (
        <dl className="space-y-1 text-xs">
          {order.items.map((i) => <p key={i}>{i}</p>)}
          <div className="flex justify-between pt-1"><dt className="text-muted">Subtotal</dt><dd>{order.subtotal}</dd></div>
          <div className="flex justify-between"><dt className="text-muted">Delivery</dt><dd>{order.delivery_fee}</dd></div>
          <div className="flex justify-between"><dt className="text-muted">Service fee</dt><dd>{order.service_fee}</dd></div>
          <div className="flex justify-between"><dt className="text-muted">VAT</dt><dd>{order.vat}</dd></div>
          {order.discount && <div className="flex justify-between text-secondary"><dt>Discount</dt><dd>-{order.discount}</dd></div>}
          <div className="flex justify-between border-t border-border pt-1 text-sm font-bold"><dt>Total</dt><dd>{order.total}</dd></div>
          {order.estimated_arrival && <p className="text-muted">Estimated arrival {order.estimated_arrival}</p>}
        </dl>
      )}
      {approval.preview.message && <p className="text-xs text-muted">{approval.preview.message}</p>}
      <div className="flex gap-2">
        <Button size="sm" onClick={() => onDecide(true)} disabled={busy}>Approve</Button>
        <Button size="sm" variant="outline" onClick={() => onDecide(false)} disabled={busy}>Not now</Button>
      </div>
    </div>
  );
}
