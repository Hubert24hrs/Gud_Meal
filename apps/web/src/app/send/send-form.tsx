"use client";

import {
  ApiError,
  formatNaira,
  formatTime,
  newIdempotencyKey,
  type ParcelCategory,
  type ParcelQuote,
  type ParcelSize,
  type ParcelStop,
  type PlaceArea,
} from "@gudmeal/api-client";
import { Button, Field, Input, Select } from "@gudmeal/ui";
import { useQuery } from "@tanstack/react-query";
import { CircleDot, MapPin, Package, Timer } from "lucide-react";
import { useEffect, useRef, useState } from "react";
import { ParcelArt } from "@/components/illustrations";
import { publicApi, useApi } from "@/lib/api";
import { useAuth } from "@/lib/auth";
import { AREAS, CITY_NAMES, useLocation } from "@/lib/location";

const SIZES: { id: ParcelSize; label: string; hint: string }[] = [
  { id: "small", label: "Small", hint: "Documents, phone, shoes · up to 5 kg" },
  { id: "medium", label: "Medium", hint: "Shoebox to small carton · up to 10 kg" },
  { id: "large", label: "Large", hint: "Bulky but fits a bike · up to 20 kg" },
];
const CATEGORIES: Record<ParcelCategory, string> = {
  documents: "Documents", clothing: "Clothing", electronics: "Electronics", food: "Food",
  cosmetics: "Cosmetics", household: "Household", other: "Other",
};
const PHONE = /^\+?[0-9 ]{7,20}$/;

interface StopState { area: string; line1: string; name: string; phone: string; notes: string }

export function SendForm() {
  const api = useApi();
  const { user } = useAuth();
  const { area } = useLocation();
  const areas = useQuery({ queryKey: ["areas"], queryFn: () => publicApi.catalog.areas() });
  const list: PlaceArea[] = areas.data ?? AREAS.map((a) => ({ name: a.name, city: a.city, lat: a.location.lat, lng: a.location.lng }));
  const [pickup, setPickup] = useState<StopState>({ area: area.name, line1: "", name: "", phone: "", notes: "" });
  const [dropoff, setDropoff] = useState<StopState>({ area: "", line1: "", name: "", phone: "", notes: "" });
  const [size, setSize] = useState<ParcelSize>("small");
  const [category, setCategory] = useState<ParcelCategory>("documents");
  const [what, setWhat] = useState("");
  const [when, setWhen] = useState<string>("");
  const [quote, setQuote] = useState<ParcelQuote | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  const orderKey = useRef(newIdempotencyKey("parcel"));
  const checkoutKey = useRef(newIdempotencyKey("checkout"));

  useEffect(() => {
    setPickup((p) => ({ ...p, name: p.name || user?.displayName || "", phone: p.phone || user?.phoneNumber || "" }));
  }, [user]);

  const changed = () => setQuote(null);
  const find = (name: string) => list.find((a) => a.name === name);

  function validate(): string | null {
    for (const [label, s] of [["pickup", pickup], ["drop-off", dropoff]] as const) {
      if (!find(s.area)) return `Choose the ${label} area`;
      if (s.line1.trim().length < 3) return `Enter the ${label} street address`;
      if (s.name.trim().length < 2) return `Enter the ${label === "pickup" ? "sender" : "recipient"}’s name`;
      if (!PHONE.test(s.phone.trim())) return `Enter a valid ${label === "pickup" ? "sender" : "recipient"} phone number`;
    }
    if (find(pickup.area)!.city !== find(dropoff.area)!.city) {
      return "Pickup and drop-off must be in the same city. Interstate waybill is coming soon.";
    }
    return null;
  }

  const stop = (s: StopState): ParcelStop => {
    const a = find(s.area)!;
    return {
      name: s.name.trim(), phone: s.phone.trim(), line1: s.line1.trim(), area: a.name,
      city: CITY_NAMES[a.city as "lagos" | "enugu"] ?? a.city, location: { lat: a.lat, lng: a.lng },
      instructions: s.notes.trim() || null,
    };
  };

  async function getPrice() {
    const problem = validate();
    if (problem) return setError(problem);
    setBusy(true);
    setError(null);
    try {
      setQuote(await api.parcels.quote({
        pickup: stop(pickup), dropoff: stop(dropoff), size, category, description: what.trim(),
        scheduled_for: when ? new Date(when).toISOString() : null,
      }));
    } catch (e) {
      setError(e instanceof ApiError ? e.message : "Couldn’t get a price. Please try again.");
    } finally {
      setBusy(false);
    }
  }

  async function book() {
    if (!quote) return;
    setBusy(true);
    setError(null);
    try {
      const order = await api.parcels.book(quote.id, orderKey.current);
      const res = await api.orders.checkout(order.id, checkoutKey.current);
      window.location.assign(res.authorization_url); // provider-hosted page; card data never touches Gud Meal
    } catch (e) {
      setError(e instanceof ApiError ? e.message : "Couldn’t book the delivery. Please try again.");
      setBusy(false);
    }
  }

  const stopFields = (s: StopState, set: (v: StopState) => void, who: "Sender" | "Recipient") => (
    <div className="grid gap-3 sm:grid-cols-2">
      <Field label="Area" htmlFor={`${who}-area`}>
        <Select id={`${who}-area`} value={s.area} onChange={(e) => { set({ ...s, area: e.target.value }); changed(); }}>
          <option value="">Choose area</option>
          {(["lagos", "enugu"] as const).map((city) => (
            <optgroup key={city} label={CITY_NAMES[city]}>
              {list.filter((a) => a.city === city).map((a) => <option key={a.name} value={a.name}>{a.name}</option>)}
            </optgroup>
          ))}
        </Select>
      </Field>
      <Field label="Street address and landmark" htmlFor={`${who}-line`}>
        <Input id={`${who}-line`} value={s.line1} onChange={(e) => { set({ ...s, line1: e.target.value }); changed(); }} />
      </Field>
      <Field label={`${who} name`} htmlFor={`${who}-name`}>
        <Input id={`${who}-name`} value={s.name} onChange={(e) => { set({ ...s, name: e.target.value }); changed(); }} />
      </Field>
      <Field label={`${who} phone`} htmlFor={`${who}-phone`}>
        <Input id={`${who}-phone`} inputMode="tel" value={s.phone} onChange={(e) => { set({ ...s, phone: e.target.value }); changed(); }} />
      </Field>
      <div className="sm:col-span-2">
        <Field label="Instructions for the rider (optional)" htmlFor={`${who}-notes`}>
          <Input id={`${who}-notes`} value={s.notes} onChange={(e) => set({ ...s, notes: e.target.value })} />
        </Field>
      </div>
    </div>
  );

  const b = quote?.breakdown;
  return (
    <div className="container-page max-w-3xl space-y-6 pb-32 pt-6 md:pb-12">
      <div className="flex items-center gap-4 rounded-2xl bg-secondary-soft p-4">
        <ParcelArt className="w-24 shrink-0" />
        <div>
          <h1 className="text-3xl font-black tracking-tight">Package Delivery</h1>
          <p className="text-muted">Send anything that fits on a bike, across Lagos or Enugu. You see the exact price before you pay.</p>
        </div>
      </div>

      <section className="space-y-3">
        <h2 className="flex items-center gap-2 text-lg font-extrabold"><CircleDot className="size-5 text-primary" aria-hidden="true" /> Pickup</h2>
        {stopFields(pickup, setPickup, "Sender")}
      </section>
      <section className="space-y-3">
        <h2 className="flex items-center gap-2 text-lg font-extrabold"><MapPin className="size-5 text-primary" aria-hidden="true" /> Drop-off</h2>
        {stopFields(dropoff, setDropoff, "Recipient")}
      </section>

      <section className="space-y-3">
        <h2 className="flex items-center gap-2 text-lg font-extrabold"><Package className="size-5 text-primary" aria-hidden="true" /> What are you sending?</h2>
        <div className="grid gap-2 sm:grid-cols-3" role="radiogroup" aria-label="Package size">
          {SIZES.map((s) => (
            <button key={s.id} type="button" role="radio" aria-checked={size === s.id} onClick={() => { setSize(s.id); changed(); }}
              className={`rounded-2xl border-2 p-3 text-left ${size === s.id ? "border-primary bg-primary-soft" : "border-border"}`}>
              <span className="block font-bold">{s.label}</span>
              <span className="text-sm text-muted">{s.hint}</span>
            </button>
          ))}
        </div>
        <div className="flex flex-wrap gap-2">
          {(Object.keys(CATEGORIES) as ParcelCategory[]).map((c) => (
            <button key={c} type="button" aria-pressed={category === c} onClick={() => { setCategory(c); changed(); }}
              className={`rounded-full border px-3 py-1.5 text-sm font-semibold ${category === c ? "border-primary bg-primary-soft" : "border-border"}`}>
              {CATEGORIES[c]}
            </button>
          ))}
        </div>
        <Field label="Short description (optional)" htmlFor="what">
          <Input id="what" maxLength={200} value={what} onChange={(e) => { setWhat(e.target.value); changed(); }} />
        </Field>
      </section>

      <section className="space-y-3">
        <h2 className="flex items-center gap-2 text-lg font-extrabold"><Timer className="size-5 text-primary" aria-hidden="true" /> When?</h2>
        <div className="flex flex-wrap items-center gap-3">
          <button type="button" aria-pressed={!when} onClick={() => { setWhen(""); changed(); }}
            className={`rounded-full border px-4 py-2 font-semibold ${!when ? "border-primary bg-primary-soft" : "border-border"}`}>Now</button>
          <label className="flex items-center gap-2 text-sm">
            <span className="font-semibold">Schedule</span>
            <input type="datetime-local" value={when} onChange={(e) => { setWhen(e.target.value); changed(); }}
              className="rounded-md border border-border bg-surface px-3 py-2" aria-label="Scheduled pickup time" />
          </label>
        </div>
        <p className="text-xs text-muted">Scheduled pickups: 30 minutes to 7 days ahead, between 7am and 9pm.</p>
      </section>

      <div className="grid gap-2 sm:grid-cols-2">
        {[["Cash on delivery for vendors", "Riders collect payment from your buyer and we pay you out."], ["Interstate waybill", "Send between Lagos, Enugu and other states."]].map(([t, d]) => (
          <div key={t} className="rounded-2xl border border-dashed border-border p-3 opacity-80">
            <p className="font-bold">{t} <span className="ml-1 rounded bg-accent-soft px-1.5 py-0.5 text-[11px] font-bold">Coming soon</span></p>
            <p className="text-sm text-muted">{d}</p>
          </div>
        ))}
      </div>

      {quote && b && (
        <div className="rounded-2xl border border-border bg-surface p-4" aria-live="polite">
          <Row label={`Delivery (${quote.distance_km.toFixed(1)} km, ${size})`} value={b.delivery_fee_kobo} />
          <Row label="Booking fee" value={b.service_fee_kobo} />
          <Row label="VAT (7.5%)" value={b.vat_kobo} />
          <div className="my-2 border-t border-border" />
          <Row label="Total" value={b.total_kobo} bold />
          <p className="mt-2 text-xs text-muted">
            {quote.scheduled_for ? "Scheduled pickup" : "Rider assigned after payment"} · delivered around {formatTime(quote.estimated_delivery_at)} · price held until {formatTime(quote.expires_at)}
          </p>
        </div>
      )}

      <div className="fixed inset-x-0 bottom-[64px] z-20 border-t border-border bg-background/95 p-3 backdrop-blur md:static md:border-0 md:bg-transparent md:p-0">
        {error && <p role="alert" className="mb-2 text-sm font-semibold text-danger">{error}</p>}
        <Button size="lg" block loading={busy} onClick={quote ? book : getPrice}>
          {quote ? `Book & pay ${formatNaira(quote.breakdown.total_kobo)}` : "See price"}
        </Button>
      </div>
    </div>
  );
}

function Row({ label, value, bold = false }: { label: string; value: number; bold?: boolean }) {
  return (
    <p className={`flex justify-between py-0.5 ${bold ? "text-lg font-extrabold" : ""}`}>
      <span>{label}</span>
      <span>{formatNaira(value)}</span>
    </p>
  );
}
