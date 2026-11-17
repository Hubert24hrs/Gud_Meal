/// The search for the test server as this platform runs it: sockets and files on phones, nothing in a browser.
library;

export 'test_server_stub.dart' if (dart.library.io) 'test_server_io.dart';
