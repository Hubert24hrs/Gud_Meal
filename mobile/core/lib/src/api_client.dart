import 'dart:math';

import 'package:dio/dio.dart';

import 'discover.dart';
import 'models.dart';

typedef TokenProvider = Future<String?> Function();

class ApiException implements Exception {
  ApiException(this.status, this.code, this.message, [this.details = const {}]);
  final int status;
  final String code;
  final String message;
  final Map<String, dynamic> details;

  factory ApiException.fromDio(DioException e) {
    final res = e.response;
    if (res == null) {
      return ApiException(0, 'network_error', "We couldn't reach Gud Meal. Check your connection and try again.");
    }
    final data = res.data;
    if (data is Map && data['error'] is Map) {
      final err = Map<String, dynamic>.from(data['error'] as Map);
      return ApiException(res.statusCode ?? 0, '${err['code'] ?? 'error'}', '${err['message'] ?? 'Something went wrong'}',
          Map<String, dynamic>.from((err['details'] as Map?) ?? const {}));
    }
    if (data is Map && data['detail'] is String) {
      return ApiException(res.statusCode ?? 0, 'error', data['detail'] as String);
    }
    return ApiException(res.statusCode ?? 0, 'error', 'Something went wrong (${res.statusCode})');
  }

  @override
  String toString() => message;
}

String newIdempotencyKey([String prefix = 'app']) {
  final r = Random.secure();
  final hex = List.generate(16, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
  return '$prefix-$hex';
}

/// Typed client for gudmeal-api. Every request carries the user's Firebase ID token.
class GudMealApi {
  GudMealApi({required String baseUrl, required TokenProvider token, Dio? dio})
      : _dio = dio ?? Dio(BaseOptions(baseUrl: baseUrl, connectTimeout: const Duration(seconds: 10), receiveTimeout: const Duration(seconds: 20))) {
    _dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) async {
      final t = await token();
      if (t != null) options.headers['Authorization'] = 'Bearer $t';
      handler.next(options);
    }));
  }

  final Dio _dio;

  Future<T> _call<T>(Future<Response<dynamic>> Function() run, T Function(dynamic data) parse) async {
    try {
      final res = await run();
      return parse(res.data);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Map<String, dynamic> _map(dynamic d) => Map<String, dynamic>.from(d as Map);
  List<Map<String, dynamic>> _list(dynamic d) => (d as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();

  // ------------------------------------------------------------------- catalog
  /// Merchants for a service: restaurants (`vertical: 'food'`) or beauty shops (`vertical: 'beauty'`).
  Future<List<RestaurantCard>> restaurants({
    GeoPoint? near,
    String? query,
    String? cuisine,
    String vertical = 'food',
    String? category,
    String? city,
    bool pickup = false,
    String sort = 'recommended',
    int limit = 50,
  }) =>
      _call(
          () => _dio.get('/v1/restaurants', queryParameters: {
                if (near != null) 'lat': near.lat,
                if (near != null) 'lng': near.lng,
                if (query != null && query.isNotEmpty) 'q': query,
                'cuisine': ?cuisine,
                'vertical': vertical,
                'category': ?category,
                'city': ?city,
                if (pickup) 'pickup': true,
                'sort': sort,
                'limit': limit,
              }),
          (d) => _list(d).map(RestaurantCard.fromJson).toList());

  Future<List<ServiceInfo>> services({String? city}) =>
      _call(() => _dio.get('/v1/services', queryParameters: {'city': ?city}), (d) => _list(d).map(ServiceInfo.fromJson).toList());

  Future<List<BrowseCategory>> categories(String vertical, {String? city}) => _call(
      () => _dio.get('/v1/services/$vertical/categories', queryParameters: {'city': ?city}),
      (d) => _list(d).map(BrowseCategory.fromJson).toList());

  /// Discover tab: most loved dishes, new kitchens and top-rated kitchens (with delivery fee/ETA near [near]).
  Future<DiscoverFeed> discover({String? city, GeoPoint? near, int limit = 6}) => _call(
      () => _dio.get('/v1/discover/dishes', queryParameters: {
            'city': ?city,
            if (near != null) 'lat': near.lat,
            if (near != null) 'lng': near.lng,
            'limit': limit,
          }),
      (d) => DiscoverFeed.fromJson(_map(d)));

  /// Items (dishes or products) and merchants matching [query].
  Future<({List<Map<String, dynamic>> items, List<RestaurantCard> merchants})> search(String query, {String? vertical, GeoPoint? near}) =>
      _call(
          () => _dio.get('/v1/search', queryParameters: {
                'q': query,
                'vertical': ?vertical,
                if (near != null) 'lat': near.lat,
                if (near != null) 'lng': near.lng,
              }), (d) {
        final m = _map(d);
        return (items: _list(m['items']), merchants: _list(m['restaurants']).map(RestaurantCard.fromJson).toList());
      });

  Future<List<PlaceArea>> areas({String? city}) =>
      _call(() => _dio.get('/v1/places/areas', queryParameters: {'city': ?city}), (d) => _list(d).map(PlaceArea.fromJson).toList());

  Future<SupportContacts> supportContacts() =>
      _call(() => _dio.get('/v1/config/public'), (d) => SupportContacts.fromJson(Map<String, dynamic>.from(_map(d)['support'] as Map)));

  Future<RestaurantDetail> restaurant(String id, {GeoPoint? near}) => _call(
      () => _dio.get('/v1/restaurants/$id', queryParameters: {if (near != null) 'lat': near.lat, if (near != null) 'lng': near.lng}),
      (d) => RestaurantDetail.fromJson(_map(d)));

  // ------------------------------------------------------------------- ordering
  Future<Quote> quote({required String restaurantId, required List<CartLine> lines, required String fulfillment, DeliveryAddress? address, String? voucher}) =>
      _call(
          () => _dio.post('/v1/quotes', data: {
                'restaurant_id': restaurantId,
                'lines': lines.map((l) => l.toJson()).toList(),
                'fulfillment': fulfillment,
                if (address != null) 'delivery_address': address.toJson(),
                if (voucher != null && voucher.isNotEmpty) 'voucher_code': voucher,
              }),
          (d) => Quote.fromJson(_map(d)));

  Future<Order> createOrder(String quoteId, String idempotencyKey, {String? contactPhone}) => _call(
      () => _dio.post('/v1/orders',
          data: {'quote_id': quoteId, 'channel': 'app', 'contact_phone': ?contactPhone},
          options: Options(headers: {'Idempotency-Key': idempotencyKey})),
      (d) => Order.fromJson(_map(d)));

  /// [provider]: null = card/transfer/USSD (the server picks the gateway, with failover), 'wallet' or 'cash'.
  Future<CheckoutResult> checkout(String orderId, String idempotencyKey, {String? provider}) => _call(
      () => _dio.post('/v1/orders/$orderId/checkout',
          data: {'provider': ?provider}, options: Options(headers: {'Idempotency-Key': idempotencyKey})),
      (d) => CheckoutResult.fromJson(_map(d)));

  Future<PaymentOptions> paymentOptions(String orderId) =>
      _call(() => _dio.get('/v1/orders/$orderId/payment-options'), (d) => PaymentOptions.fromJson(_map(d)));

  // ------------------------------------------------------------------- wallet & seller cash on delivery
  Future<WalletOverview> wallet() => _call(() => _dio.get('/v1/wallet'), (d) => WalletOverview.fromJson(_map(d)));

  Future<TopUpResult> topUpWallet(int amountKobo, String idempotencyKey) => _call(
      () => _dio.post('/v1/wallet/topups',
          data: {'amount_kobo': amountKobo}, options: Options(headers: {'Idempotency-Key': idempotencyKey})),
      (d) => TopUpResult.fromJson(_map(d)));

  Future<void> setRefundToWallet(bool on) =>
      _call(() => _dio.put('/v1/wallet/settings', data: {'refund_to_wallet': on}), (_) {});

  Future<int> moveCodToWallet(int amountKobo, String idempotencyKey) => _call(
      () => _dio.post('/v1/seller/move-to-wallet',
          data: {'amount_kobo': amountKobo}, options: Options(headers: {'Idempotency-Key': idempotencyKey})),
      (d) => (_map(d)['wallet_balance_kobo'] as num).toInt());

  Future<void> requestSellerPayout({
    required int amountKobo,
    required String bankName,
    required String accountNumber,
    required String accountName,
    required String idempotencyKey,
  }) =>
      _call(
          () => _dio.post('/v1/seller/payouts',
              data: {'amount_kobo': amountKobo, 'bank_name': bankName, 'account_number': accountNumber, 'account_name': accountName},
              options: Options(headers: {'Idempotency-Key': idempotencyKey})),
          (_) {});

  Future<String> verifyPayment(String reference) =>
      _call(() => _dio.post('/v1/payments/verify', data: {'reference': reference}), (d) => '${_map(d)['status']}');

  // ------------------------------------------------------------------- package delivery
  Future<ParcelQuote> parcelQuote({
    required ParcelStop pickup,
    required ParcelStop dropoff,
    required String size,
    required String category,
    String description = '',
    DateTime? scheduledFor,
    int? codAmountKobo,
  }) =>
      _call(
          () => _dio.post('/v1/parcels/quotes', data: {
                'pickup': pickup.toJson(),
                'dropoff': dropoff.toJson(),
                'size': size,
                'category': category,
                'description': description,
                if (scheduledFor != null) 'scheduled_for': scheduledFor.toUtc().toIso8601String(),
                'cod_amount_kobo': ?codAmountKobo,
              }),
          (d) => ParcelQuote.fromJson(_map(d)));

  Future<Order> createParcel(String quoteId, String idempotencyKey) => _call(
      () => _dio.post('/v1/parcels', data: {'quote_id': quoteId, 'channel': 'app'}, options: Options(headers: {'Idempotency-Key': idempotencyKey})),
      (d) => Order.fromJson(_map(d)));

  Future<OrderSummary> orderSummary() => _call(() => _dio.get('/v1/me/order-summary'), (d) => OrderSummary.fromJson(_map(d)));

  Future<void> openSupportTicket({required String category, required String description, String? orderId}) => _call(
      () => _dio.post('/v1/support/tickets', data: {'category': category, 'description': description, 'order_id': ?orderId, 'channel': 'app'}),
      (_) {});

  Future<List<Order>> myOrders() => _call(() => _dio.get('/v1/orders'), (d) => _list(d).map(Order.fromJson).toList());
  Future<Order> order(String id) => _call(() => _dio.get('/v1/orders/$id'), (d) => Order.fromJson(_map(d)));
  Future<Tracking> tracking(String id) => _call(() => _dio.get('/v1/orders/$id/tracking'), (d) => Tracking.fromJson(_map(d)));
  Future<String?> deliveryCode(String id) => _call(() => _dio.get('/v1/orders/$id/codes'), (d) => _map(d)['delivery_code'] as String?);
  Future<Order> cancel(String id) => _call(() => _dio.post('/v1/orders/$id/cancel', data: {'reason': 'Cancelled in app'}), (d) => Order.fromJson(_map(d)));

  Future<List<DeliveryAddress>> addresses() => _call(() => _dio.get('/v1/me/addresses'), (d) => _list(d).map(DeliveryAddress.fromJson).toList());
  Future<void> saveAddress(DeliveryAddress a) => _call(() => _dio.post('/v1/me/addresses', data: a.toJson()), (_) {});
  Future<void> registerDevice(String token, String platform) =>
      _call(() => _dio.post('/v1/me/devices', data: {'token': token, 'platform': platform}), (_) {});

  // ------------------------------------------------------------------- rider
  Future<RiderProfile> riderProfile() => _call(() => _dio.get('/v1/rider/profile'), (d) => RiderProfile.fromJson(_map(d)));
  Future<RiderProfile> setOnline(bool online) =>
      _call(() => _dio.put('/v1/rider/availability', data: {'online': online}), (d) => RiderProfile.fromJson(_map(d)));
  Future<void> sendLocation(GeoPoint p, {double? accuracyM}) => _call(
      () => _dio.post('/v1/rider/location', data: {'lat': p.lat, 'lng': p.lng, 'accuracy_m': ?accuracyM}), (_) {});
  Future<List<DeliveryOffer>> offers() => _call(() => _dio.get('/v1/rider/offers'), (d) => _list(d).map(DeliveryOffer.fromJson).toList());
  Future<Order> acceptOffer(String id) => _call(() => _dio.post('/v1/rider/offers/$id/accept'), (d) => Order.fromJson(_map(d)));
  Future<void> declineOffer(String id, String reason) => _call(() => _dio.post('/v1/rider/offers/$id/decline', data: {'reason': reason}), (_) {});
  Future<List<Order>> activeDeliveries() => _call(() => _dio.get('/v1/rider/deliveries'), (d) => _list(d).map(Order.fromJson).toList());
  Future<Order> pickup(String orderId) => _call(() => _dio.post('/v1/rider/deliveries/$orderId/pickup'), (d) => Order.fromJson(_map(d)));
  Future<Order> inTransit(String orderId) => _call(() => _dio.post('/v1/rider/deliveries/$orderId/in-transit'), (d) => Order.fromJson(_map(d)));
  /// [cashCollected] must be true when the order has cash to collect; the amount always comes from the server.
  Future<Order> deliver(String orderId, String code, {bool cashCollected = false}) => _call(
      () => _dio.post('/v1/rider/deliveries/$orderId/deliver', data: {'code': code, 'cash_collected': cashCollected}),
      (d) => Order.fromJson(_map(d)));
  Future<Earnings> earnings() => _call(() => _dio.get('/v1/rider/earnings'), (d) => Earnings.fromJson(_map(d)));
  Future<void> requestPayout(int amountKobo, String key) => _call(
      () => _dio.post('/v1/rider/payouts', data: {'amount_kobo': amountKobo}, options: Options(headers: {'Idempotency-Key': key})), (_) {});
  Future<void> emergency(String description, GeoPoint? at) => _call(
      () => _dio.post('/v1/rider/emergency', data: {'description': description, if (at != null) 'lat': at.lat, if (at != null) 'lng': at.lng}),
      (_) {});
}

/// Client for gudmeal-agents (the LangGraph AI service).
class GudMealAgentsApi {
  GudMealAgentsApi({required String baseUrl, required TokenProvider token, Dio? dio})
      : _dio = dio ?? Dio(BaseOptions(baseUrl: baseUrl, receiveTimeout: const Duration(seconds: 60))) {
    _dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) async {
      final t = await token();
      if (t != null) options.headers['Authorization'] = 'Bearer $t';
      handler.next(options);
    }));
  }

  final Dio _dio;

  Future<ChatResponse> chat(String message, {String? threadId, DeliveryAddress? address}) async {
    try {
      final res = await _dio.post('/v1/chat', data: {
        'message': message,
        'channel': 'app',
        'thread_id': ?threadId,
        if (address != null && threadId == null) 'delivery_address': address.toJson(),
      });
      return ChatResponse.fromJson(Map<String, dynamic>.from(res.data as Map));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<ChatResponse> decide(String threadId, {required bool approved, required String toolCallId}) async {
    try {
      final res = await _dio.post('/v1/chat/$threadId/approval', data: {'approved': approved, 'tool_call_id': toolCallId});
      return ChatResponse.fromJson(Map<String, dynamic>.from(res.data as Map));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
