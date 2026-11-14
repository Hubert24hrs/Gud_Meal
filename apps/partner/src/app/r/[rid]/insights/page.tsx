"use client";

import { formatDayLabel, formatNaira } from "@gudmeal/api-client";
import { BarChart, Card, ErrorState, Select, Skeleton, Stat } from "@gudmeal/ui";
import { useQuery } from "@tanstack/react-query";
import { use, useState } from "react";
import { useApi } from "@/lib/api";

export default function InsightsPage({ params }: { params: Promise<{ rid: string }> }) {
  const { rid } = use(params);
  const api = useApi();
  const [days, setDays] = useState(14);
  const a = useQuery({ queryKey: ["analytics", rid, days], queryFn: () => api.partner.analytics(rid, days) });

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h2 className="font-display text-2xl">Insights</h2>
        <label className="flex items-center gap-2 text-sm">Period
          <Select value={days} onChange={(e) => setDays(Number(e.target.value))} className="w-36">
            <option value={7}>Last 7 days</option><option value={14}>Last 14 days</option><option value={30}>Last 30 days</option>
          </Select>
        </label>
      </div>
      {a.isLoading ? <Skeleton className="h-80" /> : a.error || !a.data ? (
        <ErrorState message={(a.error as Error)?.message ?? "Unavailable"} onRetry={() => a.refetch()} />
      ) : (
        <>
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
            <Stat label="Gross sales" value={formatNaira(a.data.gross_sales_kobo)} hint={`${a.data.orders_completed} completed orders`} />
            <Stat label="Your earnings" value={formatNaira(a.data.net_earnings_kobo)} hint={`after ${formatNaira(a.data.commission_kobo)} commission`} />
            <Stat label="Average order" value={formatNaira(a.data.average_order_kobo)} />
            <Stat label="Next 7 days (forecast)" value={`${a.data.forecast_next_7_days_orders} orders`}
              hint={a.data.avg_prep_minutes ? `avg prep ${a.data.avg_prep_minutes} min` : "weighted recent average"} />
          </div>
          <Card className="p-5">
            <h3 className="mb-4 font-semibold">Daily sales</h3>
            <BarChart label="Daily gross sales" data={a.data.series.map((s) => ({ label: formatDayLabel(s.date), value: s.gross_kobo }))} format={formatNaira} />
          </Card>
          <Card className="p-5">
            <h3 className="mb-3 font-semibold">Top items</h3>
            {a.data.top_items.length ? (
              <ol className="space-y-2 text-sm">
                {a.data.top_items.map((t, i) => <li key={t.name} className="flex justify-between"><span>{i + 1}. {t.name}</span><span className="tabular-nums text-muted">{t.quantity} sold</span></li>)}
              </ol>
            ) : <p className="text-sm text-muted">Sales data appears after your first completed orders.</p>}
            {a.data.acceptance_rate !== null && <p className="mt-4 text-xs text-muted">Acceptance rate: {Math.round(a.data.acceptance_rate * 100)}%</p>}
          </Card>
        </>
      )}
    </div>
  );
}
