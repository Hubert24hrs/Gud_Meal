import { Bike, ShieldCheck, Sparkles, Wallet } from "lucide-react";
import Link from "next/link";
import { AskBox } from "@/components/ask-box";
import { BeautyArt, FoodArt, GudyArt, ParcelArt } from "@/components/illustrations";
import { ServiceBubbles } from "@/components/service-bubbles";
import { AddressPill, BrandTile, PromoTag, SectionTitle } from "@/components/storefront";
import { safe, serverApi } from "@/lib/server-api";

export const dynamic = "force-dynamic";

const IDEAS = [
  "I have ₦10,000. Best meal for two before 8pm?",
  "Find me a good sunscreen",
  "Send a package to Yaba",
  "Abeg, wetin una dey sell?",
];

export default async function HomePage() {
  const [{ data: food }, { data: beauty }] = await Promise.all([
    safe(serverApi.catalog.restaurants({ limit: 8, vertical: "food", city: "lagos" })),
    safe(serverApi.catalog.restaurants({ limit: 4, vertical: "beauty", city: "lagos" })),
  ]);
  const picks = [...(food ?? []), ...(beauty ?? [])].sort((a, b) => Number(b.is_featured) - Number(a.is_featured));
  const deal = picks.find((r) => r.promotions?.length);

  return (
    <>
      <section className="gm-hero pb-12">
        <div className="container-page grid items-center gap-4 pt-4 md:grid-cols-[1fr_1.1fr] md:pt-10">
          <div className="hidden space-y-5 text-white md:block">
            <h1 className="font-display text-5xl leading-[1.05] tracking-tight lg:text-6xl">
              Food, beauty and packages, delivered.
            </h1>
            <p className="max-w-lg text-lg text-white/90">
              Lagos and Enugu’s favourite kitchens, partner beauty shops and bike couriers in one app. Drag a bubble
              to play, tap one to start.
            </p>
            <div className="max-w-lg rounded-2xl bg-white/95 p-2 text-text"><AskBox /></div>
          </div>
          <div>
            <div className="flex justify-center"><AddressPill onDark /></div>
            <h1 className="sr-only md:hidden">Gud Meal: food, beauty and package delivery in Lagos and Enugu</h1>
            <ServiceBubbles
              bubbles={[
                { id: "food", label: "Food", href: "/food", art: <FoodArt />, size: 1.12 },
                { id: "beauty", label: "Beauty & Skin care", href: "/beauty", art: <BeautyArt /> },
                { id: "parcel", label: "Package Delivery", href: "/send", art: <ParcelArt />, size: 1.02 },
              ]}
            />
          </div>
        </div>
      </section>

      <div className="container-page">
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

        <div className="mt-6 grid gap-4 md:grid-cols-2">
          {deal && (
            <Link href={`/restaurants/${deal.id}`} className="flex overflow-hidden rounded-2xl border border-border bg-surface shadow-card">
              <div className="flex-1 space-y-2 p-5">
                <PromoTag>Deal</PromoTag>
                <p className="text-lg font-extrabold">{deal.promotions[0]!.label}</p>
                <p className="text-sm text-muted">Use code <b>{deal.promotions[0]!.code}</b> at {deal.name}.</p>
              </div>
              <div className="relative w-36 shrink-0 bg-gradient-to-br from-[#D7263D] to-primary"><FoodArt className="absolute -bottom-3 -right-3 w-36" /></div>
            </Link>
          )}
          <Link href="/send" className="flex items-center gap-4 rounded-2xl bg-secondary-soft p-5">
            <ParcelArt className="w-24 shrink-0" />
            <div>
              <p className="text-lg font-extrabold">Send a package</p>
              <p className="text-sm text-muted">Bike delivery across Lagos or Enugu: now, or at a time you choose.</p>
            </div>
          </Link>
        </div>

        <div className="mt-6 rounded-2xl border border-[#CFDBFF] bg-[#EAF0FF] p-5 text-[#1F2A44]">
          <div className="flex items-center gap-3">
            <GudyArt blink className="size-12 shrink-0" />
            <div>
              <p className="text-lg font-extrabold text-[#1546C9]">Ask Gudy</p>
              <p className="text-sm">Your AI assistant. English, Pidgin, Igbo, Yoruba or Hausa.</p>
            </div>
          </div>
          <div className="mt-4 flex flex-wrap gap-2">
            {IDEAS.map((idea) => (
              <Link key={idea} href={`/assistant?q=${encodeURIComponent(idea)}`} className="rounded-full border border-[#CFDBFF] bg-white px-3 py-1.5 text-sm font-medium hover:border-[#1F5EFF]">
                {idea}
              </Link>
            ))}
          </div>
        </div>
      </div>

      <section className="container-page grid gap-4 py-12 sm:grid-cols-3">
        {[
          { icon: Sparkles, title: "Gudy plans to your budget", body: "Say what you want and how much you have. Gudy builds options with exact totals, fees and VAT included, and you approve before paying." },
          { icon: Wallet, title: "Transparent, safe payments", body: "Pay with card, transfer or USSD on a secure page. We verify every payment before your order is sent." },
          { icon: Bike, title: "Live tracking to your door", body: "Follow your rider and confirm delivery with your private 4-digit code. Packages too." },
        ].map(({ icon: Icon, title, body }) => (
          <div key={title} className="rounded-lg border border-border bg-surface p-5">
            <Icon className="mb-3 size-6 text-primary" aria-hidden="true" />
            <h3 className="font-semibold">{title}</h3>
            <p className="mt-1 text-sm text-muted">{body}</p>
          </div>
        ))}
      </section>

      <section className="container-page pb-6">
        <div className="grid gap-4 rounded-xl bg-secondary p-8 text-on-secondary sm:grid-cols-2 sm:p-10">
          <div>
            <h2 className="font-display text-3xl">Sell on Gud Meal. Ride with Gud Meal.</h2>
            <p className="mt-2 opacity-90">Restaurants and beauty shops get orders, insights and weekly settlements. Riders earn on their schedule.</p>
          </div>
          <div className="flex flex-wrap items-center gap-3 sm:justify-end">
            <Link href="/partner-with-us" className="rounded-full bg-white px-5 py-3 font-semibold text-secondary">Add your business</Link>
            <Link href="/ride" className="rounded-full border border-white/50 px-5 py-3 font-semibold">Become a rider</Link>
          </div>
        </div>
        <p className="mt-4 flex items-center gap-2 text-xs text-muted"><ShieldCheck className="size-4" aria-hidden="true" /> You approve every order before you pay.</p>
      </section>
    </>
  );
}
