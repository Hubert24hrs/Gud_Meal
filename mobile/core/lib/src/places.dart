// Maps and location models (plain Dart: no code generation). Every distance and time here comes from the API;
// `source` says whether Google measured it ('google') or it is GudMeals' own estimate ('estimate' / 'local').

import 'dart:math' as math;

import 'models.dart';

/// True when Google measured the value; otherwise screens say "estimate".
bool isMeasured(String? source) => source == 'google';

GeoPoint? _point(Object? j) {
  if (j is! Map) return null;
  final lat = j['lat'], lng = j['lng'];
  if (lat is! num || lng is! num) return null;
  return GeoPoint(lat: lat.toDouble(), lng: lng.toDouble());
}

DateTime? _time(Object? j) => j is String ? DateTime.tryParse(j) : null;

/// One address suggestion while typing.
class PlaceSuggestion {
  const PlaceSuggestion({required this.placeId, required this.title, this.subtitle = '', this.distanceM, this.source = 'local'});

  final String placeId;
  final String title;
  final String subtitle;
  final int? distanceM;
  final String source;

  factory PlaceSuggestion.fromJson(Map<String, dynamic> j) => PlaceSuggestion(
        placeId: j['place_id'] as String,
        title: j['title'] as String,
        subtitle: (j['subtitle'] as String?) ?? '',
        distanceM: (j['distance_m'] as num?)?.toInt(),
        source: (j['source'] as String?) ?? 'local',
      );
}

/// A resolved place: address text, pin and how precise the pin is.
class PlaceResult {
  const PlaceResult({
    this.placeId,
    required this.formattedAddress,
    required this.location,
    this.area,
    this.city,
    this.precision = 'approximate',
    this.source = 'local',
  });

  final String? placeId;
  final String formattedAddress;
  final GeoPoint location;
  final String? area;
  final String? city;

  /// 'rooftop' | 'street' | 'area' | 'approximate'
  final String precision;
  final String source;

  /// Street-level or better: good enough to deliver to without asking for a landmark.
  bool get isPrecise => precision == 'rooftop' || precision == 'street';

  factory PlaceResult.fromJson(Map<String, dynamic> j) => PlaceResult(
        placeId: j['place_id'] as String?,
        formattedAddress: j['formatted_address'] as String,
        location: _point(j['location'])!,
        area: j['area'] as String?,
        city: j['city'] as String?,
        precision: (j['precision'] as String?) ?? 'approximate',
        source: (j['source'] as String?) ?? 'local',
      );
}

/// A place plus whether GudMeals delivers there.
class PlaceLookup {
  const PlaceLookup({required this.place, required this.serviceable, this.zone, this.city});

  final PlaceResult place;
  final bool serviceable;
  final String? zone;
  final String? city;

  factory PlaceLookup.fromJson(Map<String, dynamic> j) => PlaceLookup(
        place: PlaceResult.fromJson(Map<String, dynamic>.from(j['place'] as Map)),
        serviceable: j['serviceable'] == true,
        zone: j['zone'] as String?,
        city: j['city'] as String?,
      );

  /// The address to save or quote with. The pin is the one the user confirmed.
  DeliveryAddress toAddress({String? label, String? line1, String? instructions, String? contactPhone, GeoPoint? pin}) {
    final cityName = _cityName(city ?? place.city);
    return DeliveryAddress(
      label: label,
      line1: (line1 != null && line1.trim().length >= 3) ? line1.trim() : place.formattedAddress,
      area: place.area,
      city: cityName,
      state: cityName,
      location: pin ?? place.location,
      instructions: instructions,
      contactPhone: contactPhone,
    );
  }
}

String _cityName(String? id) => switch (id) {
      'enugu' => 'Enugu',
      _ => 'Lagos',
    };

/// Road distance, arrival time and delivery fee from one kitchen to one address.
class DeliveryEstimate {
  const DeliveryEstimate({
    required this.restaurantId,
    required this.name,
    required this.area,
    required this.roadDistanceKm,
    required this.travelMinutes,
    required this.etaMinutes,
    this.deliveryFeeKobo,
    required this.delivers,
    required this.isOpen,
    required this.source,
  });

  final String restaurantId;
  final String name;
  final String area;
  final double roadDistanceKm;
  final int travelMinutes;
  final int etaMinutes;
  final int? deliveryFeeKobo;
  final bool delivers;
  final bool isOpen;
  final String source;

  factory DeliveryEstimate.fromJson(Map<String, dynamic> j) => DeliveryEstimate(
        restaurantId: j['restaurant_id'] as String,
        name: j['name'] as String,
        area: (j['area'] as String?) ?? '',
        roadDistanceKm: (j['road_distance_km'] as num).toDouble(),
        travelMinutes: (j['travel_minutes'] as num).toInt(),
        etaMinutes: (j['eta_minutes'] as num).toInt(),
        deliveryFeeKobo: (j['delivery_fee_kobo'] as num?)?.toInt(),
        delivers: j['delivers'] == true,
        isOpen: j['is_open'] == true,
        source: (j['source'] as String?) ?? 'estimate',
      );
}

/// What the customer's live delivery map shows. The rider's position and route only exist while a rider is on
/// this delivery (the API enforces it).
class LiveTracking {
  const LiveTracking({
    required this.orderId,
    required this.status,
    this.riderName,
    this.riderLocation,
    this.etaMinutes,
    this.etaSource,
    this.routePolyline,
    this.updatedAt,
    this.estimatedDeliveryAt,
    this.pickupLocation,
    this.dropoffLocation,
  });

  final String orderId;
  final String status;
  final String? riderName;
  final GeoPoint? riderLocation;
  final int? etaMinutes;
  final String? etaSource;
  final String? routePolyline;
  final DateTime? updatedAt;
  final DateTime? estimatedDeliveryAt;
  final GeoPoint? pickupLocation;
  final GeoPoint? dropoffLocation;

  bool get isLive => riderLocation != null;

  /// The rider is still heading to the kitchen.
  bool get toPickup => status == 'rider_assigned';

  List<GeoPoint> get route => routePolyline == null || routePolyline!.isEmpty ? const [] : decodePolyline(routePolyline!);

  factory LiveTracking.fromJson(Map<String, dynamic> j) => LiveTracking(
        orderId: j['order_id'] as String,
        status: j['status'] as String,
        riderName: j['rider_name'] as String?,
        riderLocation: _point(j['rider_location']),
        etaMinutes: (j['eta_minutes'] as num?)?.toInt(),
        etaSource: j['eta_source'] as String?,
        routePolyline: j['route_polyline'] as String?,
        updatedAt: _time(j['updated_at']),
        estimatedDeliveryAt: _time(j['estimated_delivery_at']),
        pickupLocation: _point(j['pickup_location']),
        dropoffLocation: _point(j['dropoff_location']),
      );
}

/// A restaurant or shop on the nearby map. Distance and arrival time are GudMeals' free local estimate.
class MapPlace {
  const MapPlace({
    required this.id,
    required this.name,
    required this.location,
    this.area = '',
    this.vertical = 'food',
    this.rating = 0,
    this.isOpen = false,
    this.etaMinutes,
    this.distanceKm,
    this.deliveryFeeKobo,
    this.deliversHere,
    this.cuisines = const [],
  });

  final String id;
  final String name;
  final GeoPoint location;
  final String area;
  final String vertical;
  final double rating;
  final bool isOpen;
  final int? etaMinutes;
  final double? distanceKm;
  final int? deliveryFeeKobo;
  final bool? deliversHere;
  final List<String> cuisines;

  static MapPlace? fromCard(Map<String, dynamic> j) {
    final at = _point(j['location']);
    if (at == null) return null;
    return MapPlace(
      id: j['id'] as String,
      name: j['name'] as String,
      location: at,
      area: (j['area'] as String?) ?? '',
      vertical: (j['vertical'] as String?) ?? 'food',
      rating: (j['rating'] as num?)?.toDouble() ?? 0,
      isOpen: j['is_open'] == true,
      etaMinutes: (j['eta_minutes'] as num?)?.toInt(),
      distanceKm: (j['distance_km'] as num?)?.toDouble(),
      deliveryFeeKobo: (j['delivery_fee_kobo'] as num?)?.toInt(),
      deliversHere: j['delivers_to_location'] as bool?,
      cuisines: [for (final c in (j['cuisines'] as List? ?? const [])) '$c'],
    );
  }
}

/// Decodes a Google encoded polyline (precision 5).
List<GeoPoint> decodePolyline(String encoded) {
  final points = <GeoPoint>[];
  var index = 0, lat = 0, lng = 0;
  int next() {
    var result = 0, shift = 0, b = 0;
    do {
      if (index >= encoded.length) throw const FormatException('Truncated polyline');
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    return (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
  }

  while (index < encoded.length) {
    lat += next();
    lng += next();
    points.add(GeoPoint(lat: lat / 1e5, lng: lng / 1e5));
  }
  return points;
}

/// Straight-line distance in km (display only; prices and arrival times come from the API).
double haversineKm(GeoPoint a, GeoPoint b) {
  const r = 6371.0;
  double rad(double d) => d * math.pi / 180;
  final dLat = rad(b.lat - a.lat), dLng = rad(b.lng - a.lng);
  final h = math.pow(math.sin(dLat / 2), 2) + math.cos(rad(a.lat)) * math.cos(rad(b.lat)) * math.pow(math.sin(dLng / 2), 2);
  return 2 * r * math.asin(math.sqrt(h));
}

/// Turn-by-turn directions in the Google Maps app (or website). No API key is involved.
Uri navigationUri(GeoPoint destination, {String travelMode = 'driving'}) => Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '${destination.lat.toStringAsFixed(6)},${destination.lng.toStringAsFixed(6)}',
      'travelmode': travelMode,
      'dir_action': 'navigate',
    });

/// A new Places session token: one address search (typing + one pick) is billed as one session.
String newPlacesSession() {
  final r = math.Random.secure();
  return List.generate(16, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
}
