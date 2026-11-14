import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gud_meal_core/gud_meal_core.dart';

/// Records requests and replies with canned JSON — no network.
class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.status, this.body);
  final int status;
  final Object body;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);
    return ResponseBody.fromString(jsonEncode(body), status, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

const orderJson = {
  'id': 'o1',
  'short_code': 'BGHZ6Z',
  'status': 'in_transit',
  'restaurant_name': 'Suya Lane',
  'fulfillment': 'delivery',
  'lines': [
    {'item_id': 'sl-beef-suya', 'name': 'Beef Suya (250g)', 'quantity': 2, 'line_total_kobo': 900000, 'selection_labels': ['Yaji level: Medium']}
  ],
  'breakdown': {
    'subtotal_kobo': 1150000, 'delivery_fee_kobo': 175000, 'service_fee_kobo': 57500, 'small_order_fee_kobo': 0,
    'vat_kobo': 17438, 'discount_kobo': 50000, 'total_kobo': 1349938, 'voucher_code': 'WELCOME500', 'discount_funded_by': 'platform'
  },
  'progress': {'step': 4, 'total_steps': 5, 'label': 'On the way to you'},
  'rider_name': 'Chidi Okafor',
  'estimated_delivery_at': '2026-11-14T23:16:05.349906Z',
  'unknown_future_field': true,
};

void main() {
  group('formatting', () {
    test('naira from kobo', () {
      expect(formatNaira(1000000), '₦10,000');
      expect(formatNaira(150050), '₦1,500.50');
      expect(formatNaira(-500), '-₦5');
      expect(formatNaira(null), '—');
    });
    test('Lagos time is UTC+1', () {
      expect(formatLagosTime(DateTime.utc(2026, 11, 14, 23, 16)), '12:16 AM');
    });
    test('every order status has a label', () {
      expect(orderStatusLabels.length, 17);
      expect(statusLabel('in_transit'), 'On the way');
    });
  });

  group('option rules mirror the API', () {
    const group = OptionGroup(id: 'p', name: 'Protein', minSelect: 1, maxSelect: 1, choices: [
      OptionChoice(id: 'chicken', name: 'Chicken'),
      OptionChoice(id: 'turkey', name: 'Turkey', priceDeltaKobo: 150000),
    ]);
    const item = MenuItem(id: 'i', restaurantId: 'r', name: 'Jollof', priceKobo: 550000, optionGroupIds: ['p']);
    test('required group', () {
      expect(validateSelections(item, {'p': group}, {}), contains('Choose 1'));
      expect(validateSelections(item, {'p': group}, {'p': ['turkey']}), isNull);
    });
    test('extras price', () {
      expect(optionsPriceKobo(item, {'p': group}, {'p': ['turkey']}), 150000);
    });
  });

  test('parses API order payloads (snake_case, unknown fields ignored)', () {
    final order = Order.fromJson(orderJson);
    expect(order.shortCode, 'BGHZ6Z');
    expect(order.breakdown!.totalKobo, 1349938);
    expect(order.lines.single.selectionLabels, ['Yaji level: Medium']);
    expect(order.progress!.step, 4);
    expect(order.estimatedDeliveryAt!.isUtc, isTrue);
  });

  test('cart lines serialise to the API shape', () {
    const line = CartLine(itemId: 'jj', quantity: 2, selections: [OptionSelection(groupId: 'p', choiceIds: ['chicken'])]);
    expect(line.toJson(), {
      'item_id': 'jj',
      'quantity': 2,
      'selections': [
        {'group_id': 'p', 'choice_ids': ['chicken']}
      ],
    });
  });

  group('GudMealApi', () {
    test('sends bearer token and idempotency key', () async {
      final adapter = FakeAdapter(201, orderJson);
      final dio = Dio(BaseOptions(baseUrl: 'http://api.test'))..httpClientAdapter = adapter;
      final api = GudMealApi(baseUrl: 'http://api.test', token: () async => 'tok-123', dio: dio);
      final order = await api.createOrder('q1', 'app-key-12345678');
      expect(order.id, 'o1');
      final req = adapter.requests.single;
      expect(req.path, '/v1/orders');
      expect(req.headers['Authorization'], 'Bearer tok-123');
      expect(req.headers['Idempotency-Key'], 'app-key-12345678');
    });

    test('maps API errors to ApiException', () async {
      final adapter = FakeAdapter(409, {
        'error': {'code': 'price_changed', 'message': 'Prices changed', 'details': {'new_total_kobo': 1}}
      });
      final dio = Dio(BaseOptions(baseUrl: 'http://api.test'))..httpClientAdapter = adapter;
      final api = GudMealApi(baseUrl: 'http://api.test', token: () async => null, dio: dio);
      await expectLater(
        api.order('x'),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 'price_changed').having((e) => e.status, 'status', 409)),
      );
    });

    test('idempotency keys are unique', () {
      expect(newIdempotencyKey(), isNot(newIdempotencyKey()));
      expect(newIdempotencyKey('rider').startsWith('rider-'), isTrue);
    });
  });

  test('fake auth repository signs in and out', () async {
    final auth = FakeAuthRepository();
    await auth.signInWithEmail('ada@example.com', 'secret1');
    expect(auth.currentUser?.email, 'ada@example.com');
    expect(await auth.idToken(), startsWith('fake-token-'));
    await auth.signOut();
    expect(auth.currentUser, isNull);
  });
}
