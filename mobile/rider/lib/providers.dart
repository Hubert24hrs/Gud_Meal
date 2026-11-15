import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gud_meal_core/gud_meal_core.dart';

final configProvider = Provider<AppConfig>((ref) => AppConfig.fromEnvironment());
final authRepositoryProvider = Provider<AuthRepository>((ref) => throw UnimplementedError('override in main'));
final authStateProvider = StreamProvider<GmUser?>((ref) => ref.watch(authRepositoryProvider).authStateChanges());

final apiProvider = Provider<GudMealApi>((ref) {
  final auth = ref.watch(authRepositoryProvider);
  return GudMealApi(baseUrl: ref.watch(configProvider).apiUrl, token: auth.idToken);
});

/// Location port: Geolocator on devices, a fake in tests.
abstract class LocationSource {
  Future<bool> ensurePermission();
  Stream<(GeoPoint, double)> positions();
}

class GeolocatorSource implements LocationSource {
  @override
  Future<bool> ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
    return permission == LocationPermission.always || permission == LocationPermission.whileInUse;
  }

  @override
  Stream<(GeoPoint, double)> positions() => Geolocator.getPositionStream(
        // Battery-aware: update when the rider moves 25 m; the API rate-limits pings server-side too.
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 25),
      ).map((p) => (GeoPoint(lat: p.latitude, lng: p.longitude), p.accuracy));
}

final locationSourceProvider = Provider<LocationSource>((ref) => GeolocatorSource());

final riderProfileProvider = FutureProvider<RiderProfile>((ref) => ref.watch(apiProvider).riderProfile());
final offersProvider = FutureProvider<List<DeliveryOffer>>((ref) => ref.watch(apiProvider).offers());
final activeDeliveriesProvider = FutureProvider<List<Order>>((ref) => ref.watch(apiProvider).activeDeliveries());
final earningsProvider = FutureProvider<Earnings>((ref) => ref.watch(apiProvider).earnings());

/// Streams the rider's GPS position to the API while online. Poor connectivity: failed pings are dropped
/// (the next position supersedes them) rather than queued, so the server never receives stale bursts.
/// The API refuses positions from offline riders (409); the reporter then stops sharing.
class LocationReporter {
  LocationReporter(this._api, this._source);
  final GudMealApi _api;
  final LocationSource _source;
  StreamSubscription<(GeoPoint, double)>? _sub;
  GeoPoint? last;

  bool get active => _sub != null;

  /// True when the server said this rider is offline and sharing stopped.
  bool stoppedByServer = false;

  Future<bool> ensurePermission() => _source.ensurePermission();

  Future<bool> start() async {
    if (_sub != null) return true;
    if (!await _source.ensurePermission()) return false;
    stoppedByServer = false;
    _sub = _source.positions().listen((event) async {
      last = event.$1;
      try {
        await _api.sendLocation(event.$1, accuracyM: event.$2);
      } on ApiException catch (e) {
        if (e.status == 409) {
          stoppedByServer = true;
          await stop();
        }
        // Otherwise offline or rate limited: skip this ping.
      } catch (_) {
        // Skip this ping.
      }
    });
    return true;
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }
}

final locationReporterProvider = Provider<LocationReporter>((ref) {
  final reporter = LocationReporter(ref.watch(apiProvider), ref.watch(locationSourceProvider));
  ref.onDispose(reporter.stop);
  return reporter;
});

/// Goes online or offline in the order the API needs: online first, then share positions; stop sharing first,
/// then go offline. Returns a message to show, or null on success.
Future<String?> setRiderOnline(GudMealApi api, LocationReporter reporter, bool online) async {
  try {
    if (online) {
      if (!await reporter.ensurePermission()) return 'Location permission is required to go online.';
      await api.setOnline(true);
      await reporter.start();
    } else {
      await reporter.stop();
      await api.setOnline(false);
    }
    return null;
  } on ApiException catch (e) {
    await reporter.stop();
    return e.message;
  }
}
