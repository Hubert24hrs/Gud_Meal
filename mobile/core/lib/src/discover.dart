/// Discover tab feed: hero dishes for the dish carousel (GET /v1/discover/dishes).
///
/// Plain immutable classes (no code generation): the feed is read-only and small.
library;

/// One hero dish. Prices and delivery fees come from the API exactly as the menu and pricing engine set them.
class DiscoverDish {
  const DiscoverDish({
    required this.itemId,
    required this.restaurantId,
    required this.restaurantName,
    required this.name,
    required this.priceKobo,
    this.area = '',
    this.city = 'lagos',
    this.description = '',
    this.imageUrl,
    this.art = 'plate',
    this.kind = 'main',
    this.tags = const [],
    this.dietary = const [],
    this.allergens = const [],
    this.spiceLevel = 0,
    this.serves = 1,
    this.prepMinutes,
    this.likes = 0,
    this.rating = 0,
    this.ratingCount = 0,
    this.eyebrow = '',
    this.hasOptions = false,
    this.isAvailable = true,
    this.isOpen = true,
    this.isAcceptingOrders = true,
    this.isNewKitchen = false,
    this.distanceKm,
    this.etaMinutes,
    this.deliveryFeeKobo,
    this.deliversToLocation,
  });

  final String itemId;
  final String restaurantId;
  final String restaurantName;
  final String area;
  final String city;
  final String name;
  final String description;
  final int priceKobo;
  final String? imageUrl;

  /// Illustrated-plate family from the API: rice, soup_swallow, broth, skewers, grill, pizza, wrap, bites, bowl, plate.
  final String art;
  final String kind;
  final List<String> tags;
  final List<String> dietary;
  final List<String> allergens;
  final int spiceLevel;
  final int serves;
  final int? prepMinutes;

  /// How many times the dish has been ordered.
  final int likes;

  /// The kitchen's rating out of 5.
  final double rating;
  final int ratingCount;

  /// Short line above the title, e.g. "#1 Most loved dish" or "New kitchen · Lekki".
  final String eyebrow;
  final bool hasOptions;
  final bool isAvailable;
  final bool isOpen;
  final bool isAcceptingOrders;
  final bool isNewKitchen;
  final double? distanceKm;
  final int? etaMinutes;
  final int? deliveryFeeKobo;
  final bool? deliversToLocation;

  /// Whether the customer can order it right now.
  bool get canOrderNow => isAvailable && isOpen && isAcceptingOrders;

  /// What's in it, for the "Ingredients" tab: tags, dietary notes and allergens, de-duplicated.
  List<String> get highlights {
    final seen = <String>{};
    return [
      for (final t in [...tags, ...dietary, ...allergens.map((a) => 'contains $a')])
        if (t.trim().isNotEmpty && seen.add(t.trim().toLowerCase())) t.trim(),
    ];
  }

  factory DiscoverDish.fromJson(Map<String, dynamic> j) => DiscoverDish(
        itemId: j['item_id'] as String,
        restaurantId: j['restaurant_id'] as String,
        restaurantName: j['restaurant_name'] as String? ?? '',
        area: j['area'] as String? ?? '',
        city: j['city'] as String? ?? 'lagos',
        name: j['name'] as String,
        description: j['description'] as String? ?? '',
        priceKobo: (j['price_kobo'] as num).toInt(),
        imageUrl: j['image_url'] as String?,
        art: j['art'] as String? ?? 'plate',
        kind: j['kind'] as String? ?? 'main',
        tags: _strings(j['tags']),
        dietary: _strings(j['dietary']),
        allergens: _strings(j['allergens']),
        spiceLevel: (j['spice_level'] as num?)?.toInt() ?? 0,
        serves: (j['serves'] as num?)?.toInt() ?? 1,
        prepMinutes: (j['prep_minutes'] as num?)?.toInt(),
        likes: (j['likes'] as num?)?.toInt() ?? 0,
        rating: (j['rating'] as num?)?.toDouble() ?? 0,
        ratingCount: (j['rating_count'] as num?)?.toInt() ?? 0,
        eyebrow: j['eyebrow'] as String? ?? '',
        hasOptions: j['has_options'] as bool? ?? false,
        isAvailable: j['is_available'] as bool? ?? true,
        isOpen: j['is_open'] as bool? ?? true,
        isAcceptingOrders: j['is_accepting_orders'] as bool? ?? true,
        isNewKitchen: j['is_new_kitchen'] as bool? ?? false,
        distanceKm: (j['distance_km'] as num?)?.toDouble(),
        etaMinutes: (j['eta_minutes'] as num?)?.toInt(),
        deliveryFeeKobo: (j['delivery_fee_kobo'] as num?)?.toInt(),
        deliversToLocation: j['delivers_to_location'] as bool?,
      );

  @override
  bool operator ==(Object other) => other is DiscoverDish && other.itemId == itemId && other.restaurantId == restaurantId;

  @override
  int get hashCode => Object.hash(itemId, restaurantId);
}

/// A titled group of hero dishes: `most_loved`, `new_kitchens` or `top_rated`.
class DiscoverSection {
  const DiscoverSection({required this.id, required this.title, this.subtitle = '', this.dishes = const []});

  final String id;
  final String title;
  final String subtitle;
  final List<DiscoverDish> dishes;

  /// Short label for the section switcher chips.
  String get shortTitle => switch (id) {
        'most_loved' => 'Most loved',
        'new_kitchens' => 'New kitchens',
        'top_rated' => 'Top rated',
        _ => title,
      };

  factory DiscoverSection.fromJson(Map<String, dynamic> j) => DiscoverSection(
        id: j['id'] as String,
        title: j['title'] as String? ?? '',
        subtitle: j['subtitle'] as String? ?? '',
        dishes: [for (final d in (j['dishes'] as List? ?? const [])) DiscoverDish.fromJson(Map<String, dynamic>.from(d as Map))],
      );
}

class DiscoverFeed {
  const DiscoverFeed({this.city, this.sections = const []});

  final String? city;
  final List<DiscoverSection> sections;

  /// Sections that have something to show.
  List<DiscoverSection> get nonEmpty => [for (final s in sections) if (s.dishes.isNotEmpty) s];

  factory DiscoverFeed.fromJson(Map<String, dynamic> j) => DiscoverFeed(
        city: j['city'] as String?,
        sections: [for (final s in (j['sections'] as List? ?? const [])) DiscoverSection.fromJson(Map<String, dynamic>.from(s as Map))],
      );
}

List<String> _strings(Object? v) => v is List ? [for (final e in v) '$e'] : const [];
