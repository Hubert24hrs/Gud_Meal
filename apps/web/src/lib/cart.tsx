"use client";

import type { CartLine, OptionSelection } from "@gudmeal/api-client";
import { createContext, useCallback, useContext, useEffect, useMemo, useReducer, useState, type ReactNode } from "react";

/** A cart is for one restaurant. Prices here are for display only — the server quote is authoritative. */
export interface CartItem {
  key: string;
  item_id: string;
  name: string;
  unit_price_kobo: number;
  quantity: number;
  selections: OptionSelection[];
  selection_labels: string[];
  notes?: string;
}

export interface CartState {
  restaurant_id: string | null;
  restaurant_name: string | null;
  items: CartItem[];
}

type Action =
  | { type: "add"; restaurant_id: string; restaurant_name: string; item: CartItem }
  | { type: "quantity"; key: string; quantity: number }
  | { type: "clear" }
  | { type: "hydrate"; state: CartState };

const EMPTY: CartState = { restaurant_id: null, restaurant_name: null, items: [] };
const STORAGE_KEY = "gudmeal.cart.v1";

export function cartKey(itemId: string, selections: OptionSelection[], notes?: string): string {
  const sel = selections.map((s) => `${s.group_id}:${[...s.choice_ids].sort().join(",")}`).sort().join("|");
  return `${itemId}#${sel}#${notes ?? ""}`;
}

export function cartReducer(state: CartState, action: Action): CartState {
  switch (action.type) {
    case "hydrate":
      return action.state;
    case "clear":
      return EMPTY;
    case "add": {
      const base = state.restaurant_id === action.restaurant_id ? state : { ...EMPTY, restaurant_id: action.restaurant_id };
      const existing = base.items.find((i) => i.key === action.item.key);
      const items = existing
        ? base.items.map((i) => (i.key === action.item.key ? { ...i, quantity: Math.min(50, i.quantity + action.item.quantity) } : i))
        : [...base.items, action.item];
      return { restaurant_id: action.restaurant_id, restaurant_name: action.restaurant_name, items };
    }
    case "quantity": {
      const items = state.items
        .map((i) => (i.key === action.key ? { ...i, quantity: Math.max(0, Math.min(50, action.quantity)) } : i))
        .filter((i) => i.quantity > 0);
      return items.length ? { ...state, items } : EMPTY;
    }
  }
}

export function subtotal(state: CartState): number {
  return state.items.reduce((sum, i) => sum + i.unit_price_kobo * i.quantity, 0);
}

export function toCartLines(state: CartState): CartLine[] {
  return state.items.map((i) => ({ item_id: i.item_id, quantity: i.quantity, selections: i.selections, notes: i.notes || null }));
}

interface CartContextValue {
  cart: CartState;
  count: number;
  subtotalKobo: number;
  add: (restaurantId: string, restaurantName: string, item: CartItem) => void;
  setQuantity: (key: string, quantity: number) => void;
  clear: () => void;
}

const CartContext = createContext<CartContextValue | null>(null);

export function CartProvider({ children }: { children: ReactNode }) {
  const [cart, dispatch] = useReducer(cartReducer, EMPTY);
  // Persist only after the saved cart has been loaded; otherwise the first (empty) render would overwrite it.
  const [hydrated, setHydrated] = useState(false);

  useEffect(() => {
    try {
      const raw = window.localStorage.getItem(STORAGE_KEY);
      if (raw) dispatch({ type: "hydrate", state: JSON.parse(raw) as CartState });
    } catch {
      /* storage unavailable — start empty */
    }
    setHydrated(true);
  }, []);

  useEffect(() => {
    if (!hydrated) return;
    try {
      window.localStorage.setItem(STORAGE_KEY, JSON.stringify(cart));
    } catch {
      /* ignore */
    }
  }, [cart, hydrated]);

  const add = useCallback((rid: string, name: string, item: CartItem) => dispatch({ type: "add", restaurant_id: rid, restaurant_name: name, item }), []);
  const setQuantity = useCallback((key: string, quantity: number) => dispatch({ type: "quantity", key, quantity }), []);
  const clear = useCallback(() => {
    // Write synchronously: checkout clears the cart right before redirecting to the payment page.
    try {
      window.localStorage.setItem(STORAGE_KEY, JSON.stringify(EMPTY));
    } catch {
      /* ignore */
    }
    dispatch({ type: "clear" });
  }, []);

  const value = useMemo(() => ({
    cart, add, setQuantity, clear,
    count: cart.items.reduce((n, i) => n + i.quantity, 0),
    subtotalKobo: subtotal(cart),
  }), [cart, add, setQuantity, clear]);

  return <CartContext.Provider value={value}>{children}</CartContext.Provider>;
}

export function useCart(): CartContextValue {
  const ctx = useContext(CartContext);
  if (!ctx) throw new Error("useCart must be used inside CartProvider");
  return ctx;
}
