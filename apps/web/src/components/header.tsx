"use client";

import { Button, Logo, Select } from "@gudmeal/ui";
import { MapPin, ShoppingBag, Sparkles, User } from "lucide-react";
import Link from "next/link";
import { useState } from "react";
import { useAuth } from "@/lib/auth";
import { useCart } from "@/lib/cart";
import { LAGOS_AREAS, useLocation } from "@/lib/location";
import { CartDrawer } from "./cart-drawer";

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
        <label className="ml-2 hidden items-center gap-1.5 rounded-full border border-border bg-surface pl-3 sm:flex">
          <MapPin className="size-4 text-primary" aria-hidden="true" />
          <span className="sr-only">Delivery area</span>
          <Select value={area.name} onChange={(e) => setArea(e.target.value)}
            className="h-9 w-auto border-0 bg-transparent pr-8 font-semibold focus:ring-0">
            {LAGOS_AREAS.map((a) => <option key={a.name}>{a.name}</option>)}
          </Select>
        </label>
        <nav className="ml-auto flex items-center gap-1 sm:gap-2" aria-label="Main">
          <Link href="/restaurants" className="hidden rounded-full px-3 py-2 text-sm font-semibold hover:bg-surface-muted md:block">
            Restaurants
          </Link>
          <Link href="/assistant" className="flex items-center gap-1.5 rounded-full px-3 py-2 text-sm font-semibold text-secondary hover:bg-secondary-soft">
            <Sparkles className="size-4" aria-hidden="true" /> <span className="hidden sm:inline">Ask Gud Meal</span>
          </Link>
          {user ? (
            <Link href="/account" className="flex items-center gap-1.5 rounded-full px-3 py-2 text-sm font-semibold hover:bg-surface-muted">
              <User className="size-4" aria-hidden="true" /> <span className="hidden sm:inline">Account</span>
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
      <div className="container-page pb-2 sm:hidden">
        <label className="flex items-center gap-1.5 rounded-full border border-border bg-surface pl-3">
          <MapPin className="size-4 text-primary" aria-hidden="true" />
          <span className="sr-only">Delivery area</span>
          <Select value={area.name} onChange={(e) => setArea(e.target.value)} className="h-9 border-0 bg-transparent font-semibold focus:ring-0">
            {LAGOS_AREAS.map((a) => <option key={a.name}>{a.name}</option>)}
          </Select>
        </label>
      </div>
      <CartDrawer open={cartOpen} onClose={() => setCartOpen(false)} />
    </header>
  );
}
