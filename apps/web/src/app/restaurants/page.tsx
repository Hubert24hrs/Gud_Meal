import type { Metadata } from "next";
import { Suspense } from "react";
import { RestaurantBrowser } from "./restaurant-browser";

export const metadata: Metadata = {
  title: "Restaurants in Lagos",
  description: "Browse Lagos restaurants on Yummy Chops — jollof, suya, swallow, small chops, grills and healthy bowls.",
  alternates: { canonical: "/restaurants" },
};

export default function RestaurantsPage() {
  return (
    <div className="container-page py-8">
      <h1 className="font-display text-3xl sm:text-4xl">Restaurants near you</h1>
      <Suspense>
        <RestaurantBrowser />
      </Suspense>
    </div>
  );
}
