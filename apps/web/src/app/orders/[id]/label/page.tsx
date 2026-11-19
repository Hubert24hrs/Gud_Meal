"use client";

import { formatDateTime, formatNaira } from "@gudmeal/api-client";
import { Button, ErrorState, Skeleton } from "@gudmeal/ui";
import { useQuery } from "@tanstack/react-query";
import { ArrowLeft, Printer } from "lucide-react";
import Link from "next/link";
import { use } from "react";
import { RequireAuth } from "@/components/require-auth";
import { useApi } from "@/lib/api";

export default function LabelPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params);
  return <RequireAuth><WaybillLabel id={id} /></RequireAuth>;
}

/** A printable waybill label. If there's no printer, writing the tracking number on the package is enough. */
function WaybillLabel({ id }: { id: string }) {
  const api = useApi();
  const order = useQuery({ queryKey: ["order", id], queryFn: () => api.orders.get(id) });
  const o = order.data;
  if (order.isLoading) return <div className="container-page max-w-xl py-8"><Skeleton className="h-96" /></div>;
  if (order.error || !o?.waybill) {
    return <div className="container-page max-w-xl py-8"><ErrorState message="This order has no waybill label." /></div>;
  }
  const w = o.waybill;
  const size = `${w.size[0]!.toUpperCase()}${w.size.slice(1)}`;
  return (
    <div className="container-page max-w-xl py-6">
      <div className="mb-4 flex items-center justify-between gap-3 print:hidden">
        <Link href={`/orders/${o.id}`} className="inline-flex items-center gap-1 text-sm font-semibold text-muted hover:text-text">
          <ArrowLeft className="size-4" aria-hidden="true" /> Back to the order
        </Link>
        <Button onClick={() => window.print()}><Printer className="size-4" aria-hidden="true" /> Print label</Button>
      </div>
      <article className="print-area space-y-4 rounded-xl border-2 border-text bg-white p-5 text-black">
        <header className="flex items-start justify-between gap-3 border-b-2 border-black pb-3">
          <div>
            <p className="text-xs font-bold uppercase tracking-wider">Yummy Chops · Interstate waybill</p>
            <p className="font-mono text-3xl font-black tracking-[0.15em] sm:text-4xl">{w.tracking_code}</p>
          </div>
          <p className="text-right text-sm font-bold">{w.origin_city_name}<br />→ {w.destination_city_name}</p>
        </header>
        <div className="grid gap-4 sm:grid-cols-2">
          <section>
            <p className="text-xs font-bold uppercase">From</p>
            <p className="text-lg font-bold">{w.sender.name}</p>
            <p>{w.sender.phone}</p>
            <p className="text-sm">{w.first_mile === "dropoff" ? `Dropped at ${w.origin_hub_name}` : [w.sender.line1, w.sender.area, w.origin_city_name].filter(Boolean).join(", ")}</p>
          </section>
          <section>
            <p className="text-xs font-bold uppercase">To</p>
            <p className="text-lg font-bold">{w.recipient.name}</p>
            <p>{w.recipient.phone}</p>
            <p className="text-sm">
              {w.last_mile === "collect"
                ? `Collect at ${w.destination_hub_name}`
                : [w.recipient.line1, w.recipient.area, w.destination_city_name].filter(Boolean).join(", ")}
            </p>
          </section>
        </div>
        <p className="border-t border-black pt-3 text-sm">
          {size} · {w.weight_kg} kg · {w.category}{w.description ? ` · ${w.description}` : ""}
        </p>
        {w.cod_amount_kobo ? (
          <p className="rounded border-2 border-dashed border-black p-2 text-center text-xl font-black">
            COLLECT {formatNaira(w.cod_amount_kobo)} CASH ON DELIVERY
          </p>
        ) : null}
        <p className="text-xs">
          Carrier: {w.carrier_name} · Booked {formatDateTime(o.created_at)} · Order #{o.short_code}
        </p>
      </article>
      <p className="mt-4 text-sm text-muted print:hidden">
        No printer? Write the tracking number clearly on the package. The hub staff and riders only need that number.
      </p>
    </div>
  );
}
