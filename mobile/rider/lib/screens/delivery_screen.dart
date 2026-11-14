import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gud_meal_core/gud_meal_core.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers.dart';

final _deliveryProvider = FutureProvider.family<Order, String>((ref, id) async {
  final list = await ref.watch(apiProvider).activeDeliveries();
  return list.firstWhere((o) => o.id == id, orElse: () => throw ApiException(404, 'not_found', 'This delivery is no longer active'));
});

/// Opens turn-by-turn navigation in Google Maps (riders' preferred navigation app).
Future<void> navigateTo(GeoPoint p) => launchUrl(
      Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${p.lat},${p.lng}&travelmode=driving'),
      mode: LaunchMode.externalApplication,
    );

class DeliveryScreen extends ConsumerStatefulWidget {
  const DeliveryScreen({super.key, required this.orderId});
  final String orderId;

  @override
  ConsumerState<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends ConsumerState<DeliveryScreen> {
  final _code = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _act(Future<Order> Function(GudMealApi api) action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final updated = await action(ref.read(apiProvider));
      ref.invalidate(_deliveryProvider(widget.orderId));
      ref.invalidate(activeDeliveriesProvider);
      if (updated.status == 'delivered' || updated.status == 'completed') {
        ref.invalidate(earningsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Delivered — well done!')));
          context.go('/');
        }
      }
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final delivery = ref.watch(_deliveryProvider(widget.orderId));
    return Scaffold(
      appBar: AppBar(title: const Text('Delivery')),
      body: delivery.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (o) => ListView(padding: const EdgeInsets.all(16), children: [
          Text('#${o.shortCode} · ${statusLabel(o.status)}', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.storefront_rounded),
              title: Text(o.restaurantName),
              subtitle: Text(o.restaurantAddress ?? ''),
              trailing: o.restaurantLocation == null ? null : IconButton(tooltip: 'Navigate', icon: const Icon(Icons.navigation_rounded), onPressed: () => navigateTo(o.restaurantLocation!)),
            ),
          ),
          if (o.deliveryAddress != null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.home_rounded),
                title: Text(o.customerName ?? 'Customer'),
                subtitle: Text([o.deliveryAddress!.line1, o.deliveryAddress!.area, o.deliveryAddress!.instructions].whereType<String>().join(' · ')),
                trailing: IconButton(tooltip: 'Navigate', icon: const Icon(Icons.navigation_rounded), onPressed: () => navigateTo(o.deliveryAddress!.location)),
              ),
            ),
          const SizedBox(height: 8),
          Text('Items: ${o.lines.map((l) => '${l.quantity}× ${l.name}').join(', ')}'),
          Text('You earn ${formatNaira(o.riderPayKobo)}', style: const TextStyle(fontWeight: FontWeight.w700)),
          if (o.status == 'rider_assigned' && o.readyAt == null)
            const Padding(padding: EdgeInsets.only(top: 8), child: Text('The kitchen is still preparing this order.')),
          const SizedBox(height: 20),
          if (o.status == 'rider_assigned')
            FilledButton(onPressed: _busy ? null : () => _act((api) => api.pickup(o.id)), child: const Text('Confirm pickup')),
          if (o.status == 'picked_up')
            FilledButton(onPressed: _busy ? null : () => _act((api) => api.inTransit(o.id)), child: const Text('Start trip to customer')),
          if (o.status == 'picked_up' || o.status == 'in_transit') DeliveryCodeForm(controller: _code, busy: _busy, onSubmit: (code) => _act((api) => api.deliver(o.id, code))),
          if (_error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
        ]),
      ),
    );
  }
}

/// 4-digit code the customer reads out on arrival. Validated locally, verified by the API (5 attempts max).
class DeliveryCodeForm extends StatelessWidget {
  const DeliveryCodeForm({super.key, required this.controller, required this.onSubmit, this.busy = false});
  final TextEditingController controller;
  final ValueChanged<String> onSubmit;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            maxLength: 4,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 28, letterSpacing: 12, fontWeight: FontWeight.w800),
            decoration: const InputDecoration(labelText: "Customer's delivery code", counterText: ''),
          ),
          const SizedBox(height: 8),
          FilledButton(onPressed: busy || value.text.length != 4 ? null : () => onSubmit(value.text), child: const Text('Complete delivery')),
        ]),
      ),
    );
  }
}
