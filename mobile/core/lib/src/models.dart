// Gud Meal API models (mirrors services/api JSON). All money values are integer kobo.
import 'package:freezed_annotation/freezed_annotation.dart';

part 'models.freezed.dart';
part 'models.g.dart';

@freezed
abstract class GeoPoint with _$GeoPoint {
  const factory GeoPoint({required double lat, required double lng}) = _GeoPoint;
  factory GeoPoint.fromJson(Map<String, dynamic> json) => _$GeoPointFromJson(json);
}

@freezed
abstract class RestaurantCard with _$RestaurantCard {
  const factory RestaurantCard({
    required String id,
    required String name,
    @Default('') String description,
    @Default(<String>[]) List<String> cuisines,
    @Default('') String area,
    @Default(0) double rating,
    @Default(0) int ratingCount,
    @Default(false) bool isOpen,
    @Default(true) bool isAcceptingOrders,
    @Default(false) bool isFeatured,
    String? coverUrl,
    double? distanceKm,
    int? etaMinutes,
    int? deliveryFeeKobo,
    bool? deliversToLocation,
  }) = _RestaurantCard;
  factory RestaurantCard.fromJson(Map<String, dynamic> json) => _$RestaurantCardFromJson(json);
}

@freezed
abstract class OptionChoice with _$OptionChoice {
  const factory OptionChoice({
    required String id,
    required String name,
    @Default(0) int priceDeltaKobo,
    @Default(true) bool isAvailable,
  }) = _OptionChoice;
  factory OptionChoice.fromJson(Map<String, dynamic> json) => _$OptionChoiceFromJson(json);
}

@freezed
abstract class OptionGroup with _$OptionGroup {
  const factory OptionGroup({
    required String id,
    required String name,
    @Default(0) int minSelect,
    @Default(1) int maxSelect,
    @Default(<OptionChoice>[]) List<OptionChoice> choices,
  }) = _OptionGroup;
  factory OptionGroup.fromJson(Map<String, dynamic> json) => _$OptionGroupFromJson(json);
}

@freezed
abstract class MenuItem with _$MenuItem {
  const factory MenuItem({
    required String id,
    required String restaurantId,
    required String name,
    @Default('') String description,
    required int priceKobo,
    @Default('main') String kind,
    @Default(<String>[]) List<String> allergens,
    @Default(<String>[]) List<String> dietary,
    @Default(1) int serves,
    @Default(0) int spiceLevel,
    @Default(true) bool isAvailable,
    @Default(<String>[]) List<String> optionGroupIds,
  }) = _MenuItem;
  factory MenuItem.fromJson(Map<String, dynamic> json) => _$MenuItemFromJson(json);
}

@freezed
abstract class MenuCategory with _$MenuCategory {
  const factory MenuCategory({required String id, required String name}) = _MenuCategory;
  factory MenuCategory.fromJson(Map<String, dynamic> json) => _$MenuCategoryFromJson(json);
}

@freezed
abstract class MenuSection with _$MenuSection {
  const factory MenuSection({required MenuCategory category, @Default(<MenuItem>[]) List<MenuItem> items}) = _MenuSection;
  factory MenuSection.fromJson(Map<String, dynamic> json) => _$MenuSectionFromJson(json);
}

@freezed
abstract class RestaurantDetail with _$RestaurantDetail {
  const factory RestaurantDetail({
    required RestaurantCard restaurant,
    @Default('') String address,
    @Default(20) int avgPrepMinutes,
    @Default(<MenuSection>[]) List<MenuSection> sections,
    @Default(<String, OptionGroup>{}) Map<String, OptionGroup> optionGroups,
  }) = _RestaurantDetail;
  factory RestaurantDetail.fromJson(Map<String, dynamic> json) => _$RestaurantDetailFromJson(json);
}

@freezed
abstract class OptionSelection with _$OptionSelection {
  const factory OptionSelection({required String groupId, @Default(<String>[]) List<String> choiceIds}) = _OptionSelection;
  factory OptionSelection.fromJson(Map<String, dynamic> json) => _$OptionSelectionFromJson(json);
}

@freezed
abstract class CartLine with _$CartLine {
  const factory CartLine({
    required String itemId,
    required int quantity,
    @Default(<OptionSelection>[]) List<OptionSelection> selections,
    String? notes,
  }) = _CartLine;
  factory CartLine.fromJson(Map<String, dynamic> json) => _$CartLineFromJson(json);
}

@freezed
abstract class DeliveryAddress with _$DeliveryAddress {
  const factory DeliveryAddress({
    String? label,
    required String line1,
    String? area,
    @Default('Lagos') String city,
    @Default('Lagos') String state,
    required GeoPoint location,
    String? instructions,
    String? contactPhone,
  }) = _DeliveryAddress;
  factory DeliveryAddress.fromJson(Map<String, dynamic> json) => _$DeliveryAddressFromJson(json);
}

@freezed
abstract class PricedLine with _$PricedLine {
  const factory PricedLine({
    required String itemId,
    required String name,
    required int quantity,
    required int lineTotalKobo,
    @Default(<String>[]) List<String> selectionLabels,
  }) = _PricedLine;
  factory PricedLine.fromJson(Map<String, dynamic> json) => _$PricedLineFromJson(json);
}

@freezed
abstract class PriceBreakdown with _$PriceBreakdown {
  const factory PriceBreakdown({
    required int subtotalKobo,
    @Default(0) int deliveryFeeKobo,
    @Default(0) int serviceFeeKobo,
    @Default(0) int smallOrderFeeKobo,
    @Default(0) int vatKobo,
    @Default(0) int discountKobo,
    required int totalKobo,
    String? voucherCode,
  }) = _PriceBreakdown;
  factory PriceBreakdown.fromJson(Map<String, dynamic> json) => _$PriceBreakdownFromJson(json);
}

@freezed
abstract class Quote with _$Quote {
  const factory Quote({
    required String id,
    required String restaurantName,
    @Default(<PricedLine>[]) List<PricedLine> lines,
    required PriceBreakdown breakdown,
    required String fulfillment,
    required int etaMinutes,
    required DateTime estimatedDeliveryAt,
    required DateTime expiresAt,
  }) = _Quote;
  factory Quote.fromJson(Map<String, dynamic> json) => _$QuoteFromJson(json);
}

@freezed
abstract class OrderProgress with _$OrderProgress {
  const factory OrderProgress({required int step, @Default(5) int totalSteps, required String label}) = _OrderProgress;
  factory OrderProgress.fromJson(Map<String, dynamic> json) => _$OrderProgressFromJson(json);
}

@freezed
abstract class Order with _$Order {
  const factory Order({
    required String id,
    required String shortCode,
    required String status,
    required String restaurantName,
    @Default('delivery') String fulfillment,
    @Default(<PricedLine>[]) List<PricedLine> lines,
    PriceBreakdown? breakdown,
    DeliveryAddress? deliveryAddress,
    OrderProgress? progress,
    String? riderName,
    String? customerName,
    String? restaurantAddress,
    GeoPoint? restaurantLocation,
    DateTime? estimatedDeliveryAt,
    DateTime? readyAt,
    DateTime? createdAt,
    int? riderPayKobo,
    @Default(false) bool reviewed,
  }) = _Order;
  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);
}

@freezed
abstract class CheckoutResult with _$CheckoutResult {
  const factory CheckoutResult({
    required String orderId,
    required String reference,
    required String authorizationUrl,
    required int amountKobo,
    required String provider,
  }) = _CheckoutResult;
  factory CheckoutResult.fromJson(Map<String, dynamic> json) => _$CheckoutResultFromJson(json);
}

@freezed
abstract class Tracking with _$Tracking {
  const factory Tracking({
    required String status,
    String? riderName,
    GeoPoint? riderLocation,
    int? etaMinutes,
    DateTime? estimatedDeliveryAt,
  }) = _Tracking;
  factory Tracking.fromJson(Map<String, dynamic> json) => _$TrackingFromJson(json);
}

@freezed
abstract class DeliveryOffer with _$DeliveryOffer {
  const factory DeliveryOffer({
    required String id,
    required String orderId,
    required String restaurantName,
    required double distanceToRestaurantKm,
    required int payoutKobo,
    required DateTime expiresAt,
    required GeoPoint pickup,
    GeoPoint? dropoff,
    String? dropoffArea,
  }) = _DeliveryOffer;
  factory DeliveryOffer.fromJson(Map<String, dynamic> json) => _$DeliveryOfferFromJson(json);
}

@freezed
abstract class RiderProfile with _$RiderProfile {
  const factory RiderProfile({
    required String uid,
    required String name,
    @Default('motorcycle') String vehicle,
    @Default('pending') String status,
    @Default(false) bool isOnline,
    @Default(5) double rating,
    @Default(<String>[]) List<String> activeOrderIds,
    @Default(0) int completedDeliveries,
  }) = _RiderProfile;
  factory RiderProfile.fromJson(Map<String, dynamic> json) => _$RiderProfileFromJson(json);
}

@freezed
abstract class Earnings with _$Earnings {
  const factory Earnings({
    required int balanceKobo,
    required int pendingPayoutsKobo,
    required int availableKobo,
    required int deliveriesCompleted,
    required int earnedLast7DaysKobo,
  }) = _Earnings;
  factory Earnings.fromJson(Map<String, dynamic> json) => _$EarningsFromJson(json);
}

@freezed
abstract class ChatApproval with _$ChatApproval {
  const factory ChatApproval({
    required String tool,
    required String toolCallId,
    @Default(<String, dynamic>{}) Map<String, dynamic> preview,
  }) = _ChatApproval;
  factory ChatApproval.fromJson(Map<String, dynamic> json) => _$ChatApprovalFromJson(json);
}

@freezed
abstract class ChatResponse with _$ChatResponse {
  const factory ChatResponse({
    required String threadId,
    required String status,
    String? reply,
    String? agent,
    @Default(<Map<String, dynamic>>[]) List<Map<String, dynamic>> cards,
    ChatApproval? approval,
  }) = _ChatResponse;
  factory ChatResponse.fromJson(Map<String, dynamic> json) => _$ChatResponseFromJson(json);
}
