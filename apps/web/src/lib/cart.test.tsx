import type { MenuItem, OptionGroup } from "@gudmeal/api-client";
import { fireEvent, render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import { validateSelections } from "@/components/item-dialog";
import { CartProvider, cartKey, cartReducer, subtotal, toCartLines, useCart, type CartState } from "./cart";

const EMPTY: CartState = { restaurant_id: null, restaurant_name: null, items: [] };
const jollof = (qty = 1) => ({
  key: cartKey("jj", [{ group_id: "p", choice_ids: ["chicken"] }]), item_id: "jj", name: "Jollof", unit_price_kobo: 550_000,
  quantity: qty, selections: [{ group_id: "p", choice_ids: ["chicken"] }], selection_labels: ["Protein: Chicken"],
});

describe("cart reducer", () => {
  it("merges identical lines and sums the subtotal", () => {
    let s = cartReducer(EMPTY, { type: "add", restaurant_id: "r1", restaurant_name: "R1", item: jollof(1) });
    s = cartReducer(s, { type: "add", restaurant_id: "r1", restaurant_name: "R1", item: jollof(2) });
    expect(s.items).toHaveLength(1);
    expect(s.items[0]!.quantity).toBe(3);
    expect(subtotal(s)).toBe(1_650_000);
    expect(toCartLines(s)).toEqual([{ item_id: "jj", quantity: 3, selections: [{ group_id: "p", choice_ids: ["chicken"] }], notes: null }]);
  });

  it("starts a fresh cart when switching restaurants", () => {
    let s = cartReducer(EMPTY, { type: "add", restaurant_id: "r1", restaurant_name: "R1", item: jollof() });
    s = cartReducer(s, { type: "add", restaurant_id: "r2", restaurant_name: "R2", item: { ...jollof(), key: "other" } });
    expect(s.restaurant_id).toBe("r2");
    expect(s.items).toHaveLength(1);
  });

  it("removes lines at zero and empties the cart", () => {
    let s = cartReducer(EMPTY, { type: "add", restaurant_id: "r1", restaurant_name: "R1", item: jollof() });
    s = cartReducer(s, { type: "quantity", key: s.items[0]!.key, quantity: 0 });
    expect(s).toEqual(EMPTY);
  });

  it("selection order does not change the line key", () => {
    expect(cartKey("x", [{ group_id: "a", choice_ids: ["2", "1"] }])).toBe(cartKey("x", [{ group_id: "a", choice_ids: ["1", "2"] }]));
  });
});

describe("option validation mirrors the API", () => {
  const group: OptionGroup = { id: "p", restaurant_id: "r1", name: "Protein", min_select: 1, max_select: 1,
    choices: [{ id: "chicken", name: "Chicken", price_delta_kobo: 0, is_available: true }] };
  const item = { option_group_ids: ["p"] } as MenuItem;
  it("requires mandatory choices", () => {
    expect(validateSelections(item, { p: group }, {})).toMatch(/Choose 1/);
    expect(validateSelections(item, { p: group }, { p: ["chicken"] })).toBeNull();
  });
});

function Harness() {
  const { count, add } = useCart();
  return <button onClick={() => add("r1", "R1", jollof())}>items: {count}</button>;
}

describe("CartProvider", () => {
  it("keeps a saved cart across reloads (StrictMode double effects)", async () => {
    const { StrictMode } = await import("react");
    window.localStorage.setItem("gudmeal.cart.v1", JSON.stringify({ restaurant_id: "r1", restaurant_name: "R1", items: [jollof(2)] }));
    const { unmount } = render(<StrictMode><CartProvider><Harness /></CartProvider></StrictMode>);
    expect(await screen.findByText("items: 2")).toBeTruthy();
    expect(JSON.parse(window.localStorage.getItem("gudmeal.cart.v1")!).items).toHaveLength(1);
    unmount();
    window.localStorage.clear();
  });

  it("persists to localStorage", () => {
    render(<CartProvider><Harness /></CartProvider>);
    fireEvent.click(screen.getByRole("button"));
    expect(screen.getByRole("button").textContent).toBe("items: 1");
    expect(JSON.parse(window.localStorage.getItem("gudmeal.cart.v1")!).items).toHaveLength(1);
  });
});
