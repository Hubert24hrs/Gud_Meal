import 'test_server.dart';

/// The browser side of `test_server_io.dart`. A web page cannot open connections to the addresses around it, and
/// `AppConfig.findTestServer` is never true in a browser, so nothing here is reached.

TestServerFinder platformFinder(List<String> knownHosts) =>
    throw UnsupportedError('The search for the test server runs on phones only');

void closeApp() => throw UnsupportedError('Closing the app is for phone test builds only');
