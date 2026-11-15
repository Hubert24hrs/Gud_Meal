import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gud_meal_core/gud_meal_core.dart';

import 'features/assistant/assistant_screen.dart';
import 'features/auth/sign_in_screen.dart';
import 'features/cart/checkout_screen.dart';
import 'features/discover/discover_screen.dart';
import 'features/home/home_screen.dart';
import 'features/orders/order_screen.dart';
import 'features/orders/orders_screen.dart';
import 'features/parcel/parcel_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/restaurant/restaurant_screen.dart';
import 'features/support/support_screen.dart';
import 'features/vertical/vertical_screen.dart';
import 'providers.dart';
import 'shell.dart';

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

/// Screens that need an account. Tabs (Orders, Profile) show a sign-in prompt instead of redirecting.
const _protected = ['/checkout', '/assistant', '/send', '/orders/'];

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authRepositoryProvider);
  final listenable = _AuthListenable(auth.authStateChanges());
  ref.onDispose(listenable.dispose);
  return GoRouter(
    navigatorKey: _rootKey,
    refreshListenable: listenable,
    redirect: (context, state) {
      final signedIn = auth.currentUser != null;
      final path = state.matchedLocation;
      if (!signedIn && _protected.any(path.startsWith)) return '/sign-in?next=${Uri.encodeComponent(state.uri.toString())}';
      if (signedIn && path == '/sign-in') return state.uri.queryParameters['next'] ?? '/';
      return null;
    },
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/', builder: (_, _) => const HomeScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/discover', builder: (_, _) => const DiscoverScreen())]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/orders',
              builder: (_, _) => const OrdersScreen(),
              routes: [
                GoRoute(
                  path: ':id',
                  parentNavigatorKey: _rootKey,
                  builder: (_, s) => OrderScreen(id: s.pathParameters['id']!, paymentReference: s.uri.queryParameters['ref']),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [GoRoute(path: '/support', builder: (_, _) => const SupportScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen())]),
        ],
      ),
      GoRoute(path: '/sign-in', builder: (_, _) => const SignInScreen()),
      GoRoute(path: '/food', builder: (_, s) => VerticalScreen(vertical: 'food', category: s.uri.queryParameters['category'])),
      GoRoute(path: '/beauty', builder: (_, s) => VerticalScreen(vertical: 'beauty', category: s.uri.queryParameters['category'])),
      GoRoute(path: '/send', builder: (_, _) => const ParcelScreen()),
      GoRoute(path: '/restaurants/:id', builder: (_, s) => RestaurantScreen(id: s.pathParameters['id']!)),
      GoRoute(path: '/checkout', builder: (_, _) => const CheckoutScreen()),
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
      themeMode: ref.watch(themeModeProvider),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
