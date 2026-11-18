import Link from "next/link";
import { BeautyArt, FoodArt, ParcelArt } from "@/components/illustrations";
import { ServiceBubbles } from "@/components/service-bubbles";
import { AddressPill, BrandTile, SectionTitle } from "@/components/storefront";
import { safe, serverApi } from "@/lib/server-api";

export const dynamic = "force-dynamic";

/**
 * Home, kept minimal like the app's and Glovo's (ADR-0021): the delivery area, the three services as big floating
 * bubbles on the red header, then the places picked for the customer. Nothing else: Gudy floats over every page,
 * deals show as a "Promo" tag on the shop tiles, and the business and rider sign-ups are in the footer.
 */
export default async function HomePage() {
  const [{ data: food }, { data: beauty }] = await Promise.all([
    safe(serverApi.catalog.restaurants({ limit: 8, vertical: "food", city: "lagos" })),
    safe(serverApi.catalog.restaurants({ limit: 4, vertical: "beauty", city: "lagos" })),
  ]);
  const picks = [...(food ?? []), ...(beauty ?? [])].sort((a, b) => Number(b.is_featured) - Number(a.is_featured));

  return (
    <>
      <section className="gm-hero pb-12">
        <div className="container-page pt-4 md:pt-8">
          <div className="mx-auto max-w-2xl">
            <h1 className="sr-only">GudMeals: food, supplements & skin care and package delivery in Lagos and Enugu</h1>
            <div className="flex justify-center"><AddressPill onDark /></div>
            <ServiceBubbles
              height={372}
              bubbles={[
                { id: "food", label: "Food", href: "/food", art: <FoodArt />, size: 1.12 },
                { id: "beauty", label: "Supplements & Skin Care", href: "/beauty", art: <BeautyArt /> },
                { id: "parcel", label: "Package Delivery", href: "/send", art: <ParcelArt />, size: 1.02 },
              ]}
            />
          </div>
        </div>
      </section>

      <div className="container-page pb-10">
        <SectionTitle info="Top-rated places near you, picked for you" action={<Link href="/discover" className="text-sm font-semibold text-primary hover:underline">See all</Link>}>
          These are for you
        </SectionTitle>
        {picks.length > 0 ? (
          <div className="-mx-4 flex gap-3 overflow-x-auto px-4 pb-2 [scrollbar-width:none]">
            {picks.map((r) => <BrandTile key={r.id} card={r} />)}
          </div>
        ) : (
          <p className="rounded-lg border border-dashed border-border p-6 text-sm text-muted">
            Stores are loading slowly right now. <Link href="/food" className="text-primary underline">Browse Food</Link>.
          </p>
        )}
      </div>
    </>
  );
}
