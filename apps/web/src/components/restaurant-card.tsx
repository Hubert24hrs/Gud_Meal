import type { RestaurantCard as Card } from "@gudmeal/api-client";
import { formatNaira } from "@gudmeal/api-client";
import { Badge, cn } from "@gudmeal/ui";
import { Clock, Star } from "lucide-react";
import Image from "next/image";
import Link from "next/link";

const PALETTES = [
  ["#E85D32", "#F5B942"], ["#1D754E", "#9BD2A7"], ["#B4442A", "#F28C5B"], ["#2B5D4A", "#E8C468"],
  ["#7A3E2C", "#E9A46A"], ["#145C43", "#F5B942"],
];

/** Restaurant artwork: uploaded cover photo when present, otherwise a branded duotone tile. */
export function RestaurantArt({ card, className, label = true }: { card: Pick<Card, "id" | "name" | "cover_url" | "cuisines">; className?: string; label?: boolean }) {
  if (card.cover_url) {
    return (
      <div className={cn("relative overflow-hidden", className)}>
        <Image src={card.cover_url} alt="" fill sizes="(max-width: 768px) 100vw, 33vw" className="object-cover" />
      </div>
    );
  }
  const idx = [...card.id].reduce((a, c) => a + c.charCodeAt(0), 0) % PALETTES.length;
  const [a, b] = PALETTES[idx]!;
  const initials = card.name.split(/\s+/).slice(0, 2).map((w) => w[0]).join("");
  return (
    <div className={cn("relative flex items-end overflow-hidden", className)}
      style={{ background: `radial-gradient(120% 120% at 100% 0%, ${b} 0%, ${a} 55%)` }} aria-hidden="true">
      <svg className="absolute inset-0 size-full opacity-[.12]" viewBox="0 0 100 60" preserveAspectRatio="none">
        <defs>
          <pattern id={`p-${card.id}`} width="10" height="10" patternUnits="userSpaceOnUse">
            <circle cx="5" cy="5" r="1.4" fill="#fff" />
          </pattern>
        </defs>
        <rect width="100" height="60" fill={`url(#p-${card.id})`} />
      </svg>
      {label && <span className="relative m-3 font-display text-4xl font-semibold text-white/95 drop-shadow-sm">{initials}</span>}
      {label && (
        <span className="relative mb-4 ml-auto mr-3 rounded-full bg-white/20 px-2 py-0.5 text-xs font-semibold text-white">
          {card.cuisines[0]}
        </span>
      )}
    </div>
  );
}

export function RestaurantCard({ card }: { card: Card }) {
  const unavailable = !card.is_open || !card.is_accepting_orders;
  return (
    <Link href={`/restaurants/${card.id}`} className="group block focus-visible:outline-none">
      <article className={cn("overflow-hidden rounded-lg border border-border bg-surface shadow-card transition-transform group-hover:-translate-y-0.5 group-focus-visible:ring-2 group-focus-visible:ring-primary", unavailable && "opacity-75")}>
        <div className="relative">
          <RestaurantArt card={card} className="aspect-[16/9]" />
          {card.is_featured && <Badge tone="warning" className="absolute left-3 top-3 bg-accent text-text">Featured</Badge>}
          {unavailable && (
            <span className="absolute inset-0 grid place-items-center bg-black/45 text-sm font-semibold text-white">
              {card.is_open ? "Not taking orders" : "Closed now"}
            </span>
          )}
        </div>
        <div className="space-y-1.5 p-4">
          <div className="flex items-start justify-between gap-2">
            <h3 className="font-display text-lg leading-tight">{card.name}</h3>
            <span className="flex shrink-0 items-center gap-1 text-sm font-semibold">
              <Star className="size-4 fill-accent text-accent" aria-hidden="true" />
              {card.rating.toFixed(1)}
              <span className="sr-only">out of 5</span>
            </span>
          </div>
          <p className="text-sm text-muted">{card.cuisines.join(" · ")} · {card.area}</p>
          <div className="flex flex-wrap items-center gap-x-3 gap-y-1 pt-1 text-sm">
            {card.eta_minutes !== null && (
              <span className="flex items-center gap-1"><Clock className="size-4 text-muted" aria-hidden="true" /> {card.eta_minutes} min</span>
            )}
            {card.delivers_to_location === false ? (
              <span className="text-muted">Pickup only for your area</span>
            ) : card.delivery_fee_kobo !== null ? (
              <span>{formatNaira(card.delivery_fee_kobo)} delivery</span>
            ) : null}
          </div>
        </div>
      </article>
    </Link>
  );
}
