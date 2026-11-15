import type { WaybillTracking } from "@gudmeal/api-client";
import { cleanup, render, screen } from "@testing-library/react";
import { afterEach, describe, expect, it, vi } from "vitest";

vi.mock("next/navigation", () => ({
  useRouter: () => ({ push: vi.fn(), back: vi.fn(), replace: vi.fn() }),
  usePathname: () => "/",
  useSearchParams: () => new URLSearchParams(),
}));

const { WaybillTimeline } = await import("./waybill-timeline");
const { normaliseTrackingCode, TRACKING_PATTERN } = await import("@/app/track/track-form");
const { routeForScreen } = await import("@/app/assistant/chat");

const base: WaybillTracking = {
  tracking_code: "GMW7K3P9Q2X",
  origin: "Lagos",
  destination: "Abuja",
  stage: "departed",
  label: "On the way to Abuja",
  step: 2,
  steps: ["Booked", "At the hub", "On the way", "Arrived", "Delivered"],
  eta_from: "2026-11-17",
  eta_to: "2026-11-18",
  eta_text: "Tue 17 Nov – Wed 18 Nov",
  last_mile: "collect",
  collection_point: { name: "Partner terminal, Utako (sample)", address: "Utako District, Abuja", hours: "Mon–Sat, 8am–7pm" },
  milestones: [
    { stage: "awaiting_dropoff", label: "Drop off at the hub", at: "2026-11-16T09:00:00Z", place: "Gud Meal Hub, Lekki (sample)" },
    { stage: "at_origin_hub", label: "At the Lagos hub", at: "2026-11-16T10:00:00Z", place: "Gud Meal Hub, Lekki (sample)" },
    { stage: "departed", label: "On the way to Abuja", at: "2026-11-16T18:00:00Z", place: "Gud Meal Hub, Lekki (sample)" },
  ],
  delivered: false,
};

describe("waybill tracking", () => {
  afterEach(cleanup);

  it("shows the route, current step, expected window, collection point and newest scan first", () => {
    render(<WaybillTimeline data={base} />);
    expect(screen.getByText("Lagos → Abuja")).toBeTruthy();
    expect(screen.getByText("GMW7K3P9Q2X")).toBeTruthy();
    expect(screen.getByText("Expected Tue 17 Nov – Wed 18 Nov")).toBeTruthy();
    expect(screen.getByText(/Partner terminal, Utako/)).toBeTruthy();
    const history = screen.getByRole("list", { name: "Shipment history" });
    expect(history.querySelectorAll("li")[0]!.textContent).toContain("On the way to Abuja");
    expect(screen.getAllByText("On the way to Abuja")).toHaveLength(2); // headline and newest scan
  });

  it("hides the expected date and collection point once delivered or cancelled", () => {
    render(<WaybillTimeline data={{ ...base, delivered: true, label: "Delivered", step: 4 }} />);
    expect(screen.queryByText(/Expected/)).toBeNull();
    expect(screen.queryByText(/Collection point/)).toBeNull();
    cleanup();
    render(<WaybillTimeline data={{ ...base, label: "Cancelled", step: -1 }} />);
    expect(screen.queryByRole("list", { name: "Shipment progress" })).toBeNull();
  });

  it("accepts tracking numbers however people type them, and routes Gudy's button to the interstate form", () => {
    expect(normaliseTrackingCode(" gmw-7k3p 9q2x ")).toBe("GMW7K3P9Q2X");
    expect(TRACKING_PATTERN.test("GMW7K3P9Q2X")).toBe(true);
    expect(TRACKING_PATTERN.test("GMW7K3P9Q2O")).toBe(false); // O and 0 are never used
    expect(routeForScreen("waybill")).toBe("/send?mode=interstate");
  });
});
