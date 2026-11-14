"use client";

import { formatDateTime, nairaToKobo, type SupportTicket } from "@gudmeal/api-client";
import { Badge, Button, Card, Dialog, EmptyState, ErrorState, Field, Input, Select, Skeleton, Textarea } from "@gudmeal/ui";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import Link from "next/link";
import { useState } from "react";
import { useApi } from "@/lib/api";

const PRIORITY_TONE = { urgent: "danger", high: "warning", normal: "info", low: "neutral" } as const;

export default function SupportPage() {
  const api = useApi();
  const [status, setStatus] = useState("open");
  const [active, setActive] = useState<SupportTicket | null>(null);
  const list = useQuery({ queryKey: ["tickets", status], queryFn: () => api.admin.tickets(status || undefined), refetchInterval: 20_000 });
  return (
    <div className="space-y-4">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <h1 className="font-display text-3xl">Support & disputes</h1>
        <Select value={status} onChange={(e) => setStatus(e.target.value)} className="w-44" aria-label="Status">
          {["open", "escalated", "in_progress", "resolved", "closed", ""].map((s) => <option key={s} value={s}>{s || "All"}</option>)}
        </Select>
      </div>
      {list.isLoading ? <Skeleton className="h-64" /> : list.error ? <ErrorState message={(list.error as Error).message} /> : !list.data?.length ? (
        <EmptyState title="No tickets" body="Customer, rider and AI-escalated issues appear here by priority." />
      ) : (
        <div className="grid gap-3 lg:grid-cols-2">
          {list.data.map((t) => (
            <Card key={t.id} className="space-y-2 p-4">
              <div className="flex flex-wrap items-center gap-2">
                <Badge tone={PRIORITY_TONE[t.priority]}>{t.priority}</Badge>
                <Badge>{t.category.replaceAll("_", " ")}</Badge>
                <Badge tone="info">{t.channel}</Badge>
                <span className="ml-auto text-xs text-muted">{formatDateTime(t.created_at)}</span>
              </div>
              <p className="text-sm">{t.description}</p>
              {t.order_id && <Link href={`/orders/${t.order_id}`} className="text-xs text-primary">Order {t.order_id.slice(0, 8)} →</Link>}
              <Button size="sm" variant="outline" onClick={() => setActive(t)}>Resolve</Button>
            </Card>
          ))}
        </div>
      )}
      {active && <Resolve ticket={active} onClose={() => setActive(null)} />}
    </div>
  );
}

function Resolve({ ticket, onClose }: { ticket: SupportTicket; onClose: () => void }) {
  const api = useApi();
  const qc = useQueryClient();
  const [status, setStatus] = useState("resolved");
  const [resolution, setResolution] = useState("");
  const [refund, setRefund] = useState("");
  const [liability, setLiability] = useState("restaurant");
  const save = useMutation({
    mutationFn: () => api.admin.resolveTicket(ticket.id, {
      status, resolution, refund_amount_kobo: refund ? nairaToKobo(Number(refund)) : undefined, refund_liability: liability,
    }),
    onSuccess: () => { qc.invalidateQueries({ queryKey: ["tickets"] }); onClose(); },
  });
  return (
    <Dialog open onClose={onClose} title="Resolve ticket" footer={
      <div className="flex justify-end gap-2"><Button variant="ghost" onClick={onClose}>Cancel</Button>
        <Button onClick={() => save.mutate()} loading={save.isPending}>Save</Button></div>
    }>
      <div className="space-y-4">
        <p className="text-sm text-muted">{ticket.description}</p>
        <Field label="Status" htmlFor="st"><Select id="st" value={status} onChange={(e) => setStatus(e.target.value)}>
          {["in_progress", "escalated", "resolved", "closed"].map((s) => <option key={s}>{s}</option>)}</Select></Field>
        <Field label="Resolution note" htmlFor="res"><Textarea id="res" value={resolution} onChange={(e) => setResolution(e.target.value)} /></Field>
        {ticket.order_id && (
          <div className="grid gap-3 sm:grid-cols-2">
            <Field label="Request refund (₦)" htmlFor="rf" hint="Finance approves before money moves"><Input id="rf" type="number" min={0} value={refund} onChange={(e) => setRefund(e.target.value)} /></Field>
            <Field label="Who is liable" htmlFor="li"><Select id="li" value={liability} onChange={(e) => setLiability(e.target.value)}>
              <option value="restaurant">Restaurant</option><option value="platform">Platform</option></Select></Field>
          </div>
        )}
        {save.error && <ErrorState message={(save.error as Error).message} />}
      </div>
    </Dialog>
  );
}
