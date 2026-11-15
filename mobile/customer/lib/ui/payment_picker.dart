import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gud_meal_core/gud_meal_core.dart';

import '../providers.dart';

enum PayMethod { card, wallet, cash }

extension PayMethodCheckout on PayMethod {
  /// Value sent to checkout: none for card (the server picks the gateway and fails over if it is down).
  String? get provider => switch (this) {
        PayMethod.card => null,
        PayMethod.wallet => 'wallet',
        PayMethod.cash => 'cash',
      };
}

/// Card / Gud Meal wallet / pay on delivery. The hints (balance, first order) come from the API so customers see
/// why an option is off; the server checks everything again at checkout.
class PaymentMethodPicker extends ConsumerWidget {
  const PaymentMethodPicker({
    super.key,
    required this.totalKobo,
    required this.value,
    required this.onChanged,
    this.offerCash = true,
    this.cashReason,
  });

  final int totalKobo;
  final PayMethod value;
  final ValueChanged<PayMethod> onChanged;

  /// Packages are paid when booking, so they don't offer cash at the door.
  final bool offerCash;

  /// A reason the screen already knows, e.g. pickup orders.
  final String? cashReason;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(walletProvider);
    final w = wallet.asData?.value;
    final balance = w?.balanceKobo ?? 0;
    final short = totalKobo > balance ? totalKobo - balance : 0;
    final walletOk = w != null && w.enabled && short == 0;

    var cashWhyNot = cashReason;
    if (cashWhyNot == null && offerCash) {
      final completed = ref.watch(orderSummaryProvider).asData?.value.completedCount;
      if (completed != null && completed < 1) cashWhyNot = 'Unlocks after your first order';
    }
    final cashOk = offerCash && cashWhyNot == null;

    if ((value == PayMethod.wallet && w != null && !walletOk) || (value == PayMethod.cash && !cashOk)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => onChanged(PayMethod.card));
    }

    final walletNote = wallet.isLoading
        ? 'Checking your balance…'
        : w == null
            ? 'Not available right now'
            : !w.enabled
                ? 'Not available right now'
                : walletOk
                    ? 'Balance ${formatNaira(balance)} · pays in one tap'
                    : 'Balance ${formatNaira(balance)} · top up ${formatNaira(short)} more';

    return RadioGroup<PayMethod>(
      groupValue: value,
      onChanged: (m) {
        if (m != null) onChanged(m);
      },
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _option(PayMethod.card, Icons.credit_card_rounded, 'Card, bank transfer or USSD', 'On a secure payment page', true),
        _option(PayMethod.wallet, Icons.account_balance_wallet_rounded, 'Gud Meal wallet', walletNote, walletOk),
        if (offerCash)
          _option(PayMethod.cash, Icons.payments_rounded, 'Pay on delivery',
              cashOk ? 'Pay the rider in cash when it arrives' : cashWhyNot!, cashOk),
        if (w != null && w.enabled && !walletOk)
          TextButton.icon(
            onPressed: () => context.push('/wallet'),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Top up your wallet'),
          ),
      ]),
    );
  }

  Widget _option(PayMethod method, IconData icon, String title, String note, bool enabled) => RadioListTile<PayMethod>(
        value: method,
        enabled: enabled,
        contentPadding: EdgeInsets.zero,
        secondary: Icon(icon),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(note),
      );
}
