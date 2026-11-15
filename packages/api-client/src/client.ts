import type * as T from "./types";

export class ApiError extends Error {
  constructor(
    public status: number,
    public code: string,
    message: string,
    public details: Record<string, unknown> = {},
  ) {
    super(message);
    this.name = "ApiError";
  }
}

export interface ClientOptions {
  baseUrl: string;
  /** Returns a fresh Firebase ID token, or null when signed out. */
  getToken?: () => Promise<string | null>;
  /** Returns an App Check token when App Check is enabled. */
  getAppCheckToken?: () => Promise<string | null>;
  fetchImpl?: typeof fetch;
}

type Query = Record<string, string | number | boolean | null | undefined | string[]>;

export function newIdempotencyKey(prefix = "gm"): string {
  const rand = typeof crypto !== "undefined" && "randomUUID" in crypto
    ? crypto.randomUUID().replace(/-/g, "")
    : Math.random().toString(36).slice(2) + Date.now().toString(36);
  return `${prefix}-${rand}`;
}

export function createApi(opts: ClientOptions) {
  const base = opts.baseUrl.replace(/\/$/, "");
  const doFetch = opts.fetchImpl ?? fetch;

  async function request<R>(method: string, path: string, init: { body?: unknown; query?: Query; idempotencyKey?: string; auth?: boolean } = {}): Promise<R> {
    const url = new URL(base + path);
    for (const [k, v] of Object.entries(init.query ?? {})) {
      if (v === undefined || v === null || v === "") continue;
      if (Array.isArray(v)) v.forEach((x) => url.searchParams.append(k, x));
      else url.searchParams.set(k, String(v));
    }
    const headers: Record<string, string> = { Accept: "application/json" };
    if (init.body !== undefined) headers["Content-Type"] = "application/json";
    if (init.idempotencyKey) headers["Idempotency-Key"] = init.idempotencyKey;
    if (init.auth !== false && opts.getToken) {
      const token = await opts.getToken();
      if (token) headers.Authorization = `Bearer ${token}`;
    }
    if (opts.getAppCheckToken) {
      const ac = await opts.getAppCheckToken();
      if (ac) headers["X-Firebase-AppCheck"] = ac;
    }
    let res: Response;
    try {
      res = await doFetch(url, { method, headers, body: init.body === undefined ? undefined : JSON.stringify(init.body) });
    } catch {
      throw new ApiError(0, "network_error", "We couldn't reach Gud Meal. Check your connection and try again.");
    }
    if (res.status === 204) return undefined as R;
    const text = await res.text();
    const data = text ? JSON.parse(text) : undefined;
    if (!res.ok) {
      const err = data?.error ?? {};
      const detail = typeof data?.detail === "string" ? data.detail : undefined;
      throw new ApiError(res.status, err.code ?? "error", err.message ?? detail ?? "Something went wrong", err.details ?? {});
    }
    return data as R;
  }

  const get = <R>(path: string, query?: Query, auth = true) => request<R>("GET", path, { query, auth });
  const post = <R>(path: string, body: unknown = {}, idempotencyKey?: string) =>
    request<R>("POST", path, { body, idempotencyKey });
  const put = <R>(path: string, body: unknown) => request<R>("PUT", path, { body });
  const patch = <R>(path: string, body: unknown) => request<R>("PATCH", path, { body });
  const del = <R>(path: string) => request<R>("DELETE", path);

  return {
    request,
    catalog: {
      restaurants: (q: {
        lat?: number; lng?: number; cuisine?: string; q?: string; open_now?: boolean; sort?: string; limit?: number;
        vertical?: "food" | "beauty" | "all"; city?: string; category?: string; pickup?: boolean;
      } = {}) => get<T.RestaurantCard[]>("/v1/restaurants", q, false),
      services: (city?: string) => get<T.ServiceInfo[]>("/v1/services", city ? { city } : undefined, false),
      categories: (vertical: "food" | "beauty", city?: string) =>
        get<T.BrowseCategory[]>(`/v1/services/${vertical}/categories`, city ? { city } : undefined, false),
      areas: (city?: string) => get<T.PlaceArea[]>("/v1/places/areas", city ? { city } : undefined, false),
      resolvePlace: (q: string, city?: string) => get<T.PlaceArea>("/v1/places/resolve", { q, ...(city ? { city } : {}) }, false),
      restaurant: (id: string, loc?: { lat: number; lng: number }) => get<T.RestaurantDetail>(`/v1/restaurants/${id}`, loc, false),
      search: (q: string, loc?: { lat: number; lng: number }, vertical?: "food" | "beauty") =>
        get<{
          items: { item: T.MenuItem; restaurant_id: string; restaurant_name: string; vertical?: "food" | "beauty" }[];
          restaurants: T.RestaurantCard[];
        }>("/v1/search", { q, ...loc, ...(vertical ? { vertical } : {}) }, false),
      cuisines: () => get<{ name: string; restaurants: number }[]>("/v1/cuisines", undefined, false),
      publicConfig: () => get<Record<string, unknown>>("/v1/config/public", undefined, false),
    },
    me: {
      get: () => get<T.Me>("/v1/me"),
      profile: () => get<T.CustomerProfile>("/v1/me/profile"),
      updateProfile: (data: Partial<T.CustomerProfile>) => patch<T.CustomerProfile>("/v1/me/profile", data),
      addresses: () => get<T.SavedAddress[]>("/v1/me/addresses"),
      addAddress: (a: T.DeliveryAddress) => post<T.SavedAddress>("/v1/me/addresses", a),
      deleteAddress: (id: string) => del<void>(`/v1/me/addresses/${id}`),
      setFavourite: (rid: string, favourite: boolean) => put(`/v1/me/favourites/${rid}`, { favourite }),
      notifications: () => get<{ id: string; title: string; body: string; created_at: string }[]>("/v1/me/notifications"),
    },
    orders: {
      quote: (req: T.QuoteRequest) => post<T.Quote>("/v1/quotes", req),
      create: (quoteId: string, key: string, channel: "web" | "app" = "web", contact_phone?: string) =>
        post<T.Order>("/v1/orders", { quote_id: quoteId, channel, contact_phone }, key),
      checkout: (orderId: string, key: string, provider?: string) =>
        post<T.CheckoutResult>(`/v1/orders/${orderId}/checkout`, provider ? { provider } : {}, key),
      list: (limit = 20) => get<T.Order[]>("/v1/orders", { limit }),
      get: (id: string) => get<T.Order>(`/v1/orders/${id}`),
      events: (id: string) => get<T.OrderEvent[]>(`/v1/orders/${id}/events`),
      codes: (id: string) => get<{ delivery_code: string | null; pickup_code: string | null }>(`/v1/orders/${id}/codes`),
      tracking: (id: string) => get<T.Tracking>(`/v1/orders/${id}/tracking`),
      cancel: (id: string, reason?: string) => post<T.Order>(`/v1/orders/${id}/cancel`, { reason }),
      review: (id: string, body: { food_rating: number; delivery_rating?: number; comment?: string }) =>
        post(`/v1/orders/${id}/review`, body),
      reorder: (id: string, delivery_address?: T.DeliveryAddress) => post<T.Quote>(`/v1/orders/${id}/reorder`, { delivery_address }),
      payments: (id: string) => get<T.PaymentView[]>(`/v1/orders/${id}/payments`),
      summary: () => get<T.OrderSummary>("/v1/me/order-summary"),
    },
    parcels: {
      quote: (req: T.ParcelQuoteRequest) => post<T.ParcelQuote>("/v1/parcels/quotes", req),
      getQuote: (id: string) => get<T.ParcelQuote>(`/v1/parcels/quotes/${id}`),
      book: (quoteId: string, key: string, channel: "web" | "app" = "web") =>
        post<T.Order>("/v1/parcels", { quote_id: quoteId, channel }, key),
    },
    payments: {
      verify: (reference: string) => post<T.PaymentView>("/v1/payments/verify", { reference }),
    },
    mealPlans: (body: { budget_kobo: number; party_size: number; location: T.GeoPoint; deliver_by?: string | null }) =>
      post<T.MealPlanResult>("/v1/meal-plans", body),
    support: {
      open: (body: { order_id?: string; category: string; description: string; missing_item_ids?: string[]; channel?: string }) =>
        post<T.SupportTicket>("/v1/support/tickets", { channel: "web", ...body }),
      mine: () => get<T.SupportTicket[]>("/v1/support/tickets"),
    },
    applications: {
      restaurant: (body: Record<string, unknown>) => post<T.Application>("/v1/applications/restaurant", body),
      rider: (body: Record<string, unknown>) => post<T.Application>("/v1/applications/rider", body),
      mine: () => get<T.Application[]>("/v1/applications/mine"),
    },
    partner: {
      restaurants: () => get<{ restaurant: T.Restaurant; role: string }[]>("/v1/partner/restaurants"),
      menu: (rid: string) => get<{ restaurant: T.Restaurant; categories: T.MenuCategory[]; items: T.MenuItem[]; option_groups: T.OptionGroup[] }>(
        `/v1/partner/restaurants/${rid}/menu`),
      setCategories: (rid: string, names: string[]) => put(`/v1/partner/restaurants/${rid}/categories`, { names }),
      createItem: (rid: string, item: Record<string, unknown>) => post<T.MenuItem>(`/v1/partner/restaurants/${rid}/items`, item),
      updateItem: (rid: string, id: string, item: Record<string, unknown>) => put<T.MenuItem>(`/v1/partner/restaurants/${rid}/items/${id}`, item),
      setAvailability: (rid: string, id: string, available: boolean) =>
        patch<T.MenuItem>(`/v1/partner/restaurants/${rid}/items/${id}/availability`, { available }),
      deleteItem: (rid: string, id: string) => del<void>(`/v1/partner/restaurants/${rid}/items/${id}`),
      settings: (rid: string, body: Record<string, unknown>) => patch<T.Restaurant>(`/v1/partner/restaurants/${rid}/settings`, body),
      setAccepting: (rid: string, accepting: boolean) => put<T.Restaurant>(`/v1/partner/restaurants/${rid}/accepting`, { accepting }),
      orders: (rid: string, status?: T.OrderStatus[]) => get<T.Order[]>(`/v1/partner/restaurants/${rid}/orders`, { status, limit: 100 }),
      accept: (rid: string, oid: string, prep_minutes: number) => post<T.Order>(`/v1/partner/restaurants/${rid}/orders/${oid}/accept`, { prep_minutes }),
      reject: (rid: string, oid: string, reason: string) => post<T.Order>(`/v1/partner/restaurants/${rid}/orders/${oid}/reject`, { reason }),
      preparing: (rid: string, oid: string) => post<T.Order>(`/v1/partner/restaurants/${rid}/orders/${oid}/preparing`),
      ready: (rid: string, oid: string) => post<T.Order>(`/v1/partner/restaurants/${rid}/orders/${oid}/ready`),
      handover: (rid: string, oid: string, code: string) => post<T.Order>(`/v1/partner/restaurants/${rid}/orders/${oid}/handover`, { code }),
      analytics: (rid: string, days = 14) => get<T.Analytics>(`/v1/partner/restaurants/${rid}/analytics`, { days }),
      settlements: (rid: string) => get<T.Settlement[]>(`/v1/partner/restaurants/${rid}/settlements`),
    },
    admin: {
      overview: () => get<T.Overview>("/v1/admin/overview"),
      analytics: (days = 14) => get<T.Analytics>("/v1/admin/analytics", { days }),
      orders: (status?: T.OrderStatus) => get<T.Order[]>("/v1/admin/orders", { status, limit: 200 }),
      order: (id: string) => get<{ order: T.Order; events: T.OrderEvent[]; payments?: T.PaymentView[]; ledger?: { kind: string; account: string; direction: string; amount_kobo: number }[] }>(`/v1/admin/orders/${id}`),
      transition: (id: string, body: { to: T.OrderStatus; reason: string; refund_amount_kobo?: number; liability?: string }) =>
        post<T.Order>(`/v1/admin/orders/${id}/transition`, body),
      assignRider: (id: string, rider_uid: string, reason: string) => post<T.Order>(`/v1/admin/orders/${id}/assign-rider`, { rider_uid, reason }),
      applications: (status?: string) => get<T.Application[]>("/v1/admin/applications", { status }),
      decideApplication: (id: string, approve: boolean, reason?: string) => post<T.Application>(`/v1/admin/applications/${id}/decision`, { approve, reason }),
      restaurants: () => get<T.Restaurant[]>("/v1/admin/restaurants"),
      setRestaurantStatus: (id: string, status: string, reason: string) => put(`/v1/admin/restaurants/${id}/status`, { status, reason }),
      riders: () => get<T.RiderProfile[]>("/v1/admin/riders"),
      setRiderStatus: (uid: string, status: string, reason: string) => put(`/v1/admin/riders/${uid}/status`, { status, reason }),
      refunds: (status?: string) => get<T.Refund[]>("/v1/admin/refunds", { status }),
      decideRefund: (id: string, approve: boolean, note?: string) => post<T.Refund>(`/v1/admin/refunds/${id}/decision`, { approve, note }),
      payments: (status?: string) => get<T.PaymentView[]>("/v1/admin/payments", { status }),
      ledger: () => get<T.LedgerOverview>("/v1/admin/ledger"),
      settlements: () => get<T.Settlement[]>("/v1/admin/settlements"),
      generateSettlements: (period_start: string, period_end: string) => post<unknown[]>("/v1/admin/settlements/generate", { period_start, period_end }),
      markSettlementPaid: (id: string, bank_reference: string) => post(`/v1/admin/settlements/${id}/paid`, { bank_reference }),
      payouts: (status?: string) => get<{ id: string; rider_id: string; amount_kobo: number; status: string; requested_at: string }[]>("/v1/admin/payouts", { status }),
      decidePayout: (id: string, approve: boolean, bank_reference?: string) => post(`/v1/admin/payouts/${id}/decision`, { approve, bank_reference }),
      pricing: () => get<T.PricingConfig>("/v1/admin/config/pricing"),
      updatePricing: (cfg: T.PricingConfig) => put<T.PricingConfig>("/v1/admin/config/pricing", cfg),
      flags: () => get<Record<string, { key: string; enabled: boolean; description: string }>>("/v1/admin/flags"),
      setFlag: (key: string, enabled: boolean, description: string) => put(`/v1/admin/flags/${key}`, { enabled, description }),
      audit: (q: { resource_type?: string; resource_id?: string; actor_id?: string } = {}) => get<T.AuditEvent[]>("/v1/admin/audit", q),
      tickets: (status?: string) => get<T.SupportTicket[]>("/v1/admin/support/tickets", { status }),
      resolveTicket: (id: string, body: Record<string, unknown>) => patch<T.SupportTicket>(`/v1/admin/support/tickets/${id}`, body),
    },
  };
}

export type GudMealApi = ReturnType<typeof createApi>;

export function createAgentsApi(opts: ClientOptions) {
  const api = createApi(opts);
  return {
    chat: (body: { message: string; thread_id?: string | null; channel?: string; delivery_address?: unknown }) =>
      api.request<T.ChatResponse>("POST", "/v1/chat", { body }),
    approve: (threadId: string, approved: boolean, tool_call_id?: string) =>
      api.request<T.ChatResponse>("POST", `/v1/chat/${threadId}/approval`, { body: { approved, tool_call_id } }),
    threads: () => api.request<{ thread_id: string; title: string | null; updated_at: string }[]>("GET", "/v1/threads"),
    messages: (threadId: string) => api.request<{ role: "user" | "assistant"; text: string }[]>("GET", `/v1/threads/${threadId}/messages`),
    metrics: (days = 7) => api.request<Record<string, unknown>>("GET", "/v1/admin/metrics", { query: { days } }),
    invocations: () => api.request<Record<string, unknown>[]>("GET", "/v1/admin/tool-invocations"),
  };
}
