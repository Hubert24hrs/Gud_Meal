import 'package:flutter/material.dart';

/// How the apps name a merchant service and its shops. The API calls a service a "vertical".
class ServiceCopy {
  const ServiceCopy({
    required this.id,
    required this.title,
    required this.route,
    required this.icon,
    required this.shops,
    required this.allShops,
    required this.popular,
    required this.items,
    required this.typeFilter,
    required this.readyIn,
    required this.steps,
  });

  /// The API's id: food, or beauty (Supplements & Skin Care).
  final String id;
  final String title;

  /// The service's page in the customer app.
  final String route;
  final IconData icon;

  /// "restaurants", "shops".
  final String shops;

  /// "All restaurants", "All shops".
  final String allShops;

  /// "Popular brands", "Popular shops".
  final String popular;

  /// What the shop sells, for search results: "Dishes", "Products".
  final String items;

  /// The label of the filter by what a shop carries: "Food type", "Product type".
  final String typeFilter;

  /// "ready in", "packed in" (before "~12 min").
  final String readyIn;

  /// The five steps of an order's timeline.
  final List<String> steps;
}

const foodService = ServiceCopy(
  id: 'food',
  title: 'Food',
  route: '/food',
  icon: Icons.restaurant_rounded,
  shops: 'restaurants',
  allShops: 'All restaurants',
  popular: 'Popular brands',
  items: 'Dishes',
  typeFilter: 'Food type',
  readyIn: 'ready in',
  steps: ['Placed', 'Accepted', 'Preparing', 'On the way', 'Delivered'],
);

/// Vitamins, supplements and skin care from partner shops. The API still calls it `beauty`.
const beautyService = ServiceCopy(
  id: 'beauty',
  title: 'Supplements & Skin Care',
  route: '/beauty',
  icon: Icons.spa_rounded,
  shops: 'shops',
  allShops: 'All shops',
  popular: 'Popular shops',
  items: 'Products',
  typeFilter: 'Product type',
  readyIn: 'packed in',
  steps: ['Placed', 'Accepted', 'Packing', 'On the way', 'Delivered'],
);

/// The merchant services in the order the home screen shows them (Package Delivery is a courier job, not a shop).
const merchantServices = [foodService, beautyService];

/// The copy for [vertical]; unknown services read like Food, so an older app still shows something sensible.
ServiceCopy serviceCopy(String vertical) =>
    merchantServices.firstWhere((s) => s.id == vertical, orElse: () => foodService);

/// Names of every kind of order, for spending summaries and order lists.
const serviceNames = {
  'food': 'Food',
  'beauty': 'Supplements & Skin Care',
  'parcel': 'Package Delivery',
  'waybill': 'Interstate',
};
