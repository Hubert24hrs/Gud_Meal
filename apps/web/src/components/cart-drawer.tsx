"use client";

import { Button, EmptyState, Price } from "@gudmeal/ui";
import { Minus, Plus, ShoppingBag, X } from "lucide-react";
import Link from "next/link";
import { useEffect } from "react";
import { useCart } from "@/lib/cart";

export function CartDrawer({ open, onClose }: { open: boolean; onClose: () => void }) {
  const { cart, setQuantity, subtotalKobo, clear } = useCart();

  useEffect(() => {
    if (!open) return;
    const onKey = (e: KeyboardEvent) => e.key === "Escape" && onClose();
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [open, onClose]);

  if (!open) return null;
  return (
    <div className="fixed inset-0 z-40" role="dialog" aria-modal="true" aria-label="Your cart">
      <button className="absolute inset-0 bg-black/40" aria-label="Close cart" onClick={onClose} />
      <aside className="absolute right-0 top-0 flex h-dvh w-full max-w-md flex-col bg-background shadow-raised">
        <div className="flex items-center justify-between border-b border-border px-5 py-4">
          <div>
            <h2 className="font-display text-xl">Your order</h2>
            {cart.restaurant_name && <p className="text-sm text-muted">from {cart.restaurant_name}</p>}
          </div>
          <button onClick={onClose} className="rounded-full p-2 hover:bg-surface-muted" aria-label="Close"><X className="size-5" /></button>
        </div>
        <div className="flex-1 space-y-3 overflow-y-auto px-5 py-4">
          {cart.items.length === 0 ? (
            <EmptyState icon={<ShoppingBag className="size-8" />} title="Your cart is empty"
              body="Add dishes from a restaurant to get started."
              action={<Link href="/restaurants" onClick={onClose}><Button size="sm">Browse restaurants</Button></Link>} />
          ) : cart.items.map((item) => (
            <div key={item.key} className="flex gap-3 rounded-md border border-border bg-surface p-3">
              <div className="min-w-0 flex-1">
                <p className="font-semibold">{item.name}</p>
                {item.selection_labels.length > 0 && <p className="text-xs text-muted">{item.selection_labels.join(" · ")}</p>}
                {item.notes && <p className="text-xs italic text-muted">“{item.notes}”</p>}
                <Price kobo={item.unit_price_kobo * item.quantity} className="mt-1 block text-sm font-semibold" />
              </div>
              <div className="flex items-center gap-1 self-center">
                <button className="grid size-8 place-items-center rounded-full border border-border hover:bg-surface-muted"
                  onClick={() => setQuantity(item.key, item.quantity - 1)} aria-label={`Remove one ${item.name}`}>
                  <Minus className="size-4" />
                </button>
                <span className="w-6 text-center tabular-nums" aria-live="polite">{item.quantity}</span>
                <button className="grid size-8 place-items-center rounded-full border border-border hover:bg-surface-muted"
                  onClick={() => setQuantity(item.key, item.quantity + 1)} aria-label={`Add one ${item.name}`}>
                  <Plus className="size-4" />
                </button>
              </div>
            </div>
          ))}
        </div>
        {cart.items.length > 0 && (
          <div className="space-y-3 border-t border-border px-5 py-4">
            <div className="flex justify-between text-sm">
              <span className="text-muted">Items subtotal</span>
              <Price kobo={subtotalKobo} className="font-semibold" />
            </div>
            <p className="text-xs text-muted">Delivery, service fee and VAT are calculated at checkout.</p>
            <Link href="/checkout" onClick={onClose}><Button block size="lg">Go to checkout</Button></Link>
            <button onClick={clear} className="w-full text-center text-xs text-muted underline-offset-2 hover:underline">Clear cart</button>
          </div>
        )}
      </aside>
    </div>
  );
}
