"use client";

import { createAgentsApi, createApi } from "@gudmeal/api-client";
import { useMemo } from "react";
import { useAuth } from "./auth";
import { appCheckToken } from "./firebase";

export const API_URL = process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:8000";
export const AGENTS_URL = process.env.NEXT_PUBLIC_AGENTS_URL ?? "http://localhost:8100";

/** Public (unauthenticated) client for browsing. */
export const publicApi = createApi({ baseUrl: API_URL });

export function useApi() {
  const { getToken } = useAuth();
  return useMemo(
    () => createApi({ baseUrl: API_URL, getToken, getAppCheckToken: appCheckToken }),
    [getToken],
  );
}

export function useAgentsApi() {
  const { getToken } = useAuth();
  return useMemo(() => createAgentsApi({ baseUrl: AGENTS_URL, getToken }), [getToken]);
}
