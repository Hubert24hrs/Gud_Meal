// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GeoPoint _$GeoPointFromJson(Map<String, dynamic> json) => _GeoPoint(
  lat: (json['lat'] as num).toDouble(),
  lng: (json['lng'] as num).toDouble(),
);

Map<String, dynamic> _$GeoPointToJson(_GeoPoint instance) => <String, dynamic>{
  'lat': instance.lat,
  'lng': instance.lng,
};

_RestaurantCard _$RestaurantCardFromJson(Map<String, dynamic> json) =>
    _RestaurantCard(
      id: json['id'] as String,
      vertical: json['vertical'] as String? ?? 'food',
      city: json['city'] as String? ?? 'lagos',
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      cuisines:
          (json['cuisines'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      area: json['area'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      ratingCount: (json['rating_count'] as num?)?.toInt() ?? 0,
      isOpen: json['is_open'] as bool? ?? false,
      isAcceptingOrders: json['is_accepting_orders'] as bool? ?? true,
      isFeatured: json['is_featured'] as bool? ?? false,
      coverUrl: json['cover_url'] as String?,
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      etaMinutes: (json['eta_minutes'] as num?)?.toInt(),
      deliveryFeeKobo: (json['delivery_fee_kobo'] as num?)?.toInt(),
      deliversToLocation: json['delivers_to_location'] as bool?,
      supportsPickup: json['supports_pickup'] as bool? ?? true,
      supportsDelivery: json['supports_delivery'] as bool? ?? true,
      promotions:
          (json['promotions'] as List<dynamic>?)
              ?.map((e) => PromoBadge.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <PromoBadge>[],
    );

Map<String, dynamic> _$RestaurantCardToJson(_RestaurantCard instance) =>
    <String, dynamic>{
      'id': instance.id,
      'vertical': instance.vertical,
      'city': instance.city,
      'name': instance.name,
      'description': instance.description,
      'cuisines': instance.cuisines,
      'area': instance.area,
      'rating': instance.rating,
      'rating_count': instance.ratingCount,
      'is_open': instance.isOpen,
      'is_accepting_orders': instance.isAcceptingOrders,
      'is_featured': instance.isFeatured,
      'cover_url': ?instance.coverUrl,
      'distance_km': ?instance.distanceKm,
      'eta_minutes': ?instance.etaMinutes,
      'delivery_fee_kobo': ?instance.deliveryFeeKobo,
      'delivers_to_location': ?instance.deliversToLocation,
      'supports_pickup': instance.supportsPickup,
      'supports_delivery': instance.supportsDelivery,
      'promotions': instance.promotions.map((e) => e.toJson()).toList(),
    };

_OptionChoice _$OptionChoiceFromJson(Map<String, dynamic> json) =>
    _OptionChoice(
      id: json['id'] as String,
      name: json['name'] as String,
      priceDeltaKobo: (json['price_delta_kobo'] as num?)?.toInt() ?? 0,
      isAvailable: json['is_available'] as bool? ?? true,
    );

Map<String, dynamic> _$OptionChoiceToJson(_OptionChoice instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'price_delta_kobo': instance.priceDeltaKobo,
      'is_available': instance.isAvailable,
    };

_OptionGroup _$OptionGroupFromJson(Map<String, dynamic> json) => _OptionGroup(
  id: json['id'] as String,
  name: json['name'] as String,
  minSelect: (json['min_select'] as num?)?.toInt() ?? 0,
  maxSelect: (json['max_select'] as num?)?.toInt() ?? 1,
  choices:
      (json['choices'] as List<dynamic>?)
          ?.map((e) => OptionChoice.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <OptionChoice>[],
);

Map<String, dynamic> _$OptionGroupToJson(_OptionGroup instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'min_select': instance.minSelect,
      'max_select': instance.maxSelect,
      'choices': instance.choices.map((e) => e.toJson()).toList(),
    };

_MenuItem _$MenuItemFromJson(Map<String, dynamic> json) => _MenuItem(
  id: json['id'] as String,
  restaurantId: json['restaurant_id'] as String,
  name: json['name'] as String,
  description: json['description'] as String? ?? '',
  priceKobo: (json['price_kobo'] as num).toInt(),
  kind: json['kind'] as String? ?? 'main',
  allergens:
      (json['allergens'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  dietary:
      (json['dietary'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  serves: (json['serves'] as num?)?.toInt() ?? 1,
  spiceLevel: (json['spice_level'] as num?)?.toInt() ?? 0,
  isAvailable: json['is_available'] as bool? ?? true,
  optionGroupIds:
      (json['option_group_ids'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
  unitLabel: json['unit_label'] as String?,
);

Map<String, dynamic> _$MenuItemToJson(_MenuItem instance) => <String, dynamic>{
  'id': instance.id,
  'restaurant_id': instance.restaurantId,
  'name': instance.name,
  'description': instance.description,
  'price_kobo': instance.priceKobo,
  'kind': instance.kind,
  'allergens': instance.allergens,
  'dietary': instance.dietary,
  'serves': instance.serves,
  'spice_level': instance.spiceLevel,
  'is_available': instance.isAvailable,
  'option_group_ids': instance.optionGroupIds,
  'unit_label': ?instance.unitLabel,
};

_MenuCategory _$MenuCategoryFromJson(Map<String, dynamic> json) =>
    _MenuCategory(id: json['id'] as String, name: json['name'] as String);

Map<String, dynamic> _$MenuCategoryToJson(_MenuCategory instance) =>
    <String, dynamic>{'id': instance.id, 'name': instance.name};

_MenuSection _$MenuSectionFromJson(Map<String, dynamic> json) => _MenuSection(
  category: MenuCategory.fromJson(json['category'] as Map<String, dynamic>),
  items:
      (json['items'] as List<dynamic>?)
          ?.map((e) => MenuItem.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <MenuItem>[],
);

Map<String, dynamic> _$MenuSectionToJson(_MenuSection instance) =>
    <String, dynamic>{
      'category': instance.category.toJson(),
      'items': instance.items.map((e) => e.toJson()).toList(),
    };

_RestaurantDetail _$RestaurantDetailFromJson(Map<String, dynamic> json) =>
    _RestaurantDetail(
      restaurant: RestaurantCard.fromJson(
        json['restaurant'] as Map<String, dynamic>,
      ),
      address: json['address'] as String? ?? '',
      avgPrepMinutes: (json['avg_prep_minutes'] as num?)?.toInt() ?? 20,
      sections:
          (json['sections'] as List<dynamic>?)
              ?.map((e) => MenuSection.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <MenuSection>[],
      optionGroups:
          (json['option_groups'] as Map<String, dynamic>?)?.map(
            (k, e) =>
                MapEntry(k, OptionGroup.fromJson(e as Map<String, dynamic>)),
          ) ??
          const <String, OptionGroup>{},
    );

Map<String, dynamic> _$RestaurantDetailToJson(
  _RestaurantDetail instance,
) => <String, dynamic>{
  'restaurant': instance.restaurant.toJson(),
  'address': instance.address,
  'avg_prep_minutes': instance.avgPrepMinutes,
  'sections': instance.sections.map((e) => e.toJson()).toList(),
  'option_groups': instance.optionGroups.map((k, e) => MapEntry(k, e.toJson())),
};

_OptionSelection _$OptionSelectionFromJson(Map<String, dynamic> json) =>
    _OptionSelection(
      groupId: json['group_id'] as String,
      choiceIds:
          (json['choice_ids'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
    );

Map<String, dynamic> _$OptionSelectionToJson(_OptionSelection instance) =>
    <String, dynamic>{
      'group_id': instance.groupId,
      'choice_ids': instance.choiceIds,
    };

_CartLine _$CartLineFromJson(Map<String, dynamic> json) => _CartLine(
  itemId: json['item_id'] as String,
  quantity: (json['quantity'] as num).toInt(),
  selections:
      (json['selections'] as List<dynamic>?)
          ?.map((e) => OptionSelection.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <OptionSelection>[],
  notes: json['notes'] as String?,
);

Map<String, dynamic> _$CartLineToJson(_CartLine instance) => <String, dynamic>{
  'item_id': instance.itemId,
  'quantity': instance.quantity,
  'selections': instance.selections.map((e) => e.toJson()).toList(),
  'notes': ?instance.notes,
};

_DeliveryAddress _$DeliveryAddressFromJson(Map<String, dynamic> json) =>
    _DeliveryAddress(
      label: json['label'] as String?,
      line1: json['line1'] as String,
      area: json['area'] as String?,
      city: json['city'] as String? ?? 'Lagos',
      state: json['state'] as String? ?? 'Lagos',
      location: GeoPoint.fromJson(json['location'] as Map<String, dynamic>),
      instructions: json['instructions'] as String?,
      contactPhone: json['contact_phone'] as String?,
    );

Map<String, dynamic> _$DeliveryAddressToJson(_DeliveryAddress instance) =>
    <String, dynamic>{
      'label': ?instance.label,
      'line1': instance.line1,
      'area': ?instance.area,
      'city': instance.city,
      'state': instance.state,
      'location': instance.location.toJson(),
      'instructions': ?instance.instructions,
      'contact_phone': ?instance.contactPhone,
    };

_PricedLine _$PricedLineFromJson(Map<String, dynamic> json) => _PricedLine(
  itemId: json['item_id'] as String,
  name: json['name'] as String,
  quantity: (json['quantity'] as num).toInt(),
  lineTotalKobo: (json['line_total_kobo'] as num).toInt(),
  selectionLabels:
      (json['selection_labels'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
);

Map<String, dynamic> _$PricedLineToJson(_PricedLine instance) =>
    <String, dynamic>{
      'item_id': instance.itemId,
      'name': instance.name,
      'quantity': instance.quantity,
      'line_total_kobo': instance.lineTotalKobo,
      'selection_labels': instance.selectionLabels,
    };

_PriceBreakdown _$PriceBreakdownFromJson(Map<String, dynamic> json) =>
    _PriceBreakdown(
      subtotalKobo: (json['subtotal_kobo'] as num).toInt(),
      deliveryFeeKobo: (json['delivery_fee_kobo'] as num?)?.toInt() ?? 0,
      serviceFeeKobo: (json['service_fee_kobo'] as num?)?.toInt() ?? 0,
      smallOrderFeeKobo: (json['small_order_fee_kobo'] as num?)?.toInt() ?? 0,
      vatKobo: (json['vat_kobo'] as num?)?.toInt() ?? 0,
      discountKobo: (json['discount_kobo'] as num?)?.toInt() ?? 0,
      codFeeKobo: (json['cod_fee_kobo'] as num?)?.toInt() ?? 0,
      totalKobo: (json['total_kobo'] as num).toInt(),
      voucherCode: json['voucher_code'] as String?,
    );

Map<String, dynamic> _$PriceBreakdownToJson(_PriceBreakdown instance) =>
    <String, dynamic>{
      'subtotal_kobo': instance.subtotalKobo,
      'delivery_fee_kobo': instance.deliveryFeeKobo,
      'service_fee_kobo': instance.serviceFeeKobo,
      'small_order_fee_kobo': instance.smallOrderFeeKobo,
      'vat_kobo': instance.vatKobo,
      'discount_kobo': instance.discountKobo,
      'cod_fee_kobo': instance.codFeeKobo,
      'total_kobo': instance.totalKobo,
      'voucher_code': ?instance.voucherCode,
    };

_Quote _$QuoteFromJson(Map<String, dynamic> json) => _Quote(
  id: json['id'] as String,
  restaurantName: json['restaurant_name'] as String,
  lines:
      (json['lines'] as List<dynamic>?)
          ?.map((e) => PricedLine.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <PricedLine>[],
  breakdown: PriceBreakdown.fromJson(json['breakdown'] as Map<String, dynamic>),
  fulfillment: json['fulfillment'] as String,
  etaMinutes: (json['eta_minutes'] as num).toInt(),
  estimatedDeliveryAt: DateTime.parse(json['estimated_delivery_at'] as String),
  expiresAt: DateTime.parse(json['expires_at'] as String),
);

Map<String, dynamic> _$QuoteToJson(_Quote instance) => <String, dynamic>{
  'id': instance.id,
  'restaurant_name': instance.restaurantName,
  'lines': instance.lines.map((e) => e.toJson()).toList(),
  'breakdown': instance.breakdown.toJson(),
  'fulfillment': instance.fulfillment,
  'eta_minutes': instance.etaMinutes,
  'estimated_delivery_at': instance.estimatedDeliveryAt.toIso8601String(),
  'expires_at': instance.expiresAt.toIso8601String(),
};

_OrderProgress _$OrderProgressFromJson(Map<String, dynamic> json) =>
    _OrderProgress(
      step: (json['step'] as num).toInt(),
      totalSteps: (json['total_steps'] as num?)?.toInt() ?? 5,
      label: json['label'] as String,
    );

Map<String, dynamic> _$OrderProgressToJson(_OrderProgress instance) =>
    <String, dynamic>{
      'step': instance.step,
      'total_steps': instance.totalSteps,
      'label': instance.label,
    };

_Order _$OrderFromJson(Map<String, dynamic> json) => _Order(
  id: json['id'] as String,
  shortCode: json['short_code'] as String,
  vertical: json['vertical'] as String? ?? 'food',
  status: json['status'] as String,
  restaurantName: json['restaurant_name'] as String,
  fulfillment: json['fulfillment'] as String? ?? 'delivery',
  lines:
      (json['lines'] as List<dynamic>?)
          ?.map((e) => PricedLine.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <PricedLine>[],
  breakdown: json['breakdown'] == null
      ? null
      : PriceBreakdown.fromJson(json['breakdown'] as Map<String, dynamic>),
  deliveryAddress: json['delivery_address'] == null
      ? null
      : DeliveryAddress.fromJson(
          json['delivery_address'] as Map<String, dynamic>,
        ),
  progress: json['progress'] == null
      ? null
      : OrderProgress.fromJson(json['progress'] as Map<String, dynamic>),
  riderName: json['rider_name'] as String?,
  customerName: json['customer_name'] as String?,
  restaurantAddress: json['restaurant_address'] as String?,
  restaurantLocation: json['restaurant_location'] == null
      ? null
      : GeoPoint.fromJson(json['restaurant_location'] as Map<String, dynamic>),
  estimatedDeliveryAt: json['estimated_delivery_at'] == null
      ? null
      : DateTime.parse(json['estimated_delivery_at'] as String),
  readyAt: json['ready_at'] == null
      ? null
      : DateTime.parse(json['ready_at'] as String),
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  riderPayKobo: (json['rider_pay_kobo'] as num?)?.toInt(),
  reviewed: json['reviewed'] as bool? ?? false,
  parcel: json['parcel'] == null
      ? null
      : ParcelDetails.fromJson(json['parcel'] as Map<String, dynamic>),
  refundTotalKobo: (json['refund_total_kobo'] as num?)?.toInt() ?? 0,
  payment: json['payment'] == null
      ? const OrderPayment()
      : OrderPayment.fromJson(json['payment'] as Map<String, dynamic>),
  cashCollectedAt: json['cash_collected_at'] == null
      ? null
      : DateTime.parse(json['cash_collected_at'] as String),
  paymentMethod: json['payment_method'] as String?,
  collectCashKobo: (json['collect_cash_kobo'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$OrderToJson(_Order instance) => <String, dynamic>{
  'id': instance.id,
  'short_code': instance.shortCode,
  'vertical': instance.vertical,
  'status': instance.status,
  'restaurant_name': instance.restaurantName,
  'fulfillment': instance.fulfillment,
  'lines': instance.lines.map((e) => e.toJson()).toList(),
  'breakdown': ?instance.breakdown?.toJson(),
  'delivery_address': ?instance.deliveryAddress?.toJson(),
  'progress': ?instance.progress?.toJson(),
  'rider_name': ?instance.riderName,
  'customer_name': ?instance.customerName,
  'restaurant_address': ?instance.restaurantAddress,
  'restaurant_location': ?instance.restaurantLocation?.toJson(),
  'estimated_delivery_at': ?instance.estimatedDeliveryAt?.toIso8601String(),
  'ready_at': ?instance.readyAt?.toIso8601String(),
  'created_at': ?instance.createdAt?.toIso8601String(),
  'rider_pay_kobo': ?instance.riderPayKobo,
  'reviewed': instance.reviewed,
  'parcel': ?instance.parcel?.toJson(),
  'refund_total_kobo': instance.refundTotalKobo,
  'payment': instance.payment.toJson(),
  'cash_collected_at': ?instance.cashCollectedAt?.toIso8601String(),
  'payment_method': ?instance.paymentMethod,
  'collect_cash_kobo': instance.collectCashKobo,
};

_OrderPayment _$OrderPaymentFromJson(Map<String, dynamic> json) =>
    _OrderPayment(
      provider: json['provider'] as String?,
      reference: json['reference'] as String?,
      status: json['status'] as String? ?? 'unpaid',
      paidAt: json['paid_at'] == null
          ? null
          : DateTime.parse(json['paid_at'] as String),
    );

Map<String, dynamic> _$OrderPaymentToJson(_OrderPayment instance) =>
    <String, dynamic>{
      'provider': ?instance.provider,
      'reference': ?instance.reference,
      'status': instance.status,
      'paid_at': ?instance.paidAt?.toIso8601String(),
    };

_CheckoutResult _$CheckoutResultFromJson(Map<String, dynamic> json) =>
    _CheckoutResult(
      orderId: json['order_id'] as String,
      status: json['status'] as String? ?? '',
      reference: json['reference'] as String,
      authorizationUrl: json['authorization_url'] as String?,
      amountKobo: (json['amount_kobo'] as num).toInt(),
      provider: json['provider'] as String,
      failoverFrom: json['failover_from'] as String?,
    );

Map<String, dynamic> _$CheckoutResultToJson(_CheckoutResult instance) =>
    <String, dynamic>{
      'order_id': instance.orderId,
      'status': instance.status,
      'reference': instance.reference,
      'authorization_url': ?instance.authorizationUrl,
      'amount_kobo': instance.amountKobo,
      'provider': instance.provider,
      'failover_from': ?instance.failoverFrom,
    };

_PaymentMethodOption _$PaymentMethodOptionFromJson(Map<String, dynamic> json) =>
    _PaymentMethodOption(
      id: json['id'] as String,
      label: json['label'] as String,
      available: json['available'] as bool? ?? false,
      reason: json['reason'] as String?,
      balanceKobo: (json['balance_kobo'] as num?)?.toInt(),
      shortByKobo: (json['short_by_kobo'] as num?)?.toInt(),
    );

Map<String, dynamic> _$PaymentMethodOptionToJson(
  _PaymentMethodOption instance,
) => <String, dynamic>{
  'id': instance.id,
  'label': instance.label,
  'available': instance.available,
  'reason': ?instance.reason,
  'balance_kobo': ?instance.balanceKobo,
  'short_by_kobo': ?instance.shortByKobo,
};

_PaymentOptions _$PaymentOptionsFromJson(Map<String, dynamic> json) =>
    _PaymentOptions(
      orderId: json['order_id'] as String,
      totalKobo: (json['total_kobo'] as num).toInt(),
      methods:
          (json['methods'] as List<dynamic>?)
              ?.map(
                (e) => PaymentMethodOption.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const <PaymentMethodOption>[],
    );

Map<String, dynamic> _$PaymentOptionsToJson(_PaymentOptions instance) =>
    <String, dynamic>{
      'order_id': instance.orderId,
      'total_kobo': instance.totalKobo,
      'methods': instance.methods.map((e) => e.toJson()).toList(),
    };

_WalletTransaction _$WalletTransactionFromJson(Map<String, dynamic> json) =>
    _WalletTransaction(
      id: json['id'] as String,
      kind: json['kind'] as String,
      description: json['description'] as String? ?? '',
      reference: json['reference'] as String?,
      orderId: json['order_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      direction: json['direction'] as String? ?? 'in',
      amountKobo: (json['amount_kobo'] as num).toInt(),
    );

Map<String, dynamic> _$WalletTransactionToJson(_WalletTransaction instance) =>
    <String, dynamic>{
      'id': instance.id,
      'kind': instance.kind,
      'description': instance.description,
      'reference': ?instance.reference,
      'order_id': ?instance.orderId,
      'created_at': instance.createdAt.toIso8601String(),
      'direction': instance.direction,
      'amount_kobo': instance.amountKobo,
    };

_WalletLimits _$WalletLimitsFromJson(Map<String, dynamic> json) =>
    _WalletLimits(
      minTopupKobo: (json['min_topup_kobo'] as num?)?.toInt() ?? 50000,
      maxTopupKobo: (json['max_topup_kobo'] as num?)?.toInt() ?? 10000000,
      maxBalanceKobo: (json['max_balance_kobo'] as num?)?.toInt() ?? 30000000,
    );

Map<String, dynamic> _$WalletLimitsToJson(_WalletLimits instance) =>
    <String, dynamic>{
      'min_topup_kobo': instance.minTopupKobo,
      'max_topup_kobo': instance.maxTopupKobo,
      'max_balance_kobo': instance.maxBalanceKobo,
    };

_SellerSummary _$SellerSummaryFromJson(Map<String, dynamic> json) =>
    _SellerSummary(
      codBalanceKobo: (json['cod_balance_kobo'] as num?)?.toInt() ?? 0,
      pendingPayoutsKobo: (json['pending_payouts_kobo'] as num?)?.toInt() ?? 0,
      availableKobo: (json['available_kobo'] as num?)?.toInt() ?? 0,
      minPayoutKobo: (json['min_payout_kobo'] as num?)?.toInt() ?? 100000,
    );

Map<String, dynamic> _$SellerSummaryToJson(_SellerSummary instance) =>
    <String, dynamic>{
      'cod_balance_kobo': instance.codBalanceKobo,
      'pending_payouts_kobo': instance.pendingPayoutsKobo,
      'available_kobo': instance.availableKobo,
      'min_payout_kobo': instance.minPayoutKobo,
    };

_WalletOverview _$WalletOverviewFromJson(Map<String, dynamic> json) =>
    _WalletOverview(
      balanceKobo: (json['balance_kobo'] as num?)?.toInt() ?? 0,
      enabled: json['enabled'] as bool? ?? true,
      limits: json['limits'] == null
          ? const WalletLimits()
          : WalletLimits.fromJson(json['limits'] as Map<String, dynamic>),
      refundToWallet: json['refund_to_wallet'] as bool? ?? false,
      transactions:
          (json['transactions'] as List<dynamic>?)
              ?.map(
                (e) => WalletTransaction.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const <WalletTransaction>[],
      seller: json['seller'] == null
          ? null
          : SellerSummary.fromJson(json['seller'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$WalletOverviewToJson(_WalletOverview instance) =>
    <String, dynamic>{
      'balance_kobo': instance.balanceKobo,
      'enabled': instance.enabled,
      'limits': instance.limits.toJson(),
      'refund_to_wallet': instance.refundToWallet,
      'transactions': instance.transactions.map((e) => e.toJson()).toList(),
      'seller': ?instance.seller?.toJson(),
    };

_TopUpResult _$TopUpResultFromJson(Map<String, dynamic> json) => _TopUpResult(
  reference: json['reference'] as String,
  provider: json['provider'] as String,
  authorizationUrl: json['authorization_url'] as String?,
  amountKobo: (json['amount_kobo'] as num).toInt(),
);

Map<String, dynamic> _$TopUpResultToJson(_TopUpResult instance) =>
    <String, dynamic>{
      'reference': instance.reference,
      'provider': instance.provider,
      'authorization_url': ?instance.authorizationUrl,
      'amount_kobo': instance.amountKobo,
    };

_Tracking _$TrackingFromJson(Map<String, dynamic> json) => _Tracking(
  status: json['status'] as String,
  riderName: json['rider_name'] as String?,
  riderLocation: json['rider_location'] == null
      ? null
      : GeoPoint.fromJson(json['rider_location'] as Map<String, dynamic>),
  etaMinutes: (json['eta_minutes'] as num?)?.toInt(),
  estimatedDeliveryAt: json['estimated_delivery_at'] == null
      ? null
      : DateTime.parse(json['estimated_delivery_at'] as String),
);

Map<String, dynamic> _$TrackingToJson(_Tracking instance) => <String, dynamic>{
  'status': instance.status,
  'rider_name': ?instance.riderName,
  'rider_location': ?instance.riderLocation?.toJson(),
  'eta_minutes': ?instance.etaMinutes,
  'estimated_delivery_at': ?instance.estimatedDeliveryAt?.toIso8601String(),
};

_DeliveryOffer _$DeliveryOfferFromJson(Map<String, dynamic> json) =>
    _DeliveryOffer(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      restaurantName: json['restaurant_name'] as String,
      distanceToRestaurantKm: (json['distance_to_restaurant_km'] as num)
          .toDouble(),
      payoutKobo: (json['payout_kobo'] as num).toInt(),
      expiresAt: DateTime.parse(json['expires_at'] as String),
      pickup: GeoPoint.fromJson(json['pickup'] as Map<String, dynamic>),
      dropoff: json['dropoff'] == null
          ? null
          : GeoPoint.fromJson(json['dropoff'] as Map<String, dynamic>),
      dropoffArea: json['dropoff_area'] as String?,
    );

Map<String, dynamic> _$DeliveryOfferToJson(_DeliveryOffer instance) =>
    <String, dynamic>{
      'id': instance.id,
      'order_id': instance.orderId,
      'restaurant_name': instance.restaurantName,
      'distance_to_restaurant_km': instance.distanceToRestaurantKm,
      'payout_kobo': instance.payoutKobo,
      'expires_at': instance.expiresAt.toIso8601String(),
      'pickup': instance.pickup.toJson(),
      'dropoff': ?instance.dropoff?.toJson(),
      'dropoff_area': ?instance.dropoffArea,
    };

_RiderProfile _$RiderProfileFromJson(Map<String, dynamic> json) =>
    _RiderProfile(
      uid: json['uid'] as String,
      name: json['name'] as String,
      vehicle: json['vehicle'] as String? ?? 'motorcycle',
      status: json['status'] as String? ?? 'pending',
      isOnline: json['is_online'] as bool? ?? false,
      rating: (json['rating'] as num?)?.toDouble() ?? 5,
      activeOrderIds:
          (json['active_order_ids'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      completedDeliveries: (json['completed_deliveries'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$RiderProfileToJson(_RiderProfile instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'name': instance.name,
      'vehicle': instance.vehicle,
      'status': instance.status,
      'is_online': instance.isOnline,
      'rating': instance.rating,
      'active_order_ids': instance.activeOrderIds,
      'completed_deliveries': instance.completedDeliveries,
    };

_Earnings _$EarningsFromJson(Map<String, dynamic> json) => _Earnings(
  balanceKobo: (json['balance_kobo'] as num).toInt(),
  pendingPayoutsKobo: (json['pending_payouts_kobo'] as num).toInt(),
  availableKobo: (json['available_kobo'] as num).toInt(),
  deliveriesCompleted: (json['deliveries_completed'] as num).toInt(),
  earnedLast7DaysKobo: (json['earned_last7_days_kobo'] as num).toInt(),
  cashHeldKobo: (json['cash_held_kobo'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$EarningsToJson(_Earnings instance) => <String, dynamic>{
  'balance_kobo': instance.balanceKobo,
  'pending_payouts_kobo': instance.pendingPayoutsKobo,
  'available_kobo': instance.availableKobo,
  'deliveries_completed': instance.deliveriesCompleted,
  'earned_last7_days_kobo': instance.earnedLast7DaysKobo,
  'cash_held_kobo': instance.cashHeldKobo,
};

_ChatApproval _$ChatApprovalFromJson(Map<String, dynamic> json) =>
    _ChatApproval(
      tool: json['tool'] as String,
      toolCallId: json['tool_call_id'] as String,
      preview:
          json['preview'] as Map<String, dynamic>? ?? const <String, dynamic>{},
    );

Map<String, dynamic> _$ChatApprovalToJson(_ChatApproval instance) =>
    <String, dynamic>{
      'tool': instance.tool,
      'tool_call_id': instance.toolCallId,
      'preview': instance.preview,
    };

_ChatResponse _$ChatResponseFromJson(Map<String, dynamic> json) =>
    _ChatResponse(
      threadId: json['thread_id'] as String,
      status: json['status'] as String,
      reply: json['reply'] as String?,
      agent: json['agent'] as String?,
      cards:
          (json['cards'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          const <Map<String, dynamic>>[],
      approval: json['approval'] == null
          ? null
          : ChatApproval.fromJson(json['approval'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ChatResponseToJson(_ChatResponse instance) =>
    <String, dynamic>{
      'thread_id': instance.threadId,
      'status': instance.status,
      'reply': ?instance.reply,
      'agent': ?instance.agent,
      'cards': instance.cards,
      'approval': ?instance.approval?.toJson(),
    };

_PromoBadge _$PromoBadgeFromJson(Map<String, dynamic> json) =>
    _PromoBadge(code: json['code'] as String, label: json['label'] as String);

Map<String, dynamic> _$PromoBadgeToJson(_PromoBadge instance) =>
    <String, dynamic>{'code': instance.code, 'label': instance.label};

_ServiceInfo _$ServiceInfoFromJson(Map<String, dynamic> json) => _ServiceInfo(
  id: json['id'] as String,
  name: json['name'] as String,
  tagline: json['tagline'] as String? ?? '',
  available: json['available'] as bool? ?? true,
  merchants: (json['merchants'] as num?)?.toInt(),
  options:
      (json['options'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  comingSoon:
      (json['coming_soon'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
  cities:
      (json['cities'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
);

Map<String, dynamic> _$ServiceInfoToJson(_ServiceInfo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'tagline': instance.tagline,
      'available': instance.available,
      'merchants': ?instance.merchants,
      'options': instance.options,
      'coming_soon': instance.comingSoon,
      'cities': instance.cities,
    };

_BrowseCategory _$BrowseCategoryFromJson(Map<String, dynamic> json) =>
    _BrowseCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      emoji: json['emoji'] as String? ?? '',
      merchants: (json['merchants'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$BrowseCategoryToJson(_BrowseCategory instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'emoji': instance.emoji,
      'merchants': instance.merchants,
    };

_PlaceArea _$PlaceAreaFromJson(Map<String, dynamic> json) => _PlaceArea(
  name: json['name'] as String,
  city: json['city'] as String,
  lat: (json['lat'] as num).toDouble(),
  lng: (json['lng'] as num).toDouble(),
);

Map<String, dynamic> _$PlaceAreaToJson(_PlaceArea instance) =>
    <String, dynamic>{
      'name': instance.name,
      'city': instance.city,
      'lat': instance.lat,
      'lng': instance.lng,
    };

_ParcelStop _$ParcelStopFromJson(Map<String, dynamic> json) => _ParcelStop(
  name: json['name'] as String,
  phone: json['phone'] as String,
  line1: json['line1'] as String,
  area: json['area'] as String?,
  city: json['city'] as String? ?? 'Lagos',
  location: GeoPoint.fromJson(json['location'] as Map<String, dynamic>),
  instructions: json['instructions'] as String?,
);

Map<String, dynamic> _$ParcelStopToJson(_ParcelStop instance) =>
    <String, dynamic>{
      'name': instance.name,
      'phone': instance.phone,
      'line1': instance.line1,
      'area': ?instance.area,
      'city': instance.city,
      'location': instance.location.toJson(),
      'instructions': ?instance.instructions,
    };

_ParcelDetails _$ParcelDetailsFromJson(Map<String, dynamic> json) =>
    _ParcelDetails(
      pickup: ParcelStop.fromJson(json['pickup'] as Map<String, dynamic>),
      dropoff: ParcelStop.fromJson(json['dropoff'] as Map<String, dynamic>),
      size: json['size'] as String? ?? 'small',
      category: json['category'] as String? ?? 'other',
      description: json['description'] as String? ?? '',
      city: json['city'] as String? ?? 'lagos',
      codAmountKobo: (json['cod_amount_kobo'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ParcelDetailsToJson(_ParcelDetails instance) =>
    <String, dynamic>{
      'pickup': instance.pickup.toJson(),
      'dropoff': instance.dropoff.toJson(),
      'size': instance.size,
      'category': instance.category,
      'description': instance.description,
      'city': instance.city,
      'cod_amount_kobo': ?instance.codAmountKobo,
    };

_ParcelQuote _$ParcelQuoteFromJson(Map<String, dynamic> json) => _ParcelQuote(
  id: json['id'] as String,
  details: ParcelDetails.fromJson(json['details'] as Map<String, dynamic>),
  breakdown: PriceBreakdown.fromJson(json['breakdown'] as Map<String, dynamic>),
  distanceKm: (json['distance_km'] as num).toDouble(),
  etaMinutes: (json['eta_minutes'] as num).toInt(),
  estimatedDeliveryAt: DateTime.parse(json['estimated_delivery_at'] as String),
  scheduledFor: json['scheduled_for'] == null
      ? null
      : DateTime.parse(json['scheduled_for'] as String),
  expiresAt: DateTime.parse(json['expires_at'] as String),
);

Map<String, dynamic> _$ParcelQuoteToJson(_ParcelQuote instance) =>
    <String, dynamic>{
      'id': instance.id,
      'details': instance.details.toJson(),
      'breakdown': instance.breakdown.toJson(),
      'distance_km': instance.distanceKm,
      'eta_minutes': instance.etaMinutes,
      'estimated_delivery_at': instance.estimatedDeliveryAt.toIso8601String(),
      'scheduled_for': ?instance.scheduledFor?.toIso8601String(),
      'expires_at': instance.expiresAt.toIso8601String(),
    };

_VerticalSpend _$VerticalSpendFromJson(Map<String, dynamic> json) =>
    _VerticalSpend(
      orders: (json['orders'] as num?)?.toInt() ?? 0,
      spentKobo: (json['spent_kobo'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$VerticalSpendToJson(_VerticalSpend instance) =>
    <String, dynamic>{
      'orders': instance.orders,
      'spent_kobo': instance.spentKobo,
    };

_FavouriteMerchant _$FavouriteMerchantFromJson(Map<String, dynamic> json) =>
    _FavouriteMerchant(
      id: json['id'] as String,
      name: json['name'] as String,
      orders: (json['orders'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$FavouriteMerchantToJson(_FavouriteMerchant instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'orders': instance.orders,
    };

_OrderSummary _$OrderSummaryFromJson(Map<String, dynamic> json) =>
    _OrderSummary(
      ordersCount: (json['orders_count'] as num?)?.toInt() ?? 0,
      completedCount: (json['completed_count'] as num?)?.toInt() ?? 0,
      inProgressCount: (json['in_progress_count'] as num?)?.toInt() ?? 0,
      totalSpentKobo: (json['total_spent_kobo'] as num?)?.toInt() ?? 0,
      thisMonthSpentKobo: (json['this_month_spent_kobo'] as num?)?.toInt() ?? 0,
      refundedKobo: (json['refunded_kobo'] as num?)?.toInt() ?? 0,
      byVertical:
          (json['by_vertical'] as Map<String, dynamic>?)?.map(
            (k, e) =>
                MapEntry(k, VerticalSpend.fromJson(e as Map<String, dynamic>)),
          ) ??
          const <String, VerticalSpend>{},
      favouriteMerchant: json['favourite_merchant'] == null
          ? null
          : FavouriteMerchant.fromJson(
              json['favourite_merchant'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$OrderSummaryToJson(_OrderSummary instance) =>
    <String, dynamic>{
      'orders_count': instance.ordersCount,
      'completed_count': instance.completedCount,
      'in_progress_count': instance.inProgressCount,
      'total_spent_kobo': instance.totalSpentKobo,
      'this_month_spent_kobo': instance.thisMonthSpentKobo,
      'refunded_kobo': instance.refundedKobo,
      'by_vertical': instance.byVertical.map((k, e) => MapEntry(k, e.toJson())),
      'favourite_merchant': ?instance.favouriteMerchant?.toJson(),
    };

_SupportContacts _$SupportContactsFromJson(Map<String, dynamic> json) =>
    _SupportContacts(
      whatsapp: json['whatsapp'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      hours: json['hours'] as String? ?? '',
      placeholders: json['placeholders'] as bool? ?? true,
    );

Map<String, dynamic> _$SupportContactsToJson(_SupportContacts instance) =>
    <String, dynamic>{
      'whatsapp': instance.whatsapp,
      'phone': instance.phone,
      'email': instance.email,
      'hours': instance.hours,
      'placeholders': instance.placeholders,
    };
