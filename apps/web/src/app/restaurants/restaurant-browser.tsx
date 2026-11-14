"use client";

import { EmptyState, ErrorState, Input, Select, Skeleton, Toggle, cn } from "@gudmeal/ui";
import { useQuery } from "@tanstack/react-query";
import { Search } from "lucide-react";
import { useRouter, useSearchParams } from "next/navigation";
import { useDeferredValue, useState } from "react";
import { RestaurantCard } from "@/components/restaurant-card";
import { publicApi } from "@/lib/api";
import { useLocation } from "@/lib/location";

const SORTS = [
  { value: "recommended", label: "Recommended" },
  { value: "distance", label: "Nearest" },
  { value: "rating", label: "Top rated" },
  { value: "delivery_fee", label: "Lowest delivery fee" },
];

export function RestaurantBrowser() {
  const params = useSearchParams();
  const router = useRouter();
  const { area } = useLocation();
  const cuisine = params.get("cuisine") ?? "";
  const [q, setQ] = useState(params.get("q") ?? "");
  const [openNow, setOpenNow] = useState(false);
  const [sort, setSort] = useState("recommended");
  const query = useDeferredValue(q);

  const cuisines = useQuery({ queryKey: ["cuisines"], queryFn: () => publicApi.catalog.cuisines() });
  const list = useQuery({
    queryKey: ["restaurants", area.name, cuisine, query, openNow, sort],
    queryFn: () => publicApi.catalog.restaurants({ ...area.location, cuisine: cuisine || undefined, q: query || undefined, open_now: openNow, sort }),
  });

  const setCuisine = (c: string) => {
    const next = new URLSearchParams(params.toString());
    if (c) next.set("cuisine", c); else next.delete("cuisine");
    router.replace(`/restaurants?${next.toString()}`, { scroll: false });
  };

  return (
    <div className="mt-6 space-y-6">
      <div className="flex flex-col gap-3 md:flex-row md:items-center">
        <label className="relative flex-1">
          <span className="sr-only">Search restaurants</span>
          <Search className="pointer-events-none absolute left-3 top-1/2 size-4 -translate-y-1/2 text-muted" aria-hidden="true" />
          <Input value={q} onChange={(e) => setQ(e.target.value)} placeholder="Search jollof, suya, shawarma…" className="pl-9" />
        </label>
        <div className="flex items-center gap-4">
          <Toggle checked={openNow} onChange={setOpenNow} label="Open now" />
          <label className="flex items-center gap-2 text-sm">
            <span className="sr-only">Sort by</span>
            <Select value={sort} onChange={(e) => setSort(e.target.value)} className="w-48">
              {SORTS.map((s) => <option key={s.value} value={s.value}>{s.label}</option>)}
            </Select>
          </label>
        </div>
      </div>
      <div className="flex gap-2 overflow-x-auto pb-1" role="tablist" aria-label="Cuisines">
        {[{ name: "", restaurants: 0 }, ...(cuisines.data ?? [])].map((c) => (
          <button key={c.name || "all"} role="tab" aria-selected={cuisine === c.name} onClick={() => setCuisine(c.name)}
            className={cn("shrink-0 rounded-full border px-3 py-1.5 text-sm font-medium",
              cuisine === c.name ? "border-primary bg-primary text-on-primary" : "border-border bg-surface hover:border-primary")}>
            {c.name || "All"}
          </button>
        ))}
      </div>

      {list.isLoading ? (
        <div className="grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
          {Array.from({ length: 6 }, (_, i) => <Skeleton key={i} className="h-64" />)}
        </div>
      ) : list.error ? (
        <ErrorState message={(list.error as Error).message} onRetry={() => list.refetch()} />
      ) : list.data && list.data.length ? (
        <>
          <p className="text-sm text-muted" aria-live="polite">{list.data.length} restaurants delivering around {area.name}</p>
          <div className="grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
            {list.data.map((r) => <RestaurantCard key={r.id} card={r} />)}
          </div>
        </>
      ) : (
        <EmptyState title="No restaurants match" body="Try another cuisine or clear your search." />
      )}
    </div>
  );
}
