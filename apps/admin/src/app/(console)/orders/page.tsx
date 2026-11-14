"use client";

import { formatDateTime, formatNaira, ORDER_STATUS, type OrderStatus } from "@gudmeal/api-client";
import { DataTable, ErrorState, Select, Skeleton, StatusBadge } from "@gudmeal/ui";
import { useQuery } from "@tanstack/react-query";
import { useRouter, useSearchParams } from "next/navigation";
import { Suspense } from "react";
import { useApi } from "@/lib/api";

export default function OrdersPage() {
  return <Suspense><Orders /></Suspense>;
}

function Orders() {
  const api = useApi();
  const router = useRouter();
  const status = (useSearchParams().get("status") ?? "") as OrderStatus | "";
  const orders = useQuery({ queryKey: ["admin-orders", status], queryFn: () => api.admin.orders(status || undefined), refetchInterval: 10_000 });
  return (
    <div className="space-y-4">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <h1 className="font-display text-3xl">Orders</h1>
        <label className="flex items-center gap-2 text-sm">Status
          <Select value={status} onChange={(e) => router.replace(e.target.value ? `/orders?status=${e.target.value}` : "/orders")} className="w-56">
            <option value="">All</option>
            {Object.entries(ORDER_STATUS).map(([k, v]) => <option key={k} value={k}>{v.label}</option>)}
          </Select>
        </label>
      </div>
      {orders.isLoading ? <Skeleton className="h-96" /> : orders.error ? (
        <ErrorState message={(orders.error as Error).message} onRetry={() => orders.refetch()} />
      ) : (
        <DataTable rows={orders.data ?? []} rowKey={(o) => o.id} empty="No orders" onRowClick={(o) => router.push(`/orders/${o.id}`)} columns={[
          { key: "code", header: "Order", render: (o) => <span className="font-semibold">#{o.short_code}</span> },
          { key: "when", header: "Placed", render: (o) => formatDateTime(o.created_at) },
          { key: "restaurant", header: "Restaurant", render: (o) => o.restaurant_name },
          { key: "customer", header: "Customer", render: (o) => o.customer_name ?? o.customer_id.slice(0, 8) },
          { key: "channel", header: "Channel", render: (o) => o.channel },
          { key: "total", header: "Total", render: (o) => formatNaira(o.breakdown.total_kobo), className: "tabular-nums" },
          { key: "status", header: "Status", render: (o) => <StatusBadge status={o.status} /> },
        ]} />
      )}
    </div>
  );
}
