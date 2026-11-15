// Loads the Maps JavaScript API on the web (mobile uses the native SDKs and needs nothing here).
export 'maps_loader_stub.dart' if (dart.library.js_interop) 'maps_loader_web.dart';
