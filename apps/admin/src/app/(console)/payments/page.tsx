"use client";

import { formatDateTime, formatNaira } from "@gudmeal/api-client";
import { Badge, DataTable, ErrorState, Select, Skeleton } from "@gudmeal/ui";
import { useQuery } from "@tanstack/react-query";
import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import { Suspense } from "react";
import { useApi } from "@/lib/api";

export default function PaymentsPage() {
  return <Suspense><Payments /></Suspense>;
}

function Payments() {
  const api = useApi();
  const router = useRouter();
  const status = useSearchParams().get("status") ?? "";
  const list = useQuery({ queryKey: ["payments", status], queryFn: () => api.admin.payments(status || undefined), refetchInterval: 20_000 });
  return (
    <div className="space-y-4">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <h1 className="font-display text-3xl">Payments</h1>
        <Select value={status} onChange={(e) => router.replace(e.target.value ? `/payments?status=${e.target.value}` : "/payments")} className="w-44" aria-label="Status">
          {["", "pending", "succeeded", "failed", "abandoned", "flagged", "initialized"].map((s) => <option key={s} value={s}>{s || "All"}</option>)}
        </Select>
      </div>
      <p className="text-sm text-muted">Flagged payments were reported successful by the provider but failed server-side checks (amount, currency or reference). They are never fulfilled automatically.</p>
      {list.isLoading ? <Skeleton className="h-64" /> : list.error ? <ErrorState message={(list.error as Error).message} /> : (
        <DataTable rows={list.data ?? []} rowKey={(p) => p.id} empty="No payments" columns={[
          { key: "when", header: "Created", render: (p) => formatDateTime(p.created_at) },
          { key: "ref", header: "Reference", render: (p) => <span className="font-mono text-xs">{p.reference}</span> },
          { key: "order", header: "Order", render: (p) => <Link className="text-primary" href={`/orders/${p.order_id}`}>{p.order_id.slice(0, 8)}</Link> },
          { key: "provider", header: "Provider", render: (p) => p.provider },
          { key: "amount", header: "Amount", render: (p) => formatNaira(p.amount_kobo) },
          { key: "refunded", header: "Refunded", render: (p) => (p.refunded_kobo ? formatNaira(p.refunded_kobo) : "—") },
          { key: "status", header: "Status", render: (p) => <Badge tone={p.status === "succeeded" ? "success" : p.status === "flagged" ? "danger" : "warning"}>{p.status}</Badge> },
        ]} />
      )}
    </div>
  );
}
