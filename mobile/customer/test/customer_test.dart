import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gud_meal_core/gud_meal_core.dart';
import 'package:gud_meal_customer/features/auth/sign_in_screen.dart';
import 'package:gud_meal_customer/features/cart/cart_controller.dart';
import 'package:gud_meal_customer/features/cart/checkout_screen.dart';
import 'package:gud_meal_customer/features/restaurant/restaurant_screen.dart';
import 'package:gud_meal_customer/providers.dart';

const suya = RestaurantCard(id: 'r-suya', name: 'Suya Lane', cuisines: ['Grills'], area: 'Victoria Island', rating: 4.8, isOpen: true, etaMinutes: 40, deliveryFeeKobo: 175000);
const amala = RestaurantCard(id: 'r-amala', name: "Mama Ayo's Kitchen", cuisines: ['Nigerian'], area: 'Yaba', rating: 4.6, isOpen: false);

const heat = OptionGroup(id: 'heat', name: 'Yaji level', minSelect: 1, maxSelect: 1, choices: [
  OptionChoice(id: 'mild', name: 'Mild'),
  OptionChoice(id: 'fire', name: 'Fire', priceDeltaKobo: 20000),
]);
const beefSuya = MenuItem(id: 'sl-beef', restaurantId: 'r-suya', name: 'Beef Suya', priceKobo: 450000, optionGroupIds: ['heat']);

CartItem item(String id, int qty, {List<OptionSelection> sel = const []}) =>
    CartItem(itemId: id, name: id, unitPriceKobo: 100000, quantity: qty, selections: sel);

/// Records quotes; never hits the network.
class FakeApi extends GudMealApi {
  FakeApi() : super(baseUrl: 'http://fake', token: () async => 'tok');
  final quotes = <List<CartLine>>[];

  @override
  Future<Quote> quote({required String restaurantId, required List<CartLine> lines, required String fulfillment, DeliveryAddress? address, String? voucher}) async {
    quotes.add(lines);
    return Quote(
      id: 'q1', restaurantName: 'Suya Lane', fulfillment: fulfillment, etaMinutes: 40,
      breakdown: const PriceBreakdown(subtotalKobo: 900000, deliveryFeeKobo: 175000, serviceFeeKobo: 45000, vatKobo: 16500, totalKobo: 1136500),
      estimatedDeliveryAt: DateTime.utc(2026, 11, 14, 19, 30), expiresAt: DateTime.utc(2026, 11, 14, 19, 0),
    );
  }
}

Widget harness(Widget child, {List overrides = const []}) => ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(FakeAuthRepository(const GmUser(uid: 'u1'))), ...overrides],
      child: MaterialApp(theme: buildGudMealTheme(Brightness.light), home: child),
    );

void main() {
  group('CartController', () {
    test('merges identical lines and totals the subtotal', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final cart = c.read(cartProvider.notifier);
      cart.add('r1', 'R1', item('a', 1));
      cart.add('r1', 'R1', item('a', 2));
      cart.add('r1', 'R1', item('b', 1));
      final state = c.read(cartProvider);
      expect(state.count, 4);
      expect(state.subtotalKobo, 400000);
      expect(state.toLines().map((l) => l.itemId), ['a', 'b']);
    });

    test('refuses mixing restaurants unless replacing', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final cart = c.read(cartProvider.notifier);
      cart.add('r1', 'R1', item('a', 1));
      expect(cart.add('r2', 'R2', item('b', 1)), isFalse);
      expect(cart.add('r2', 'R2', item('b', 1), replace: true), isTrue);
      expect(c.read(cartProvider).restaurantId, 'r2');
      expect(c.read(cartProvider).items.single.itemId, 'b');
    });

    test('quantity zero removes the line and empties the cart', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final cart = c.read(cartProvider.notifier)..add('r1', 'R1', item('a', 1));
      cart.setQuantity(c.read(cartProvider).items.single.key, 0);
      expect(c.read(cartProvider).isEmpty, isTrue);
      expect(c.read(cartProvider).restaurantId, isNull);
    });
  });

  test('Nigerian phone numbers normalise to E.164', () {
    expect(normaliseNigerianPhone('0803 123 4567'), '+2348031234567');
    expect(normaliseNigerianPhone('+2349061234567'), '+2349061234567');
    expect(normaliseNigerianPhone('8031234567'), '+2348031234567');
    expect(normaliseNigerianPhone('12345'), isNull);
  });

  testWidgets('item sheet requires the mandatory choice before adding', (tester) async {
    final container = ProviderContainer(overrides: [authRepositoryProvider.overrideWithValue(FakeAuthRepository())]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Scaffold(body: ItemSheet(item: beefSuya, groups: const {'heat': heat}, restaurantId: 'r-suya', restaurantName: 'Suya Lane')),
      ),
    ));
    final addButton = find.widgetWithText(FilledButton, 'Add · ₦4,500');
    expect(tester.widget<FilledButton>(addButton).onPressed, isNull);
    await tester.tap(find.text('Fire +₦200'));
    await tester.pump();
    final enabled = find.widgetWithText(FilledButton, 'Add · ₦4,700');
    expect(tester.widget<FilledButton>(enabled).onPressed, isNotNull);
    await tester.tap(enabled);
    await tester.pump();
    final cart = container.read(cartProvider);
    expect(cart.items.single.selections.single.choiceIds, ['fire']);
    expect(cart.subtotalKobo, 470000);
  });

  testWidgets('checkout asks the server for the total before paying', (tester) async {
    final api = FakeApi();
    final container = ProviderContainer(overrides: [
      authRepositoryProvider.overrideWithValue(FakeAuthRepository(const GmUser(uid: 'u1'))),
      apiProvider.overrideWithValue(api),
    ]);
    addTearDown(container.dispose);
    container.read(cartProvider.notifier).add('r-suya', 'Suya Lane', item('sl-beef', 2));
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const MaterialApp(home: CheckoutScreen())));
    await tester.tap(find.text('Review total'));
    await tester.pump();
    expect(find.text('Enter your street address'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Street address'), '5 Admiralty Road');
    await tester.tap(find.text('Review total'));
    await tester.pumpAndSettle();
    expect(api.quotes.single.single.quantity, 2);
    expect(find.text('Pay ₦11,365'), findsOneWidget);
    expect(find.text('₦1,750'), findsOneWidget);
  });
}
