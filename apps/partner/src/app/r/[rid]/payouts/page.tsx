"use client";

import { formatDateTime, formatNaira } from "@gudmeal/api-client";
import { Badge, DataTable, ErrorState, Skeleton } from "@gudmeal/ui";
import { useQuery } from "@tanstack/react-query";
import { use } from "react";
import { useApi } from "@/lib/api";

export default function PayoutsPage({ params }: { params: Promise<{ rid: string }> }) {
  const { rid } = use(params);
  const api = useApi();
  const s = useQuery({ queryKey: ["settlements", rid], queryFn: () => api.partner.settlements(rid) });
  return (
    <div className="space-y-4">
      <h2 className="font-display text-2xl">Settlements</h2>
      <p className="text-sm text-muted">Statements are generated from GudMeals&apos;s double-entry ledger: your earnings minus commission and any refunds you were responsible for.</p>
      {s.isLoading ? <Skeleton className="h-48" /> : s.error ? (
        <ErrorState message={(s.error as Error).message} onRetry={() => s.refetch()} />
      ) : (
        <DataTable rows={s.data ?? []} rowKey={(r) => r.id} empty="No settlement statements yet" columns={[
          { key: "period", header: "Period", render: (r) => `${formatDateTime(r.period_start)} – ${formatDateTime(r.period_end)}` },
          { key: "orders", header: "Orders", render: (r) => r.orders_count },
          { key: "gross", header: "Gross", render: (r) => formatNaira(r.gross_kobo) },
          { key: "commission", header: "Commission", render: (r) => formatNaira(r.commission_kobo) },
          { key: "adj", header: "Adjustments", render: (r) => formatNaira(r.adjustments_kobo) },
          { key: "net", header: "Net payout", render: (r) => <strong>{formatNaira(r.net_kobo)}</strong> },
          { key: "status", header: "Status", render: (r) => <Badge tone={r.status === "paid" ? "success" : "warning"}>{r.status}</Badge> },
        ]} />
      )}
    </div>
  );
}
