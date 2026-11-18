import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'test_server.dart';

/// The parts of the test-server search that need sockets and files (phones; `test_server_stub.dart` is the browser).

const _apiPort = 8000;

/// What `GET /v1/health` of the GudMeals API says about itself (services/api/.../api/v1/public.py).
const _service = 'gudmeal-api';

/// True when the GudMeals API answers on [host]: its health answer names the service.
Future<bool> answersAsGudMeal(
  String host, {
  int port = _apiPort,
  Duration timeout = const Duration(milliseconds: 1800),
}) async {
  final client = HttpClient()..connectionTimeout = timeout;
  try {
    final request = await client.getUrl(Uri(scheme: 'http', host: host, port: port, path: '/v1/health')).timeout(timeout);
    final response = await request.close().timeout(timeout);
    if (response.statusCode != HttpStatus.ok) return false;
    final body = jsonDecode(await response.transform(utf8.decoder).join().timeout(timeout));
    return body is Map && body['service'] == _service;
  } catch (_) {
    return false; // nothing there, something else there, or too slow
  } finally {
    client.close(force: true);
  }
}

/// True when something listens on the API's port of [host]: the quick question asked of every address in a search.
Future<bool> listensOnApiPort(
  String host, {
  int port = _apiPort,
  Duration timeout = const Duration(milliseconds: 450),
}) async {
  try {
    final socket = await Socket.connect(host, port, timeout: timeout);
    socket.destroy();
    return true;
  } catch (_) {
    return false;
  }
}

/// Mobile-data and other interfaces that are not a Wi-Fi, hotspot or cable network shared with a computer.
final _notShared = RegExp(r'^(rmnet|r_rmnet|rev_rmnet|ccmni|ccinet|wwan|pdp|clat|v4-|dummy|tun|ppp|seth)', caseSensitive: false);
final _wifi = RegExp(r'^(wlan|wl|swlan|ap|softap|en|eth)', caseSensitive: false);

/// This device's own IPv4 addresses on networks it can share with a computer, Wi-Fi first.
Future<List<String>> ownAddresses() async {
  final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4);
  final shared = interfaces.where((interface) => !_notShared.hasMatch(interface.name)).toList()
    ..sort((a, b) => (_wifi.hasMatch(a.name) ? 0 : 1).compareTo(_wifi.hasMatch(b.name) ? 0 : 1));
  return [
    for (final interface in shared)
      for (final address in interface.addresses)
        if (isPrivateIPv4(address.address)) address.address,
  ];
}

/// Kept in the app's cache folder: losing it only means one more search.
File get _lastHostFile => File('${Directory.systemTemp.path}${Platform.pathSeparator}gudmeal_test_server_host');

Future<String?> loadLastHost() async {
  final file = _lastHostFile;
  if (!await file.exists()) return null;
  final host = (await file.readAsString()).trim();
  return host.isEmpty ? null : host;
}

Future<void> saveLastHost(String host) => _lastHostFile.writeAsString(host, flush: true);

/// The search as a phone runs it. [knownHosts] are the addresses the build was made with.
TestServerFinder platformFinder(List<String> knownHosts) => TestServerFinder(
      knownHosts: knownHosts,
      isGudMeal: answersAsGudMeal,
      portOpen: listensOnApiPort,
      localAddresses: ownAddresses,
      loadLastHost: loadLastHost,
      saveLastHost: saveLastHost,
    );

/// Ends the app. The sign-in emulator's address is fixed for as long as the app runs, so after the computer has
/// moved to a new address only a fresh start can connect to it.
void closeApp() => exit(0);
