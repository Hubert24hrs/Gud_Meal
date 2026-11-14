"use client";

import type { GeoPoint } from "@gudmeal/api-client";
import { createContext, useContext, useEffect, useMemo, useState, type ReactNode } from "react";

/** Launch areas in Lagos. Production uses Google Places autocomplete + geocoding when a Maps key is set. */
export const LAGOS_AREAS: { name: string; location: GeoPoint }[] = [
  { name: "Lekki Phase 1", location: { lat: 6.4474, lng: 3.4733 } },
  { name: "Victoria Island", location: { lat: 6.4281, lng: 3.4219 } },
  { name: "Ikoyi", location: { lat: 6.4520, lng: 3.4350 } },
  { name: "Oniru", location: { lat: 6.4366, lng: 3.4497 } },
  { name: "Yaba", location: { lat: 6.5095, lng: 3.3711 } },
  { name: "Surulere", location: { lat: 6.4969, lng: 3.3602 } },
  { name: "Ikeja GRA", location: { lat: 6.5833, lng: 3.3500 } },
];

interface LocationState {
  area: (typeof LAGOS_AREAS)[number];
  setArea: (name: string) => void;
}

const STORAGE_KEY = "gudmeal.area.v1";
const LocationContext = createContext<LocationState | null>(null);

export function LocationProvider({ children }: { children: ReactNode }) {
  const [area, setAreaState] = useState(LAGOS_AREAS[0]!);
  useEffect(() => {
    try {
      const saved = window.localStorage.getItem(STORAGE_KEY);
      const found = LAGOS_AREAS.find((a) => a.name === saved);
      if (found) setAreaState(found);
    } catch {
      /* ignore */
    }
  }, []);
  const value = useMemo<LocationState>(() => ({
    area,
    setArea: (name: string) => {
      const found = LAGOS_AREAS.find((a) => a.name === name);
      if (!found) return;
      setAreaState(found);
      try {
        window.localStorage.setItem(STORAGE_KEY, name);
      } catch {
        /* ignore */
      }
    },
  }), [area]);
  return <LocationContext.Provider value={value}>{children}</LocationContext.Provider>;
}

export function useLocation(): LocationState {
  const ctx = useContext(LocationContext);
  if (!ctx) throw new Error("useLocation must be used inside LocationProvider");
  return ctx;
}
