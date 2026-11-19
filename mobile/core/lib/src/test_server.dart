import 'dart:async';
import 'dart:math' as math;

/// Asks one address a yes-or-no question (does the Yummy Chops API answer there? does anything listen there?).
typedef HostCheck = Future<bool> Function(String host);

/// Looks for the computer that runs the Yummy Chops test server, for phone test builds.
///
/// A test build is made for the address the computer had on its Wi-Fi at that moment, and that address changes when
/// the computer joins another Wi-Fi. So the app first tries the addresses it knows (the one that worked last time,
/// then the ones the build was made with) and, when none answers, asks every address on the phone's own networks.
/// Store builds never do this: see `AppConfig.findTestServer` and docs/adr/0020-test-apps-find-the-test-server.md.
///
/// Everything that touches the network or the disk is passed in, so the search itself is plain logic.
class TestServerFinder {
  TestServerFinder({
    required List<String> knownHosts,
    required this.isGudMeal,
    required this.portOpen,
    required this.localAddresses,
    required this.loadLastHost,
    required this.saveLastHost,
    this.batchSize = 64,
    this.maxNetworks = 4,
  }) : _builtIn = knownHosts.where((host) => host.isNotEmpty).toList();

  final List<String> _builtIn;

  /// The full check: the Yummy Chops API answers on this host. Never throws.
  final HostCheck isGudMeal;

  /// The quick check used on every address of a network: something listens on the API's port. Never throws.
  final HostCheck portOpen;

  /// This phone's own IPv4 addresses on Wi-Fi-like networks (not mobile data).
  final Future<List<String>> Function() localAddresses;

  /// The host that worked last time, kept between launches.
  final Future<String?> Function() loadLastHost;
  final Future<void> Function(String host) saveLastHost;

  /// How many addresses are asked at the same time during a search.
  final int batchSize;

  /// At most this many networks are searched (the phone's own first), so "not found" comes within seconds.
  final int maxNetworks;

  /// The hosts to try before searching: the one that worked last time, then the ones the build was made with.
  Future<List<String>> knownHosts() async {
    final last = await _quietly(loadLastHost);
    return <String>{if (last != null && last.isNotEmpty) last, ..._builtIn}.toList();
  }

  /// The first known host where the Yummy Chops API answers, or null. All are asked at once; the earlier one wins.
  Future<String?> findKnown() async {
    final hosts = await knownHosts();
    final answers = [for (final host in hosts) _ask(isGudMeal, host)];
    for (var i = 0; i < hosts.length; i++) {
      if (await answers[i]) return _remember(hosts[i]);
    }
    return null;
  }

  /// Asks every address on the phone's own networks, then on the networks of the known hosts (the computer may have a
  /// new address on the same Wi-Fi). [onNetwork] hears which network is being searched, as `192.168.100`.
  Future<String?> search({void Function(String network)? onNetwork}) async {
    final own = (await _quietly(localAddresses)) ?? const <String>[];
    final networks = <String>{
      for (final address in own)
        if (isPrivateIPv4(address)) networkOf(address),
      for (final host in await knownHosts())
        if (isPrivateIPv4(host)) networkOf(host),
    }.take(maxNetworks);
    for (final network in networks) {
      onNetwork?.call(network);
      final hosts = [
        for (var last = 1; last <= 254; last++)
          if (!own.contains('$network.$last')) '$network.$last',
      ];
      for (var start = 0; start < hosts.length; start += batchSize) {
        final batch = hosts.sublist(start, math.min(start + batchSize, hosts.length));
        final open = await Future.wait(batch.map((host) => _ask(portOpen, host)));
        for (var i = 0; i < batch.length; i++) {
          if (open[i] && await _ask(isGudMeal, batch[i])) return _remember(batch[i]);
        }
      }
    }
    return null;
  }

  /// The known hosts first, then a search of the Wi-Fi.
  Future<String?> find({void Function(String network)? onNetwork}) async =>
      await findKnown() ?? await search(onNetwork: onNetwork);

  /// An address the tester typed: accepted when the Yummy Chops API answers there.
  Future<String?> tryTyped(String typed) async {
    final host = cleanHost(typed);
    if (host == null || !await _ask(isGudMeal, host)) return null;
    return _remember(host);
  }

  /// True when the app can still reach the test server on [host] (asked again when the app comes back to the front).
  Future<bool> answersOn(String host) => _ask(isGudMeal, host);

  /// A check that fails for any reason counts as "no": one odd address must not stop the search.
  static Future<bool> _ask(HostCheck check, String host) async {
    try {
      return await check(host);
    } catch (_) {
      return false;
    }
  }

  Future<String> _remember(String host) async {
    await _quietly(() => saveLastHost(host));
    return host;
  }

  /// The remembered host is a convenience: a full or unreadable disk must not stop the search.
  static Future<T?> _quietly<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (_) {
      return null;
    }
  }
}

final _ipv4 = RegExp(r'^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$');

List<int>? _parts(String host) {
  final match = _ipv4.firstMatch(host);
  if (match == null) return null;
  final parts = [for (var i = 1; i <= 4; i++) int.parse(match.group(i)!)];
  return parts.every((part) => part <= 255) ? parts : null;
}

/// True for an address of a home, office or hotspot network (10.x, 172.16-31.x, 192.168.x): the only kind searched.
bool isPrivateIPv4(String host) {
  final parts = _parts(host);
  if (parts == null) return false;
  return parts[0] == 10 || (parts[0] == 172 && parts[1] >= 16 && parts[1] <= 31) || (parts[0] == 192 && parts[1] == 168);
}

/// `192.168.100.8` is on the network `192.168.100` (the 254 addresses that share its first three numbers).
String networkOf(String address) => address.substring(0, address.lastIndexOf('.'));

/// The address inside what a tester typed or pasted: `192.168.100.8`, `http://192.168.100.8:8090/` and
/// ` 192.168.100.8 ` all give `192.168.100.8`. Null when there is no IPv4 address in it.
String? cleanHost(String typed) {
  var text = typed.trim();
  final scheme = text.indexOf('://');
  if (scheme >= 0) text = text.substring(scheme + 3);
  text = text.split('/').first.split(':').first.trim();
  return _parts(text) == null ? null : text;
}
