import 'package:flutter_test/flutter_test.dart';
import 'package:gud_meal_core/gud_meal_core.dart';

/// Responses copied from the running API. Both broke the rider app in a phone test: the earnings field name has a
/// digit (`earned_last_7_days_kobo`, which code generation spells `earned_last7_days_kobo`) and riders get
/// `items` (no prices) instead of the customer's priced `lines`.
void main() {
  test('rider earnings parse the API response', () {
    final earnings = Earnings.fromJson({
      'balance_kobo': 261190,
      'pending_payouts_kobo': 0,
      'cash_held_kobo': 0,
      'available_kobo': 261190,
      'deliveries_completed': 1,
      'earned_last_7_days_kobo': 60990,
      'payouts': [
        {'id': 'p1', 'amount_kobo': 100000, 'status': 'paid', 'requested_at': '2026-11-16T23:43:08.785935'},
      ],
    });
    expect(earnings.earnedLast7DaysKobo, 60990);
    expect(earnings.availableKobo, 261190);
  });

  test("a rider's order lists what to collect without prices", () {
    final order = Order.fromJson({
      'id': 'o1',
      'short_code': 'D6JM7E',
      'vertical': 'food',
      'status': 'rider_assigned',
      'restaurant_name': 'Jollof Junction',
      'items': [
        {'name': 'Party Jollof Rice', 'quantity': 2},
        {'name': 'Chapman', 'quantity': 1},
      ],
      'rider_pay_kobo': 60990,
    });
    expect(order.items.map((i) => '${i.quantity}× ${i.name}'), ['2× Party Jollof Rice', '1× Chapman']);
    expect(order.lines, isEmpty);
  });
}
