import type { MenuItem, RestaurantDetail } from "@gudmeal/api-client";
import { cleanup, render } from "@testing-library/react";
import { afterEach, beforeAll, describe, expect, it } from "vitest";
import { CartProvider } from "@/lib/cart";
import { Menu } from "./menu";

const item = (over: Partial<MenuItem> = {}): MenuItem => ({
  id: "sl-beef-suya", restaurant_id: "r-suya-lane", category_id: "c1", name: "Beef Suya (250g)", description: "Thinly sliced beef.",
  price_kobo: 450_000, image_url: null, kind: "main", tags: [], dietary: [], allergens: [], serves: 1, spice_level: 2,
  is_available: true, is_active: true, popularity: 10, option_group_ids: [], prep_minutes: 15, position: 0, ...over,
});
const detail = (open = true, items: MenuItem[] = [item(), item({ id: "sl-asun", name: "Asun" })]): RestaurantDetail => ({
  restaurant: {
    id: "r-suya-lane", vertical: "food", city: "lagos", promotions: [], name: "Suya Lane", slug: "suya-lane", description: "", cuisines: [],
    tags: [], image_url: null, cover_url: null, area: "Victoria Island", rating: 4.8, rating_count: 10, price_level: 2, is_open: open,
    is_accepting_orders: true, is_featured: false, next_opening_at: null, distance_km: null, eta_minutes: null, delivery_fee_kobo: null,
    min_order_kobo: 0, supports_delivery: true, supports_pickup: true, delivers_to_location: null,
  },
  address: "1 Adeola Odeku St", location: { lat: 6.43, lng: 3.42 }, opening_hours: {} as RestaurantDetail["opening_hours"],
  avg_prep_minutes: 15, sections: [{ category: { id: "c1", name: "Suya & grills", position: 0 }, items }], option_groups: {},
});

beforeAll(() => {
  // jsdom has no modal dialogs
  HTMLDialogElement.prototype.showModal ??= function (this: HTMLDialogElement) { this.setAttribute("open", ""); };
  HTMLDialogElement.prototype.close ??= function (this: HTMLDialogElement) { this.removeAttribute("open"); };
});
afterEach(cleanup);

const renderMenu = (d: RestaurantDetail, openItemId?: string) =>
  render(<CartProvider><Menu detail={d} openItemId={openItemId} /></CartProvider>);

describe("restaurant menu opened from the Discover carousel", () => {
  it("opens the dish straight away when it can be ordered", () => {
    renderMenu(detail(), "sl-beef-suya");
    const dialog = document.querySelector("dialog");
    expect(dialog?.hasAttribute("open")).toBe(true);
    expect(dialog?.querySelector("h2")?.textContent).toBe("Beef Suya (250g)");
  });

  it("just shows the menu when the kitchen is closed, the dish is sold out or unknown", () => {
    renderMenu(detail(false), "sl-beef-suya");
    expect(document.querySelector("dialog")).toBeNull();
    cleanup();
    renderMenu(detail(true, [item({ is_available: false })]), "sl-beef-suya");
    expect(document.querySelector("dialog")).toBeNull();
    cleanup();
    renderMenu(detail(), "not-on-the-menu");
    expect(document.querySelector("dialog")).toBeNull();
    cleanup();
    renderMenu(detail());
    expect(document.querySelector("dialog")).toBeNull();
  });
});
