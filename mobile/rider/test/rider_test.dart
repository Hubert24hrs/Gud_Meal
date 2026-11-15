import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gud_meal_core/gud_meal_core.dart';
import 'package:gud_meal_rider/providers.dart';
import 'package:gud_meal_rider/screens/delivery_screen.dart';
import 'package:gud_meal_rider/screens/home_screen.dart';

class FakeLocation implements LocationSource {
  FakeLocation({this.allowed = true});
  final bool allowed;
  final controller = StreamController<(GeoPoint, double)>();

  @override
  Future<bool> ensurePermission() async => allowed;

  @override
  Stream<(GeoPoint, double)> positions() => controller.stream;
}

class RecordingApi extends GudMealApi {
  RecordingApi({this.failLocation = false}) : super(baseUrl: 'http://fake', token: () async => 't');
  final bool failLocation;
  final sent = <GeoPoint>[];

  @override
  Future<void> sendLocation(GeoPoint p, {double? accuracyM}) async {
    if (failLocation) throw ApiException(0, 'network_error', 'offline');
    sent.add(p);
  }
}

DeliveryOffer offer(DateTime expiresAt) => DeliveryOffer(
      id: 'a1', orderId: 'o1', restaurantName: 'Suya Lane', distanceToRestaurantKm: 1.2, payoutKobo: 121960,
      expiresAt: expiresAt, pickup: const GeoPoint(lat: 6.43, lng: 3.42), dropoffArea: 'Lekki Phase 1',
    );

void main() {
  parcelTests();
  cashTests();
  testWidgets('offer shows countdown, payout and disables actions once expired', (tester) async {
    final now = DateTime.utc(2026, 11, 14, 20, 0, 0);
    await tester.pumpWidget(ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(FakeAuthRepository())],
      child: MaterialApp(home: Scaffold(body: Column(children: [
        OfferCard(offer: offer(now.add(const Duration(seconds: 30))), now: () => now),
        OfferCard(offer: offer(now.subtract(const Duration(seconds: 1))), now: () => now),
      ]))),
    ));
    expect(find.text('30s'), findsOneWidget);
    expect(find.text('Expired'), findsOneWidget);
    expect(find.text('You earn ₦1,219.60'), findsNWidgets(2));
    final accepts = tester.widgetList<FilledButton>(find.widgetWithText(FilledButton, 'Accept')).toList();
    expect(accepts.first.onPressed, isNotNull);
    expect(accepts.last.onPressed, isNull);
  });

  testWidgets('delivery code form only submits four digits', (tester) async {
    String? submitted;
    final controller = TextEditingController();
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: DeliveryCodeForm(controller: controller, onSubmit: (c) => submitted = c))));
    final button = find.widgetWithText(FilledButton, 'Complete delivery');
    await tester.enterText(find.byType(TextField), '12a');
    await tester.pump();
    expect(controller.text, '12');
    expect(tester.widget<FilledButton>(button).onPressed, isNull);
    await tester.enterText(find.byType(TextField), '4118');
    await tester.pump();
    await tester.tap(button);
    expect(submitted, '4118');
  });

  group('LocationReporter', () {
    test('streams positions to the API while online', () async {
      final api = RecordingApi();
      final source = FakeLocation();
      final reporter = LocationReporter(api, source);
      expect(await reporter.start(), isTrue);
      source.controller.add((const GeoPoint(lat: 6.44, lng: 3.46), 8.0));
      await Future<void>.delayed(Duration.zero);
      expect(api.sent.single.lat, 6.44);
      await reporter.stop();
      expect(reporter.active, isFalse);
    });

    test('refuses to start without location permission', () async {
      final reporter = LocationReporter(RecordingApi(), FakeLocation(allowed: false));
      expect(await reporter.start(), isFalse);
      expect(reporter.active, isFalse);
    });

    test('drops pings while offline instead of crashing', () async {
      final api = RecordingApi(failLocation: true);
      final source = FakeLocation();
      final reporter = LocationReporter(api, source);
      await reporter.start();
      source.controller.add((const GeoPoint(lat: 6.44, lng: 3.46), 8.0));
      await Future<void>.delayed(Duration.zero);
      expect(reporter.last?.lat, 6.44);
      await reporter.stop();
    });
  });
}

class _ParcelApi extends GudMealApi {
  _ParcelApi() : super(baseUrl: 'http://fake', token: () async => 'tok');

  @override
  Future<List<Order>> activeDeliveries() async => [
        const Order(
          id: 'p1',
          shortCode: 'PKG123',
          vertical: 'parcel',
          status: 'rider_assigned',
          restaurantName: 'Package from Ada',
          restaurantAddress: '5 Bisola Durosinmi-Etti Drive, Lekki Phase 1',
          restaurantLocation: GeoPoint(lat: 6.44, lng: 3.46),
          riderPayKobo: 120000,
          deliveryAddress: DeliveryAddress(line1: '4 Herbert Macaulay Way', area: 'Yaba', location: GeoPoint(lat: 6.51, lng: 3.37), contactPhone: '+2348055555555'),
          parcel: ParcelDetails(
            pickup: ParcelStop(name: 'Ada', phone: '+2348011111111', line1: '5 Bisola Durosinmi-Etti Drive', location: GeoPoint(lat: 6.44, lng: 3.46)),
            dropoff: ParcelStop(name: 'Ngozi', phone: '+2348055555555', line1: '4 Herbert Macaulay Way', location: GeoPoint(lat: 6.51, lng: 3.37)),
            size: 'medium',
            category: 'clothing',
            description: 'Two dresses',
          ),
        ),
      ];
}

class _CashApi extends GudMealApi {
  _CashApi() : super(baseUrl: 'http://fake', token: () async => 'tok');
  final delivered = <(String, bool)>[];

  static const cashOrder = Order(
    id: 'c1',
    shortCode: 'CASH12',
    status: 'in_transit',
    restaurantName: 'Jollof Junction',
    restaurantLocation: GeoPoint(lat: 6.44, lng: 3.46),
    riderPayKobo: 90000,
    paymentMethod: 'cash',
    collectCashKobo: 1136500,
    deliveryAddress: DeliveryAddress(line1: '5 Admiralty Way', area: 'Lekki Phase 1', location: GeoPoint(lat: 6.44, lng: 3.47)),
  );

  @override
  Future<List<Order>> activeDeliveries() async => [cashOrder];

  @override
  Future<Order> deliver(String orderId, String code, {bool cashCollected = false}) async {
    delivered.add((code, cashCollected));
    return cashOrder.copyWith(status: 'delivered');
  }
}

void cashTests() {
  testWidgets('cash jobs show the amount and need the rider to confirm the cash before delivery', (tester) async {
    final api = _CashApi();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(FakeAuthRepository(const GmUser(uid: 'demo-rider-1'))),
        apiProvider.overrideWithValue(api),
      ],
      child: MaterialApp.router(
        routerConfig: GoRouter(initialLocation: '/deliveries/c1', routes: [
          GoRoute(path: '/', builder: (_, _) => const Scaffold(body: Text('HOME'))),
          GoRoute(path: '/deliveries/:id', builder: (_, s) => DeliveryScreen(orderId: s.pathParameters['id']!)),
        ]),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Collect ₦11,365 in cash'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '4118');
    await tester.pump();
    final button = find.widgetWithText(FilledButton, 'Complete delivery');
    await tester.ensureVisible(button);
    expect(tester.widget<FilledButton>(button).onPressed, isNull); // cash not confirmed yet
    await tester.tap(find.byKey(const ValueKey('cash-taken')));
    await tester.pump();
    expect(tester.widget<FilledButton>(button).onPressed, isNotNull);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(api.delivered.single, ('4118', true));
    expect(find.text('HOME'), findsOneWidget);
  });
}

void parcelTests() {
  testWidgets('package jobs show sender and recipient contacts and package wording', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(FakeAuthRepository(const GmUser(uid: 'demo-rider-1'))),
        apiProvider.overrideWithValue(_ParcelApi()),
      ],
      child: const MaterialApp(home: DeliveryScreen(orderId: 'p1')),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Package · medium · clothing'), findsOneWidget);
    expect(find.text('Pickup: Ada'), findsOneWidget);
    expect(find.text('Drop-off: Ngozi'), findsOneWidget);
    expect(find.text('Contents: Two dresses'), findsOneWidget);
    expect(find.byTooltip('Call Ada'), findsOneWidget);
    expect(find.byTooltip('Call Ngozi'), findsOneWidget);
    expect(find.text('Package collected'), findsOneWidget);
    expect(find.textContaining('kitchen'), findsNothing);
  });
}
