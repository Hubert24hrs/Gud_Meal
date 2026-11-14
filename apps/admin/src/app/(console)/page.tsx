"use client";

import { formatNaira, ORDER_STATUS, type OrderStatus } from "@gudmeal/api-client";
import { Badge, BarChart, Card, ErrorState, Skeleton, Stat, StatusBadge } from "@gudmeal/ui";
import { useQuery } from "@tanstack/react-query";
import Link from "next/link";
import { useApi } from "@/lib/api";

export default function Overview() {
  const api = useApi();
  const o = useQuery({ queryKey: ["overview"], queryFn: () => api.admin.overview(), refetchInterval: 15_000 });
  const a = useQuery({ queryKey: ["analytics", 14], queryFn: () => api.admin.analytics(14) });
  if (o.isLoading) return <Skeleton className="h-96" />;
  if (o.error || !o.data) return <ErrorState message={(o.error as Error)?.message ?? "Unavailable"} onRetry={() => o.refetch()} />;
  const d = o.data;
  return (
    <div className="space-y-6">
      <div className="flex items-end justify-between">
        <h1 className="font-display text-3xl">Real-time overview</h1>
        <p className="text-xs text-muted">Auto-refreshes every 15s</p>
      </div>
      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <Stat label="Orders today" value={d.orders_today} hint={`${d.active_orders} in progress`} />
        <Stat label="GMV today" value={formatNaira(d.gmv_today_kobo)} hint={`Platform revenue ${formatNaira(d.platform_revenue_today_kobo)}`} />
        <Stat label="Riders online" value={d.riders_online} hint={`${d.riders_busy} on a delivery`} />
        <Stat label="Needs attention" value={d.stuck_orders.length + d.flagged_payments + d.pending_refunds}
          tone={d.stuck_orders.length + d.flagged_payments ? "danger" : undefined}
          hint={`${d.stuck_orders.length} stuck · ${d.flagged_payments} flagged payments · ${d.pending_refunds} refunds`} />
      </div>
      <div className="grid gap-4 lg:grid-cols-[1.4fr_1fr]">
        <Card className="p-5">
          <h2 className="mb-4 font-semibold">Completed orders · last 14 days</h2>
          {a.data ? <BarChart label="Completed orders per day" data={a.data.series.map((s) => ({ label: s.date.slice(5), value: s.orders }))} />
            : <Skeleton className="h-40" />}
          {a.data && <p className="mt-3 text-xs text-muted">Forecast next 7 days: <strong>{a.data.forecast_next_7_days_orders}</strong> orders</p>}
        </Card>
        <Card className="space-y-3 p-5">
          <h2 className="font-semibold">Exceptions</h2>
          {d.stuck_orders.length === 0 && d.flagged_payments === 0 ? <p className="text-sm text-muted">No exceptions right now. 🎉</p> : null}
          {d.stuck_orders.map((s) => (
            <Link key={s.id} href={`/orders/${s.id}`} className="flex items-center justify-between rounded-md border border-border p-2 text-sm hover:border-primary">
              <span>#{s.short_code} <StatusBadge status={s.status} /></span>
              <Badge tone="danger">{s.minutes_since_update} min idle</Badge>
            </Link>
          ))}
          {d.flagged_payments > 0 && <Link href="/payments?status=flagged" className="block text-sm font-semibold text-danger">{d.flagged_payments} flagged payment(s) → review</Link>}
          <div className="flex flex-wrap gap-2 pt-2 text-sm">
            <Link href="/applications" className="rounded-full bg-surface-muted px-3 py-1">{d.pending_applications} applications</Link>
            <Link href="/support" className="rounded-full bg-surface-muted px-3 py-1">{d.open_tickets} open tickets</Link>
            <Link href="/refunds" className="rounded-full bg-surface-muted px-3 py-1">{d.pending_refunds} refunds to review</Link>
          </div>
        </Card>
      </div>
      <Card className="p-5">
        <h2 className="mb-3 font-semibold">Today by status</h2>
        <div className="flex flex-wrap gap-2">
          {Object.entries(d.orders_by_status).map(([status, n]) => (
            <Link key={status} href={`/orders?status=${status}`} className="rounded-full border border-border px-3 py-1 text-sm hover:border-primary">
              {ORDER_STATUS[status as OrderStatus]?.label ?? status}: <strong>{n}</strong>
            </Link>
          ))}
          {Object.keys(d.orders_by_status).length === 0 && <p className="text-sm text-muted">No orders yet today.</p>}
        </div>
      </Card>
    </div>
  );
}
