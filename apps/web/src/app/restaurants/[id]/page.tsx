import { formatNaira } from "@gudmeal/api-client";
import { Badge } from "@gudmeal/ui";
import { Clock, MapPin, Star } from "lucide-react";
import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { MerchantArt } from "@/components/storefront";
import { safe, serverApi } from "@/lib/server-api";
import { Menu } from "./menu";

export const dynamic = "force-dynamic";

type Props = { params: Promise<{ id: string }> };

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { id } = await params;
  const { data } = await safe(serverApi.catalog.restaurant(id));
  if (!data) return { title: "Restaurant" };
  const r = data.restaurant;
  return {
    title: `${r.name} — order online in ${r.area}`,
    description: `${r.description} Order ${r.cuisines.join(", ")} from ${r.name} on Gud Meal.`,
    alternates: { canonical: `/restaurants/${id}` },
  };
}

export default async function RestaurantPage({ params }: Props) {
  const { id } = await params;
  const { data, error } = await safe(serverApi.catalog.restaurant(id));
  if (!data) {
    if (error?.toLowerCase().includes("not found")) notFound();
    return <div className="container-page py-16 text-center text-muted">This restaurant is unavailable right now. Please try again shortly.</div>;
  }
  const r = data.restaurant;
  const jsonLd = {
    "@context": "https://schema.org",
    "@type": "Restaurant",
    name: r.name,
    servesCuisine: r.cuisines,
    address: { "@type": "PostalAddress", streetAddress: data.address, addressLocality: "Lagos", addressCountry: "NG" },
    geo: { "@type": "GeoCoordinates", latitude: data.location.lat, longitude: data.location.lng },
    aggregateRating: r.rating_count ? { "@type": "AggregateRating", ratingValue: r.rating, reviewCount: r.rating_count } : undefined,
    priceRange: "₦".repeat(r.price_level),
  };

  return (
    <div>
      <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }} />
      <MerchantArt card={r} className="h-40 w-full sm:h-56" />
      <div className="container-page">
        <div className="-mt-10 rounded-xl border border-border bg-surface p-5 shadow-card sm:p-6">
          <div className="flex flex-wrap items-start justify-between gap-3">
            <div>
              <h1 className="font-display text-3xl sm:text-4xl">{r.name}</h1>
              <p className="mt-1 max-w-2xl text-muted">{r.description}</p>
            </div>
            {r.is_open && r.is_accepting_orders ? <Badge tone="success">Open now</Badge> : <Badge tone="danger">Closed</Badge>}
          </div>
          <dl className="mt-4 flex flex-wrap gap-x-6 gap-y-2 text-sm">
            <div className="flex items-center gap-1.5"><Star className="size-4 fill-accent text-accent" aria-hidden="true" />
              <dt className="sr-only">Rating</dt><dd><strong>{r.rating.toFixed(1)}</strong> ({r.rating_count.toLocaleString()} ratings)</dd></div>
            <div className="flex items-center gap-1.5"><Clock className="size-4 text-muted" aria-hidden="true" />
              <dt className="sr-only">Preparation</dt><dd>{data.restaurant.vertical === "beauty" ? "packed in" : "ready in"} ~{data.avg_prep_minutes} min</dd></div>
            <div className="flex items-center gap-1.5"><MapPin className="size-4 text-muted" aria-hidden="true" />
              <dt className="sr-only">Address</dt><dd>{data.address}</dd></div>
            {r.min_order_kobo > 0 && <div><dt className="inline text-muted">Minimum order </dt><dd className="inline">{formatNaira(r.min_order_kobo)}</dd></div>}
          </dl>
        </div>
        <Menu detail={data} />
      </div>
    </div>
  );
}
