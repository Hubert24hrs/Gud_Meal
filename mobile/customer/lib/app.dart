import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gud_meal_core/gud_meal_core.dart';

import 'features/assistant/assistant_screen.dart';
import 'features/auth/sign_in_screen.dart';
import 'features/cart/checkout_screen.dart';
import 'features/home/home_screen.dart';
import 'features/orders/order_screen.dart';
import 'features/orders/orders_screen.dart';
import 'features/restaurant/restaurant_screen.dart';
import 'providers.dart';

/// Re-runs GoRouter redirects whenever the signed-in user changes.
class _AuthListenable extends ChangeNotifier {
  _AuthListenable(Stream<GmUser?> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }
  late final StreamSubscription<GmUser?> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

const _protected = ['/checkout', '/orders', '/assistant'];

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authRepositoryProvider);
  final listenable = _AuthListenable(auth.authStateChanges());
  ref.onDispose(listenable.dispose);
  return GoRouter(
    refreshListenable: listenable,
    redirect: (context, state) {
      final signedIn = auth.currentUser != null;
      final path = state.matchedLocation;
      if (!signedIn && _protected.any(path.startsWith)) return '/sign-in?next=${Uri.encodeComponent(state.uri.toString())}';
      if (signedIn && path == '/sign-in') return state.uri.queryParameters['next'] ?? '/';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
      GoRoute(path: '/sign-in', builder: (_, _) => const SignInScreen()),
      GoRoute(path: '/restaurants/:id', builder: (_, s) => RestaurantScreen(id: s.pathParameters['id']!)),
      GoRoute(path: '/checkout', builder: (_, _) => const CheckoutScreen()),
      GoRoute(path: '/orders', builder: (_, _) => const OrdersScreen()),
      GoRoute(
        path: '/orders/:id',
        builder: (_, s) => OrderScreen(id: s.pathParameters['id']!, paymentReference: s.uri.queryParameters['ref']),
      ),
      GoRoute(path: '/assistant', builder: (_, s) => AssistantScreen(initial: s.uri.queryParameters['q'])),
    ],
  );
});

class GudMealApp extends ConsumerWidget {
  const GudMealApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Gud Meal',
      debugShowCheckedModeBanner: false,
      theme: buildGudMealTheme(Brightness.light),
      darkTheme: buildGudMealTheme(Brightness.dark),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
