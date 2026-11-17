import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gud_meal_core/gud_meal_core.dart';

import 'app.dart';
import 'providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = AppConfig.fromEnvironment();
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: config.firebaseApiKey,
      appId: config.firebaseAppId,
      messagingSenderId: config.firebaseMessagingSenderId,
      projectId: config.firebaseProjectId,
    ),
  );
  if (config.useEmulators) {
    await connectAuthEmulator(FirebaseAuth.instance, config.emulatorHost);
  }
  runApp(ProviderScope(
    overrides: [
      configProvider.overrideWithValue(config),
      authRepositoryProvider.overrideWithValue(FirebaseAuthRepository(FirebaseAuth.instance)),
    ],
    child: const RiderApp(),
  ));
}
