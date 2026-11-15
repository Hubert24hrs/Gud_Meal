import type { GeoPoint } from "./types";

/** Decodes a Google encoded polyline (precision 5) into points. */
export function decodePolyline(encoded: string): GeoPoint[] {
  const points: GeoPoint[] = [];
  let index = 0;
  let lat = 0;
  let lng = 0;
  const next = () => {
    let result = 0;
    let shift = 0;
    let b: number;
    do {
      if (index >= encoded.length) throw new Error("Truncated polyline");
      b = encoded.charCodeAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    return result & 1 ? ~(result >> 1) : result >> 1;
  };
  while (index < encoded.length) {
    lat += next();
    lng += next();
    points.push({ lat: lat / 1e5, lng: lng / 1e5 });
  }
  return points;
}

/** A new Places session token: one address search (typing + one pick) is billed as one session. */
export function newPlacesSession(): string {
  const bytes = new Uint8Array(16);
  if (typeof crypto !== "undefined" && "getRandomValues" in crypto) crypto.getRandomValues(bytes);
  else for (let i = 0; i < bytes.length; i++) bytes[i] = Math.floor(Math.random() * 256);
  return Array.from(bytes, (b) => b.toString(16).padStart(2, "0")).join("");
}

/** Turn-by-turn directions in Google Maps (app or website). No API key involved. */
export function directionsUrl(to: GeoPoint, travelMode: "driving" | "two-wheeler" | "walking" = "driving"): string {
  const params = new URLSearchParams({
    api: "1",
    destination: `${to.lat.toFixed(6)},${to.lng.toFixed(6)}`,
    travelmode: travelMode,
  });
  return `https://www.google.com/maps/dir/?${params.toString()}`;
}

/** True when Google measured the value; otherwise screens say "estimate". */
export const isMeasured = (source?: string | null) => source === "google";
