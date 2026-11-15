import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gud_meal_core/gud_meal_core.dart';

import '../../providers.dart';
import '../../widgets.dart';

const _live = {
  'pending_payment', 'paid', 'submitted_to_restaurant', 'restaurant_accepted', 'preparing', 'ready_for_pickup',
  'rider_assigned', 'picked_up', 'in_transit', 'delivered', 'refund_pending',
};
const _steps = ['Placed', 'Accepted', 'Preparing', 'On the way', 'Delivered'];

/// Live order tracking. Polls the API every 5 s while the order is active (Firestore listener in production).
class OrderScreen extends ConsumerStatefulWidget {
  const OrderScreen({super.key, required this.id, this.paymentReference});
  final String id;

  /// Set when returning from checkout; used to re-verify the payment server-side on resume.
  final String? paymentReference;

  @override
  ConsumerState<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends ConsumerState<OrderScreen> with WidgetsBindingObserver {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      final status = ref.read(orderProvider(widget.id)).value?.status;
      if (status == null || _live.contains(status)) ref.invalidate(orderProvider(widget.id));
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Returning from the payment page: ask the server to verify with the provider (never trust the redirect).
    final reference = widget.paymentReference;
    if (state == AppLifecycleState.resumed && reference != null) {
      ref.read(apiProvider).verifyPayment(reference).whenComplete(() => ref.invalidate(orderProvider(widget.id)));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final order = ref.watch(orderProvider(widget.id));
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Order')),
      body: order.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorRetry(error: e, onRetry: () => ref.invalidate(orderProvider(widget.id))),
        data: (o) {
          final step = o.progress?.step ?? 0;
          final parcel = o.vertical == 'parcel' ? o.parcel : null;
          final steps = switch (o.vertical) {
            'parcel' => const ['Booked', 'Rider found', 'Heading to pickup', 'On the way', 'Delivered'],
            'beauty' => const ['Placed', 'Accepted', 'Packing', 'On the way', 'Delivered'],
            _ => _steps,
          };
          return ListView(padding: const EdgeInsets.all(16), children: [
            Row(children: [
              Expanded(child: Text(o.progress?.label ?? statusLabel(o.status), style: theme.textTheme.headlineSmall)),
              StatusChip(o.status, label: o.vertical == 'parcel' ? o.progress?.label : null),
            ]),
            Text('#${o.shortCode} · ${o.restaurantName}', style: theme.textTheme.bodySmall),
            const SizedBox(height: 16),
            if (step >= 0)
              Row(children: [
                for (var i = 0; i < steps.length; i++)
                  Expanded(
                    child: Column(children: [
                      Container(
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: i < step ? theme.colorScheme.secondary : i == step ? theme.colorScheme.primary : theme.colorScheme.outline,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(steps[i], style: theme.textTheme.labelSmall, textAlign: TextAlign.center),
                    ]),
                  ),
              ]),
            if (o.estimatedDeliveryAt != null && step < 5)
              Padding(padding: const EdgeInsets.only(top: 12), child: Text('Estimated arrival: ${formatLagosTime(o.estimatedDeliveryAt)}')),
            if (o.payment.provider == 'cash' && o.payment.status != 'paid' && !['cancelled', 'draft', 'pending_payment'].contains(o.status))
              Card(
                color: theme.colorScheme.secondaryContainer,
                margin: const EdgeInsets.only(top: 12),
                child: ListTile(
                  leading: const Icon(Icons.payments_rounded),
                  title: Text('Pay ${formatNaira(o.breakdown?.totalKobo)} in cash when it arrives',
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: const Text('Have the exact amount ready if you can. Share your delivery code after you pay.'),
                ),
              ),
            if (o.riderName != null)
              ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.delivery_dining_rounded), title: Text(o.riderName!), subtitle: const Text('Your rider')),
            if (step >= 1 && step < 5) _DeliveryCode(orderId: o.id, recipient: parcel?.dropoff.name),
            if (parcel != null) ...[
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${parcel.size[0].toUpperCase()}${parcel.size.substring(1)} package · ${parcel.category}',
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    if (parcel.description.isNotEmpty) Text(parcel.description),
                    const SizedBox(height: 10),
                    _Stop(icon: Icons.trip_origin_rounded, title: 'Pickup', stop: parcel.pickup),
                    const SizedBox(height: 8),
                    _Stop(icon: Icons.location_on_rounded, title: 'Drop-off', stop: parcel.dropoff),
                    if ((parcel.codAmountKobo ?? 0) > 0) ...[
                      const SizedBox(height: 10),
                      Text(
                        o.cashCollectedAt != null
                            ? 'Collected ${formatNaira(parcel.codAmountKobo)} from ${parcel.dropoff.name}: it is in your wallet as cash-on-delivery money.'
                            : 'The rider collects ${formatNaira(parcel.codAmountKobo)} from ${parcel.dropoff.name} for you.',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ]),
                ),
              ),
            ],
            const Divider(height: 32),
            for (final ln in o.lines)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(children: [Expanded(child: Text('${ln.quantity} × ${ln.name}')), Text(formatNaira(ln.lineTotalKobo))]),
              ),
            const Divider(),
            Row(children: [
              const Expanded(child: Text('Total', style: TextStyle(fontWeight: FontWeight.w800))),
              Text(formatNaira(o.breakdown?.totalKobo), style: const TextStyle(fontWeight: FontWeight.w800)),
            ]),
            if (o.payment.provider == 'wallet' && o.payment.status != 'unpaid')
              const Padding(padding: EdgeInsets.only(top: 4), child: Text('Paid from your Gud Meal wallet')),
            if (o.payment.provider == 'cash' && o.payment.status == 'paid')
              const Padding(padding: EdgeInsets.only(top: 4), child: Text('Paid in cash on delivery')),
            if (o.refundTotalKobo > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Refunded ${formatNaira(o.refundTotalKobo)}${['wallet', 'cash'].contains(o.payment.provider) ? ' to your wallet' : ''}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            if (['draft', 'pending_payment', 'submitted_to_restaurant'].contains(o.status) ||
                (parcel != null && ['paid', 'ready_for_pickup'].contains(o.status)))
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: OutlinedButton(
                  onPressed: () async {
                    await ref.read(apiProvider).cancel(o.id);
                    ref.invalidate(orderProvider(o.id));
                  },
                  child: const Text('Cancel order'),
                ),
              ),
          ]);
        },
      ),
    );
  }
}

class _Stop extends StatelessWidget {
  const _Stop({required this.icon, required this.title, required this.stop});
  final IconData icon;
  final String title;
  final ParcelStop stop;

  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: Theme.of(context).textTheme.labelMedium),
            Text('${stop.name} · ${stop.phone}', style: const TextStyle(fontWeight: FontWeight.w700)),
            Text([stop.line1, stop.area, stop.city].whereType<String>().join(', ')),
          ]),
        ),
      ]);
}

class _DeliveryCode extends ConsumerWidget {
  const _DeliveryCode({required this.orderId, this.recipient});
  final String orderId;

  /// For packages: who receives it (they must give the rider this code).
  final String? recipient;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<String?>(
      future: ref.read(apiProvider).deliveryCode(orderId),
      builder: (context, snap) => snap.data == null
          ? const SizedBox.shrink()
          : Card(
              child: ListTile(
                leading: const Icon(Icons.key_rounded),
                title: Text('Delivery code: ${snap.data}', style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 2)),
                subtitle: Text(recipient == null
                    ? 'Share it only when you have your order.'
                    : 'Send this code to $recipient. The rider needs it to complete the delivery.'),
              ),
            ),
    );
  }
}
