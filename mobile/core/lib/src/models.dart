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
    @Default('food') String vertical,
    @Default('lagos') String city,
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
    @Default(true) bool supportsPickup,
    @Default(true) bool supportsDelivery,
    @Default(<PromoBadge>[]) List<PromoBadge> promotions,
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
    String? unitLabel,
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
    @Default(0) int codFeeKobo,
    @Default(0) int linehaulFeeKobo,
    @Default(0) int pickupFeeKobo,
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
  const factory OrderProgress({
    required int step,
    @Default(5) int totalSteps,
    required String label,
    /// Waybills use their own steps (Booked, At the hub, On the way, Arrived, Delivered).
    @Default(<String>[]) List<String> steps,
  }) = _OrderProgress;
  factory OrderProgress.fromJson(Map<String, dynamic> json) => _$OrderProgressFromJson(json);
}

@freezed
abstract class Order with _$Order {
  const factory Order({
    required String id,
    required String shortCode,
    @Default('food') String vertical,
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
    ParcelDetails? parcel,
    @Default(0) int refundTotalKobo,
    @Default(OrderPayment()) OrderPayment payment,
    DateTime? cashCollectedAt,
    // Rider view: cash to take at the door ('cash' = pay on delivery) and the amount (0 when prepaid).
    String? paymentMethod,
    @Default(0) int collectCashKobo,
    /// Interstate waybill details (vertical 'waybill').
    WaybillDetails? waybill,
    /// Rider view of a waybill's rider job: 'first_mile' ends with hub staff, 'last_mile' at the door.
    String? legKind,
    @Default(false) bool hubHandover,
  }) = _Order;
  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);
}

/// How an order is paid: a gateway (paystack, flutterwave…), the wallet, or cash on delivery.
@freezed
abstract class OrderPayment with _$OrderPayment {
  const factory OrderPayment({String? provider, String? reference, @Default('unpaid') String status, DateTime? paidAt}) =
      _OrderPayment;
  factory OrderPayment.fromJson(Map<String, dynamic> json) => _$OrderPaymentFromJson(json);
}

@freezed
abstract class CheckoutResult with _$CheckoutResult {
  const factory CheckoutResult({
    required String orderId,
    @Default('') String status,
    required String reference,
    /// Null for wallet and pay-on-delivery checkouts: the order is already placed.
    String? authorizationUrl,
    required int amountKobo,
    required String provider,
    String? failoverFrom,
  }) = _CheckoutResult;
  factory CheckoutResult.fromJson(Map<String, dynamic> json) => _$CheckoutResultFromJson(json);
}

@freezed
abstract class PaymentMethodOption with _$PaymentMethodOption {
  const factory PaymentMethodOption({
    required String id,
    required String label,
    @Default(false) bool available,
    String? reason,
    int? balanceKobo,
    int? shortByKobo,
  }) = _PaymentMethodOption;
  factory PaymentMethodOption.fromJson(Map<String, dynamic> json) => _$PaymentMethodOptionFromJson(json);
}

@freezed
abstract class PaymentOptions with _$PaymentOptions {
  const factory PaymentOptions({
    required String orderId,
    required int totalKobo,
    @Default(<PaymentMethodOption>[]) List<PaymentMethodOption> methods,
  }) = _PaymentOptions;
  factory PaymentOptions.fromJson(Map<String, dynamic> json) => _$PaymentOptionsFromJson(json);
}

@freezed
abstract class WalletTransaction with _$WalletTransaction {
  const factory WalletTransaction({
    required String id,
    required String kind,
    @Default('') String description,
    String? reference,
    String? orderId,
    required DateTime createdAt,
    @Default('in') String direction,
    required int amountKobo,
  }) = _WalletTransaction;
  factory WalletTransaction.fromJson(Map<String, dynamic> json) => _$WalletTransactionFromJson(json);
}

@freezed
abstract class WalletLimits with _$WalletLimits {
  const factory WalletLimits({
    @Default(50000) int minTopupKobo,
    @Default(10000000) int maxTopupKobo,
    @Default(30000000) int maxBalanceKobo,
  }) = _WalletLimits;
  factory WalletLimits.fromJson(Map<String, dynamic> json) => _$WalletLimitsFromJson(json);
}

/// Cash-on-delivery money collected for a seller (vendor COD on packages).
@freezed
abstract class SellerSummary with _$SellerSummary {
  const factory SellerSummary({
    @Default(0) int codBalanceKobo,
    @Default(0) int pendingPayoutsKobo,
    @Default(0) int availableKobo,
    @Default(100000) int minPayoutKobo,
  }) = _SellerSummary;
  factory SellerSummary.fromJson(Map<String, dynamic> json) => _$SellerSummaryFromJson(json);
}

@freezed
abstract class WalletOverview with _$WalletOverview {
  const factory WalletOverview({
    @Default(0) int balanceKobo,
    @Default(true) bool enabled,
    @Default(WalletLimits()) WalletLimits limits,
    @Default(false) bool refundToWallet,
    @Default(<WalletTransaction>[]) List<WalletTransaction> transactions,
    SellerSummary? seller,
  }) = _WalletOverview;
  factory WalletOverview.fromJson(Map<String, dynamic> json) => _$WalletOverviewFromJson(json);
}

// ------------------------------------------------------------------------------------------ waybill

@freezed
abstract class WaybillParty with _$WaybillParty {
  const factory WaybillParty({
    required String name,
    required String phone,
    String? line1,
    String? area,
    GeoPoint? location,
    String? instructions,
  }) = _WaybillParty;
  factory WaybillParty.fromJson(Map<String, dynamic> json) => _$WaybillPartyFromJson(json);
}

@freezed
abstract class WaybillDetails with _$WaybillDetails {
  const factory WaybillDetails({
    String? trackingCode,
    @Default('') String originCity,
    @Default('') String destinationCity,
    @Default('') String originCityName,
    @Default('') String destinationCityName,
    @Default('') String originHubId,
    @Default('') String destinationHubId,
    @Default('') String originHubName,
    @Default('') String destinationHubName,
    @Default('') String destinationHubAddress,
    @Default('') String destinationHubHours,
    @Default('pickup') String firstMile,
    @Default('door') String lastMile,
    required WaybillParty sender,
    required WaybillParty recipient,
    @Default('small') String size,
    @Default(1) double weightKg,
    @Default('other') String category,
    @Default('') String description,
    int? codAmountKobo,
    @Default('') String carrierName,
    String? stage,
    String? etaFrom,
    String? etaTo,
  }) = _WaybillDetails;
  factory WaybillDetails.fromJson(Map<String, dynamic> json) => _$WaybillDetailsFromJson(json);
}

@freezed
abstract class WaybillQuote with _$WaybillQuote {
  const factory WaybillQuote({
    required String id,
    required WaybillDetails details,
    required PriceBreakdown breakdown,
    @Default('') String etaText,
    required DateTime expiresAt,
  }) = _WaybillQuote;
  factory WaybillQuote.fromJson(Map<String, dynamic> json) => _$WaybillQuoteFromJson(json);
}

@freezed
abstract class WaybillHub with _$WaybillHub {
  const factory WaybillHub({
    required String id,
    required String name,
    required String city,
    @Default('') String address,
    @Default('') String hours,
    @Default(true) bool isSample,
  }) = _WaybillHub;
  factory WaybillHub.fromJson(Map<String, dynamic> json) => _$WaybillHubFromJson(json);
}

@freezed
abstract class WaybillOrigin with _$WaybillOrigin {
  const factory WaybillOrigin({
    required String id,
    required String name,
    @Default(false) bool homePickup,
    @Default(<WaybillHub>[]) List<WaybillHub> dropoffHubs,
  }) = _WaybillOrigin;
  factory WaybillOrigin.fromJson(Map<String, dynamic> json) => _$WaybillOriginFromJson(json);
}

@freezed
abstract class WaybillDestination with _$WaybillDestination {
  const factory WaybillDestination({
    required String city,
    required String name,
    @Default(false) bool doorDelivery,
    @Default(<int>[1, 2]) List<int> transitDays,
    @Default(0) int fromKobo,
    @Default('') String carrier,
    @Default(<WaybillHub>[]) List<WaybillHub> collectionHubs,
  }) = _WaybillDestination;
  factory WaybillDestination.fromJson(Map<String, dynamic> json) => _$WaybillDestinationFromJson(json);
}

@freezed
abstract class WaybillDestinations with _$WaybillDestinations {
  const factory WaybillDestinations({
    @Default(<WaybillHub>[]) List<WaybillHub> dropoffHubs,
    @Default(<WaybillDestination>[]) List<WaybillDestination> destinations,
  }) = _WaybillDestinations;
  factory WaybillDestinations.fromJson(Map<String, dynamic> json) => _$WaybillDestinationsFromJson(json);
}

@freezed
abstract class WaybillScan with _$WaybillScan {
  const factory WaybillScan({required String stage, required String label, required DateTime at, String? place}) =
      _WaybillScan;
  factory WaybillScan.fromJson(Map<String, dynamic> json) => _$WaybillScanFromJson(json);
}

@freezed
abstract class WaybillTracking with _$WaybillTracking {
  const factory WaybillTracking({
    required String trackingCode,
    @Default('') String origin,
    @Default('') String destination,
    @Default('') String label,
    @Default(0) int step,
    @Default(<String>[]) List<String> steps,
    @Default('') String etaText,
    @Default('door') String lastMile,
    @Default(<WaybillScan>[]) List<WaybillScan> milestones,
    @Default(false) bool delivered,
  }) = _WaybillTracking;
  factory WaybillTracking.fromJson(Map<String, dynamic> json) => _$WaybillTrackingFromJson(json);
}

@freezed
abstract class TopUpResult with _$TopUpResult {
  const factory TopUpResult({
    required String reference,
    required String provider,
    String? authorizationUrl,
    required int amountKobo,
  }) = _TopUpResult;
  factory TopUpResult.fromJson(Map<String, dynamic> json) => _$TopUpResultFromJson(json);
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
    /// Cash collected at the door that the rider still has to hand in (netted off before withdrawals).
    @Default(0) int cashHeldKobo,
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


// ------------------------------------------------------------------------------------- multi-service
@freezed
abstract class PromoBadge with _$PromoBadge {
  const factory PromoBadge({required String code, required String label}) = _PromoBadge;
  factory PromoBadge.fromJson(Map<String, dynamic> json) => _$PromoBadgeFromJson(json);
}

/// A Gud Meal service: food, beauty or parcel (the home-screen bubbles).
@freezed
abstract class ServiceInfo with _$ServiceInfo {
  const factory ServiceInfo({
    required String id,
    required String name,
    @Default('') String tagline,
    @Default(true) bool available,
    int? merchants,
    @Default(<String>[]) List<String> options,
    @Default(<String>[]) List<String> comingSoon,
    @Default(<String>[]) List<String> cities,
  }) = _ServiceInfo;
  factory ServiceInfo.fromJson(Map<String, dynamic> json) => _$ServiceInfoFromJson(json);
}

@freezed
abstract class BrowseCategory with _$BrowseCategory {
  const factory BrowseCategory({required String id, required String name, @Default('') String emoji, @Default(0) int merchants}) =
      _BrowseCategory;
  factory BrowseCategory.fromJson(Map<String, dynamic> json) => _$BrowseCategoryFromJson(json);
}

/// A neighbourhood with an approximate centre, used for addresses without a map pin.
@freezed
abstract class PlaceArea with _$PlaceArea {
  const factory PlaceArea({required String name, required String city, required double lat, required double lng}) = _PlaceArea;
  factory PlaceArea.fromJson(Map<String, dynamic> json) => _$PlaceAreaFromJson(json);
}

@freezed
abstract class ParcelStop with _$ParcelStop {
  const factory ParcelStop({
    required String name,
    required String phone,
    required String line1,
    String? area,
    @Default('Lagos') String city,
    required GeoPoint location,
    String? instructions,
  }) = _ParcelStop;
  factory ParcelStop.fromJson(Map<String, dynamic> json) => _$ParcelStopFromJson(json);
}

@freezed
abstract class ParcelDetails with _$ParcelDetails {
  const factory ParcelDetails({
    required ParcelStop pickup,
    required ParcelStop dropoff,
    @Default('small') String size,
    @Default('other') String category,
    @Default('') String description,
    @Default('lagos') String city,
    /// Cash the rider collects from the recipient for the sender (vendor cash on delivery).
    int? codAmountKobo,
  }) = _ParcelDetails;
  factory ParcelDetails.fromJson(Map<String, dynamic> json) => _$ParcelDetailsFromJson(json);
}

@freezed
abstract class ParcelQuote with _$ParcelQuote {
  const factory ParcelQuote({
    required String id,
    required ParcelDetails details,
    required PriceBreakdown breakdown,
    required double distanceKm,
    required int etaMinutes,
    required DateTime estimatedDeliveryAt,
    DateTime? scheduledFor,
    required DateTime expiresAt,
  }) = _ParcelQuote;
  factory ParcelQuote.fromJson(Map<String, dynamic> json) => _$ParcelQuoteFromJson(json);
}

@freezed
abstract class VerticalSpend with _$VerticalSpend {
  const factory VerticalSpend({@Default(0) int orders, @Default(0) int spentKobo}) = _VerticalSpend;
  factory VerticalSpend.fromJson(Map<String, dynamic> json) => _$VerticalSpendFromJson(json);
}

@freezed
abstract class FavouriteMerchant with _$FavouriteMerchant {
  const factory FavouriteMerchant({required String id, required String name, @Default(0) int orders}) = _FavouriteMerchant;
  factory FavouriteMerchant.fromJson(Map<String, dynamic> json) => _$FavouriteMerchantFromJson(json);
}

/// Totals across a customer's paid orders (net of refunds), from /v1/me/order-summary.
@freezed
abstract class OrderSummary with _$OrderSummary {
  const factory OrderSummary({
    @Default(0) int ordersCount,
    @Default(0) int completedCount,
    @Default(0) int inProgressCount,
    @Default(0) int totalSpentKobo,
    @Default(0) int thisMonthSpentKobo,
    @Default(0) int refundedKobo,
    @Default(<String, VerticalSpend>{}) Map<String, VerticalSpend> byVertical,
    FavouriteMerchant? favouriteMerchant,
  }) = _OrderSummary;
  factory OrderSummary.fromJson(Map<String, dynamic> json) => _$OrderSummaryFromJson(json);
}

@freezed
abstract class SupportContacts with _$SupportContacts {
  const factory SupportContacts({
    @Default('') String whatsapp,
    @Default('') String phone,
    @Default('') String email,
    @Default('') String hours,
    @Default(true) bool placeholders,
  }) = _SupportContacts;
  factory SupportContacts.fromJson(Map<String, dynamic> json) => _$SupportContactsFromJson(json);
}
