"use client";

import { formatTime, type GeoPoint } from "@gudmeal/api-client";
import { Badge, Card, ErrorState, MapView, Skeleton } from "@gudmeal/ui";
import { useQuery } from "@tanstack/react-query";
import { useState } from "react";
import { useApi } from "@/lib/api";

const BROWSER_KEY = process.env.NEXT_PUBLIC_GOOGLE_MAPS_BROWSER_KEY || undefined;

/** Launch cities (centres). A rider belongs to the nearer one, so each map shows one city at a useful scale. */
const CITIES = { lagos: { name: "Lagos", at: { lat: 6.5244, lng: 3.3792 } }, enugu: { name: "Enugu", at: { lat: 6.4584, lng: 7.5464 } } } as const;
type City = keyof typeof CITIES;
const cityOf = (p: GeoPoint): City =>
  Math.hypot(p.lat - CITIES.lagos.at.lat, p.lng - CITIES.lagos.at.lng) <= Math.hypot(p.lat - CITIES.enugu.at.lat, p.lng - CITIES.enugu.at.lng) ? "lagos" : "enugu";

/**
 * Online riders for dispatch. Riders on a delivery show their live position; idle riders are only ever known to
 * about 1 km (the API stores nothing more precise), and offline riders are not shown at all.
 */
export function LiveRidersMap() {
  const api = useApi();
  const [selected, setSelected] = useState<string | null>(null);
  const [city, setCity] = useState<City>("lagos");
  const live = useQuery({ queryKey: ["riders-live"], queryFn: () => api.admin.liveRiders(), refetchInterval: 15_000 });
  const status = useQuery({ queryKey: ["maps-status"], queryFn: () => api.admin.mapsStatus(), retry: false });

  if (live.isLoading) return <Skeleton className="h-80" />;
  if (live.error) return <ErrorState message={(live.error as Error).message} onRetry={() => live.refetch()} />;
  const online = (live.data ?? []).filter((r) => r.location);
  const riders = online.filter((r) => cityOf(r.location!) === city);
  const onDelivery = riders.filter((r) => r.on_delivery).length;

  return (
    <Card className="space-y-3 p-5">
      <div className="flex flex-wrap items-center justify-between gap-2">
        <div className="flex items-center gap-3">
          <h2 className="font-semibold">Live riders</h2>
          <div className="flex rounded-md border border-border text-xs" role="group" aria-label="City">
            {(Object.keys(CITIES) as City[]).map((c) => (
              <button key={c} type="button" aria-pressed={city === c} onClick={() => { setCity(c); setSelected(null); }}
                className={`px-2.5 py-1 ${city === c ? "bg-primary text-on-primary" : "text-muted"}`}>
                {CITIES[c].name} ({online.filter((r) => cityOf(r.location!) === c).length})
              </button>
            ))}
          </div>
        </div>
        <div className="flex flex-wrap gap-2 text-xs">
          <Badge tone="success">{onDelivery} on delivery</Badge>
          <Badge>{riders.length - onDelivery} available</Badge>
          {status.data && (
            <Badge tone={status.data.provider === "google" ? "success" : "warning"}>
              {status.data.provider === "google"
                ? `Google Maps · ${status.data.requests_today.toLocaleString()} / ${status.data.daily_cap.toLocaleString()} requests today`
                : "Estimates only (no Google Maps key)"}
            </Badge>
          )}
        </div>
      </div>
      {riders.length === 0 ? (
        <p className="text-sm text-muted">No riders online in {CITIES[city].name} right now.</p>
      ) : (
        <>
          <MapView
            height={320}
            connect={false}
            googleKey={BROWSER_KEY}
            selectedId={selected}
            onPinClick={setSelected}
            pins={riders.map((r) => ({ point: r.location!, kind: r.on_delivery ? "rider" as const : "rider-idle" as const, id: r.rider_id, label: r.name }))}
          />
          <ul className="grid gap-2 text-sm sm:grid-cols-2">
            {riders.map((r) => (
              <li key={r.rider_id}>
                <button
                  type="button"
                  onClick={() => setSelected(r.rider_id)}
                  className={`w-full rounded-lg border p-2 text-left ${selected === r.rider_id ? "border-primary bg-primary-soft" : "border-border"}`}
                >
                  <span className="font-semibold">{r.name}</span> · {r.vehicle}
                  <span className="block text-xs text-muted">
                    {r.on_delivery ? `On delivery (${r.active_order_ids.length})` : "Available"} ·{" "}
                    {r.precision === "precise" ? "live position" : "area only (~1 km)"}
                    {r.located_at ? ` · seen ${formatTime(r.located_at)}` : ""}
                  </span>
                </button>
              </li>
            ))}
          </ul>
        </>
      )}
    </Card>
  );
}
