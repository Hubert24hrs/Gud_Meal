import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gud_meal_core/gud_meal_core.dart';
import 'package:gud_meal_customer/features/orders/order_screen.dart';
import 'package:gud_meal_customer/providers.dart';

/// An order whose payment page was closed before paying (found on a phone test: the order sat at
/// "Awaiting payment" with only a Cancel button).
class _UnpaidOrderApi extends GudMealApi {
  _UnpaidOrderApi() : super(baseUrl: 'http://fake', token: () async => 't');
  final checkouts = <String?>[];
  var paid = false;

  @override
  Future<Order> order(String id) async => Order(
        id: id,
        shortCode: 'MZGBBZ',
        vertical: 'waybill',
        status: paid ? 'paid' : 'pending_payment',
        restaurantName: 'Gud Meal Waybill',
        payment: OrderPayment(provider: 'local_sandbox', status: paid ? 'paid' : 'pending'),
      );

  @override
  Future<CheckoutResult> checkout(String orderId, String idempotencyKey, {String? provider}) async {
    checkouts.add(provider);
    if (provider == 'wallet') paid = true;
    return CheckoutResult(orderId: orderId, reference: 'GM-MZGBBZ-1', amountKobo: 1333000, provider: provider ?? 'local_sandbox');
  }
}

void main() {
  testWidgets('an unpaid order can still be paid from the order screen', (tester) async {
    final api = _UnpaidOrderApi();
    await tester.pumpWidget(ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(FakeAuthRepository()), apiProvider.overrideWithValue(api)],
      child: MaterialApp(theme: buildGudMealTheme(Brightness.light), home: const OrderScreen(id: 'o1')),
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining('Finish paying'), findsOneWidget);
    expect(find.text('Pay by card, transfer or USSD'), findsOneWidget);

    await tester.tap(find.text('Pay from my Gud Meal wallet'));
    await tester.pumpAndSettle();
    expect(api.checkouts, ['wallet']);
    expect(find.textContaining('Finish paying'), findsNothing); // paid: the order goes ahead

    await tester.pumpWidget(const SizedBox()); // dispose the screen and its refresh timer
  });
}
