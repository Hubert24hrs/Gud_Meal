import type { PlaceLookup, PlaceSuggestion } from "@gudmeal/api-client";
import { AddressSearch, MapView, projectPoints } from "@gudmeal/ui";
import { cleanup, fireEvent, render, screen, waitFor } from "@testing-library/react";
import { useState } from "react";
import { afterEach, describe, expect, it, vi } from "vitest";

afterEach(cleanup);

const suggestion: PlaceSuggestion = {
  place_id: "ChIJ-admiralty", title: "5 Admiralty Way", subtitle: "Lekki Phase 1, Lagos", distance_m: 900, source: "google",
};
const lookup: PlaceLookup = {
  place: {
    place_id: "ChIJ-admiralty", formatted_address: "5 Admiralty Way, Lekki Phase 1, Lagos", location: { lat: 6.4478, lng: 3.4723 },
    area: "Lekki Phase 1", city: "lagos", precision: "rooftop", source: "google",
  },
  serviceable: true, zone: "island", city: "lagos",
};

describe("AddressSearch", () => {
  it("searches through the API with one session per pick and returns the chosen place", async () => {
    const search = vi.fn(async (_q: string, _session: string) => [suggestion]);
    const details = vi.fn(async (_placeId: string, _session: string) => lookup);
    const onPicked = vi.fn();
    function Parent() {
      const [, setN] = useState(0);
      return <AddressSearch search={(q, s) => search(q, s)} details={(id, s) => details(id, s)} onPicked={(l) => { onPicked(l); setN((n) => n + 1); }} />;
    }
    render(<Parent />);

    fireEvent.change(screen.getByRole("combobox", { name: "Find your address" }), { target: { value: "Ad" } });
    await new Promise((r) => setTimeout(r, 450));
    expect(search).not.toHaveBeenCalled(); // under 3 characters: no request

    fireEvent.change(screen.getByRole("combobox"), { target: { value: "Admiralty" } });
    const option = await screen.findByRole("option", { name: /5 Admiralty Way/ });
    expect(option.textContent).toContain("900 m");
    fireEvent.mouseDown(option);

    await waitFor(() => expect(onPicked).toHaveBeenCalledWith(lookup));
    // The list stays closed after a pick, even when the parent re-renders with new inline callbacks.
    await new Promise((r) => setTimeout(r, 450));
    expect(screen.queryByRole("listbox")).toBeNull();
    expect(search).toHaveBeenCalledTimes(1);
    const searchSession = search.mock.calls[0]![1];
    const pickSession = details.mock.calls[0]![1];
    expect(searchSession).toMatch(/^[0-9a-f]{32}$/);
    expect(pickSession).toBe(searchSession);
  });

  it("explains when the browser cannot share a location", async () => {
    const original = Object.getOwnPropertyDescriptor(window.navigator, "geolocation");
    Object.defineProperty(window.navigator, "geolocation", {
      configurable: true,
      value: { getCurrentPosition: (_ok: unknown, fail: () => void) => fail() },
    });
    render(<AddressSearch search={vi.fn(async () => [])} details={vi.fn()} reverse={vi.fn()} onPicked={vi.fn()} />);
    fireEvent.click(screen.getByRole("button", { name: "Use my current location" }));
    expect(await screen.findByRole("alert")).toHaveProperty("textContent", "Location is off or blocked. Search for your address instead.");
    if (original) Object.defineProperty(window.navigator, "geolocation", original);
  });
});

describe("MapView", () => {
  it("draws a schematic map with pins, the route and an accessible description when there is no key", () => {
    const onPinClick = vi.fn();
    render(
      <MapView
        route="_p~iF~ps|U_ulLnnqC"
        onPinClick={onPinClick}
        pins={[
          { point: { lat: 6.431, lng: 3.421 }, kind: "kitchen", label: "Suya Lane", id: "k" },
          { point: { lat: 6.4478, lng: 3.4723 }, kind: "home", label: "You" },
          { point: { lat: 6.44, lng: 3.45 }, kind: "rider", label: "Musa" },
        ]}
      />,
    );
    const map = screen.getByRole("img", { name: "Map showing Suya Lane, You, Musa" });
    expect(map.querySelector("polyline")).not.toBeNull();
    expect(screen.getByText("Map preview · not to scale")).toBeTruthy();
    fireEvent.click(screen.getByRole("button", { name: "Suya Lane" }));
    expect(onPinClick).toHaveBeenCalledWith("k");
  });

  it("keeps north up and every pin inside the box", () => {
    const lekki = { lat: 6.4478, lng: 3.4723 }, yaba = { lat: 6.5095, lng: 3.3711 };
    const project = projectPoints([lekki, yaba], { width: 300, height: 200 });
    const a = project(lekki), y = project(yaba);
    expect(y.y).toBeLessThan(a.y);
    expect(y.x).toBeLessThan(a.x);
    for (const p of [a, y]) {
      expect(p.x).toBeGreaterThanOrEqual(0);
      expect(p.x).toBeLessThanOrEqual(300);
      expect(p.y).toBeGreaterThanOrEqual(0);
      expect(p.y).toBeLessThanOrEqual(200);
    }
  });
});
