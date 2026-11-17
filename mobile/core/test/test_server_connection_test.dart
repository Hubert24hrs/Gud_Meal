import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gud_meal_core/gud_meal_core.dart';
import 'package:gud_meal_core/src/test_server_io.dart';

/// The search's real connections, against small servers on this machine (no widget binding here: it would replace
/// the real HTTP client with one that refuses every request).
Future<HttpServer> _serve(Map<String, Object?> health) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  server.listen((request) async {
    final found = request.uri.path == '/v1/health';
    request.response.statusCode = found ? HttpStatus.ok : HttpStatus.notFound;
    request.response.headers.contentType = ContentType.json;
    request.response.write(jsonEncode(found ? health : {'detail': 'Not Found'}));
    await request.response.close();
  });
  return server;
}

/// A port on this machine that nothing listens on.
Future<int> _closedPort() async {
  final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  final port = socket.port;
  await socket.close();
  return port;
}

void main() {
  const here = '127.0.0.1';

  setUp(() => HttpOverrides.global = null);

  test('the Gud Meal API is recognised by its health answer', () async {
    final server = await _serve({'status': 'ok', 'service': 'gudmeal-api'});
    addTearDown(() => server.close(force: true));
    expect(await listensOnApiPort(here, port: server.port), isTrue);
    expect(await answersAsGudMeal(here, port: server.port), isTrue);
  });

  test('another program on the same port is not Gud Meal', () async {
    final server = await _serve({'status': 'ok'});
    addTearDown(() => server.close(force: true));
    expect(await listensOnApiPort(here, port: server.port), isTrue);
    expect(await answersAsGudMeal(here, port: server.port), isFalse);
  });

  test('a program that does not speak HTTP is not Gud Meal', () async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    server.listen((socket) {
      socket.write('hello\r\n');
      socket.destroy();
    });
    expect(await answersAsGudMeal(here, port: server.port), isFalse);
  });

  test('nothing listening is no answer', () async {
    final port = await _closedPort();
    expect(await listensOnApiPort(here, port: port), isFalse);
    expect(await answersAsGudMeal(here, port: port), isFalse);
  });

  test('a server that accepts the connection and then says nothing is given up on', () async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final held = <Socket>[];
    addTearDown(() async {
      for (final socket in held) {
        socket.destroy();
      }
      await server.close();
    });
    server.listen(held.add);
    final watch = Stopwatch()..start();
    expect(await answersAsGudMeal(here, port: server.port, timeout: const Duration(milliseconds: 300)), isFalse);
    expect(watch.elapsed, lessThan(const Duration(seconds: 3)));
  });

  test('the remembered address survives a restart of the app', () async {
    await saveLastHost('10.221.34.228');
    expect(await loadLastHost(), '10.221.34.228');
    await saveLastHost('192.168.100.8');
    expect(await loadLastHost(), '192.168.100.8');
  });

  test('the whole search works over real connections', () async {
    final server = await _serve({'status': 'ok', 'service': 'gudmeal-api'});
    addTearDown(() => server.close(force: true));
    final port = server.port;
    final saved = <String>[];
    final finder = TestServerFinder(
      knownHosts: ['127.0.0.9'], // not a private network address, so there is nothing to search around it
      isGudMeal: (host) => answersAsGudMeal(host, port: port, timeout: const Duration(milliseconds: 500)),
      portOpen: (host) => listensOnApiPort(host, port: port, timeout: const Duration(milliseconds: 300)),
      localAddresses: () async => const [],
      loadLastHost: () async => here,
      saveLastHost: (host) async => saved.add(host),
    );
    expect(await finder.find(), here);
    expect(saved, [here]);
  });

  test('this device can list its own addresses', () async {
    // Which addresses come back depends on the machine: the list must come back, and hold private addresses only.
    final addresses = await ownAddresses();
    expect(addresses.every(isPrivateIPv4), isTrue);
  });
}
