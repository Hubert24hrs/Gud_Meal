import 'dart:async';

import 'package:flutter/material.dart';

import 'config.dart';
import 'test_server.dart';
import 'test_server_platform.dart';
import 'theme/theme.dart';

/// Phone test builds: [config] pointed at the computer that runs the test server.
///
/// When an address the app already knows answers, this returns at once and shows nothing. Otherwise it puts up a
/// small screen ([TestServerSearch]) that searches the phone's Wi-Fi and lets the tester try again or type the
/// address. Call it before anything connects to the server (the sign-in emulator's address cannot change later).
Future<AppConfig> locateTestServer(AppConfig config, {required String appName, TestServerFinder? finder}) async {
  final search = finder ?? platformFinder([config.serverHost, ...config.testServerHosts]);
  final known = await search.findKnown();
  if (known != null) return config.onHost(known);
  final found = Completer<String>();
  runApp(TestServerSearch(
    appName: appName,
    finder: search,
    fallbackHost: config.serverHost,
    onFound: (host) {
      if (!found.isCompleted) found.complete(host);
    },
  ));
  return config.onHost(await found.future);
}

/// The screen a phone test build shows while it looks for the test server, and when it cannot find it.
class TestServerSearch extends StatefulWidget {
  const TestServerSearch({
    super.key,
    required this.appName,
    required this.finder,
    required this.fallbackHost,
    required this.onFound,
  });

  final String appName;
  final TestServerFinder finder;

  /// The address the build was made for: used when the tester opens the app without a server.
  final String fallbackHost;
  final ValueChanged<String> onFound;

  @override
  State<TestServerSearch> createState() => _TestServerSearchState();
}

class _TestServerSearchState extends State<TestServerSearch> {
  final _typed = TextEditingController();
  bool _searching = true;
  String? _network;
  bool _checkingTyped = false;
  String? _typedProblem;

  @override
  void initState() {
    super.initState();
    _search();
  }

  @override
  void dispose() {
    _typed.dispose();
    super.dispose();
  }

  void _searchAgain() {
    setState(() {
      _searching = true;
      _network = null;
    });
    _search();
  }

  Future<void> _search() async {
    final host = await widget.finder.find(onNetwork: (network) {
      if (mounted) setState(() => _network = network);
    });
    if (!mounted) return;
    if (host != null) {
      widget.onFound(host);
    } else {
      setState(() => _searching = false);
    }
  }

  Future<void> _useTyped() async {
    setState(() {
      _checkingTyped = true;
      _typedProblem = null;
    });
    final host = await widget.finder.tryTyped(_typed.text);
    if (!mounted) return;
    if (host != null) {
      widget.onFound(host);
      return;
    }
    setState(() {
      _checkingTyped = false;
      _typedProblem = cleanHost(_typed.text) == null
          ? 'Type an address like 192.168.100.8'
          : 'Gud Meal did not answer at that address';
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: widget.appName,
      debugShowCheckedModeBanner: false,
      theme: buildGudMealTheme(Brightness.light),
      darkTheme: buildGudMealTheme(Brightness.dark),
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Builder(builder: (context) => _searching ? _looking(context) : _missing(context)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _looking(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final network = _network;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 24),
        Text('Looking for the Gud Meal test server', style: text.titleLarge, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(
          network == null ? 'Checking the addresses this app already knows' : 'Searching this Wi-Fi ($network.1 to $network.254)',
          style: text.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _missing(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.wifi_find, size: 48, color: theme.colorScheme.primary),
        const SizedBox(height: 16),
        Text("Can't find the test server", style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(
          'Put this phone on the same Wi-Fi as the computer that runs Gud Meal, and check that Gud Meal is running '
          'there. Then try again.',
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          key: const Key('test-server-retry'),
          onPressed: _searchAgain,
          icon: const Icon(Icons.refresh),
          label: const Text('Try again'),
        ),
        const SizedBox(height: 28),
        Text("Or type the computer's address", style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        TextField(
          key: const Key('test-server-address'),
          controller: _typed,
          keyboardType: TextInputType.url,
          autocorrect: false,
          enabled: !_checkingTyped,
          decoration: InputDecoration(
            hintText: '192.168.100.8',
            errorText: _typedProblem,
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (_) => _useTyped(),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          key: const Key('test-server-use-address'),
          onPressed: _checkingTyped ? null : _useTyped,
          child: Text(_checkingTyped ? 'Checking' : 'Use this address'),
        ),
        const SizedBox(height: 20),
        TextButton(
          key: const Key('test-server-skip'),
          onPressed: () => widget.onFound(widget.fallbackHost),
          child: const Text('Open the app anyway'),
        ),
      ],
    );
  }
}

enum _Notice { lost, looking, stillMissing, moved }

/// Phone test builds: notices that the test server stopped answering while the app was away (the computer joined
/// another Wi-Fi, or was switched off) and helps the tester find it again.
///
/// It goes in `MaterialApp.builder` through [wrap], above the app's pages. A server found at a new address needs a
/// fresh start of the app, because the sign-in emulator's address is fixed while the app runs.
class TestServerWatch extends StatefulWidget {
  const TestServerWatch({
    super.key,
    required this.config,
    required this.child,
    this.finder,
    this.onClose,
    this.patience = const Duration(seconds: 2),
  });

  final AppConfig config;
  final Widget child;

  /// For tests; the app uses the platform's own search.
  final TestServerFinder? finder;

  /// For tests; the app closes itself.
  final VoidCallback? onClose;

  /// The wait between the three attempts made before the notice appears: a phone that wakes up needs a moment to
  /// rejoin its Wi-Fi.
  final Duration patience;

  /// For `MaterialApp.builder`: watches in a phone test build and leaves every other build untouched.
  static Widget wrap(AppConfig config, Widget? child) {
    final app = child ?? const SizedBox.shrink();
    return config.findTestServer ? TestServerWatch(config: config, child: app) : app;
  }

  @override
  State<TestServerWatch> createState() => _TestServerWatchState();
}

class _TestServerWatchState extends State<TestServerWatch> with WidgetsBindingObserver {
  late final TestServerFinder _finder =
      widget.finder ?? platformFinder([widget.config.serverHost, ...widget.config.testServerHosts]);
  _Notice? _notice;
  String? _movedTo;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  Future<void> _check() async {
    if (_checking || _notice != null) return;
    _checking = true;
    try {
      for (var attempt = 0; attempt < 3; attempt++) {
        if (attempt > 0) await Future<void>.delayed(widget.patience);
        if (!mounted) return;
        if (await _finder.answersOn(widget.config.serverHost)) return;
      }
      if (mounted) setState(() => _notice = _Notice.lost);
    } finally {
      _checking = false;
    }
  }

  Future<void> _look() async {
    setState(() => _notice = _Notice.looking);
    final host = await _finder.find();
    if (!mounted) return;
    setState(() {
      if (host == null) {
        _notice = _Notice.stillMissing;
      } else if (host == widget.config.serverHost) {
        _notice = null; // it is back where it was: carry on
      } else {
        _movedTo = host;
        _notice = _Notice.moved;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final notice = _notice;
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (notice != null) ...[
          const ModalBarrier(dismissible: false, color: Colors.black54),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Card(
                    child: Padding(padding: const EdgeInsets.all(20), child: _card(context, notice)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _card(BuildContext context, _Notice notice) {
    final theme = Theme.of(context);
    final (String title, String body) = switch (notice) {
      _Notice.lost => (
          "Can't reach the test server",
          'The computer that runs Gud Meal may have joined another Wi-Fi or gone to sleep. Put this phone on the '
              'same Wi-Fi as the computer, then look for it.',
        ),
      _Notice.looking => ('Looking for the test server', 'Searching this Wi-Fi for the computer that runs Gud Meal.'),
      _Notice.stillMissing => (
          "Still can't find it",
          'Check that the computer is on, that Gud Meal is running there, and that this phone is on the same Wi-Fi.',
        ),
      _Notice.moved => (
          'Found the computer at a new address',
          'It is now at $_movedTo. Close the app and open it again to connect.',
        ),
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(body, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 16),
        if (notice == _Notice.looking)
          const Center(child: CircularProgressIndicator())
        else if (notice == _Notice.moved)
          FilledButton(
            key: const Key('test-server-close-app'),
            onPressed: widget.onClose ?? closeApp,
            child: const Text('Close the app'),
          )
        else ...[
          FilledButton(
            key: const Key('test-server-look'),
            onPressed: _look,
            child: Text(notice == _Notice.lost ? 'Look for it' : 'Look again'),
          ),
          TextButton(
            key: const Key('test-server-not-now'),
            onPressed: () => setState(() => _notice = null),
            child: const Text('Not now'),
          ),
        ],
      ],
    );
  }
}
