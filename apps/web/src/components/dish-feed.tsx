"use client";

import type { DiscoverDish, DiscoverSectionId } from "@gudmeal/api-client";
import { ErrorState } from "@gudmeal/ui";
import { keepPreviousData, useQuery } from "@tanstack/react-query";
import { Flame, Star, Store } from "lucide-react";
import { useState, type ReactNode } from "react";
import { publicApi } from "@/lib/api";
import { useLocation } from "@/lib/location";
import { DishOrbitCarousel } from "./dish-orbit-carousel";
import { FilterPill } from "./storefront";

const SECTIONS: Record<DiscoverSectionId, { short: string; icon: ReactNode }> = {
  most_loved: { short: "Most loved", icon: <Flame className="size-4 text-primary" aria-hidden="true" /> },
  new_kitchens: { short: "New kitchens", icon: <Store className="size-4 text-primary" aria-hidden="true" /> },
  top_rated: { short: "Top rated", icon: <Star className="size-4 text-primary" aria-hidden="true" /> },
};

/** "Order food": the kitchen's menu with this dish open. */
export const orderHref = (d: DiscoverDish) => `/restaurants/${d.restaurant_id}?item=${encodeURIComponent(d.item_id)}`;

/** "Ask Yummy": the assistant, already asked about this dish (same question as the app). */
export const askHref = (d: DiscoverDish) =>
  `/assistant?q=${encodeURIComponent(`Tell me about the ${d.name} from ${d.restaurant_name}. What does it come with, and what would it cost delivered to me?`)}`;

/** Shown while the dishes load: a soft plate and title placeholders. */
function FeedPlaceholder() {
  return (
    <div className="mt-6 flex flex-col items-center gap-3 py-6" role="status">
      <span className="sr-only">Loading today’s dishes</span>
      <div className="gm-skeleton size-[190px] rounded-full" aria-hidden="true" />
      <div className="gm-skeleton mt-3 h-3 w-[120px] rounded-lg" aria-hidden="true" />
      <div className="gm-skeleton h-7 w-[200px] rounded-lg" aria-hidden="true" />
      <div className="gm-skeleton h-8 w-[160px] rounded-lg" aria-hidden="true" />
    </div>
  );
}

/**
 * Discover's dish feed: section chips (most loved, new kitchens, top rated) over the dish orbit carousel.
 * Dishes, prices, delivery fees and times come from GET /v1/discover/dishes for the chosen area.
 * If the feed can't load, the stores list below the carousel still works.
 */
export function DishFeed() {
  const { area } = useLocation();
  const [sectionId, setSectionId] = useState<DiscoverSectionId | null>(null);
  const feed = useQuery({
    queryKey: ["discover-dishes", area.name],
    queryFn: () => publicApi.catalog.discover({ city: area.city, ...area.location, limit: 8 }),
    // keep the current dishes on screen while another area loads, so the carousel can swing to the new ones
    placeholderData: keepPreviousData,
  });

  if (feed.isPending) return <FeedPlaceholder />;
  if (feed.isError) {
    return (
      <div className="mt-6">
        <ErrorState message="We couldn’t load today’s dishes. The stores below still work." onRetry={() => void feed.refetch()} />
      </div>
    );
  }
  const sections = feed.data.sections.filter((s) => s.dishes.length > 0);
  if (sections.length === 0) return null;
  const selected = sections.find((s) => s.id === sectionId) ?? sections[0]!;

  return (
    // not a landmark of its own: the carousel inside is the region, named after the list
    <div className="mt-5">
      <div className="-mx-4 flex gap-2 overflow-x-auto px-4 pb-1 md:mx-0 md:px-0" role="group" aria-label="Dish lists">
        {sections.map((s) => (
          <FilterPill key={s.id} selected={s.id === selected.id} onClick={() => setSectionId(s.id)}>
            {SECTIONS[s.id]?.icon}
            {SECTIONS[s.id]?.short ?? s.title}
          </FilterPill>
        ))}
      </div>
      <h2 className="mt-4 text-xl font-extrabold tracking-tight sm:text-2xl">{selected.title}</h2>
      {selected.subtitle && <p className="text-muted">{selected.subtitle}</p>}
      <DishOrbitCarousel
        dishes={selected.dishes}
        orderHref={orderHref}
        askHref={askHref}
        label={selected.title}
        className="-mx-4 mt-1 md:mx-0"
      />
    </div>
  );
}
