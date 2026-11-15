import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gud_meal_core/gud_meal_core.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter(this.body);
  final Object body;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);
    return ResponseBody.fromString(jsonEncode(body), 200, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

GudMealApi _api(_Adapter adapter) =>
    GudMealApi(baseUrl: 'http://api.test', token: () async => 't', dio: Dio(BaseOptions(baseUrl: 'http://api.test'))..httpClientAdapter = adapter);

void main() {
  test('decodes Google encoded polylines', () {
    // Google's documented example.
    final pts = decodePolyline('_p~iF~ps|U_ulLnnqC_mqNvxq`@');
    expect(pts.map((p) => [p.lat, p.lng]), [
      [38.5, -120.2],
      [40.7, -120.95],
      [43.252, -126.453],
    ]);
    expect(decodePolyline(''), isEmpty);
    expect(() => decodePolyline('_p~iF~ps|U_'), throwsFormatException);
  });

  test('navigation links open Google Maps directions without a key', () {
    final uri = navigationUri(const GeoPoint(lat: 6.4478, lng: 3.4723));
    expect(uri.host, 'www.google.com');
    expect(uri.queryParameters, {'api': '1', 'destination': '6.447800,3.472300', 'travelmode': 'driving', 'dir_action': 'navigate'});
    expect(uri.toString(), isNot(contains('key=')));
  });

  test('address search: session token, bias and parsing', () async {
    final adapter = _Adapter({
      'provider': 'google',
      'suggestions': [
        {'place_id': 'ChIJ1', 'title': '5 Admiralty Way', 'subtitle': 'Lekki Phase 1, Lagos', 'distance_m': 420, 'source': 'google'},
      ],
    });
    final session = newPlacesSession();
    expect(session, matches(RegExp(r'^[0-9a-f]{32}$')));
    final s = await _api(adapter).placeSuggestions('Admiralty', session: session, near: const GeoPoint(lat: 6.44, lng: 3.47));
    expect(s.single.title, '5 Admiralty Way');
    expect(s.single.distanceM, 420);
    final q = adapter.requests.single;
    expect(q.path, '/v1/places/autocomplete');
    expect(q.queryParameters, {'q': 'Admiralty', 'session': session, 'lat': 6.44, 'lng': 3.47});
  });

  test('place lookups become delivery addresses with the confirmed pin', () async {
    final adapter = _Adapter({
      'place': {
        'place_id': 'ChIJ1',
        'formatted_address': '5 Admiralty Way, Lekki Phase 1, Lagos',
        'location': {'lat': 6.4478, 'lng': 3.4723},
        'area': 'Lekki Phase 1',
        'city': 'lagos',
        'precision': 'rooftop',
        'source': 'google',
      },
      'serviceable': true,
      'zone': 'island',
      'city': 'lagos',
    });
    final found = await _api(adapter).placeDetails('ChIJ1', session: 'abc');
    expect(adapter.requests.single.queryParameters, {'place_id': 'ChIJ1', 'session': 'abc'});
    expect(found.serviceable, isTrue);
    expect(found.place.isPrecise, isTrue);
    final address = found.toAddress(label: 'Home', pin: const GeoPoint(lat: 6.4480, lng: 3.4725));
    expect(address.line1, '5 Admiralty Way, Lekki Phase 1, Lagos');
    expect(address.city, 'Lagos');
    expect(address.area, 'Lekki Phase 1');
    expect(address.location, const GeoPoint(lat: 6.4480, lng: 3.4725));
  });

  test('delivery estimates and live tracking parse API payloads', () async {
    final estimates = await _api(_Adapter({
      'provider': 'local',
      'estimates': [
        {
          'restaurant_id': 'r1', 'name': 'Jollof Junction', 'area': 'Lekki', 'road_distance_km': 3.2, 'travel_minutes': 11,
          'eta_minutes': 34, 'delivery_fee_kobo': 120000, 'delivers': true, 'is_open': true, 'source': 'estimate',
        },
      ],
    })).deliveryEstimates(['r1'], const GeoPoint(lat: 6.44, lng: 3.47));
    expect(estimates.single.etaMinutes, 34);
    expect(isMeasured(estimates.single.source), isFalse);

    final live = await _api(_Adapter({
      'order_id': 'o1',
      'status': 'in_transit',
      'rider_name': 'Musa',
      'rider_location': {'lat': 6.45, 'lng': 3.47},
      'eta_minutes': 9,
      'eta_source': 'google',
      'route_polyline': '_p~iF~ps|U_ulLnnqC',
      'updated_at': '2026-11-15T10:00:00Z',
      'pickup_location': {'lat': 6.43, 'lng': 3.42},
      'dropoff_location': {'lat': 6.4478, 'lng': 3.4723},
    })).liveTracking('o1');
    expect(live.isLive, isTrue);
    expect(live.route, hasLength(2));
    expect(isMeasured(live.etaSource), isTrue);

    final ended = LiveTracking.fromJson({'order_id': 'o1', 'status': 'delivered', 'rider_location': null});
    expect(ended.isLive, isFalse);
    expect(ended.route, isEmpty);
  });
}
