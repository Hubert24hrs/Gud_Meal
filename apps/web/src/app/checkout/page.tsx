"use client";

import { ApiError, formatNaira, formatTime, newIdempotencyKey, type DeliveryAddress, type Fulfillment, type Quote } from "@gudmeal/api-client";
import { Button, Card, EmptyState, ErrorState, Field, Input, Price, Select, Skeleton, cn } from "@gudmeal/ui";
import { useMutation, useQuery } from "@tanstack/react-query";
import { Bike, ShieldCheck, Store } from "lucide-react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { useEffect, useMemo, useRef, useState } from "react";
import { checkoutProvider, continueAfterCheckout, PaymentMethodPicker, type PayMethod } from "@/components/payment-method";
import { RequireAuth } from "@/components/require-auth";
import { useApi } from "@/lib/api";
import { toCartLines, useCart } from "@/lib/cart";
import { LAGOS_AREAS, useLocation } from "@/lib/location";

export default function CheckoutPage() {
  return (
    <RequireAuth reason="Sign in to place your order and track it live.">
      <Checkout />
    </RequireAuth>
  );
}

function Checkout() {
  const api = useApi();
  const { cart, clear } = useCart();
  const { area } = useLocation();
  const [fulfillment, setFulfillment] = useState<Fulfillment>("delivery");
  const [addressId, setAddressId] = useState<string>("new");
  const [line1, setLine1] = useState("");
  const [areaName, setAreaName] = useState(area.name);
  const [phone, setPhone] = useState("");
  const [instructions, setInstructions] = useState("");
  const [voucher, setVoucher] = useState("");
  const [appliedVoucher, setAppliedVoucher] = useState<string | null>(null);
  const [method, setMethod] = useState<PayMethod>("card");
  const router = useRouter();
  const orderKey = useRef(newIdempotencyKey("order"));
  const checkoutKeys = useRef<Partial<Record<PayMethod, string>>>({});

  const addresses = useQuery({ queryKey: ["addresses"], queryFn: () => api.me.addresses() });
  useEffect(() => {
    if (addresses.data?.length && addressId === "new") setAddressId(addresses.data[0]!.id);
  }, [addresses.data, addressId]);

  const address: DeliveryAddress | null = useMemo(() => {
    if (fulfillment === "pickup") return null;
    const saved = addresses.data?.find((a) => a.id === addressId);
    if (saved) return saved;
    if (line1.trim().length < 3) return null;
    const a = LAGOS_AREAS.find((x) => x.name === areaName)!;
    return { line1: line1.trim(), area: a.name, location: a.location, contact_phone: phone || null, instructions: instructions || null };
  }, [fulfillment, addresses.data, addressId, line1, areaName, phone, instructions]);

  const quoteReady = cart.items.length > 0 && cart.restaurant_id && (fulfillment === "pickup" || address);
  const quote = useQuery({
    queryKey: ["quote", cart, fulfillment, address, appliedVoucher],
    enabled: Boolean(quoteReady),
    queryFn: () => api.orders.quote({
      restaurant_id: cart.restaurant_id!, lines: toCartLines(cart), fulfillment,
      delivery_address: address, voucher_code: appliedVoucher,
    }),
    retry: false,
  });

  const placeOrder = useMutation({
    mutationFn: async (q: Quote) => {
      if (addressId === "new" && address && fulfillment === "delivery") {
        await api.me.addAddress({ ...address, label: "Saved at checkout" }).catch(() => undefined);
      }
      const order = await api.orders.create(q.id, orderKey.current, "web", phone || undefined);
      // One key per payment method: switching method after a refusal is a new request, a retry is not.
      const key = (checkoutKeys.current[method] ??= newIdempotencyKey("checkout"));
      return api.orders.checkout(order.id, key, checkoutProvider(method));
    },
    onSuccess: (res) => {
      clear();
      continueAfterCheckout(res, router.push);
    },
  });

  if (!cart.items.length) {
    return (
      <div className="container-page py-16">
        <EmptyState title="Your cart is empty" body="Pick a restaurant and add something delicious."
          action={<Link href="/restaurants"><Button>Browse restaurants</Button></Link>} />
      </div>
    );
  }

  const voucherError = quote.error instanceof ApiError && quote.error.code === "voucher_invalid" ? quote.error.message : null;

  return (
    <div className="container-page grid gap-8 py-8 lg:grid-cols-[1fr_400px]">
      <div className="space-y-6">
        <h1 className="font-display text-3xl">Checkout</h1>
        <Card className="space-y-4 p-5">
          <h2 className="font-semibold">How would you like it?</h2>
          <div className="grid grid-cols-2 gap-3" role="radiogroup" aria-label="Fulfilment">
            {([["delivery", "Delivery", Bike], ["pickup", "Pickup", Store]] as const).map(([value, label, Icon]) => (
              <button key={value} role="radio" aria-checked={fulfillment === value} onClick={() => setFulfillment(value)}
                className={cn("flex items-center gap-2 rounded-md border p-3 text-sm font-semibold",
                  fulfillment === value ? "border-primary bg-primary-soft" : "border-border")}>
                <Icon className="size-5" aria-hidden="true" /> {label}
              </button>
            ))}
          </div>
        </Card>

        {fulfillment === "delivery" && (
          <Card className="space-y-4 p-5">
            <h2 className="font-semibold">Delivery address</h2>
            {addresses.isLoading ? <Skeleton className="h-11" /> : (
              <Field label="Address" htmlFor="addr">
                <Select id="addr" value={addressId} onChange={(e) => setAddressId(e.target.value)}>
                  {addresses.data?.map((a) => <option key={a.id} value={a.id}>{a.label ? `${a.label} — ` : ""}{a.line1}, {a.area}</option>)}
                  <option value="new">+ New address</option>
                </Select>
              </Field>
            )}
            {addressId === "new" && (
              <div className="grid gap-4 sm:grid-cols-2">
                <Field label="Street address" htmlFor="line1">
                  <Input id="line1" value={line1} onChange={(e) => setLine1(e.target.value)} placeholder="12 Admiralty Way" autoComplete="street-address" />
                </Field>
                <Field label="Area" htmlFor="area">
                  <Select id="area" value={areaName} onChange={(e) => setAreaName(e.target.value)}>
                    {LAGOS_AREAS.map((a) => <option key={a.name}>{a.name}</option>)}
                  </Select>
                </Field>
                <Field label="Phone for the rider" htmlFor="phone">
                  <Input id="phone" value={phone} onChange={(e) => setPhone(e.target.value)} placeholder="0803 000 0000" inputMode="tel" autoComplete="tel" />
                </Field>
                <Field label="Delivery instructions" htmlFor="ins">
                  <Input id="ins" value={instructions} onChange={(e) => setInstructions(e.target.value)} placeholder="Gate code, landmark…" />
                </Field>
              </div>
            )}
          </Card>
        )}

        <Card className="space-y-3 p-5">
          <h2 className="font-semibold">Payment</h2>
          <PaymentMethodPicker totalKobo={quote.data?.breakdown.total_kobo ?? null} value={method} onChange={setMethod}
            cash={{ offered: true, reason: fulfillment === "pickup" ? "Only for delivery orders" : null }} />
        </Card>

        <Card className="space-y-3 p-5">
          <h2 className="font-semibold">Voucher</h2>
          <form className="flex gap-2" onSubmit={(e) => { e.preventDefault(); setAppliedVoucher(voucher.trim().toUpperCase() || null); }}>
            <label htmlFor="voucher" className="sr-only">Voucher code</label>
            <Input id="voucher" value={voucher} onChange={(e) => setVoucher(e.target.value)} placeholder="e.g. WELCOME500" className="uppercase" />
            <Button type="submit" variant="outline">Apply</Button>
          </form>
          {voucherError && <p className="text-sm text-danger" role="alert">{voucherError}</p>}
          {appliedVoucher && quote.data?.breakdown.voucher_code && <p className="text-sm text-secondary">Voucher {appliedVoucher} applied.</p>}
        </Card>
      </div>

      <aside className="lg:sticky lg:top-24 lg:self-start">
        <Card className="space-y-4 p-5">
          <div>
            <h2 className="font-display text-xl">{cart.restaurant_name}</h2>
            <p className="text-sm text-muted">{cart.items.reduce((n, i) => n + i.quantity, 0)} items</p>
          </div>
          <ul className="space-y-2 text-sm">
            {(quote.data?.lines ?? []).map((ln) => (
              <li key={ln.item_id + ln.selection_labels.join()} className="flex justify-between gap-3">
                <span>{ln.quantity} × {ln.name}{ln.selection_labels.length > 0 && <span className="block text-xs text-muted">{ln.selection_labels.join(" · ")}</span>}</span>
                <Price kobo={ln.line_total_kobo} />
              </li>
            ))}
          </ul>
          {!quoteReady ? (
            <p className="text-sm text-muted">Add a delivery address to see your total.</p>
          ) : quote.isLoading ? (
            <Skeleton className="h-32" />
          ) : quote.error && !voucherError ? (
            <ErrorState message={(quote.error as Error).message} onRetry={() => quote.refetch()} />
          ) : quote.data ? (
            <Breakdown quote={quote.data} />
          ) : null}
          {placeOrder.error && <ErrorState message={(placeOrder.error as Error).message} />}
          <Button block size="lg" disabled={!quote.data || placeOrder.isPending} loading={placeOrder.isPending}
            onClick={() => quote.data && placeOrder.mutate(quote.data)}>
            {method === "cash"
              ? `Place order · pay ${quote.data ? formatNaira(quote.data.breakdown.total_kobo) : ""} on delivery`
              : `Pay ${quote.data ? formatNaira(quote.data.breakdown.total_kobo) : ""}${method === "wallet" ? " from wallet" : ""}`}
          </Button>
          <p className="flex items-start gap-2 text-xs text-muted">
            <ShieldCheck className="mt-0.5 size-4 shrink-0 text-secondary" aria-hidden="true" />
            {method === "card" && "You'll pay on a secure payment page. Your order is sent to the kitchen once we verify the payment."}
            {method === "wallet" && "Paid instantly from your Gud Meal wallet. If the order is cancelled, the money goes straight back."}
            {method === "cash" && "Your order goes to the kitchen now. Pay the rider in cash when it arrives, then share your delivery code."}
          </p>
        </Card>
      </aside>
    </div>
  );
}

function Breakdown({ quote }: { quote: Quote }) {
  const b = quote.breakdown;
  const rows: [string, number][] = [
    ["Subtotal", b.subtotal_kobo],
    ...(b.delivery_fee_kobo ? [["Delivery", b.delivery_fee_kobo] as [string, number]] : []),
    ["Service fee", b.service_fee_kobo],
    ...(b.small_order_fee_kobo ? [["Small order fee", b.small_order_fee_kobo] as [string, number]] : []),
    ["VAT (7.5% on fees)", b.vat_kobo],
  ];
  return (
    <dl className="space-y-1.5 border-t border-border pt-3 text-sm">
      {rows.map(([label, value]) => (
        <div key={label} className="flex justify-between"><dt className="text-muted">{label}</dt><dd><Price kobo={value} /></dd></div>
      ))}
      {b.discount_kobo > 0 && (
        <div className="flex justify-between text-secondary"><dt>Discount</dt><dd>-<Price kobo={b.discount_kobo} /></dd></div>
      )}
      <div className="flex justify-between border-t border-border pt-2 text-base font-bold">
        <dt>Total</dt><dd><Price kobo={b.total_kobo} /></dd>
      </div>
      <p className="pt-1 text-xs text-muted">
        {quote.fulfillment === "delivery" ? `Estimated arrival ${formatTime(quote.estimated_delivery_at)}` : `Ready in about ${quote.eta_minutes} min`}
        {" · "}price held until {formatTime(quote.expires_at)}
      </p>
    </dl>
  );
}
