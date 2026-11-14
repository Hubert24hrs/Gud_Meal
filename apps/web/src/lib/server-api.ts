import "server-only";
import { createApi } from "@gudmeal/api-client";

/** Server-side client for SEO pages (public catalog only — no user tokens on the server). */
export const serverApi = createApi({
  baseUrl: process.env.API_URL ?? process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:8000",
});

export async function safe<T>(promise: Promise<T>): Promise<{ data: T | null; error: string | null }> {
  try {
    return { data: await promise, error: null };
  } catch (err) {
    return { data: null, error: err instanceof Error ? err.message : "Unavailable" };
  }
}
