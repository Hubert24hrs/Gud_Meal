import type { DiscoverDish } from "@gudmeal/api-client";
import { act, cleanup, fireEvent, render, screen } from "@testing-library/react";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import {
  arcPath,
  arcRest,
  compactCount,
  dishDetails,
  dishHighlights,
  DishOrbitCarousel,
  frameAt,
  mixHex,
  splitTitle,
  stepDirection,
  stripStart,
  TIMELINE,
  wrapIndex,
} from "./dish-orbit-carousel";

const dish = (over: Partial<DiscoverDish> = {}): DiscoverDish => ({
  item_id: "sl-beef-suya", restaurant_id: "r-suya-lane", restaurant_name: "Suya Lane", area: "Victoria Island", city: "lagos",
  name: "Beef Suya (250g)", description: "Thinly sliced beef, yaji spice, onions and tomatoes.", price_kobo: 450_000, image_url: null,
  art: "skewers", kind: "main", tags: ["suya", "beef"], dietary: [], allergens: ["peanuts"], spice_level: 2, serves: 1,
  prep_minutes: 15, likes: 1500, rating: 4.8, rating_count: 2031, eyebrow: "#1 Most loved dish", has_options: true,
  is_available: true, is_open: true, is_accepting_orders: true, is_new_kitchen: false, distance_km: 0, eta_minutes: 29,
  delivery_fee_kobo: 60_000, delivers_to_location: true, ...over,
});
const DISHES = [
  dish(),
  dish({ item_id: "sr-shawarma", restaurant_id: "r-shawarma", restaurant_name: "Shawarma Republic", area: "Ikeja GRA", name: "Chicken Shawarma",
    art: "wrap", eyebrow: "#2 Most loved dish", likes: 1400, rating: 4.3, delivers_to_location: false, delivery_fee_kobo: null, eta_minutes: 106 }),
  dish({ item_id: "jj-party", restaurant_id: "r-jollof", restaurant_name: "Jollof Junction", area: "Lekki Phase 1", name: "Party Jollof Rice",
    art: "rice", eyebrow: "#3 Most loved dish", is_open: false, delivery_fee_kobo: 170_000, eta_minutes: 54 }),
];
const orderHref = (d: DiscoverDish) => `/restaurants/${d.restaurant_id}?item=${d.item_id}`;
const askHref = (d: DiscoverDish) => `/assistant?q=${encodeURIComponent(d.name)}`;

function mockReducedMotion(reduce: boolean) {
  vi.stubGlobal("matchMedia", (query: string) => ({
    matches: reduce && query.includes("reduce"), media: query, addEventListener: () => {}, removeEventListener: () => {},
  }));
}
const part = (role: "in" | "out", name: string) => document.querySelector<HTMLElement>(`[data-role="${role}"][data-part="${name}"]`);
const status = () => document.querySelector(".dsh-root > p.sr-only")?.textContent;

afterEach(() => {
  cleanup();
  vi.unstubAllGlobals();
  vi.restoreAllMocks();
  vi.useRealTimers();
});

describe("dish carousel helpers", () => {
  it("splits dish names into a thin and a heavy line, like the app", () => {
    expect(splitTitle("Party Jollof Rice")).toEqual({ thin: "Party", heavy: "Jollof Rice" });
    expect(splitTitle("Beef Suya (250g)")).toEqual({ thin: "Beef", heavy: "Suya" });
    expect(splitTitle("Amala, Gbegiri & Ewedu")).toEqual({ thin: "Amala", heavy: "Gbegiri & Ewedu" });
    expect(splitTitle("Shawarma")).toEqual({ thin: "", heavy: "Shawarma" });
  });

  it("wraps round both ways and swings the short way", () => {
    expect(wrapIndex(-1, 3)).toBe(2);
    expect(wrapIndex(3, 3)).toBe(0);
    expect(wrapIndex(5, 0)).toBe(0);
    expect(stepDirection(0, 1, 3)).toBe(1);
    expect(stepDirection(0, 2, 3)).toBe(-1);
    expect(stepDirection(7, 0, 8)).toBe(1);
    expect(stripStart(0, 8, 4)).toBe(0);
    expect(stripStart(5, 8, 4)).toBe(4);
    expect(stripStart(7, 8, 4)).toBe(4);
    expect(stripStart(2, 3, 4)).toBe(0);
  });

  it("describes the dish from what the API worked out, and never shows a time for a kitchen that can't deliver", () => {
    expect(dishDetails(DISHES[0]!)).toBe("Victoria Island · 29 min · ₦600 delivery");
    expect(dishDetails(DISHES[1]!)).toBe("Ikeja GRA · Outside your delivery area");
    expect(dishDetails(DISHES[2]!)).toBe("Lekki Phase 1 · Closed now · ₦1,700 delivery");
    expect(dishDetails(dish({ is_accepting_orders: false, is_available: false, eta_minutes: null, delivery_fee_kobo: null })))
      .toBe("Victoria Island · Paused · Sold out");
    expect(dishHighlights({ tags: ["suya", "Beef"], dietary: ["beef"], allergens: ["peanuts"] })).toEqual(["suya", "Beef", "contains peanuts"]);
    expect([980, 1000, 1500, 12_400].map(compactCount)).toEqual(["980", "1k", "1.5k", "12k"]);
  });

  it("follows the original timeline: out over the top, in from the far side, band settling on the new dish", () => {
    const start = frameAt(0, 1, 0, 1);
    expect(start).toMatchObject({ outRotation: 0, outPlate: true, inPlate: false, outHead: true, inHead: false, outThin: 0, inBody: false });
    const mid = frameAt(0.5, 1, 0, 1);
    expect(mid.outRotation).toBeGreaterThan(0);
    expect(mid.inRotation).toBeLessThan(0);
    expect(mid.inHead).toBe(true);
    expect(frameAt(0.5, -1, 1, 0).outRotation).toBeLessThan(0);
    const end = frameAt(TIMELINE, 1, 0, 1);
    expect(end).toMatchObject({ outPlate: false, outHead: false, inPlate: true, inThin: 0, inHeavy: 0, outBody: 0 });
    expect(Math.abs(end.inRotation)).toBe(0);
    expect([end.band.a0, end.band.a1]).toEqual([...arcRest(1)]);
    expect(end.band.tint).toBe(1);
    expect(end.rows.every((r) => r.opacity === 1 && r.y === 0)).toBe(true);
    expect(mixHex("#000000", "#ffffff", 0.5)).toBe("#808080");
    const band = arcPath(50, 98, 299, -450, 650, 118, 8);
    expect(band.startsWith("M")).toBe(true);
    expect(band.endsWith("Z")).toBe(true);
    expect(band.split("L")).toHaveLength(18);
  });
});

describe("DishOrbitCarousel", () => {
  beforeEach(() => mockReducedMotion(true));

  it("shows the first dish with its kitchen, price and the links to order or ask Yummy", () => {
    render(<DishOrbitCarousel dishes={DISHES} orderHref={orderHref} askHref={askHref} />);
    const region = screen.getByRole("region", { name: "Featured dishes" });
    expect(region.getAttribute("aria-roledescription")).toBe("carousel");
    expect(part("in", "head")?.textContent).toContain("#1 Most loved dish");
    expect(part("in", "head")?.querySelector(".dsh-t1")?.textContent).toBe("Beef");
    expect(part("in", "head")?.querySelector(".dsh-t2")?.textContent).toBe("Suya");
    expect(screen.getByRole("link", { name: "Order food · ₦4,500 for Beef Suya (250g) from Suya Lane" }).getAttribute("href"))
      .toBe("/restaurants/r-suya-lane?item=sl-beef-suya");
    expect(screen.getByRole("link", { name: "Ask Yummy about Beef Suya (250g)" }).getAttribute("href")).toBe("/assistant?q=Beef%20Suya%20(250g)");
    expect(screen.getByRole("button", { name: "Show Chicken Shawarma" })).toBeTruthy();
    expect(screen.getByRole("img", { name: "Kitchen rated 4.8 out of 5" })).toBeTruthy();
    expect(screen.getByText("Victoria Island · 29 min · ₦600 delivery")).toBeTruthy();
    expect(part("in", "plate")?.querySelector("img")?.getAttribute("src")).toMatch(/^data:image\/svg\+xml/);
    expect(status()).toBe("Dish 1 of 3: Beef Suya (250g) from Suya Lane");
  });

  it("moves with the arrows, the pager, arrow keys and swipes (at once with reduced motion)", () => {
    render(<DishOrbitCarousel dishes={DISHES} orderHref={orderHref} />);
    const region = screen.getByRole("region", { name: "Featured dishes" });
    fireEvent.click(screen.getByRole("button", { name: "Next dish" }));
    expect(status()).toBe("Dish 2 of 3: Chicken Shawarma from Shawarma Republic");
    expect(document.querySelector('[data-role="out"]')).toBeNull();
    expect(screen.getByText("Ikeja GRA · Outside your delivery area")).toBeTruthy();

    fireEvent.keyDown(region, { key: "ArrowRight" });
    expect(status()).toContain("Dish 3 of 3: Party Jollof Rice");
    fireEvent.keyDown(region, { key: "ArrowRight" });
    expect(status()).toContain("Dish 1 of 3");
    fireEvent.keyDown(region, { key: "ArrowLeft" });
    expect(status()).toContain("Dish 3 of 3");

    fireEvent.click(screen.getByRole("button", { name: "Dish 2: Chicken Shawarma" }));
    expect(status()).toContain("Dish 2 of 3");
    expect(screen.getByRole("button", { name: "Dish 2: Chicken Shawarma" }).getAttribute("aria-current")).toBe("true");

    const plates = document.querySelector(".dsh-plates")!;
    fireEvent.pointerDown(plates, { clientX: 300, clientY: 100 });
    fireEvent.pointerUp(plates, { clientX: 310, clientY: 220 }); // a scroll, not a swipe
    expect(status()).toContain("Dish 2 of 3");
    fireEvent.pointerDown(plates, { clientX: 300, clientY: 100 });
    fireEvent.pointerUp(plates, { clientX: 200, clientY: 110 }); // swipe left: next dish
    expect(status()).toContain("Dish 3 of 3");
    fireEvent.pointerDown(plates, { clientX: 200, clientY: 100 });
    fireEvent.pointerUp(plates, { clientX: 320, clientY: 90 }); // swipe right: previous dish
    expect(status()).toContain("Dish 2 of 3");
  });

  it("shows what's in the dish and remembers likes on this page", () => {
    render(<DishOrbitCarousel dishes={DISHES} orderHref={orderHref} />);
    fireEvent.click(screen.getByRole("tab", { name: "Ingredients" }));
    expect(screen.getByRole("list", { name: "What's in Beef Suya (250g)" }).textContent).toContain("contains peanuts");
    const like = screen.getByRole("button", { name: "Like Beef Suya (250g), 1.5k orders" });
    fireEvent.click(like);
    expect(like.getAttribute("aria-pressed")).toBe("true");
    fireEvent.click(screen.getByRole("button", { name: "Not for me" }));
    expect(like.getAttribute("aria-pressed")).toBe("false");
    expect(screen.getByRole("button", { name: "Not for me" }).getAttribute("aria-pressed")).toBe("true");
  });

  it("starts a new list (another section or area) at its first dish", () => {
    const { rerender } = render(<DishOrbitCarousel dishes={DISHES} orderHref={orderHref} />);
    fireEvent.click(screen.getByRole("button", { name: "Next dish" }));
    rerender(<DishOrbitCarousel dishes={[DISHES[2]!, DISHES[0]!]} orderHref={orderHref} />);
    expect(status()).toBe("Dish 1 of 2: Party Jollof Rice from Jollof Junction");
    rerender(<DishOrbitCarousel dishes={[{ ...DISHES[2]! }, DISHES[0]!]} orderHref={orderHref} />); // same dishes, new objects
    expect(status()).toContain("Dish 1 of 2");
    rerender(<DishOrbitCarousel dishes={[]} orderHref={orderHref} />);
    expect(screen.queryByRole("region")).toBeNull();
  });

  it("swings the plates when motion is allowed, then drops the outgoing dish", () => {
    mockReducedMotion(false);
    const frames: FrameRequestCallback[] = [];
    vi.stubGlobal("requestAnimationFrame", (cb: FrameRequestCallback) => frames.push(cb));
    vi.stubGlobal("cancelAnimationFrame", () => {});
    vi.spyOn(performance, "now").mockReturnValue(0);
    render(<DishOrbitCarousel dishes={DISHES} orderHref={orderHref} autoPlayMs={0} />);
    fireEvent.click(screen.getByRole("button", { name: "Next dish" }));

    const out = part("out", "plate")!;
    const incoming = part("in", "plate")!;
    expect(out).toBeTruthy();
    expect(out.hasAttribute("inert")).toBe(true);
    expect(incoming.style.visibility).toBe("hidden"); // waits off stage until 0.3 s

    act(() => frames.shift()!(500));
    expect(out.style.transform).toMatch(/^rotate\(\d/); // forwards: out over the top
    expect(incoming.style.visibility).toBe("");
    expect(incoming.style.transform).toMatch(/^rotate\(-/); // in from the far side
    expect(part("in", "head")!.style.visibility).toBe("");
    expect(document.querySelector<SVGPathElement>(".dsh-band")!.getAttribute("d")).toMatch(/^M.*Z$/);

    act(() => {
      while (frames.length) frames.shift()!(2000);
    });
    expect(document.querySelector('[data-role="out"]')).toBeNull();
    expect(incoming.style.transform).toBe("");
    expect(document.querySelector(".dsh-band")!.getAttribute("fill")?.toLowerCase()).toBe("#f2a6c6");
  });

  it("moves on by itself, pauses on hover and with the pause button, and stays still with reduced motion", () => {
    mockReducedMotion(false);
    vi.useFakeTimers();
    vi.stubGlobal("requestAnimationFrame", () => 1);
    vi.stubGlobal("cancelAnimationFrame", () => {});
    Object.defineProperty(document, "hidden", { configurable: true, get: () => false });
    render(<DishOrbitCarousel dishes={DISHES} orderHref={orderHref} autoPlayMs={6000} />);
    const region = screen.getByRole("region", { name: "Featured dishes" });
    expect(document.querySelector(".dsh-root > p.sr-only")?.getAttribute("aria-live")).toBe("off");

    fireEvent.pointerEnter(region, { pointerType: "mouse" });
    act(() => vi.advanceTimersByTime(6000));
    expect(status()).toContain("Dish 1 of 3");
    fireEvent.pointerLeave(region, { pointerType: "mouse" });
    act(() => vi.advanceTimersByTime(6000));
    expect(status()).toContain("Dish 2 of 3");

    fireEvent.click(screen.getByRole("button", { name: "Pause the dish slides" }));
    expect(screen.getByRole("button", { name: "Play the dish slides" })).toBeTruthy();
    expect(document.querySelector(".dsh-root > p.sr-only")?.getAttribute("aria-live")).toBe("polite");
    cleanup();

    mockReducedMotion(true);
    render(<DishOrbitCarousel dishes={DISHES} orderHref={orderHref} autoPlayMs={6000} />);
    expect(screen.queryByRole("button", { name: /dish slides/ })).toBeNull();
    act(() => vi.advanceTimersByTime(30_000));
    expect(status()).toContain("Dish 1 of 3");
  });
});
