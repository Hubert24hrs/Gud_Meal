"use client";

import { formatNaira, type RestaurantCard } from "@gudmeal/api-client";
import { Skeleton } from "@gudmeal/ui";
import { useQuery } from "@tanstack/react-query";
import { Bike, Search, ThumbsUp } from "lucide-react";
import Link from "next/link";
import { useDeferredValue, useState } from "react";
import { DishFeed } from "@/components/dish-feed";
import { deliveryLabel, EmptyBlock, MerchantArt, PromoTag, ratingPercent, SectionTitle } from "@/components/storefront";
import { publicApi } from "@/lib/api";
import { useLocation } from "@/lib/location";
import { SERVICES, serviceCopy } from "@/lib/services";

function DemandRow({ card }: { card: RestaurantCard }) {
  const fee = deliveryLabel(card);
  return (
    <Link href={`/restaurants/${card.id}`} className="flex items-center gap-4 rounded-2xl border border-border bg-surface p-3.5 shadow-card hover:border-primary">
      <MerchantArt card={card} compact className="size-[72px] shrink-0 rounded-xl" />
      <div className="min-w-0 flex-1">
        <p className="truncate text-lg font-extrabold">{card.name}</p>
        <p className="flex flex-wrap items-center gap-x-2 text-sm text-muted">
          <ThumbsUp className="size-4 text-secondary" aria-hidden="true" /> {ratingPercent(card.rating)}
          {fee && <span className="flex items-center gap-1">· <Bike className="size-4" aria-hidden="true" /> {fee}</span>}
        </p>
        {card.promotions?.[0] && <div className="mt-1.5"><PromoTag>{card.promotions[0].label}</PromoTag></div>}
        {card.vertical !== "food" && <p className="mt-1 text-xs font-bold text-secondary">{serviceCopy(card.vertical).title}</p>}
      </div>
    </Link>
  );
}

/** The icon of the service a search hit belongs to. */
function HitIcon({ vertical }: { vertical?: string }) {
  const Icon = (SERVICES.find((s) => s.id === vertical) ?? SERVICES[0]!).icon;
  return <Icon className="size-5 text-primary" aria-hidden="true" />;
}

export default function DiscoverPage() {
  const { area } = useLocation();
  const [q, setQ] = useState("");
  const query = useDeferredValue(q.trim());
  const base = { ...area.location, city: area.city, sort: "rating" };
  // Every kind of shop near the customer, in one request.
  const shops = useQuery({ queryKey: ["demand", "all", area.name], queryFn: () => publicApi.catalog.restaurants({ ...base, vertical: "all", limit: 100 }) });
  const results = useQuery({ queryKey: ["discover", query, area.name], queryFn: () => publicApi.catalog.search(query, area.location), enabled: query.length >= 2 });
  const demand = [...(shops.data ?? [])]
    .sort((a, b) => b.rating * Math.min(b.rating_count, 2000) - a.rating * Math.min(a.rating_count, 2000))
    .slice(0, 12);

  return (
    <div className="pb-28 md:pb-12">
      <div className="gm-hero">
        <div className="container-page flex items-center justify-between pb-14 pt-8">
          <h1 className="text-4xl font-black text-white">Discover</h1>
          <Search className="size-16 text-white/70" aria-hidden="true" />
        </div>
      </div>
      <div className="container-page">
        <label className="-mt-2 flex items-center gap-2 rounded-full bg-surface-muted px-4 py-3">
          <Search className="size-5 text-muted" aria-hidden="true" />
          <span className="sr-only">Search Gud Meal</span>
          <input value={q} onChange={(e) => setQ(e.target.value)} placeholder="Search Gud Meal" className="w-full bg-transparent outline-none placeholder:text-muted" />
        </label>

        {query.length >= 2 ? (
          results.isLoading ? <Skeleton className="mt-6 h-40" /> : (results.data?.items.length ?? 0) + (results.data?.restaurants.length ?? 0) === 0 ? (
            <div className="mt-6"><EmptyBlock icon={<Search className="size-8" aria-hidden="true" />} title="No results" body="Try a dish, a product or a store name." /></div>
          ) : (
            <>
              {(results.data?.restaurants.length ?? 0) > 0 && (
                <>
                  <SectionTitle>Stores</SectionTitle>
                  <div className="grid gap-3 md:grid-cols-2">{results.data!.restaurants.slice(0, 6).map((r) => <DemandRow key={r.id} card={r} />)}</div>
                </>
              )}
              {(results.data?.items.length ?? 0) > 0 && (
                <>
                  <SectionTitle>Dishes & products</SectionTitle>
                  <ul className="divide-y divide-border rounded-2xl border border-border">
                    {results.data!.items.slice(0, 10).map((h) => (
                      <li key={h.item.id}>
                        <Link href={`/restaurants/${h.restaurant_id}`} className="flex items-center gap-3 p-3 hover:bg-surface-muted">
                          <HitIcon vertical={h.vertical} />
                          <span className="flex-1"><span className="block font-semibold">{h.item.name}</span><span className="text-sm text-muted">{h.restaurant_name}</span></span>
                          <span className="font-bold">{formatNaira(h.item.price_kobo)}</span>
                        </Link>
                      </li>
                    ))}
                  </ul>
                </>
              )}
            </>
          )
        ) : (
          <>
            <DishFeed />
            <SectionTitle info="Where everyone is ordering, available now">Most in demand</SectionTitle>
            <p className="-mt-2 mb-4 text-muted">Where everyone’s ordering, available now</p>
            {shops.isLoading ? <Skeleton className="h-40" /> : (
              <div className="grid gap-3 md:grid-cols-2">{demand.map((r) => <DemandRow key={r.id} card={r} />)}</div>
            )}
          </>
        )}
      </div>
    </div>
  );
}
