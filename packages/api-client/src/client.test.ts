import { describe, expect, it } from "vitest";
import { ApiError, createApi, formatDayLabel, formatNaira, ORDER_STATUS } from "./index";

function mockFetch(status: number, body: unknown, seen: Request[] = []) {
  return (async (input: URL | RequestInfo, init?: RequestInit) => {
    seen.push(new Request(input as URL, init));
    return new Response(body === undefined ? null : JSON.stringify(body), { status });
  }) as typeof fetch;
}

describe("formatNaira", () => {
  it("formats kobo as naira", () => {
    expect(formatNaira(1_000_000)).toBe("₦10,000");
    expect(formatNaira(150_050)).toBe("₦1,500.50");
    expect(formatNaira(-500)).toBe("-₦5");
    expect(formatNaira(null)).toBe("—");
  });
  it("labels chart days day-first, independent of the viewer's timezone", () => {
    expect(formatDayLabel("2026-11-02")).toBe("2 Nov");
    expect(formatDayLabel("2026-01-31T23:30:00Z")).toBe("31 Jan");
    expect(formatDayLabel("not-a-date")).toBe("not-a-date");
  });
  it("labels every order status", () => {
    expect(Object.keys(ORDER_STATUS)).toHaveLength(17);
  });
});

describe("createApi", () => {
  it("sends auth, idempotency and query parameters", async () => {
    const seen: Request[] = [];
    const api = createApi({ baseUrl: "http://api.test/", getToken: async () => "tok", fetchImpl: mockFetch(201, { id: "o1" }, seen) });
    await api.orders.create("q1", "key-12345678");
    const req = seen[0]!;
    expect(req.url).toBe("http://api.test/v1/orders");
    expect(req.headers.get("authorization")).toBe("Bearer tok");
    expect(req.headers.get("idempotency-key")).toBe("key-12345678");
    expect(await req.json()).toEqual({ quote_id: "q1", channel: "web" });

    await api.partner.orders("r1", ["submitted_to_restaurant", "preparing"]);
    expect(seen[1]!.url).toBe("http://api.test/v1/partner/restaurants/r1/orders?status=submitted_to_restaurant&status=preparing&limit=100");
  });

  it("does not send tokens to public catalog endpoints", async () => {
    const seen: Request[] = [];
    const api = createApi({ baseUrl: "http://api.test", getToken: async () => "tok", fetchImpl: mockFetch(200, [], seen) });
    await api.catalog.restaurants({ lat: 6.4, lng: 3.4 });
    expect(seen[0]!.headers.get("authorization")).toBeNull();
  });

  it("reads the Discover dish feed publicly, near the chosen area", async () => {
    const seen: Request[] = [];
    const api = createApi({ baseUrl: "http://api.test", getToken: async () => "tok", fetchImpl: mockFetch(200, { city: "lagos", sections: [] }, seen) });
    await api.catalog.discover({ city: "lagos", lat: 6.4281, lng: 3.4219, limit: 8 });
    expect(seen[0]!.url).toBe("http://api.test/v1/discover/dishes?city=lagos&lat=6.4281&lng=3.4219&limit=8");
    expect(seen[0]!.headers.get("authorization")).toBeNull();
  });

  it("maps API errors", async () => {
    const api = createApi({ baseUrl: "http://api.test", fetchImpl: mockFetch(409, { error: { code: "price_changed", message: "Prices changed" } }) });
    await expect(api.orders.get("x")).rejects.toMatchObject({ status: 409, code: "price_changed", message: "Prices changed" });
    await expect(api.orders.get("x")).rejects.toBeInstanceOf(ApiError);
  });
});

describe("growth calls", () => {
  it("sends Plus, rewards and group-order requests with idempotency keys where money moves", async () => {
    const seen: Request[] = [];
    const api = createApi({ baseUrl: "http://api.test", getToken: async () => "tok", fetchImpl: mockFetch(200, {}, seen) });
    await api.plus.subscribe("plus-key-0001", "wallet");
    await api.rewards.redeem(500, "redeem-key-01");
    await api.groups.join("ab3k7p");
    await api.groups.pay("g1", "pay-key-00001", { cover_rest: true });
    await api.groups.removeMember("g1", "cust-2");
    const [plus, redeem, join, pay, remove] = seen;
    expect(plus!.headers.get("idempotency-key")).toBe("plus-key-0001");
    expect(await plus!.json()).toEqual({ provider: "wallet", auto_renew: true });
    expect([redeem!.url, await redeem!.json()]).toEqual(["http://api.test/v1/rewards/redeem", { points: 500 }]);
    expect(join!.url).toBe("http://api.test/v1/group-orders/join");
    expect(await pay!.json()).toEqual({ cover_rest: true });
    expect(pay!.headers.get("idempotency-key")).toBe("pay-key-00001");
    expect([remove!.method, remove!.url]).toEqual(["DELETE", "http://api.test/v1/group-orders/g1/members/cust-2"]);
  });
});

