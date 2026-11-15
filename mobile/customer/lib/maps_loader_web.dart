import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Adds the Maps JavaScript API script with the browser key given at build time
/// (`--dart-define=MAPS_BROWSER_KEY=...`, restricted to Gud Meal's web domains). The key is never in the repo.
/// Returns false when there is no key or the script didn't load, so screens keep the schematic map.
Future<bool> loadGoogleMapsScript(String browserKey) {
  if (browserKey.isEmpty) return Future.value(false);
  final done = Completer<bool>();
  final script = web.HTMLScriptElement()
    ..src = 'https://maps.googleapis.com/maps/api/js?key=${Uri.encodeQueryComponent(browserKey)}&region=NG'
    ..async = true;
  script.onload = ((web.Event _) {
    if (!done.isCompleted) done.complete(true);
  }).toJS;
  script.onerror = ((web.Event _) {
    if (!done.isCompleted) done.complete(false);
  }).toJS;
  web.document.head!.append(script);
  return done.future.timeout(const Duration(seconds: 10), onTimeout: () => false);
}
