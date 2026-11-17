"use client";

import { ApiError } from "@gudmeal/api-client";
import { Button, Card, Dialog, Spinner } from "@gudmeal/ui";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { Check } from "lucide-react";
import Link from "next/link";
import { useEffect, useState } from "react";
import { useApi } from "@/lib/api";
import { ReceiptPaper, ReceiptPrinter } from "./ui/receipt-printer";

const PILL = "inline-flex items-center gap-1.5 rounded-full px-4 py-2 text-sm font-bold shadow ring-1 ring-black/5";
const PLAIN = "bg-white/90 text-[#2b2a27] hover:bg-white";
const DONE = "bg-[#1f7a4d] text-white hover:bg-[#1a6943]";

/**
 * The receipt printer for one paid order (ADR-0019). The red PRINT button prints the receipt of what was just
 * paid for and keeps it under "My receipts" on the customer's account.
 */
export function ReceiptScreen({ orderId }: { orderId: string }) {
  const api = useApi();
  const qc = useQueryClient();
  const receipt = useQuery({ queryKey: ["receipt", orderId], queryFn: () => api.orders.receipt(orderId), retry: false });
  const save = useMutation({
    mutationFn: () => api.orders.printReceipt(orderId),
    onSuccess: (kept) => {
      qc.setQueryData(["receipt", orderId], kept);
      void qc.invalidateQueries({ queryKey: ["receipts"] });
    },
  });
  const [reading, setReading] = useState(false);

  // The printer covers the whole screen: the page behind it must not scroll.
  const showing = Boolean(receipt.data);
  useEffect(() => {
    if (!showing) return;
    const root = document.documentElement;
    const before = root.style.overflow;
    root.style.overflow = "hidden";
    return () => {
      root.style.overflow = before;
    };
  }, [showing]);

  if (receipt.isLoading) {
    return <div className="container-page grid place-items-center py-20"><Spinner className="size-10 text-primary" /></div>;
  }
  if (!receipt.data) {
    const unpaid = receipt.error instanceof ApiError && receipt.error.code === "order_not_paid";
    return (
      <div className="container-page grid place-items-center py-20">
        <Card className="w-full max-w-md space-y-4 p-8 text-center">
          <h1 className="font-display text-2xl">{unpaid ? "No receipt yet" : "Receipt unavailable"}</h1>
          <p className="text-sm text-muted">
            {unpaid ? "The receipt is ready as soon as this order is paid for." : ((receipt.error as Error | null)?.message ?? "Please try again shortly.")}
          </p>
          <Link href={`/orders/${orderId}`}><Button block>Back to the order</Button></Link>
        </Card>
      </div>
    );
  }

  const r = receipt.data;
  const saved = r.saved && !save.isError;
  return (
    <div className="fixed inset-0 z-[60] bg-[#dcd8cf]">
      <ReceiptPrinter
        receipt={r}
        onPrint={() => save.mutate()}
        notice={save.isError ? "Could not save the receipt. Check your connection, then press PRINT again" : null}
      >
        <div className="absolute inset-x-0 top-0 z-40 flex flex-wrap items-center justify-between gap-2 p-3">
          <Link href={`/orders/${orderId}`} className={`${PILL} ${PLAIN}`}>Track my order</Link>
          <div className="flex flex-wrap justify-end gap-2">
            <button type="button" onClick={() => setReading(true)} className={`${PILL} ${PLAIN}`}>Read receipt</button>
            {/* Where the receipt is kept: the button turns green once this one is in there. */}
            <Link href="/receipts" className={`${PILL} ${saved ? DONE : PLAIN}`}>
              {saved && <Check className="size-4" aria-hidden="true" />}
              {saved ? "Saved in My receipts" : "My receipts"}
            </Link>
          </div>
        </div>
        {saved && <p role="status" className="sr-only">Saved to My receipts</p>}
      </ReceiptPrinter>
      <Dialog open={reading} onClose={() => setReading(false)} title={`Receipt ${r.number}`}>
        <ReceiptPaper receipt={r} />
      </Dialog>
    </div>
  );
}
