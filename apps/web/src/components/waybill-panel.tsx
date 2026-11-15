"use client";

import type { Order } from "@gudmeal/api-client";
import { Button, Card, Skeleton } from "@gudmeal/ui";
import { useQuery } from "@tanstack/react-query";
import { Link2, Printer } from "lucide-react";
import Link from "next/link";
import { useState } from "react";
import { publicApi } from "@/lib/api";
import { WaybillTimeline } from "./waybill-timeline";

const LIVE = new Set(["paid", "in_transit", "delivered"]);

/** Tracking, label and share link for an interstate waybill on the customer's order page. */
export function WaybillPanel({ order }: { order: Order }) {
  const code = order.waybill?.tracking_code;
  const [copied, setCopied] = useState(false);
  const tracking = useQuery({
    queryKey: ["waybill-track", code, order.status, order.waybill?.stage],
    queryFn: () => publicApi.waybills.track(code!),
    enabled: Boolean(code) && order.status !== "draft" && order.status !== "pending_payment",
    refetchInterval: LIVE.has(order.status) ? 15_000 : false,
  });
  if (!code || order.status === "draft" || order.status === "pending_payment") return null;

  async function share() {
    const url = `${window.location.origin}/track/${code}`;
    try {
      await navigator.clipboard.writeText(url);
      setCopied(true);
    } catch {
      window.prompt("Copy the tracking link", url);
    }
  }

  return (
    <Card className="space-y-4 p-5">
      {tracking.data ? <WaybillTimeline data={tracking.data} /> : <Skeleton className="h-40" />}
      <div className="flex flex-wrap gap-2">
        <Link href={`/orders/${order.id}/label`}>
          <Button variant="outline" size="sm"><Printer className="size-4" aria-hidden="true" /> Print label</Button>
        </Link>
        <Button variant="outline" size="sm" onClick={share}>
          <Link2 className="size-4" aria-hidden="true" /> {copied ? "Link copied" : "Copy tracking link"}
        </Button>
      </div>
      <p className="text-xs text-muted">
        Share the tracking link with the recipient. It shows progress only: no names, phone numbers or addresses.
      </p>
    </Card>
  );
}
