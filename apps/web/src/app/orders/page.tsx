"use client";

import { formatDateTime } from "@gudmeal/api-client";
import { Button, EmptyState, ErrorState, Price, Skeleton, StatusBadge } from "@gudmeal/ui";
import { useQuery } from "@tanstack/react-query";
import { Receipt } from "lucide-react";
import Link from "next/link";
import { RequireAuth } from "@/components/require-auth";
import { useApi } from "@/lib/api";

export default function OrdersPage() {
  return <RequireAuth><Orders /></RequireAuth>;
}

function Orders() {
  const api = useApi();
  const orders = useQuery({ queryKey: ["orders"], queryFn: () => api.orders.list(30) });
  return (
    <div className="container-page max-w-3xl space-y-6 py-8">
      <h1 className="font-display text-3xl">Your orders</h1>
      {orders.isLoading ? <Skeleton className="h-40" /> : orders.error ? (
        <ErrorState message={(orders.error as Error).message} onRetry={() => orders.refetch()} />
      ) : !orders.data?.length ? (
        <EmptyState icon={<Receipt className="size-8" />} title="No orders yet" body="Your first Gud Meal is a few taps away."
          action={<Link href="/restaurants"><Button>Find food</Button></Link>} />
      ) : (
        <ul className="space-y-3">
          {orders.data.map((o) => (
            <li key={o.id}>
              <Link href={`/orders/${o.id}`} className="flex items-center justify-between gap-4 rounded-lg border border-border bg-surface p-4 hover:border-primary">
                <div className="min-w-0">
                  <p className="font-semibold">{o.restaurant_name}</p>
                  <p className="truncate text-sm text-muted">{o.lines.map((l) => `${l.quantity}× ${l.name}`).join(", ")}</p>
                  <p className="text-xs text-muted">#{o.short_code} · {formatDateTime(o.created_at)}</p>
                </div>
                <div className="flex shrink-0 flex-col items-end gap-1">
                  <StatusBadge status={o.status} />
                  <Price kobo={o.breakdown.total_kobo} className="text-sm font-semibold" />
                </div>
              </Link>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
