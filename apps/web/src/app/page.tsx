import { Badge } from "@gudmeal/ui";
import { Bike, ShieldCheck, Sparkles, Wallet } from "lucide-react";
import Link from "next/link";
import { AskBox } from "@/components/ask-box";
import { RestaurantCard } from "@/components/restaurant-card";
import { safe, serverApi } from "@/lib/server-api";

export const dynamic = "force-dynamic";

export default async function HomePage() {
  const [{ data: restaurants }, { data: cuisines }] = await Promise.all([
    safe(serverApi.catalog.restaurants({ limit: 6 })),
    safe(serverApi.catalog.cuisines()),
  ]);

  return (
    <>
      <section className="relative overflow-hidden">
        <div className="pointer-events-none absolute -right-24 -top-24 size-[420px] rounded-full bg-primary-soft blur-3xl" aria-hidden="true" />
        <div className="pointer-events-none absolute -bottom-32 -left-24 size-[360px] rounded-full bg-accent-soft blur-3xl" aria-hidden="true" />
        <div className="container-page relative grid gap-10 py-14 md:grid-cols-[1.1fr_.9fr] md:py-20">
          <div className="space-y-6">
            <Badge tone="success" className="text-sm"><Sparkles className="size-3.5" /> Now delivering across Lagos</Badge>
            <h1 className="font-display text-4xl leading-[1.05] tracking-tight sm:text-6xl">
              Discover. Order. <span className="text-primary">Eat.</span>
            </h1>
            <p className="max-w-xl text-lg text-muted">
              Smoky party jollof, late-night suya, Mama&apos;s amala — from the kitchens Lagos loves.
              Tell Gud Meal your budget and we&apos;ll plan the perfect meal.
            </p>
            <AskBox />
            <div className="flex flex-wrap gap-2">
              {(cuisines ?? []).slice(0, 8).map((c) => (
                <Link key={c.name} href={`/restaurants?cuisine=${encodeURIComponent(c.name)}`}
                  className="rounded-full border border-border bg-surface px-3 py-1.5 text-sm font-medium hover:border-primary hover:text-primary">
                  {c.name}
                </Link>
              ))}
            </div>
          </div>
          <div className="relative hidden self-center md:block" aria-hidden="true">
            <div className="absolute inset-6 rotate-3 rounded-xl bg-secondary" />
            <div className="relative space-y-3 rounded-xl border border-border bg-surface p-5 shadow-raised">
              <p className="text-xs font-semibold uppercase tracking-wide text-muted">Gud Meal assistant</p>
              <div className="ml-auto max-w-[85%] rounded-lg rounded-br-sm bg-primary px-4 py-3 text-sm text-on-primary">
                I have ₦10,000. Find me the best meal for two before 8pm.
              </div>
              <div className="max-w-[90%] space-y-2 rounded-lg rounded-bl-sm bg-surface-muted px-4 py-3 text-sm">
                <p className="font-semibold">Jollof Junction · arrives ~7:35 PM</p>
                <p>2 × Party Jollof Rice (fried chicken) · 2 × Chapman</p>
                <p className="font-semibold text-secondary">Total ₦9,4xx incl. delivery & VAT</p>
              </div>
              <div className="flex gap-2 text-xs text-muted"><ShieldCheck className="size-4" /> You approve every order before you pay.</div>
            </div>
          </div>
        </div>
      </section>

      <section className="container-page py-6">
        <div className="mb-5 flex items-end justify-between">
          <h2 className="font-display text-2xl sm:text-3xl">Popular in Lagos</h2>
          <Link href="/restaurants" className="text-sm font-semibold text-primary hover:underline">See all</Link>
        </div>
        {restaurants && restaurants.length > 0 ? (
          <div className="grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
            {restaurants.map((r) => <RestaurantCard key={r.id} card={r} />)}
          </div>
        ) : (
          <p className="rounded-lg border border-dashed border-border p-6 text-sm text-muted">
            Restaurants are loading slowly right now — <Link href="/restaurants" className="text-primary underline">try the full list</Link>.
          </p>
        )}
      </section>

      <section className="container-page grid gap-4 py-12 sm:grid-cols-3">
        {[
          { icon: Sparkles, title: "AI that plans to your budget", body: "Say what you want and how much you have. We build options with exact totals — fees and VAT included." },
          { icon: Wallet, title: "Transparent, safe payments", body: "Pay with card, transfer or USSD on a secure page. We verify every payment before your order is sent." },
          { icon: Bike, title: "Live tracking to your door", body: "Follow your rider in real time and confirm delivery with your private 4-digit code." },
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
            <h2 className="font-display text-3xl">Cook it. We&apos;ll bring the customers.</h2>
            <p className="mt-2 opacity-90">Join Gud Meal Partner for orders, insights and weekly settlements. Or ride with us and earn on your schedule.</p>
          </div>
          <div className="flex flex-wrap items-center gap-3 sm:justify-end">
            <Link href="/partner-with-us" className="rounded-full bg-white px-5 py-3 font-semibold text-secondary">Add your restaurant</Link>
            <Link href="/ride" className="rounded-full border border-white/50 px-5 py-3 font-semibold">Become a rider</Link>
          </div>
        </div>
      </section>
    </>
  );
}
