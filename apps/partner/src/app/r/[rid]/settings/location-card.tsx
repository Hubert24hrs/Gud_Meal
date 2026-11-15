"use client";

import { ApiError, type GeoPoint, type RestaurantLocationUpdate } from "@gudmeal/api-client";
import { AddressSearch, Badge, Button, Card, ErrorState, Field, Input, MapView, Skeleton } from "@gudmeal/ui";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useState } from "react";
import { useApi } from "@/lib/api";

const BROWSER_KEY = process.env.NEXT_PUBLIC_GOOGLE_MAPS_BROWSER_KEY || undefined;

/**
 * The kitchen's pin. Customers' distances, delivery fees and riders' navigation all start here, so the API checks
 * a new pin against its address, keeps it inside the city's delivery areas and records every change.
 */
export function LocationCard({ rid }: { rid: string }) {
  const api = useApi();
  const qc = useQueryClient();
  const current = useQuery({ queryKey: ["location", rid], queryFn: () => api.partner.location(rid) });
  const [draft, setDraft] = useState<RestaurantLocationUpdate | null>(null);
  const [suggested, setSuggested] = useState<{ location: GeoPoint; distanceKm: number } | null>(null);

  const save = useMutation({
    mutationFn: (body: RestaurantLocationUpdate) => api.partner.updateLocation(rid, body),
    onSuccess: (saved) => {
      qc.setQueryData(["location", rid], saved);
      setDraft(null);
      setSuggested(null);
    },
    onError: (e) => {
      const at = e instanceof ApiError ? (e.details.suggested_location as GeoPoint | undefined) : undefined;
      setSuggested(at ? { location: at, distanceKm: Number(e instanceof ApiError ? e.details.distance_km : 0) } : null);
    },
  });

  if (current.isLoading) return <Skeleton className="h-64" />;
  if (current.error || !current.data) return <ErrorState message={(current.error as Error)?.message ?? "Location unavailable"} onRetry={() => current.refetch()} />;
  const loc = current.data;
  const pins = [
    { point: loc.location, kind: "kitchen" as const, label: draft ? "Current pin" : "Your kitchen" },
    ...(draft ? [{ point: draft.location, kind: "place" as const, label: "New pin" }] : []),
    ...(suggested ? [{ point: suggested.location, kind: "home" as const, label: "Address match" }] : []),
  ];

  return (
    <Card className="space-y-4 p-5">
      <div className="flex flex-wrap items-center justify-between gap-2">
        <h3 className="font-semibold">Kitchen location</h3>
        {loc.in_service_area ? <Badge tone="success">{loc.zone ?? "In our delivery area"}</Badge> : <Badge tone="danger">Outside our delivery areas</Badge>}
      </div>
      <MapView pins={pins} height={220} connect={false} googleKey={BROWSER_KEY} />
      <div className="text-sm">
        <p className="font-medium">{loc.address}</p>
        <p className="text-muted">{loc.area} · delivers up to {loc.delivery_radius_km} km (set by Gud Meal operations)</p>
      </div>

      <AddressSearch
        label="Move the pin to a new address"
        search={(q, session) => api.places.suggestions(q, session, loc.location, loc.city).then((r) => r.suggestions)}
        details={(placeId, session) => api.places.details(placeId, session)}
        onPicked={(found) => {
          setSuggested(null);
          save.reset();
          // A neighbourhood match (no Google key) is only an area: keep the street line so the partner can adjust it.
          const precise = found.place.precision === "rooftop" || found.place.precision === "street";
          setDraft({ address: precise ? found.place.formatted_address : loc.address, location: found.place.location, area: found.place.area, place_id: found.place.place_id });
        }}
      />

      {draft && (
        <div className="space-y-3 rounded-lg border border-border p-3 text-sm">
          <Field label="Address customers and riders see" htmlFor="kitchen-address" hint="Street, number and a landmark if it helps riders.">
            <Input id="kitchen-address" value={draft.address} onChange={(e) => setDraft({ ...draft, address: e.target.value })} />
          </Field>
          {suggested ? (
            <div className="space-y-2" role="alert">
              <p>
                This pin is {suggested.distanceKm.toFixed(1)} km from where that address is. Riders navigate to the pin,
                so use the address match, or keep your pin if it marks your entrance.
              </p>
              <div className="flex flex-wrap gap-2">
                <Button size="sm" loading={save.isPending} onClick={() => { const next = { ...draft, location: suggested.location }; setDraft(next); save.mutate(next); }}>
                  Use the address match
                </Button>
                <Button size="sm" variant="outline" loading={save.isPending} onClick={() => save.mutate({ ...draft, confirm_pin: true })}>Keep my pin</Button>
              </div>
            </div>
          ) : (
            <div className="flex flex-wrap gap-2">
              <Button size="sm" loading={save.isPending} disabled={draft.address.trim().length < 5} onClick={() => save.mutate({ ...draft, address: draft.address.trim() })}>
                Save new location
              </Button>
              <Button size="sm" variant="ghost" onClick={() => { setDraft(null); save.reset(); }}>Cancel</Button>
            </div>
          )}
          {save.error && !suggested && <p className="text-danger" role="alert">{(save.error as Error).message}</p>}
        </div>
      )}
      <p className="text-xs text-muted">Moves of more than 2 km are checked by Gud Meal before they go live. Every change is recorded.</p>
    </Card>
  );
}
