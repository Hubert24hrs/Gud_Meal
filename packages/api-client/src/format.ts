import type { OrderStatus } from "./types";

/** 1_000_000 kobo → "₦10,000"; keeps kobo when present ("₦1,500.50"). */
export function formatNaira(kobo: number | null | undefined): string {
  if (kobo === null || kobo === undefined || Number.isNaN(kobo)) return "—";
  const negative = kobo < 0;
  const abs = Math.abs(Math.round(kobo));
  const whole = Math.floor(abs / 100);
  const frac = abs % 100;
  const body = whole.toLocaleString("en-NG");
  return `${negative ? "-" : ""}₦${body}${frac ? `.${String(frac).padStart(2, "0")}` : ""}`;
}

export const nairaToKobo = (naira: number): number => Math.round(naira * 100);

export function formatTime(iso: string | null | undefined): string {
  if (!iso) return "—";
  return new Date(iso).toLocaleTimeString("en-NG", { hour: "numeric", minute: "2-digit", hour12: true, timeZone: "Africa/Lagos" });
}

export function formatDateTime(iso: string | null | undefined): string {
  if (!iso) return "—";
  return new Date(iso).toLocaleString("en-NG", {
    day: "numeric", month: "short", hour: "numeric", minute: "2-digit", hour12: true, timeZone: "Africa/Lagos",
  });
}

/** A calendar day ("2026-11-02") → "2 Nov". Never MM-DD: Nigerian readers take "11-02" as 11 February. */
export function formatDayLabel(isoDate: string): string {
  const [y, m, d] = isoDate.slice(0, 10).split("-").map(Number);
  if (!y || !m || !d) return isoDate;
  return new Date(Date.UTC(y, m - 1, d)).toLocaleDateString("en-NG", { day: "numeric", month: "short", timeZone: "UTC" });
}

export type Tone ="neutral" | "info" | "progress" | "success" | "warning" | "danger";

export const ORDER_STATUS: Record<OrderStatus, { label: string; tone: Tone }> = {
  draft: { label: "Draft", tone: "neutral" },
  pending_payment: { label: "Awaiting payment", tone: "warning" },
  paid: { label: "Paid", tone: "info" },
  submitted_to_restaurant: { label: "New order", tone: "info" },
  restaurant_accepted: { label: "Accepted", tone: "progress" },
  preparing: { label: "Preparing", tone: "progress" },
  ready_for_pickup: { label: "Ready", tone: "progress" },
  rider_assigned: { label: "Rider assigned", tone: "progress" },
  picked_up: { label: "Picked up", tone: "progress" },
  in_transit: { label: "On the way", tone: "progress" },
  delivered: { label: "Delivered", tone: "success" },
  completed: { label: "Completed", tone: "success" },
  cancelled: { label: "Cancelled", tone: "danger" },
  refund_pending: { label: "Refund pending", tone: "warning" },
  partially_refunded: { label: "Partially refunded", tone: "warning" },
  refunded: { label: "Refunded", tone: "neutral" },
  disputed: { label: "Disputed", tone: "danger" },
};

export const TRACKING_STEPS = ["Order placed", "Accepted", "Preparing", "On the way", "Delivered"] as const;
