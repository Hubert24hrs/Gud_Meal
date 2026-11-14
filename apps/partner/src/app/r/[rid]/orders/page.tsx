"use client";

import { formatTime, type Order, type OrderStatus } from "@gudmeal/api-client";
import { Badge, Button, Card, Dialog, EmptyState, ErrorState, Input, Price, Skeleton, StatusBadge, Textarea } from "@gudmeal/ui";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { BellRing, Bike, ChefHat, Store } from "lucide-react";
import { use, useEffect, useRef, useState } from "react";
import { useApi } from "@/lib/api";

const ACTIVE: OrderStatus[] = ["submitted_to_restaurant", "restaurant_accepted", "preparing", "ready_for_pickup", "rider_assigned"];
const COLUMNS: { title: string; statuses: OrderStatus[]; icon: typeof BellRing }[] = [
  { title: "New", statuses: ["submitted_to_restaurant"], icon: BellRing },
  { title: "In the kitchen", statuses: ["restaurant_accepted", "preparing"], icon: ChefHat },
  { title: "Ready / awaiting rider", statuses: ["ready_for_pickup", "rider_assigned"], icon: Bike },
];

export default function OrdersBoard({ params }: { params: Promise<{ rid: string }> }) {
  const { rid } = use(params);
  const api = useApi();
  const orders = useQuery({ queryKey: ["orders", rid], queryFn: () => api.partner.orders(rid, ACTIVE), refetchInterval: 5000 });
  const seen = useRef<Set<string> | null>(null);

  // Audible + title alert for new orders (kitchens are noisy).
  useEffect(() => {
    if (!orders.data) return;
    const fresh = orders.data.filter((o) => o.status === "submitted_to_restaurant").map((o) => o.id);
    if (seen.current && fresh.some((id) => !seen.current!.has(id))) {
      try {
        const ctx = new AudioContext();
        const osc = ctx.createOscillator();
        osc.frequency.value = 880;
        osc.connect(ctx.destination);
        osc.start();
        osc.stop(ctx.currentTime + 0.25);
      } catch { /* audio blocked until user interaction */ }
    }
    seen.current = new Set(fresh);
    document.title = fresh.length ? `(${fresh.length}) New orders · Gud Meal Partner` : "Orders · Gud Meal Partner";
  }, [orders.data]);

  if (orders.isLoading) return <div className="grid gap-4 lg:grid-cols-3">{[0, 1, 2].map((i) => <Skeleton key={i} className="h-80" />)}</div>;
  if (orders.error) return <ErrorState message={(orders.error as Error).message} onRetry={() => orders.refetch()} />;

  return (
    <div className="grid gap-4 lg:grid-cols-3">
      {COLUMNS.map((col) => {
        const list = (orders.data ?? []).filter((o) => col.statuses.includes(o.status));
        return (
          <section key={col.title} className="space-y-3 rounded-lg bg-surface-muted p-3" aria-label={col.title}>
            <h2 className="flex items-center gap-2 px-1 text-sm font-semibold"><col.icon className="size-4" /> {col.title}
              <Badge tone={col.title === "New" && list.length ? "progress" : "neutral"}>{list.length}</Badge></h2>
            {list.length === 0 ? <p className="px-1 py-6 text-center text-sm text-muted">Nothing here</p>
              : list.map((o) => <OrderCard key={o.id} order={o} rid={rid} />)}
          </section>
        );
      })}
      {orders.data?.length === 0 && (
        <div className="lg:col-span-3"><EmptyState title="No active orders" body="New orders appear here instantly with a sound alert." /></div>
      )}
    </div>
  );
}

function OrderCard({ order, rid }: { order: Order; rid: string }) {
  const api = useApi();
  const qc = useQueryClient();
  const [prep, setPrep] = useState(order.prep_minutes ?? 20);
  const [rejecting, setRejecting] = useState(false);
  const [reason, setReason] = useState("");
  const [code, setCode] = useState("");
  const done = () => qc.invalidateQueries({ queryKey: ["orders", rid] });
  const act = useMutation({ mutationFn: (fn: () => Promise<unknown>) => fn(), onSuccess: done });

  return (
    <Card className="space-y-3 p-4">
      <div className="flex items-start justify-between gap-2">
        <div>
          <p className="font-display text-lg">#{order.short_code}</p>
          <p className="text-xs text-muted">{formatTime(order.created_at)} · {order.customer_name ?? "Customer"}</p>
        </div>
        <div className="flex flex-col items-end gap-1">
          <StatusBadge status={order.status} />
          <Badge tone={order.fulfillment === "pickup" ? "warning" : "info"}>
            {order.fulfillment === "pickup" ? <><Store className="size-3" /> Pickup</> : <><Bike className="size-3" /> Delivery</>}
          </Badge>
        </div>
      </div>
      <ul className="space-y-1 text-sm">
        {order.lines.map((ln, i) => (
          <li key={i}><strong>{ln.quantity}×</strong> {ln.name}
            {ln.selection_labels.length > 0 && <span className="block text-xs text-muted">{ln.selection_labels.join(" · ")}</span>}
            {ln.notes && <span className="block text-xs italic text-primary-strong">“{ln.notes}”</span>}
          </li>
        ))}
      </ul>
      <p className="text-xs text-muted">Your earning: <Price kobo={order.restaurant_earning_kobo} className="font-semibold text-text" /></p>
      {order.rider_name && <p className="text-xs">Rider: <strong>{order.rider_name}</strong>{order.ready_at ? " · marked ready" : ""}</p>}
      {act.error && <p role="alert" className="text-xs text-danger">{(act.error as Error).message}</p>}

      {order.status === "submitted_to_restaurant" && (
        <div className="space-y-2">
          <label className="flex items-center gap-2 text-sm">Prep time
            <Input type="number" min={1} max={180} value={prep} onChange={(e) => setPrep(Number(e.target.value))} className="h-9 w-20" /> min
          </label>
          <div className="flex gap-2">
            <Button block onClick={() => act.mutate(() => api.partner.accept(rid, order.id, prep))} loading={act.isPending}>Accept</Button>
            <Button variant="outline" onClick={() => setRejecting(true)}>Reject</Button>
          </div>
        </div>
      )}
      {order.status === "restaurant_accepted" && (
        <Button block variant="secondary" onClick={() => act.mutate(() => api.partner.preparing(rid, order.id))} loading={act.isPending}>Start preparing</Button>
      )}
      {(order.status === "preparing" || (order.status === "rider_assigned" && !order.ready_at)) && (
        <Button block variant="secondary" onClick={() => act.mutate(() => api.partner.ready(rid, order.id))} loading={act.isPending}>Mark ready</Button>
      )}
      {order.status === "ready_for_pickup" && order.fulfillment === "pickup" && (
        <form className="flex gap-2" onSubmit={(e) => { e.preventDefault(); act.mutate(() => api.partner.handover(rid, order.id, code)); }}>
          <label htmlFor={`code-${order.id}`} className="sr-only">Customer pickup code</label>
          <Input id={`code-${order.id}`} value={code} onChange={(e) => setCode(e.target.value)} inputMode="numeric" maxLength={4} placeholder="Pickup code" className="h-9" />
          <Button type="submit" size="sm" disabled={code.length !== 4}>Hand over</Button>
        </form>
      )}
      <Dialog open={rejecting} onClose={() => setRejecting(false)} title={`Reject #${order.short_code}?`} footer={
        <div className="flex justify-end gap-2">
          <Button variant="ghost" onClick={() => setRejecting(false)}>Keep order</Button>
          <Button variant="danger" disabled={reason.trim().length < 3} loading={act.isPending}
            onClick={() => act.mutate(() => api.partner.reject(rid, order.id, reason.trim()), { onSuccess: () => setRejecting(false) })}>Reject & refund</Button>
        </div>
      }>
        <p className="mb-3 text-sm text-muted">The customer is refunded in full automatically. Frequent rejections affect your ranking.</p>
        <Textarea value={reason} onChange={(e) => setReason(e.target.value)} placeholder="Reason, e.g. item sold out" />
      </Dialog>
    </Card>
  );
}
