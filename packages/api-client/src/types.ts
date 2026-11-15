// Response and request shapes of gudmeal-api (see openapi.json). All money values are integer kobo.

export type Kobo = number;

export type OrderStatus =
  | "draft" | "pending_payment" | "paid" | "submitted_to_restaurant" | "restaurant_accepted" | "preparing"
  | "ready_for_pickup" | "rider_assigned" | "picked_up" | "in_transit" | "delivered" | "completed"
  | "cancelled" | "refund_pending" | "partially_refunded" | "refunded" | "disputed";

export type Fulfillment = "delivery" | "pickup";
export type ItemKind = "main" | "combo" | "side" | "snack" | "drink" | "dessert" | "extra" | "product";
/** Gud Meal services: food and beauty are sold by merchants; parcels are courier jobs. */
export type Vertical = "food" | "beauty" | "parcel";

export interface GeoPoint { lat: number; lng: number }

export interface OpeningHours {
  timezone: string;
  weekly: Record<string, { open: string; close: string }[]>;
  closed_dates: string[];
}

export interface PromoBadge { code: string; label: string }

export interface RestaurantCard {
  id: string; vertical: Exclude<Vertical, "parcel">; city: string; promotions: PromoBadge[]; name: string; slug: string; description: string; cuisines: string[]; tags: string[];
  image_url: string | null; cover_url: string | null; area: string; rating: number; rating_count: number;
  price_level: number; is_open: boolean; is_accepting_orders: boolean; is_featured: boolean;
  next_opening_at: string | null; distance_km: number | null; eta_minutes: number | null;
  delivery_fee_kobo: Kobo | null; min_order_kobo: Kobo; supports_delivery: boolean; supports_pickup: boolean;
  delivers_to_location: boolean | null;
}

export interface OptionChoice { id: string; name: string; price_delta_kobo: Kobo; is_available: boolean }
export interface OptionGroup {
  id: string; restaurant_id: string; name: string; min_select: number; max_select: number; choices: OptionChoice[];
}
export interface MenuCategory { id: string; name: string; position: number }
export interface MenuItem {
  id: string; restaurant_id: string; category_id: string; name: string; description: string; price_kobo: Kobo;
  image_url: string | null; kind: ItemKind; tags: string[]; dietary: string[]; allergens: string[]; serves: number;
  spice_level: number; is_available: boolean; is_active: boolean; popularity: number; option_group_ids: string[];
  prep_minutes: number | null; position: number; unit_label?: string | null;
}
export interface MenuSection { category: MenuCategory; items: MenuItem[] }
export interface RestaurantDetail {
  restaurant: RestaurantCard; address: string; location: GeoPoint; opening_hours: OpeningHours;
  avg_prep_minutes: number; sections: MenuSection[]; option_groups: Record<string, OptionGroup>;
}

export interface Restaurant {
  id: string; name: string; slug: string; description: string; cuisines: string[]; area: string; address: string;
  location: GeoPoint; rating: number; rating_count: number; avg_prep_minutes: number; opening_hours: OpeningHours;
  is_accepting_orders: boolean; status: "pending" | "active" | "suspended"; min_order_kobo: Kobo;
  supports_delivery: boolean; supports_pickup: boolean; image_url: string | null; cover_url: string | null;
  owner_uid: string | null; commission_bps: number | null; phone: string | null;
}

export interface DeliveryAddress {
  label?: string | null; line1: string; area?: string | null; city?: string; state?: string; location: GeoPoint;
  instructions?: string | null; contact_phone?: string | null;
}
export interface SavedAddress extends DeliveryAddress { id: string }

export interface OptionSelection { group_id: string; choice_ids: string[] }
export interface CartLine { item_id: string; quantity: number; selections: OptionSelection[]; notes?: string | null }

export interface QuoteRequest {
  restaurant_id: string; lines: CartLine[]; fulfillment: Fulfillment; delivery_address?: DeliveryAddress | null;
  scheduled_for?: string | null; voucher_code?: string | null;
}

export interface PricedLine {
  item_id: string; name: string; kind: ItemKind; quantity: number; unit_price_kobo: Kobo;
  options_unit_price_kobo: Kobo; line_total_kobo: Kobo; selections: OptionSelection[]; selection_labels: string[];
  notes: string | null;
}
export interface PriceBreakdown {
  subtotal_kobo: Kobo; delivery_fee_kobo: Kobo; service_fee_kobo: Kobo; small_order_fee_kobo: Kobo; vat_kobo: Kobo;
  discount_kobo: Kobo; total_kobo: Kobo; discount_funded_by: "platform" | "restaurant" | null; voucher_code: string | null;
  /** Cash-on-delivery collection fee (packages). */
  cod_fee_kobo?: Kobo;
}
export interface Quote {
  id: string; restaurant_id: string; restaurant_name: string; lines: PricedLine[]; breakdown: PriceBreakdown;
  fulfillment: Fulfillment; delivery_address: DeliveryAddress | null; distance_km: number | null; eta_minutes: number;
  estimated_delivery_at: string; scheduled_for: string | null; created_at: string; expires_at: string;
}

export interface Order {
  id: string; short_code: string; vertical?: Vertical; parcel?: ParcelDetails | null; customer_id: string; customer_name: string | null; restaurant_id: string;
  restaurant_name: string; restaurant_address: string; restaurant_location: GeoPoint; status: OrderStatus;
  fulfillment: Fulfillment; lines: PricedLine[]; breakdown: PriceBreakdown; delivery_address: DeliveryAddress | null;
  distance_km: number | null; scheduled_for: string | null;
  payment: { provider: string | null; reference: string | null; status: string; paid_at: string | null };
  rider_id: string | null; rider_name: string | null; prep_minutes: number | null; estimated_delivery_at: string | null;
  accepted_at: string | null; ready_at: string | null; picked_up_at: string | null; delivered_at: string | null;
  completed_at: string | null; cancelled_at: string | null; cancellation_reason: string | null;
  refund_total_kobo: Kobo; reviewed: boolean; channel: string; created_at: string; updated_at: string;
  /** Set when the rider took cash at the door (pay on delivery and/or a package's COD amount). */
  cash_collected_at?: string | null;
  progress: { step: number; total_steps: number; label: string };
  audience: "customer" | "restaurant" | "rider" | "staff";
  // restaurant view
  restaurant_earning_kobo?: Kobo; commission_kobo?: Kobo;
  // rider view: what to collect at the door
  payment_method?: "cash" | "prepaid"; collect_cash_kobo?: Kobo;
  // staff view
  settlement?: { commission_bps: number; commission_kobo: Kobo; rider_pay_kobo: Kobo; restaurant_earning_kobo: Kobo };
}

export interface OrderEvent {
  id: string; order_id: string; from_status: OrderStatus | null; to_status: OrderStatus; actor_type: string;
  actor_id: string; reason: string | null; at: string; metadata: Record<string, unknown>;
}

export interface Tracking {
  order_id: string; status: OrderStatus; rider_name: string | null; rider_location: GeoPoint | null;
  eta_minutes: number | null; updated_at: string | null; estimated_delivery_at: string | null;
}

export interface CheckoutResult {
  order_id: string; status: string; provider: string; reference: string;
  /** Null for wallet and pay-on-delivery checkouts (nothing to open). */
  authorization_url: string | null;
  amount_kobo: Kobo; payment_status?: string;
  /** Set when the default gateway was down and the backup gateway took the payment. */
  failover_from?: string;
}
export interface PaymentView {
  id: string; order_id: string | null; purpose?: "order" | "wallet_topup"; provider: string; reference: string;
  amount_kobo: Kobo; status: string; paid_at: string | null; refunded_kobo: Kobo; created_at: string;
  failure_reason: string | null; channel: string | null;
}

export type PaymentMethodId = "card" | "wallet" | "cash";
export interface PaymentMethodOption {
  id: PaymentMethodId; label: string; available: boolean; reason: string | null;
  provider?: string; balance_kobo?: Kobo; short_by_kobo?: Kobo;
}
export interface PaymentOptions { order_id: string; total_kobo: Kobo; methods: PaymentMethodOption[] }

export interface WalletTransaction {
  id: string; kind: string; reference: string | null; order_id: string | null; description: string;
  created_at: string; direction: "in" | "out"; amount_kobo: Kobo;
}
export interface SellerSummary {
  cod_balance_kobo: Kobo; pending_payouts_kobo: Kobo; available_kobo: Kobo; min_payout_kobo: Kobo;
}
export interface WalletOverview {
  balance_kobo: Kobo; currency: "NGN"; enabled: boolean;
  limits: { min_topup_kobo: Kobo; max_topup_kobo: Kobo; max_balance_kobo: Kobo };
  refund_to_wallet: boolean; transactions: WalletTransaction[]; seller: SellerSummary | null;
}
export interface TopUpResult {
  provider: string; reference: string; authorization_url: string | null; amount_kobo: Kobo; failover_from?: string;
}
export interface SellerPayout {
  id: string; vendor_id: string; amount_kobo: Kobo; bank_name: string; account_number: string; account_name: string;
  status: "requested" | "paid" | "rejected"; reference: string | null; decision_note: string | null;
  requested_at: string; decided_at: string | null; paid_at: string | null;
}
export interface SellerOverview extends SellerSummary { transactions: WalletTransaction[]; payouts: SellerPayout[] }
export interface CashOverview {
  riders: { rider_id: string; name: string; phone: string | null; cash_held_kobo: Kobo; earnings_kobo: Kobo; over_limit: boolean }[];
  rider_cash_limit_kobo: Kobo;
  totals: { cash_with_riders_kobo: Kobo; wallet_balances_kobo: Kobo; seller_balances_kobo: Kobo };
}

export interface Me {
  uid: string; email: string | null; phone: string | null; name: string | null; roles: string[];
  restaurant_roles: Record<string, "owner" | "manager" | "staff">; permissions: string[];
}
export interface CustomerProfile {
  uid: string; display_name: string | null; dietary: string[]; allergens: string[]; favourite_cuisines: string[];
  favourite_restaurant_ids: string[]; personalisation_consent: boolean; marketing_consent: boolean; loyalty_points: number;
  refund_to_wallet?: boolean; pay_on_delivery_blocked?: boolean;
}

export interface MealPlan {
  restaurant_id: string; restaurant_name: string; restaurant_rating: number;
  items: { item_id: string; name: string; kind: ItemKind; quantity: number; unit_total_kobo: Kobo; selection_labels: string[] }[];
  cart_lines: CartLine[]; breakdown: PriceBreakdown; distance_km: number; eta_minutes: number;
  estimated_delivery_at: string; meets_deadline: boolean; budget_remaining_kobo: Kobo; score: number; rationale: string[];
}
export interface MealPlanResult {
  plans: MealPlan[]; restaurants_considered: number; restaurants_eligible: number; cheapest_total_kobo: Kobo | null;
  notes: string[];
}

export interface Analytics {
  period_days: number; orders_total: number; orders_completed: number; gross_sales_kobo: Kobo; commission_kobo: Kobo;
  net_earnings_kobo: Kobo; average_order_kobo: Kobo; acceptance_rate: number | null; avg_prep_minutes: number | null;
  top_items: { name: string; quantity: number }[]; series: { date: string; orders: number; gross_kobo: Kobo }[];
  forecast_next_7_days_orders: number; top_restaurants?: { name: string; gross_kobo: Kobo }[];
}

export interface Overview {
  as_of: string; orders_today: number; orders_by_status: Record<string, number>; gmv_today_kobo: Kobo;
  platform_revenue_today_kobo: Kobo; active_orders: number;
  stuck_orders: { id: string; short_code: string; status: OrderStatus; minutes_since_update: number }[];
  riders_online: number; riders_busy: number; pending_applications: number; open_tickets: number;
  pending_refunds: number; flagged_payments: number;
}

export interface Application {
  id: string; type: "restaurant" | "rider"; applicant_uid: string; status: "submitted" | "in_review" | "approved" | "rejected";
  data: Record<string, unknown>; document_paths: string[]; submitted_at: string; decided_at: string | null;
  decision_reason: string | null; created_entity_id: string | null;
}

export interface Refund {
  id: string; order_id: string; payment_id: string; amount_kobo: Kobo; reason: string; liability: string; stage: string;
  status: string; requested_by: string; decided_by: string | null; decision_note: string | null; created_at: string;
  /** "wallet" = refunded instantly into the customer's Gud Meal wallet. */
  destination?: "original" | "wallet";
}

export interface SupportTicket {
  id: string; opened_by: string; order_id: string | null; category: string; description: string;
  missing_item_ids: string[]; status: string; priority: "low" | "normal" | "high" | "urgent"; channel: string;
  resolution: string | null; created_at: string; updated_at: string;
}

export interface RiderProfile {
  uid: string; name: string; phone: string | null; vehicle: "bicycle" | "motorcycle" | "car"; status: string;
  is_online: boolean; rating: number; acceptance_rate: number; active_order_ids: string[]; completed_deliveries: number;
  last_location: GeoPoint | null; last_location_at: string | null;
}

export interface AuditEvent {
  id: string; occurred_at: string; actor_id: string; actor_roles: string[]; action: string; resource_type: string;
  resource_id: string; details: Record<string, unknown>;
}

export interface LedgerOverview {
  trial_balance: { debits_kobo: Kobo; credits_kobo: Kobo };
  accounts: { account: string; type: string; balance_kobo: Kobo }[];
}

export interface Settlement {
  id: string; restaurant_id: string; period_start: string; period_end: string; orders_count: number; gross_kobo: Kobo;
  commission_kobo: Kobo; adjustments_kobo: Kobo; net_kobo: Kobo; status: string; payout_reference: string | null;
}

export interface PricingConfig {
  version: number; service_fee_bps: number; service_fee_min_kobo: Kobo; service_fee_max_kobo: Kobo;
  small_order_threshold_kobo: Kobo; small_order_fee_kobo: Kobo; vat_bps: number; default_commission_bps: number;
  delivery: { base_kobo: Kobo; per_km_kobo: Kobo; min_kobo: Kobo; max_kobo: Kobo; road_factor: string };
  rider_pay: { base_kobo: Kobo; per_km_kobo: Kobo; min_kobo: Kobo };
  avg_speed_kmh: string; dispatch_buffer_minutes: number;
  zones: { id: string; name: string; center: GeoPoint; radius_km: number; is_active: boolean; surge_bps: number }[];
}

export interface ChatCard { type: string; [key: string]: unknown }
export interface ChatApproval {
  type: "approval_required"; tool: string; tool_call_id: string;
  preview: { title: string; message?: string; order?: Record<string, unknown>; [key: string]: unknown };
}
export interface ChatResponse {
  thread_id: string; status: "completed" | "approval_required" | "blocked"; reply: string | null; agent: string | null;
  cards: ChatCard[]; approval: ChatApproval | null; warnings: string[];
}

// ------------------------------------------------------------------------------------- multi-service
export interface ServiceInfo {
  id: Vertical; name: string; tagline: string; available: boolean; merchants?: number;
  options?: string[]; coming_soon?: string[]; cities?: string[];
}
export interface BrowseCategory { id: string; name: string; emoji: string; merchants: number }
export interface PlaceArea { name: string; city: string; lat: number; lng: number }

export type ParcelSize = "small" | "medium" | "large";
export type ParcelCategory = "documents" | "clothing" | "electronics" | "food" | "cosmetics" | "household" | "other";
export interface ParcelStop {
  name: string; phone: string; line1: string; area?: string | null; city: string; location: GeoPoint; instructions?: string | null;
}
export interface ParcelDetails {
  pickup: ParcelStop; dropoff: ParcelStop; size: ParcelSize; category: ParcelCategory; description: string; city: string;
  /** Cash the rider collects from the recipient for the sender (vendor cash-on-delivery). */
  cod_amount_kobo?: Kobo | null;
}
export interface ParcelQuoteRequest {
  pickup: ParcelStop; dropoff: ParcelStop; size: ParcelSize; category: ParcelCategory; description?: string;
  scheduled_for?: string | null; cod_amount_kobo?: Kobo | null;
}
export interface ParcelQuote {
  id: string; details: ParcelDetails; breakdown: PriceBreakdown; distance_km: number; eta_minutes: number;
  estimated_delivery_at: string; scheduled_for: string | null; expires_at: string; order_id: string | null;
}
export interface OrderSummary {
  orders_count: number; completed_count: number; in_progress_count: number; total_spent_kobo: Kobo;
  this_month_spent_kobo: Kobo; refunded_kobo: Kobo; by_vertical: Record<Vertical, { orders: number; spent_kobo: Kobo }>;
  favourite_merchant: { id: string; name: string; orders: number } | null;
  first_order_at: string | null; last_order_at: string | null;
}
export interface SupportContacts { whatsapp: string; phone: string; email: string; hours: string; placeholders: boolean }
