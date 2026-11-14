"use client";

import { createApi } from "@gudmeal/api-client";
import { useMemo } from "react";
import { useAuth } from "./auth";

export const API_URL = process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:8000";

export function useApi() {
  const { getToken } = useAuth();
  return useMemo(() => createApi({ baseUrl: API_URL, getToken }), [getToken]);
}
