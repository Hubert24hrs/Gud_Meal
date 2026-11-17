import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gud_meal_core/gud_meal_core.dart';
import 'package:gud_meal_core/src/test_server_io.dart';

/// Not part of the normal run: searches the real Wi-Fi from this computer the way a phone would, against a running
/// local stack. Start the stack in LAN mode, then give an address a phone could have on this Wi-Fi:
///
///     GUDMEAL_LIVE_SEARCH_AS=192.168.100.3 flutter test test/test_server_live_test.dart
void main() {
  final phone = Platform.environment['GUDMEAL_LIVE_SEARCH_AS'];

  test('a phone on this Wi-Fi finds the running test server', () async {
    HttpOverrides.global = null;
    final networks = <String>[];
    final finder = TestServerFinder(
      knownHosts: const ['10.255.255.1'], // an address the computer does not have, as after it changed Wi-Fi
      isGudMeal: answersAsGudMeal,
      portOpen: listensOnApiPort,
      localAddresses: () async => [phone!],
      loadLastHost: () async => null,
      saveLastHost: (host) async {},
    );
    final watch = Stopwatch()..start();
    final host = await finder.find(onNetwork: networks.add);
    // ignore: avoid_print
    print('found $host in ${watch.elapsedMilliseconds} ms; networks searched: $networks');
    expect(host, isNotNull);
    expect(networkOf(host!), networkOf(phone!));
  }, skip: phone == null ? 'set GUDMEAL_LIVE_SEARCH_AS to an address on this Wi-Fi' : false, timeout: const Timeout(Duration(minutes: 1)));
}
