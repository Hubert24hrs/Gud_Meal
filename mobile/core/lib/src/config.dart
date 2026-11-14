import 'package:flutter/foundation.dart';

/// Build-time configuration via `--dart-define` (no secrets: these values ship in the app binary).
class AppConfig {
  const AppConfig({
    required this.apiUrl,
    required this.agentsUrl,
    required this.useEmulators,
    required this.firebaseApiKey,
    required this.firebaseAppId,
    required this.firebaseProjectId,
    required this.firebaseMessagingSenderId,
  });

  final String apiUrl;
  final String agentsUrl;
  final bool useEmulators;
  final String firebaseApiKey;
  final String firebaseAppId;
  final String firebaseProjectId;
  final String firebaseMessagingSenderId;

  /// Android emulators reach the host machine at 10.0.2.2.
  static String get _host => !kIsWeb && defaultTargetPlatform == TargetPlatform.android ? '10.0.2.2' : 'localhost';

  factory AppConfig.fromEnvironment() => AppConfig(
        apiUrl: const String.fromEnvironment('API_URL').isNotEmpty
            ? const String.fromEnvironment('API_URL')
            : 'http://$_host:8000',
        agentsUrl: const String.fromEnvironment('AGENTS_URL').isNotEmpty
            ? const String.fromEnvironment('AGENTS_URL')
            : 'http://$_host:8100',
        useEmulators: const bool.fromEnvironment('USE_FIREBASE_EMULATORS', defaultValue: true),
        firebaseApiKey: const String.fromEnvironment('FIREBASE_API_KEY', defaultValue: 'demo-api-key'),
        firebaseAppId: const String.fromEnvironment('FIREBASE_APP_ID', defaultValue: '1:000000000000:android:demo'),
        firebaseProjectId: const String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: 'demo-gudmeal'),
        firebaseMessagingSenderId: const String.fromEnvironment('FIREBASE_SENDER_ID', defaultValue: '000000000000'),
      );

  String get emulatorHost => _host;
}
