"use client";

import { Button, Logo, Select } from "@gudmeal/ui";
import { MapPin, ShoppingBag, User } from "lucide-react";
import Link from "next/link";
import { useState } from "react";
import { useAuth } from "@/lib/auth";
import { useCart } from "@/lib/cart";
import { AREAS, CITY_NAMES, useLocation } from "@/lib/location";
import { CartDrawer } from "./cart-drawer";
import { GudyArt } from "./illustrations";

const LINKS = [
  { href: "/food", label: "Food" },
  { href: "/beauty", label: "Beauty & Skin care" },
  { href: "/send", label: "Send a package" },
  { href: "/discover", label: "Discover" },
];

export function Header() {
  const { user } = useAuth();
  const { count } = useCart();
  const { area, setArea } = useLocation();
  const [cartOpen, setCartOpen] = useState(false);

  return (
    <header className="sticky top-0 z-30 border-b border-border/70 bg-background/90 backdrop-blur">
      <div className="container-page flex h-16 items-center gap-3">
        <Link href="/" aria-label="Gud Meal home" className="shrink-0">
          <Logo />
        </Link>
        <label className="ml-2 hidden items-center gap-1.5 rounded-full border border-border bg-surface pl-3 lg:flex">
          <MapPin className="size-4 text-primary" aria-hidden="true" />
          <span className="sr-only">Delivery area</span>
          <Select value={area.name} onChange={(e) => setArea(e.target.value)} className="h-9 w-auto border-0 bg-transparent pr-8 font-semibold focus:ring-0">
            {(["lagos", "enugu"] as const).map((city) => (
              <optgroup key={city} label={CITY_NAMES[city]}>
                {AREAS.filter((a) => a.city === city).map((a) => <option key={a.name} value={a.name}>{a.name}</option>)}
              </optgroup>
            ))}
          </Select>
        </label>
        <nav className="ml-auto flex items-center gap-1 sm:gap-2" aria-label="Main">
          {LINKS.map((l) => (
            <Link key={l.href} href={l.href} className="hidden rounded-full px-3 py-2 text-sm font-semibold hover:bg-surface-muted md:block">
              {l.label}
            </Link>
          ))}
          <Link href="/assistant" className="hidden items-center gap-1.5 rounded-full px-3 py-2 text-sm font-semibold text-[#1546C9] hover:bg-[#EAF0FF] sm:flex">
            <GudyArt className="size-6" /> Ask Gudy
          </Link>
          {user ? (
            <Link href="/account" className="hidden items-center gap-1.5 rounded-full px-3 py-2 text-sm font-semibold hover:bg-surface-muted md:flex">
              <User className="size-4" aria-hidden="true" /> Profile
            </Link>
          ) : (
            <Link href="/login" className="rounded-full px-3 py-2 text-sm font-semibold hover:bg-surface-muted">Sign in</Link>
          )}
          <Button size="sm" onClick={() => setCartOpen(true)} aria-label={`Cart, ${count} items`}>
            <ShoppingBag className="size-4" aria-hidden="true" />
            <span className="tabular-nums">{count}</span>
          </Button>
        </nav>
      </div>
      <CartDrawer open={cartOpen} onClose={() => setCartOpen(false)} />
    </header>
  );
}
