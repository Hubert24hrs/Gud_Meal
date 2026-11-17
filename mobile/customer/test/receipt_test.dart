import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gud_meal_core/gud_meal_core.dart';
import 'package:gud_meal_customer/features/orders/order_screen.dart';
import 'package:gud_meal_customer/features/receipts/receipt_printer.dart';
import 'package:gud_meal_customer/features/receipts/receipt_screen.dart';
import 'package:gud_meal_customer/providers.dart';

/// The receipt printer shown after a payment (ADR-0019).
const sample = Receipt(
  id: 'o1',
  number: 'GM-7K2M9P',
  orderId: 'o1',
  orderCode: '7K2M9P',
  customerName: 'Ada Obi',
  service: 'food',
  serviceName: 'Food',
  seller: 'Jollof Junction',
  sellerAddress: '12 Admiralty Way, Lekki Phase 1',
  lines: [
    ReceiptLine(name: 'Party Jollof Rice', quantity: 2, amountKobo: 1100000, details: ['Protein: Chicken']),
    ReceiptLine(name: 'Chapman', quantity: 2, amountKobo: 300000),
  ],
  charges: [
    ReceiptCharge(label: 'Subtotal', amountKobo: 1400000),
    ReceiptCharge(label: 'Delivery fee', amountKobo: 90000),
    ReceiptCharge(label: 'Service fee', amountKobo: 70000),
    ReceiptCharge(label: 'VAT', amountKobo: 12000),
    ReceiptCharge(label: 'Discount', amountKobo: -50000),
  ],
  totalKobo: 1522000,
  paidWith: 'Card, bank transfer or USSD',
  paymentReference: 'GM-ABC123',
);

class _Api extends GudMealApi {
  _Api({this.paid = true, this.failSaving = false}) : super(baseUrl: 'http://fake', token: () async => 't');
  bool paid;
  final bool failSaving;
  final printed = <String>[];

  @override
  Future<Receipt> receipt(String orderId) async {
    if (!paid) throw ApiException(409, 'order_not_paid', 'This order has not been paid for yet, so there is no receipt');
    return receipt_;
  }

  Receipt get receipt_ => sample.copyWith(saved: printed.isNotEmpty, printCount: printed.length);

  @override
  Future<Receipt> printReceipt(String orderId) async {
    if (failSaving) throw ApiException(503, 'unavailable', 'offline');
    printed.add(orderId);
    return receipt_;
  }

  @override
  Future<List<Receipt>> receipts() async => printed.isEmpty ? const [] : [receipt_];

  @override
  Future<Order> order(String id) async => Order(
        id: id,
        shortCode: '7K2M9P',
        status: paid ? 'submitted_to_restaurant' : 'pending_payment',
        restaurantName: 'Jollof Junction',
        payment: OrderPayment(provider: 'wallet', status: paid ? 'paid' : 'unpaid'),
      );

  @override
  Future<CheckoutResult> checkout(String orderId, String idempotencyKey, {String? provider}) async {
    if (provider == 'wallet') paid = true;
    return CheckoutResult(orderId: orderId, reference: 'GM-7K2M9P-1', amountKobo: 1522000, provider: provider ?? 'local_sandbox');
  }
}

Future<void> _pump(WidgetTester tester, Widget home, {_Api? api, bool still = false}) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 2.6;
  addTearDown(tester.view.reset);
  if (still) {
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  }
  final router = GoRouter(routes: [
    GoRoute(path: '/', builder: (_, _) => home),
    GoRoute(path: '/receipts', builder: (_, _) => const ReceiptsScreen()),
    GoRoute(
      path: '/orders/:id',
      builder: (_, s) => Scaffold(body: Text('ORDER ${s.pathParameters['id']}')),
      routes: [GoRoute(path: 'receipt', builder: (_, s) => Scaffold(body: Text('RECEIPT ${s.pathParameters['id']}')))],
    ),
  ]);
  await tester.pumpWidget(ProviderScope(
    overrides: [authRepositoryProvider.overrideWithValue(FakeAuthRepository()), apiProvider.overrideWithValue(api ?? _Api())],
    child: MaterialApp.router(theme: buildGudMealTheme(Brightness.light), routerConfig: router),
  ));
  await tester.pump();
  await tester.pump();
}

final printButton = find.byKey(const ValueKey('receipt-print'));
final strip = find.byKey(const ValueKey('receipt-strip'));

void main() {
  testWidgets('a Gud Meal printer that says what to do, then prints what was paid for', (tester) async {
    var prints = 0;
    await _pump(tester, Scaffold(body: ReceiptPrinter(receipt: sample, onPrint: () => prints++)));
    expect(find.text('Gud Meal'), findsNWidgets(2)); // the maker's mark (drawn twice for its engraved look)
    expect(find.text('PRINT'), findsOneWidget);
    expect(find.text('Press the red PRINT button to print your receipt'), findsOneWidget);
    expect(find.text('Total paid'), findsNothing);
    expect(strip, findsNothing);

    await tester.tap(printButton);
    await tester.pump(const Duration(milliseconds: 200));
    expect(prints, 1);
    expect(find.text('Printing your receipt… press PRINT to stop'), findsOneWidget);
    for (final text in [
      'JOLLOF JUNCTION', '12 Admiralty Way, Lekki Phase 1', 'Receipt GM-7K2M9P', 'Order #7K2M9P', 'Ada Obi', '2 x Party Jollof Rice',
      '₦11,000', 'Protein: Chicken', '2 x Chapman', 'Subtotal', '₦14,000', 'Delivery fee', 'Service fee', 'VAT', '-₦500',
      'Total paid', '₦15,220', 'Card, bank transfer or USSD', 'Ref GM-ABC123', 'THANK YOU',
    ]) {
      expect(find.text(text), findsOneWidget, reason: text);
    }

    // The paper feeds out bit by bit, then the printer rests.
    final half = tester.getSize(strip).height;
    await tester.pump(const Duration(seconds: 7));
    await tester.pump();
    expect(tester.getSize(strip).height, greaterThan(half));
    expect(find.text('Pull the receipt to tear it off, or press PRINT for another copy'), findsOneWidget);

    // PRINT again joins another copy onto the strip; pressing it mid-print stops the paper.
    await tester.tap(printButton);
    await tester.pump(const Duration(milliseconds: 200));
    expect(prints, 2);
    expect(find.text('Total paid'), findsNWidgets(2));
    await tester.tap(printButton);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Pull the receipt to tear it off, or press PRINT for another copy'), findsOneWidget);
    expect(prints, 2);

    // Pull the paper: it tears off and flies away.
    await tester.drag(strip, const Offset(0, -160));
    await tester.pump();
    expect(strip, findsNothing);
    expect(find.text('Press the red PRINT button to print your receipt'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(find.text('Total paid'), findsNothing);
  });

  testWidgets('the same receipt always has the same barcode; a package receipt has no items', (tester) async {
    expect(ReceiptPaper.barsFor('GM-7K2M9P'), ReceiptPaper.barsFor('GM-7K2M9P'));
    expect(ReceiptPaper.barsFor('GM-7K2M9P'), isNot(ReceiptPaper.barsFor('GM-AAAAAA')));
    expect(ReceiptPaper.barsFor('GM-7K2M9P').every((w) => w >= 1 && w <= 3), isTrue);

    await _pump(
      tester,
      const Scaffold(
        body: SingleChildScrollView(
          child: ReceiptPaper(
            receipt: Receipt(
              id: 'p1', number: 'GM-PKG001', orderId: 'p1', orderCode: 'PKG001', service: 'parcel', serviceName: 'Package Delivery',
              seller: 'Gud Meal', sellerAddress: 'Package Delivery', summary: ['From Lekki Phase 1 to Victoria Island', 'Small package: documents'],
              charges: [ReceiptCharge(label: 'Delivery fee', amountKobo: 150000)], totalKobo: 150000, paidWith: 'Gud Meal wallet',
              refundedKobo: 150000, savingsKobo: 20000,
            ),
          ),
        ),
      ),
    );
    expect(find.text('GUD MEAL'), findsOneWidget);
    expect(find.text('From Lekki Phase 1 to Victoria Island'), findsOneWidget);
    expect(find.text('Gud Meal wallet'), findsOneWidget);
    expect(find.text('Refunded'), findsOneWidget);
    expect(find.text('Saved with Gud Meal Plus'), findsOneWidget);
    expect(find.textContaining('Ref '), findsNothing);
  });

  testWidgets('PRINT keeps the receipt under My receipts', (tester) async {
    final api = _Api();
    await _pump(tester, const ReceiptScreen(orderId: 'o1'), api: api, still: true);
    expect(find.text('Saved in My receipts'), findsNothing); // not kept until it is printed

    await tester.tap(printButton);
    await tester.pump(const Duration(milliseconds: 250)); // the button is pressed, then the paper starts
    await tester.pumpAndSettle();
    expect(api.printed, ['o1']);
    expect(find.text('Saved in My receipts'), findsOneWidget);

    // A long receipt can be read in full.
    await tester.tap(find.text('Read receipt'));
    await tester.pumpAndSettle();
    expect(find.text('THANK YOU'), findsNWidgets(2));
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Saved in My receipts')); // the green button is the way to the list
    await tester.pumpAndSettle();
    expect(find.text('Jollof Junction'), findsOneWidget);
    expect(find.textContaining('Food · GM-7K2M9P'), findsOneWidget);
    expect(find.text('₦15,220'), findsOneWidget);
    await tester.tap(find.text('Jollof Junction'));
    await tester.pumpAndSettle();
    expect(find.text('RECEIPT o1'), findsOneWidget);
  });

  testWidgets('says so when the receipt could not be saved, and has no receipt before payment', (tester) async {
    await _pump(tester, const ReceiptScreen(orderId: 'o1'), api: _Api(failSaving: true), still: true);
    await tester.tap(printButton);
    await tester.pump(const Duration(milliseconds: 250)); // the button is pressed, then the paper starts
    await tester.pumpAndSettle();
    expect(find.text('Could not save the receipt. Check your connection, then press PRINT again'), findsOneWidget);
    expect(find.text('Saved in My receipts'), findsNothing);

    await _pump(tester, const ReceiptScreen(orderId: 'o2'), api: _Api(paid: false), still: true);
    await tester.pumpAndSettle();
    expect(find.text('No receipt yet'), findsOneWidget);
    expect(printButton, findsNothing);
    await tester.tap(find.text('Back to the order'));
    await tester.pumpAndSettle();
    expect(find.text('ORDER o2'), findsOneWidget);
  });

  testWidgets('My receipts starts empty', (tester) async {
    await _pump(tester, const ReceiptsScreen(), still: true);
    await tester.pumpAndSettle();
    expect(find.text('No receipts yet'), findsOneWidget);
  });

  testWidgets('the receipt printer comes up by itself right after paying, and stays one tap away afterwards', (tester) async {
    // Paid from the wallet at checkout: the order screen opens with `paid=1`.
    await _pump(tester, const OrderScreen(id: 'o1', justPaid: true), still: true);
    await tester.pumpAndSettle();
    expect(find.text('RECEIPT o1'), findsOneWidget);
    await tester.pumpWidget(const SizedBox()); // dispose the screen and its refresh timer

    // An order opened later does not interrupt, but offers its receipt.
    await _pump(tester, const OrderScreen(id: 'o1'), still: true);
    await tester.pumpAndSettle();
    expect(find.text('RECEIPT o1'), findsNothing);
    await tester.scrollUntilVisible(find.text('Print my receipt'), 200);
    await tester.tap(find.text('Print my receipt'));
    await tester.pumpAndSettle();
    expect(find.text('RECEIPT o1'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());

    // Paying an unpaid order from its own screen brings the printer up too; an unpaid order has no receipt.
    final api = _Api(paid: false);
    await _pump(tester, const OrderScreen(id: 'o1'), api: api, still: true);
    await tester.pumpAndSettle();
    expect(find.text('Print my receipt'), findsNothing);
    await tester.tap(find.text('Pay from my Gud Meal wallet'));
    await tester.pumpAndSettle();
    expect(find.text('RECEIPT o1'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
