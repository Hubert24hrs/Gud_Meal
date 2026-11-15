import { describe, expect, it } from "vitest";
import { createApi, decodePolyline, directionsUrl, isMeasured, newPlacesSession } from "./index";

function mockFetch(body: unknown, seen: Request[]) {
  return (async (input: URL | RequestInfo, init?: RequestInit) => {
    seen.push(new Request(input as URL, init));
    return new Response(JSON.stringify(body), { status: 200 });
  }) as typeof fetch;
}

describe("maps helpers", () => {
  it("decodes Google encoded polylines", () => {
    expect(decodePolyline("_p~iF~ps|U_ulLnnqC_mqNvxq`@")).toEqual([
      { lat: 38.5, lng: -120.2 },
      { lat: 40.7, lng: -120.95 },
      { lat: 43.252, lng: -126.453 },
    ]);
    expect(decodePolyline("")).toEqual([]);
    expect(() => decodePolyline("_p~iF~ps|U_")).toThrow("Truncated polyline");
  });

  it("builds keyless directions links and session tokens", () => {
    const url = new URL(directionsUrl({ lat: 6.4478, lng: 3.4723 }));
    expect(url.origin + url.pathname).toBe("https://www.google.com/maps/dir/");
    expect(Object.fromEntries(url.searchParams)).toEqual({ api: "1", destination: "6.447800,3.472300", travelmode: "driving" });
    expect(newPlacesSession()).toMatch(/^[0-9a-f]{32}$/);
    expect(newPlacesSession()).not.toBe(newPlacesSession());
    expect(isMeasured("google")).toBe(true);
    expect(isMeasured("estimate")).toBe(false);
  });
});

describe("maps endpoints", () => {
  it("searches with a session and bias, signed in", async () => {
    const seen: Request[] = [];
    const api = createApi({ baseUrl: "http://api.test", getToken: async () => "tok", fetchImpl: mockFetch({ suggestions: [], provider: "local" }, seen) });
    await api.places.suggestions("Admiralty", "s1", { lat: 6.44, lng: 3.47 }, "lagos");
    const req = seen[0]!;
    expect(req.url).toBe("http://api.test/v1/places/autocomplete?q=Admiralty&session=s1&lat=6.44&lng=3.47&city=lagos");
    expect(req.headers.get("authorization")).toBe("Bearer tok");

    await api.places.estimates(["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k"], { lat: 6.4, lng: 3.4 });
    expect(new URL(seen[1]!.url).searchParams.get("restaurant_ids")).toBe("a,b,c,d,e,f,g,h,i,j");

    await api.partner.updateLocation("r1", { address: "12 Admiralty Way, Lekki", location: { lat: 6.44, lng: 3.47 }, confirm_pin: true });
    expect(seen[2]!.method).toBe("PUT");
    expect(seen[2]!.url).toBe("http://api.test/v1/partner/restaurants/r1/location");
    expect(await seen[2]!.json()).toEqual({ address: "12 Admiralty Way, Lekki", location: { lat: 6.44, lng: 3.47 }, confirm_pin: true });

    await api.admin.liveRiders();
    expect(seen[3]!.url).toBe("http://api.test/v1/admin/riders/live");
  });
});
