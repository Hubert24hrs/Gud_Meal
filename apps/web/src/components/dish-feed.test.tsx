import type { DiscoverDish, DiscoverFeed } from "@gudmeal/api-client";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { cleanup, fireEvent, render, screen } from "@testing-library/react";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

const discover = vi.fn<(q: unknown) => Promise<DiscoverFeed>>();
vi.mock("@/lib/api", () => ({ publicApi: { catalog: { discover: (q: unknown) => discover(q) } } }));
vi.mock("@/lib/location", () => ({
  useLocation: () => ({ area: { name: "Victoria Island", city: "lagos", location: { lat: 6.4281, lng: 3.4219 } } }),
}));

const { DishFeed, askHref, orderHref } = await import("./dish-feed");

const dish = (item_id: string, name: string, restaurant_name: string): DiscoverDish => ({
  item_id, restaurant_id: `r-${item_id}`, restaurant_name, area: "Victoria Island", city: "lagos", name, description: "", price_kobo: 450_000,
  image_url: null, art: "plate", kind: "main", tags: [], dietary: [], allergens: [], spice_level: 0, serves: 1, prep_minutes: null,
  likes: 10, rating: 4.5, rating_count: 10, eyebrow: "", has_options: false, is_available: true, is_open: true, is_accepting_orders: true,
  is_new_kitchen: false, eta_minutes: 30, delivery_fee_kobo: 60_000, delivers_to_location: true,
});
const FEED: DiscoverFeed = {
  city: "lagos",
  generated_at: "2026-11-16T20:00:00Z",
  sections: [
    { id: "most_loved", title: "Most loved dishes", subtitle: "What everyone near you is ordering", dishes: [dish("a", "Beef Suya (250g)", "Suya Lane")] },
    { id: "new_kitchens", title: "New kitchen discoveries", subtitle: "", dishes: [] },
    { id: "top_rated", title: "From top-rated kitchens", subtitle: "Signature dishes", dishes: [dish("b", "Party Jollof Rice", "Jollof Junction")] },
  ],
};

function renderFeed() {
  const client = new QueryClient({ defaultOptions: { queries: { retry: false } } });
  return render(<QueryClientProvider client={client}><DishFeed /></QueryClientProvider>);
}

beforeEach(() => {
  discover.mockReset();
  vi.stubGlobal("matchMedia", (query: string) => ({ matches: query.includes("reduce"), media: query, addEventListener: () => {}, removeEventListener: () => {} }));
});
afterEach(() => {
  cleanup();
  vi.unstubAllGlobals();
});

describe("Discover dish feed", () => {
  it("loads the dishes near the chosen area and switches between the lists", async () => {
    discover.mockResolvedValue(FEED);
    renderFeed();
    expect(await screen.findByRole("heading", { name: "Most loved dishes" })).toBeTruthy();
    expect(discover).toHaveBeenCalledWith({ city: "lagos", lat: 6.4281, lng: 3.4219, limit: 8 });
    expect(screen.getByRole("region", { name: "Most loved dishes" })).toBeTruthy();
    expect(screen.getByText("Suya Lane")).toBeTruthy();
    // empty lists get no chip
    expect(screen.queryByRole("button", { name: "New kitchens" })).toBeNull();

    fireEvent.click(screen.getByRole("button", { name: "Top rated" }));
    expect(screen.getByRole("heading", { name: "From top-rated kitchens" })).toBeTruthy();
    expect(screen.getByRole("button", { name: "Top rated" }).getAttribute("aria-pressed")).toBe("true");
    expect(screen.getByText("Jollof Junction")).toBeTruthy();
    expect(screen.getByRole("link", { name: /^Order food · ₦4,500/ }).getAttribute("href")).toBe("/restaurants/r-b?item=b");
  });

  it("offers a retry when the feed can't load (the stores list below still works)", async () => {
    discover.mockRejectedValue(new Error("offline"));
    renderFeed();
    expect(await screen.findByText(/couldn’t load today’s dishes/)).toBeTruthy();
    discover.mockResolvedValue(FEED);
    fireEvent.click(screen.getByRole("button", { name: "Try again" }));
    expect(await screen.findByRole("heading", { name: "Most loved dishes" })).toBeTruthy();
  });

  it("links Order food to the dish on the kitchen's menu and asks Gudy about it", () => {
    const d = dish("sl beef/1", "Beef Suya (250g)", "Suya Lane");
    expect(orderHref(d)).toBe("/restaurants/r-sl beef/1?item=sl%20beef%2F1");
    expect(decodeURIComponent(askHref(d).split("q=")[1]!)).toBe(
      "Tell me about the Beef Suya (250g) from Suya Lane. What does it come with, and what would it cost delivered to me?",
    );
  });
});
