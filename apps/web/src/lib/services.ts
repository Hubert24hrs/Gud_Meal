import type { MerchantVertical } from "@gudmeal/api-client";
import { Sparkles, UtensilsCrossed, type LucideIcon } from "lucide-react";

/** How the website names a merchant service and its shops. The API calls a service a "vertical". */
export interface ServiceCopy {
  /** The API's id ("beauty" is Supplements & Skin Care). */
  id: MerchantVertical;
  title: string;
  /** The service's page. */
  href: string;
  icon: LucideIcon;
  /** Short name for the search box: "Search in Food". */
  searchIn: string;
  /** "restaurants", "shops". */
  shops: string;
  allShops: string;
  /** "Popular brands", "Popular shops". */
  popular: string;
  /** What the shop sells, for search results: "Dishes", "Products". */
  items: string;
  /** The label of the filter by what a shop carries: "Food type", "Product type". */
  typeFilter: string;
  /** "ready in", "packed in" (before "~12 min"). */
  readyIn: string;
  /** Who reads a note the customer leaves on an item. */
  notesFor: string;
  notesHint: string;
  /** schema.org type of the shop's page. */
  schemaType: string;
}

export const SERVICES: ServiceCopy[] = [
  {
    id: "food", title: "Food", href: "/food", icon: UtensilsCrossed, searchIn: "Food", shops: "restaurants", allShops: "All restaurants",
    popular: "Popular brands", items: "Dishes", typeFilter: "Food type", readyIn: "ready in", notesFor: "the kitchen",
    notesHint: "e.g. less pepper, no onions", schemaType: "Restaurant",
  },
  {
    id: "beauty", title: "Supplements & Skin Care", href: "/beauty", icon: Sparkles, searchIn: "Supplements & Skin Care", shops: "shops",
    allShops: "All shops", popular: "Popular shops", items: "Products", typeFilter: "Product type", readyIn: "packed in",
    notesFor: "the shop", notesHint: "e.g. a far expiry date", schemaType: "Store",
  },
];

/** The copy for a service; unknown services read like Food, so the page still shows something sensible. */
export function serviceCopy(vertical: string | null | undefined): ServiceCopy {
  return SERVICES.find((s) => s.id === vertical) ?? SERVICES[0]!;
}

/** Names of every kind of order, for spending summaries and order lists. */
export const SERVICE_NAMES: Record<string, string> = {
  ...Object.fromEntries(SERVICES.map((s) => [s.id, s.title])),
  parcel: "Package Delivery",
  waybill: "Interstate",
};
