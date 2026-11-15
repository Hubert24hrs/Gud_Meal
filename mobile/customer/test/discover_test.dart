import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gud_meal_core/gud_meal_core.dart';
import 'package:gud_meal_customer/features/discover/discover_screen.dart';
import 'package:gud_meal_customer/features/discover/dish_orbit_carousel.dart';
import 'package:gud_meal_customer/features/restaurant/restaurant_screen.dart';
import 'package:gud_meal_customer/providers.dart';
import 'package:gud_meal_customer/ui/plates.dart';

const jollofRice = DiscoverDish(
  itemId: 'jj-party-jollof',
  restaurantId: 'r-jollof',
  restaurantName: 'Jollof Junction',
  area: 'Lekki Phase 1',
  name: 'Party Jollof Rice',
  description: 'Smoky firewood jollof with dodo.',
  priceKobo: 550000,
  art: 'rice',
  tags: ['jollof', 'chicken'],
  allergens: ['celery'],
  likes: 980,
  rating: 4.7,
  eyebrow: '#1 Most loved dish',
  etaMinutes: 24,
  deliveryFeeKobo: 60000,
);
const beefSuya = DiscoverDish(
  itemId: 'sl-beef',
  restaurantId: 'r-suya',
  restaurantName: 'Suya Lane',
  area: 'Victoria Island',
  name: 'Beef Suya (250g)',
  priceKobo: 450000,
  art: 'skewers',
  likes: 1500,
  rating: 4.8,
  eyebrow: '#2 Most loved dish',
);
const amala = DiscoverDish(
  itemId: 'ma-amala',
  restaurantId: 'r-mama-ayo',
  restaurantName: "Mama Ayo's Kitchen",
  name: 'Amala, Gbegiri & Ewedu',
  priceKobo: 380000,
  art: 'soup_swallow',
  rating: 4.6,
  eyebrow: '#3 Most loved dish',
  isOpen: false,
);
const pizza = DiscoverDish(
  itemId: 'kc-suya-pizza',
  restaurantId: 'r-kiln',
  restaurantName: 'Kiln & Crust Pizza',
  area: 'Lekki Phase 1',
  name: 'Suya pizza (medium)',
  priceKobo: 900000,
  art: 'pizza',
  rating: 4.5,
  eyebrow: 'New kitchen · Lekki Phase 1',
  isNewKitchen: true,
);

void phone(WidgetTester tester, {bool reduceMotion = false}) {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 2.6;
  addTearDown(tester.view.reset);
  if (reduceMotion) {
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  }
}

Widget carousel(List<DiscoverDish> dishes, {ValueChanged<DiscoverDish>? onOrder, ValueChanged<DiscoverDish>? onAskGudy, Key? key}) => MaterialApp(
      theme: buildGudMealTheme(Brightness.light),
      home: Scaffold(
        body: SingleChildScrollView(
          child: DishOrbitCarousel(key: key, dishes: dishes, onOrder: onOrder, onAskGudy: onAskGudy, autoPlay: null),
        ),
      ),
    );

void main() {
  group('orbit maths (ported from the web component)', () {
    test('indices wrap both ways and jumps take the short way round', () {
      expect(wrapIndex(5, 5), 0);
      expect(wrapIndex(-1, 5), 4);
      expect(wrapIndex(3, 0), 0);
      expect(stepDirection(0, 1, 5), 1);
      expect(stepDirection(0, 4, 5), -1);
      expect(stepDirection(4, 0, 5), 1);
    });

    test('titles fit their line width and never exceed the maximum size', () {
      expect(fitSize(4, 48, 300, .7), 48);
      expect(fitSize(20, 48, 300, .7), closeTo(300 / (20 * .7), 1e-9));
      expect(fitSize(0, 48, 10, .7), closeTo(10 / .7, 1e-9));
    });

    test('dish names split into a thin and a heavy line', () {
      expect(splitTitle('Party Jollof Rice'), (thin: 'Party', heavy: 'Jollof Rice'));
      expect(splitTitle('Beef Suya (250g)'), (thin: 'Beef', heavy: 'Suya'));
      expect(splitTitle('Amala, Gbegiri & Ewedu'), (thin: 'Amala', heavy: 'Gbegiri & Ewedu'));
      expect(splitTitle('Whole Grilled Croaker (serves 2)'), (thin: 'Whole Grilled', heavy: 'Croaker'));
      expect(splitTitle('Plantain & Bean Power Bowl'), (thin: 'Plantain & Bean', heavy: 'Power Bowl'));
      expect(splitTitle('Chapman'), (thin: '', heavy: 'Chapman'));
    });

    test('the band rests per dish and tapers to a closed shape', () {
      expect(arcRest(0), [50, 98]);
      expect(arcRest(5), arcRest(1));
      final path = arcPath(50, 98, 299, -450, 650, 118);
      final b = path.getBounds();
      expect(b.width, greaterThan(100));
      expect(b.top, greaterThan(0), reason: 'the band sits below the orbit centre, inside the canvas');
      expect(accentFor(7), accentFor(2));
    });
  });

  testWidgets('every plate family paints without errors', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Wrap(children: [
        for (final art in ['rice', 'soup_swallow', 'broth', 'skewers', 'grill', 'pizza', 'wrap', 'bites', 'bowl', 'plate', 'unknown'])
          for (final name in ['Party Jollof Rice', 'Nigerian Fried Rice', 'Ofada rice & ayamase', 'Efo Riro & Semo', 'Catfish Pepper Soup', 'Asun (spicy goat)', 'Whole Grilled Croaker', 'Margherita', 'Puff-Puff', 'Meat pie', 'Loaded Fries', 'Yoghurt parfait', 'Fruit salad bowl', 'Abacha', 'Grilled Chicken Salad'])
            PlateArt(art: art, name: name, size: 40),
      ]),
    ));
    expect(tester.takeException(), isNull);
    expect(find.byType(PlateArt), findsNWidgets(11 * 15));
  });

  testWidgets('carousel shows the dish, its kitchen card and actions', (tester) async {
    phone(tester);
    DiscoverDish? ordered;
    DiscoverDish? asked;
    await tester.pumpWidget(carousel([jollofRice, beefSuya, amala], onOrder: (d) => ordered = d, onAskGudy: (d) => asked = d));
    await tester.pumpAndSettle();

    expect(find.text('#1 Most loved dish'), findsOneWidget);
    expect(find.text('PARTY'), findsOneWidget);
    expect(find.text('JOLLOF RICE'), findsOneWidget);
    expect(find.text('Jollof Junction'), findsOneWidget);
    expect(find.text('Lekki Phase 1 · 24 min · ₦600 delivery'), findsOneWidget);
    expect(find.text('4.7'), findsOneWidget);
    expect(find.text('980 orders'), findsOneWidget);

    await tester.tap(find.text('Order food · ₦5,500'));
    expect(ordered, jollofRice);
    await tester.tap(find.text('Ask Gudy'));
    expect(asked, jollofRice);

    // Ingredients tab lists what's in it; liking bumps the count.
    await tester.tap(find.text('Ingredients'));
    await tester.pump();
    expect(find.text('contains celery'), findsOneWidget);
    await tester.tap(find.text('980 orders'));
    await tester.pump();
    expect(find.text('981 orders'), findsOneWidget);
  });

  testWidgets('swiping swings the next plate in on the orbit; the pager jumps', (tester) async {
    phone(tester);
    final key = GlobalKey<DishOrbitCarouselState>();
    await tester.pumpWidget(carousel([jollofRice, beefSuya, amala], key: key));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(DishPlate).first, const Offset(-200, 0));
    await tester.pump(); // the swap's ticker starts on this frame
    await tester.pump(const Duration(milliseconds: 400));
    // mid-swap both plates are on stage, the incoming one still swinging in
    expect(find.byType(DishPlate), findsNWidgets(2));
    await tester.pumpAndSettle();
    expect(key.currentState!.index, 1);
    expect(find.text('BEEF'), findsOneWidget);
    expect(find.text('SUYA'), findsOneWidget);
    expect(find.byType(DishPlate), findsOneWidget);

    // swiping right goes back, and wraps round from the first dish to the last
    await tester.drag(find.byType(DishPlate).first, const Offset(200, 0));
    await tester.pumpAndSettle();
    expect(key.currentState!.index, 0);
    await tester.drag(find.byType(DishPlate).first, const Offset(200, 0));
    await tester.pumpAndSettle();
    expect(key.currentState!.index, 2);
    expect(find.text('Closed now'), findsOneWidget, reason: "the closed kitchen's card says so");

    await tester.tap(find.bySemanticsLabel('Dish 2: Beef Suya (250g)'));
    await tester.pumpAndSettle();
    expect(key.currentState!.index, 1);
  });

  testWidgets('dark theme: the rating stays readable where it overlaps the pastel badge', (tester) async {
    phone(tester);
    await tester.pumpWidget(MaterialApp(
      theme: buildGudMealTheme(Brightness.dark),
      home: const Scaffold(body: SingleChildScrollView(child: DishOrbitCarousel(dishes: [jollofRice, beefSuya], autoPlay: null))),
    ));
    await tester.pumpAndSettle();
    final numbers = tester.widgetList<Text>(find.text('4.7')).toList();
    expect(numbers, hasLength(2), reason: 'light ink over the card, dark ink clipped to the badge');
    expect(numbers.map((t) => t.style!.color).toSet(), hasLength(2));
  });

  testWidgets('mid-swap the order button still names the dish whose title is showing', (tester) async {
    phone(tester);
    final key = GlobalKey<DishOrbitCarouselState>();
    DiscoverDish? ordered;
    await tester.pumpWidget(carousel([jollofRice, beefSuya], key: key, onOrder: (d) => ordered = d));
    await tester.pumpAndSettle();
    key.currentState!.step(1);
    await tester.pump(); // the swap's ticker starts on this frame
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Order food · ₦5,500'), findsOneWidget, reason: 'the jollof title is still up');
    await tester.tap(find.text('Order food · ₦5,500'));
    expect(ordered, jollofRice);
    await tester.pumpAndSettle();
    expect(find.text('Order food · ₦4,500'), findsOneWidget);
  });

  testWidgets('with reduced motion the dish changes instantly', (tester) async {
    phone(tester, reduceMotion: true);
    final key = GlobalKey<DishOrbitCarouselState>();
    await tester.pumpWidget(carousel([jollofRice, beefSuya], key: key));
    await tester.pump();
    key.currentState!.step(1);
    await tester.pump();
    expect(find.byType(DishPlate), findsOneWidget);
    expect(find.text('SUYA'), findsOneWidget);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('Discover shows section chips and the carousel; Order food opens the dish at its kitchen', (tester) async {
    phone(tester, reduceMotion: true);
    String? opened;
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, _) => const DiscoverScreen()),
      GoRoute(path: '/restaurants/:id', builder: (_, s) {
        opened = '${s.pathParameters['id']}?${s.uri.query}';
        return const Scaffold(body: Text('STORE'));
      }),
      GoRoute(path: '/assistant', builder: (_, s) => Scaffold(body: Text('GUDY ${s.uri.queryParameters['q']}'))),
    ]);
    const feed = DiscoverFeed(city: 'lagos', sections: [
      DiscoverSection(id: 'most_loved', title: 'Most loved dishes', subtitle: 'What everyone near you is ordering', dishes: [jollofRice, beefSuya]),
      DiscoverSection(id: 'new_kitchens', title: 'New kitchen discoveries', dishes: [pizza]),
      DiscoverSection(id: 'top_rated', title: 'From top-rated kitchens', dishes: []),
    ]);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(FakeAuthRepository(const GmUser(uid: 'u1'))),
        discoverFeedProvider.overrideWith((ref) async => feed),
        merchantsProvider.overrideWith((ref, q) async => const <RestaurantCard>[]),
      ],
      child: MaterialApp.router(theme: buildGudMealTheme(Brightness.light), routerConfig: router),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Most loved'), findsOneWidget);
    expect(find.text('New kitchens'), findsOneWidget);
    expect(find.text('Top rated'), findsNothing, reason: 'empty sections are hidden');
    expect(find.text('Most loved dishes'), findsOneWidget);
    expect(find.text('JOLLOF RICE'), findsOneWidget);

    await tester.tap(find.text('New kitchens'));
    await tester.pumpAndSettle();
    expect(find.text('New kitchen discoveries'), findsOneWidget);
    expect(find.text('New kitchen · Lekki Phase 1'), findsOneWidget);
    expect(find.text('PIZZA'), findsOneWidget);

    await tester.ensureVisible(find.text('Order food · ₦9,000'));
    await tester.tap(find.text('Order food · ₦9,000'));
    await tester.pumpAndSettle();
    expect(opened, 'r-kiln?item=kc-suya-pizza');
  });

  testWidgets('a restaurant opened from Discover pops the chosen dish open', (tester) async {
    phone(tester, reduceMotion: true);
    const card = RestaurantCard(id: 'r-jollof', name: 'Jollof Junction', isOpen: true);
    const detail = RestaurantDetail(
      restaurant: card,
      sections: [
        MenuSection(category: MenuCategory(id: 'rice', name: 'Rice dishes'), items: [
          MenuItem(id: 'jj-fried', restaurantId: 'r-jollof', name: 'Nigerian Fried Rice', priceKobo: 600000),
          MenuItem(id: 'jj-party-jollof', restaurantId: 'r-jollof', name: 'Party Jollof Rice', priceKobo: 550000),
        ]),
      ],
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(FakeAuthRepository(const GmUser(uid: 'u1'))),
        restaurantDetailProvider.overrideWith((ref, id) async => detail),
      ],
      child: MaterialApp(theme: buildGudMealTheme(Brightness.light), home: const RestaurantScreen(id: 'r-jollof', initialItemId: 'jj-party-jollof')),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(ItemSheet), findsOneWidget);
    expect(find.descendant(of: find.byType(ItemSheet), matching: find.text('Party Jollof Rice')), findsOneWidget);
  });
}
