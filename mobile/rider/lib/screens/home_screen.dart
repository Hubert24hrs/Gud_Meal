import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gud_meal_core/gud_meal_core.dart';

import '../providers.dart';

class RiderHomeScreen extends ConsumerStatefulWidget {
  const RiderHomeScreen({super.key});

  @override
  ConsumerState<RiderHomeScreen> createState() => _RiderHomeScreenState();
}

class _RiderHomeScreenState extends ConsumerState<RiderHomeScreen> {
  Timer? _poll;
  String? _message;

  @override
  void initState() {
    super.initState();
    // Offers expire in ~45 s, so poll quickly. FCM push wakes the app in the background.
    _poll = Timer.periodic(const Duration(seconds: 5), (_) {
      ref.invalidate(offersProvider);
      ref.invalidate(activeDeliveriesProvider);
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _setOnline(bool online) async {
    final reporter = ref.read(locationReporterProvider);
    try {
      if (online && !await reporter.start()) {
        setState(() => _message = 'Location permission is required to go online.');
        return;
      }
      await ref.read(apiProvider).setOnline(online);
      if (!online) await reporter.stop();
      ref.invalidate(riderProfileProvider);
      setState(() => _message = null);
    } on ApiException catch (e) {
      await reporter.stop();
      setState(() => _message = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(riderProfileProvider);
    final offers = ref.watch(offersProvider);
    final active = ref.watch(activeDeliveriesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(profile.value?.name ?? 'Gud Meal Rider'),
        actions: [
          IconButton(tooltip: 'Earnings', onPressed: () => context.push('/earnings'), icon: const Icon(Icons.account_balance_wallet_rounded)),
          IconButton(tooltip: 'Sign out', onPressed: () => ref.read(authRepositoryProvider).signOut(), icon: const Icon(Icons.logout_rounded)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: theme.colorScheme.error,
        foregroundColor: Colors.white,
        onPressed: () => _sos(context),
        icon: const Icon(Icons.sos_rounded),
        label: const Text('Emergency'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(offersProvider);
          ref.invalidate(activeDeliveriesProvider);
        },
        child: ListView(padding: const EdgeInsets.all(16), children: [
          profile.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('$e'),
            data: (p) => Card(
              child: SwitchListTile(
                value: p.isOnline,
                onChanged: p.status == 'active' ? _setOnline : null,
                title: Text(p.isOnline ? 'You are online' : 'You are offline', style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text(p.status == 'active'
                    ? '${p.vehicle} · ★ ${p.rating.toStringAsFixed(2)} · ${p.completedDeliveries} deliveries'
                    : 'Your account is ${p.status}. Contact support.'),
              ),
            ),
          ),
          if (_message != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_message!, style: TextStyle(color: theme.colorScheme.error))),
          const SizedBox(height: 16),
          Text('Active deliveries', style: theme.textTheme.titleLarge),
          ...active.when(
            loading: () => [const SizedBox.shrink()],
            error: (e, _) => [Text('$e')],
            data: (list) => list.isEmpty
                ? [const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('No active deliveries'))]
                : [
                    for (final o in list)
                      Card(
                        child: ListTile(
                          title: Text('${o.restaurantName} · #${o.shortCode}', style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text('${statusLabel(o.status)} · earn ${formatNaira(o.riderPayKobo)}'),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => context.push('/deliveries/${o.id}'),
                        ),
                      ),
                  ],
          ),
          const SizedBox(height: 16),
          Text('New offers', style: theme.textTheme.titleLarge),
          ...offers.when(
            loading: () => [const SizedBox.shrink()],
            error: (e, _) => [Text('$e')],
            data: (list) => list.isEmpty
                ? [const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Waiting for orders near you…'))]
                : [for (final offer in list) OfferCard(offer: offer)],
          ),
          const SizedBox(height: 80),
        ]),
      ),
    );
  }

  Future<void> _sos(BuildContext context) async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Report an emergency'),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'What is happening?'), maxLines: 3),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Send to Gud Meal')),
        ],
      ),
    );
    if (ok == true && controller.text.trim().length >= 3) {
      await ref.read(apiProvider).emergency(controller.text.trim(), ref.read(locationReporterProvider).last);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Our operations team has been alerted. If you are in danger, call 112.')));
      }
    }
    controller.dispose();
  }
}

/// A delivery offer with a live countdown. Accepting after expiry is impossible (the API rejects it too).
class OfferCard extends ConsumerStatefulWidget {
  const OfferCard({super.key, required this.offer, this.now});
  final DeliveryOffer offer;
  final DateTime Function()? now;

  @override
  ConsumerState<OfferCard> createState() => _OfferCardState();
}

class _OfferCardState extends ConsumerState<OfferCard> {
  Timer? _tick;
  bool _busy = false;

  DateTime _now() => (widget.now ?? DateTime.now)().toUtc();

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => mounted ? setState(() {}) : null);
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.offer;
    final remaining = o.expiresAt.toUtc().difference(_now()).inSeconds;
    final expired = remaining <= 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(o.restaurantName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
            Text(expired ? 'Expired' : '${remaining}s', style: TextStyle(fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.primary)),
          ]),
          Text('${o.distanceToRestaurantKm.toStringAsFixed(1)} km to pickup${o.dropoffArea != null ? ' · drop-off in ${o.dropoffArea}' : ''}'),
          Text('You earn ${formatNaira(o.payoutKobo)}', style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: FilledButton(
                onPressed: expired || _busy
                    ? null
                    : () async {
                        setState(() => _busy = true);
                        try {
                          final order = await ref.read(apiProvider).acceptOffer(o.id);
                          ref.invalidate(offersProvider);
                          ref.invalidate(activeDeliveriesProvider);
                          if (context.mounted) context.push('/deliveries/${order.id}');
                        } on ApiException catch (e) {
                          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
                        } finally {
                          if (mounted) setState(() => _busy = false);
                        }
                      },
                child: const Text('Accept'),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: expired || _busy
                  ? null
                  : () async {
                      await ref.read(apiProvider).declineOffer(o.id, 'Declined in app');
                      ref.invalidate(offersProvider);
                    },
              child: const Text('Decline'),
            ),
          ]),
        ]),
      ),
    );
  }
}
