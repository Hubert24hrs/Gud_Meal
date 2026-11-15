# ADR-0014: Google Maps Platform behind the API (places, routes, live tracking)

- **Status:** Accepted (engineering). Real Google calls need the owner's key and billing approval.
- **Date:** 2026-11-15
- **Context owner:** owner's Google Maps Platform brief of 2026-11-15. Setup guide: [GOOGLE_MAPS.md](../GOOGLE_MAPS.md)

## Context

Customers need to see nearby restaurants, search addresses with pins, use GPS or saved addresses, and get
distances and road-based arrival times. Restaurants need a checked location and coverage area. Delivery fees
should follow road distance. Riders need navigation, customers need a live rider map, and Gudy should recommend
places by distance and arrival time.

The owner's constraints:

- Do not expose API keys in frontend code.
- Do not fabricate GPS positions or delivery estimates.
- Do not track riders outside active deliveries.
- No paid usage or deploys without approval.
- Keep the existing ordering, payment, auth and notification systems.

Before this change the API already had:

- a neighbourhood table (Lagos and Enugu centres);
- straight-line distance × a road factor;
- pricing zones;
- geohashed rider positions;
- `/v1/places/resolve`;
- an order tracking document.

## Decision

### 1. Google web services are called only by gudmeal-api

- Places API (New) (Autocomplete and Place Details), Geocoding API and Routes API (`computeRoutes`,
  `computeRouteMatrix`) are called with a **server key** from Secret Manager (`GOOGLE_MAPS_API_KEY`).
- Apps and websites call `/v1/places/*` and `/v1/delivery/estimates`. They never see that key.
- Distances that affect money are measured on the server, so a client cannot change them.

### 2. Map display uses separate, restricted keys (configuration, never committed)

Drawing a map (Maps SDK for Android/iOS, Maps JavaScript API) needs a key on the device. Google designs these
keys to be visible. Each is restricted:

- the Android key to the app's package name and signing certificate;
- the iOS key to the bundle ID;
- the browser key to Gud Meal's web domains.

Each key is limited to its display API only. Keys come from build configuration or environment variables, never
source code. Without them, apps draw a simple schematic map from the same API data.

### 3. Keyless fallback, always labelled

Without a key (local, tests, CI) or during an outage or over the daily cap, the API uses:

- its neighbourhood table;
- straight-line distance × 1.35 road factor at 18 km/h.

Every response carries `provider` / `source` (`google`, `local`, `estimate`) and `precision`, so apps and Gudy
say "estimate". Reverse geocoding without Google keeps the device's own coordinates and only names the nearest
neighbourhood ("Near Yaba, Lagos"). No position is invented.

### 4. Pricing stays in `pricing.py`

- `delivery_fee`, `rider_pay`, `parcel_fee` and `parcel_rider_pay` accept an optional measured road distance.
- `estimate_minutes` and `parcel_minutes` accept measured travel minutes. These are used only when Google
  answered.
- A quote stores `road_distance_km` and `route_source`. Creating the order re-prices with the same route, so
  traffic changing between quote and order can never cause a false "price changed".
- Coverage (zones, delivery radius) still uses straight-line distance, so a detour cannot move an address out
  of coverage.
- Money stays in integer kobo.

### 5. Rider location privacy, enforced on the server

- Location pings are refused (409) while the rider is offline.
- An idle online rider's position is stored only as the centre of a geohash-6 cell (about 1.2 × 0.6 km). That
  is enough for dispatch and is not a trail.
- The precise position is stored only while the rider has an order in `rider_assigned`, `picked_up` or
  `in_transit`. It goes to that order's tracking document with:
  - the arrival time, counted down locally and re-measured at most every `MAPS_LIVE_ETA_REFRESH_SECONDS`
    (default 180) or when the leg changes;
  - the current leg's route line.
- When the delivery ends, `release_rider` clears the position, arrival time and route line and marks tracking
  inactive. The customer endpoint only returns them while live.
- The operations map (`/v1/admin/riders/live`, dispatch permission) shows idle riders at area precision only.

### 6. Cost controls

- Field masks on every call: Place Details uses Essentials fields only; routes ask only for distance, duration
  and polyline.
- Autocomplete session tokens: one search, then one Place Details.
- Caches:
  - place details for 24 h;
  - routes for 5 min, keyed on coordinates rounded to about 11 m;
  - no caching of autocomplete results.
- One route-matrix call compares up to 10 kitchens.
- A per-instance daily cap (`MAPS_DAILY_REQUEST_CAP`, default 20,000). Above it the API falls back to estimates
  and logs a warning.
- A per-user rate limit (`places`: 40 burst, 0.5/s).
- `MAPS_TRAFFIC_AWARE` selects the Routes tier. Traffic-aware routing bills at Google's Pro rate; switching it
  off uses Essentials.
- GCP quotas and a billing budget with alerts are the hard limit (see the guide).
- Google's terms limit caching: place IDs may be stored indefinitely; Places latitude/longitude may be cached for
  at most 30 days. Our caches are far shorter. Saved addresses keep the user-confirmed pin and the place ID.
  Legal review of the Service Specific Terms is still required before launch.

### 7. Gudy

Gudy gets two read-only tools, `find_nearby_restaurants` and `compare_delivery_times`:

- no identity or amount arguments;
- they use the customer's saved address and copy minutes, kilometres and fees from the API;
- they always say the numbers are estimates and that checkout confirms the price.

Offline (keyword) mode routes "near me / closest / fastest" questions to them.

### 8. Roles

| Action | Who |
|---|---|
| Places and estimates | Any signed-in user (rate limited) |
| A kitchen's location | Its owner or manager (`settings`) |
| Moves over 2 km and radius changes | Staff only (`restaurants.manage`) |
| Live rider map | `dispatch.manual` |
| Maps status | `config.read` |

Every location change is audited (`restaurant.location_updated`).

## Consequences

- Everything works today without a key: estimates are shown, labelled. Adding the server secret switches the same
  endpoints to measured results, with no app release needed.
- Keyed and keyless environments can price a delivery slightly differently (road km against straight line ×
  factor). A quote and its order always match.
- Live tracking is the largest recurring cost. The refresh interval and traffic tier are the main controls.
- Privacy rules hold even if an app misbehaves, because the server enforces them.

## Alternatives considered

- **Calling Google directly from apps with restricted keys.** Rejected for web services: the key would ship in
  apps, nothing could be cached or capped on the server, and client-measured distances can't be trusted for
  prices.
- **Self-hosted OSRM or Valhalla with OpenStreetMap.** Cheaper at scale, but it needs infrastructure, and road
  data quality in Lagos and Enugu varies. It can be added later behind the same `MapsService` interface.
- **Distance Matrix and Directions APIs (legacy).** Replaced by the Routes API.
