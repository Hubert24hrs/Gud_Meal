import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gud_meal_core/gud_meal_core.dart';

/// Overridden in main() (Firebase) and in tests (fakes).
final configProvider = Provider<AppConfig>((ref) => AppConfig.fromEnvironment());
final authRepositoryProvider = Provider<AuthRepository>((ref) => throw UnimplementedError('override in main'));

final authStateProvider = StreamProvider<GmUser?>((ref) => ref.watch(authRepositoryProvider).authStateChanges());

final apiProvider = Provider<GudMealApi>((ref) {
  final auth = ref.watch(authRepositoryProvider);
  return GudMealApi(baseUrl: ref.watch(configProvider).apiUrl, token: auth.idToken);
});

final agentsApiProvider = Provider<GudMealAgentsApi>((ref) {
  final auth = ref.watch(authRepositoryProvider);
  return GudMealAgentsApi(baseUrl: ref.watch(configProvider).agentsUrl, token: auth.idToken);
});

/// Launch areas in Lagos (production: Places autocomplete + geocoding).
class Area {
  const Area(this.name, this.location);
  final String name;
  final GeoPoint location;
}

const lagosAreas = [
  Area('Lekki Phase 1', GeoPoint(lat: 6.4474, lng: 3.4733)),
  Area('Victoria Island', GeoPoint(lat: 6.4281, lng: 3.4219)),
  Area('Ikoyi', GeoPoint(lat: 6.4520, lng: 3.4350)),
  Area('Oniru', GeoPoint(lat: 6.4366, lng: 3.4497)),
  Area('Yaba', GeoPoint(lat: 6.5095, lng: 3.3711)),
  Area('Surulere', GeoPoint(lat: 6.4969, lng: 3.3602)),
  Area('Ikeja GRA', GeoPoint(lat: 6.5833, lng: 3.3500)),
];

class AreaController extends Notifier<Area> {
  @override
  Area build() => lagosAreas.first;
  void select(Area area) => state = area;
}

final areaProvider = NotifierProvider<AreaController, Area>(AreaController.new);

final restaurantsProvider = FutureProvider<List<RestaurantCard>>((ref) {
  final area = ref.watch(areaProvider);
  return ref.watch(apiProvider).restaurants(near: area.location);
});

final restaurantDetailProvider = FutureProvider.family<RestaurantDetail, String>((ref, id) {
  return ref.watch(apiProvider).restaurant(id, near: ref.watch(areaProvider).location);
});

final myOrdersProvider = FutureProvider<List<Order>>((ref) => ref.watch(apiProvider).myOrders());
final orderProvider = FutureProvider.family<Order, String>((ref, id) => ref.watch(apiProvider).order(id));
final addressesProvider = FutureProvider<List<DeliveryAddress>>((ref) => ref.watch(apiProvider).addresses());
