"use client";

import { formatDateTime, formatNaira, newIdempotencyKey } from "@gudmeal/api-client";
import { Badge, Button, Card, DataTable, ErrorState, Field, Input, Select, Skeleton, Stat } from "@gudmeal/ui";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useRef, useState } from "react";
import { useApi } from "@/lib/api";

type Method = "bank_transfer" | "cash_deposit" | "earnings_offset";
const METHODS: Record<Method, string> = {
  bank_transfer: "Bank transfer from the rider",
  cash_deposit: "Cash paid in at a bank or hub",
  earnings_offset: "Deduct from the rider's earnings",
};

export default function CashPage() {
  const api = useApi();
  const qc = useQueryClient();
  const cash = useQuery({ queryKey: ["cash"], queryFn: () => api.admin.cash() });
  const sellerPayouts = useQuery({ queryKey: ["seller-payouts"], queryFn: () => api.admin.sellerPayouts("requested") });
  const [rider, setRider] = useState<string | null>(null);
  const [amount, setAmount] = useState("");
  const [method, setMethod] = useState<Method>("bank_transfer");
  const [reference, setReference] = useState("");
  const remitKey = useRef(newIdempotencyKey("remit"));
  const [customer, setCustomer] = useState({ uid: "", reason: "", blocked: true });

  const remit = useMutation({
    mutationFn: () => api.admin.recordRemittance(rider!, {
      amount_kobo: Math.round(Number(amount) * 100), method, reference: reference.trim() || undefined,
    }, remitKey.current),
    onSuccess: () => {
      remitKey.current = newIdempotencyKey("remit");
      setRider(null); setAmount(""); setReference("");
      qc.invalidateQueries({ queryKey: ["cash"] });
    },
  });
  const decide = useMutation({
    mutationFn: ({ id, approve }: { id: string; approve: boolean }) => {
      if (!approve) return api.admin.decideSellerPayout(id, false, undefined, window.prompt("Reason (shown to the seller)") ?? undefined);
      const ref = window.prompt("Bank transfer reference") ?? "";
      if (ref.trim().length < 4) throw new Error("A bank transfer reference is required");
      return api.admin.decideSellerPayout(id, true, ref.trim());
    },
    onSuccess: () => { qc.invalidateQueries({ queryKey: ["seller-payouts"] }); qc.invalidateQueries({ queryKey: ["cash"] }); },
  });
  const block = useMutation({
    mutationFn: () => api.admin.setPayOnDelivery(customer.uid.trim(), customer.blocked, customer.reason.trim()),
  });

  const c = cash.data;
  const selected = c?.riders.find((r) => r.rider_id === rider);
  return (
    <div className="space-y-6">
      <div>
        <h1 className="font-display text-3xl">Cash &amp; wallets</h1>
        <p className="text-sm text-muted">Cash riders collected at the door (pay on delivery and sellers&apos; cash on delivery), money in customer wallets, and seller withdrawals.</p>
      </div>

      {cash.isLoading ? <Skeleton className="h-28" /> : cash.error ? <ErrorState message={(cash.error as Error).message} /> : c && (
        <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
          <Stat label="Cash with riders" value={formatNaira(c.totals.cash_with_riders_kobo)} hint={`${c.riders.length} rider(s) to collect from`} />
          <Stat label="Customer wallets" value={formatNaira(c.totals.wallet_balances_kobo)} hint="Owed to customers as wallet credit" />
          <Stat label="Owed to sellers" value={formatNaira(c.totals.seller_balances_kobo)} hint="Cash-on-delivery money not yet paid out" />
          <Stat label="Rider cash limit" value={formatNaira(c.rider_cash_limit_kobo)} hint="No cash jobs above this" />
        </div>
      )}

      <Card className="space-y-4 p-5">
        <h2 className="font-semibold">Riders holding cash</h2>
        <DataTable rows={c?.riders ?? []} rowKey={(r) => r.rider_id} empty="No rider is holding cash" columns={[
          { key: "n", header: "Rider", render: (r) => <span>{r.name}<span className="block text-xs text-muted">{r.phone ?? r.rider_id}</span></span> },
          { key: "c", header: "Cash held", render: (r) => <strong>{formatNaira(r.cash_held_kobo)}</strong> },
          { key: "e", header: "Earnings owed", render: (r) => formatNaira(r.earnings_kobo) },
          { key: "l", header: "", render: (r) => (r.over_limit ? <Badge tone="danger">Over limit</Badge> : null) },
          { key: "a", header: "", render: (r) => (
            <Button size="sm" variant={rider === r.rider_id ? "primary" : "outline"}
              onClick={() => { setRider(r.rider_id); setAmount(String(r.cash_held_kobo / 100)); }}>Record hand-in</Button>
          ) },
        ]} />
        {selected && (
          <form className="grid gap-3 rounded-lg border border-border p-4 sm:grid-cols-4" onSubmit={(e) => { e.preventDefault(); remit.mutate(); }}>
            <p className="font-semibold sm:col-span-4">Hand-in from {selected.name}</p>
            <Field label="Amount (₦)" htmlFor="amt"><Input id="amt" inputMode="decimal" value={amount} onChange={(e) => setAmount(e.target.value)} /></Field>
            <Field label="How" htmlFor="how">
              <Select id="how" value={method} onChange={(e) => setMethod(e.target.value as Method)}>
                {(Object.keys(METHODS) as Method[]).map((m) => <option key={m} value={m}>{METHODS[m]}</option>)}
              </Select>
            </Field>
            <Field label={method === "earnings_offset" ? "Note (optional)" : "Bank or receipt reference"} htmlFor="ref">
              <Input id="ref" value={reference} onChange={(e) => setReference(e.target.value)} />
            </Field>
            <div className="flex items-end gap-2">
              <Button type="submit" loading={remit.isPending} disabled={!Number(amount)}>Record</Button>
              <Button type="button" variant="outline" onClick={() => setRider(null)}>Cancel</Button>
            </div>
            {remit.error && <div className="sm:col-span-4"><ErrorState message={(remit.error as Error).message} /></div>}
          </form>
        )}
      </Card>

      <Card className="space-y-4 p-5">
        <h2 className="font-semibold">Seller withdrawals (cash on delivery)</h2>
        {decide.error && <ErrorState message={(decide.error as Error).message} />}
        <DataTable rows={sellerPayouts.data ?? []} rowKey={(p) => p.id} empty="No withdrawals waiting" columns={[
          { key: "s", header: "Seller", render: (p) => p.vendor_id },
          { key: "b", header: "Pay to", render: (p) => <span>{p.account_name}<span className="block text-xs text-muted">{p.bank_name} · {p.account_number}</span></span> },
          { key: "a", header: "Amount", render: (p) => <strong>{formatNaira(p.amount_kobo)}</strong> },
          { key: "t", header: "Requested", render: (p) => formatDateTime(p.requested_at) },
          { key: "x", header: "", render: (p) => (
            <div className="flex gap-2">
              <Button size="sm" onClick={() => decide.mutate({ id: p.id, approve: true })}>Paid</Button>
              <Button size="sm" variant="outline" onClick={() => decide.mutate({ id: p.id, approve: false })}>Reject</Button>
            </div>
          ) },
        ]} />
      </Card>

      <Card className="space-y-3 p-5">
        <h2 className="font-semibold">Pay on delivery for a customer</h2>
        <p className="text-sm text-muted">Switch cash payments off after a refused or failed cash delivery (or back on). The change is audited.</p>
        <form className="grid gap-3 sm:grid-cols-4" onSubmit={(e) => { e.preventDefault(); block.mutate(); }}>
          <Field label="Customer ID" htmlFor="uid"><Input id="uid" value={customer.uid} onChange={(e) => setCustomer({ ...customer, uid: e.target.value })} /></Field>
          <Field label="Action" htmlFor="act">
            <Select id="act" value={customer.blocked ? "off" : "on"} onChange={(e) => setCustomer({ ...customer, blocked: e.target.value === "off" })}>
              <option value="off">Turn pay on delivery off</option>
              <option value="on">Turn pay on delivery back on</option>
            </Select>
          </Field>
          <Field label="Reason" htmlFor="why"><Input id="why" value={customer.reason} onChange={(e) => setCustomer({ ...customer, reason: e.target.value })} /></Field>
          <div className="flex items-end">
            <Button type="submit" loading={block.isPending} disabled={!customer.uid.trim() || customer.reason.trim().length < 3}>Save</Button>
          </div>
        </form>
        {block.error && <ErrorState message={(block.error as Error).message} />}
        {block.isSuccess && <p className="text-sm text-secondary">Saved for {block.data.uid}.</p>}
      </Card>
    </div>
  );
}
