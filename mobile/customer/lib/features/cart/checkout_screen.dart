import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gud_meal_core/gud_meal_core.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers.dart';
import 'cart_controller.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _line1 = TextEditingController();
  final _phone = TextEditingController();
  final _voucher = TextEditingController();
  String _fulfillment = 'delivery';
  Quote? _quote;
  String? _error;
  bool _busy = false;
  final _orderKey = newIdempotencyKey('order');
  final _checkoutKey = newIdempotencyKey('checkout');

  @override
  void dispose() {
    _line1.dispose();
    _phone.dispose();
    _voucher.dispose();
    super.dispose();
  }

  DeliveryAddress? get _address {
    if (_fulfillment == 'pickup') return null;
    if (_line1.text.trim().length < 3) return null;
    final area = ref.read(areaProvider);
    return DeliveryAddress(line1: _line1.text.trim(), area: area.name, location: area.location, contactPhone: _phone.text.trim().isEmpty ? null : _phone.text.trim());
  }

  Future<void> _getQuote() async {
    final cart = ref.read(cartProvider);
    if (_fulfillment == 'delivery' && _address == null) {
      setState(() => _error = 'Enter your street address');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final q = await ref.read(apiProvider).quote(
            restaurantId: cart.restaurantId!,
            lines: cart.toLines(),
            fulfillment: _fulfillment,
            address: _address,
            voucher: _voucher.text.trim().toUpperCase(),
          );
      setState(() => _quote = q);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pay() async {
    final quote = _quote;
    if (quote == null) return;
    setState(() => _busy = true);
    try {
      final api = ref.read(apiProvider);
      final order = await api.createOrder(quote.id, _orderKey, contactPhone: _phone.text.trim().isEmpty ? null : _phone.text.trim());
      final checkout = await api.checkout(order.id, _checkoutKey);
      ref.read(cartProvider.notifier).clear();
      // Provider-hosted payment page: card data never touches the app.
      await launchUrl(Uri.parse(checkout.authorizationUrl), mode: LaunchMode.inAppBrowserView);
      if (mounted) context.go('/orders/${order.id}?ref=${checkout.reference}');
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final theme = Theme.of(context);
    if (cart.isEmpty) {
      return Scaffold(appBar: AppBar(title: const Text('Checkout')), body: const Center(child: Text('Your cart is empty')));
    }
    final b = _quote?.breakdown;
    return Scaffold(
      appBar: AppBar(title: Text(cart.restaurantName ?? 'Checkout')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        for (final i in cart.items)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('${i.quantity} × ${i.name}'),
            subtitle: i.selectionLabels.isEmpty ? null : Text(i.selectionLabels.join(' · ')),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(
                tooltip: 'Remove one',
                onPressed: () {
                  ref.read(cartProvider.notifier).setQuantity(i.key, i.quantity - 1);
                  setState(() => _quote = null);
                },
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Text(formatNaira(i.unitPriceKobo * i.quantity)),
            ]),
          ),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'delivery', label: Text('Delivery'), icon: Icon(Icons.delivery_dining_rounded)),
            ButtonSegment(value: 'pickup', label: Text('Pickup'), icon: Icon(Icons.storefront_rounded)),
          ],
          selected: {_fulfillment},
          onSelectionChanged: (s) => setState(() {
            _fulfillment = s.first;
            _quote = null;
          }),
        ),
        if (_fulfillment == 'delivery') ...[
          const SizedBox(height: 12),
          Text('Delivering in ${ref.watch(areaProvider).name}', style: theme.textTheme.bodySmall),
          const SizedBox(height: 8),
          TextField(controller: _line1, decoration: const InputDecoration(labelText: 'Street address'), onChanged: (_) => setState(() => _quote = null)),
          const SizedBox(height: 8),
          TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone for the rider')),
        ],
        const SizedBox(height: 8),
        TextField(controller: _voucher, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(labelText: 'Voucher (optional)')),
        const SizedBox(height: 16),
        if (b != null) ...[
          _row('Subtotal', b.subtotalKobo),
          if (b.deliveryFeeKobo > 0) _row('Delivery', b.deliveryFeeKobo),
          _row('Service fee', b.serviceFeeKobo + b.smallOrderFeeKobo),
          _row('VAT (7.5% on fees)', b.vatKobo),
          if (b.discountKobo > 0) _row('Discount', -b.discountKobo),
          const Divider(),
          _row('Total', b.totalKobo, bold: true),
          Text('Arrives around ${formatLagosTime(_quote!.estimatedDeliveryAt)} · price held until ${formatLagosTime(_quote!.expiresAt)}',
              style: theme.textTheme.bodySmall),
        ],
        if (_error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_error!, style: TextStyle(color: theme.colorScheme.error))),
      ]),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: _busy ? null : (_quote == null ? _getQuote : _pay),
            child: Text(_busy ? 'Please wait…' : _quote == null ? 'Review total' : 'Pay ${formatNaira(_quote!.breakdown.totalKobo)}'),
          ),
        ),
      ),
    );
  }

  Widget _row(String label, int kobo, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(children: [
          Expanded(child: Text(label, style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w400))),
          Text(formatNaira(kobo), style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w400)),
        ]),
      );
}
