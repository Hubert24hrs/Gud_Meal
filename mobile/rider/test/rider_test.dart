import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
