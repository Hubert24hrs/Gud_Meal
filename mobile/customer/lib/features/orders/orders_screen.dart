import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gud_meal_core/gud_meal_core.dart';

import '../../providers.dart';
import '../../widgets.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(myOrdersProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Your orders'), actions: [
        IconButton(
          tooltip: 'Sign out',
          icon: const Icon(Icons.logout_rounded),
          onPressed: () => ref.read(authRepositoryProvider).signOut(),
        ),
      ]),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(myOrdersProvider.future),
        child: orders.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ErrorRetry(error: e, onRetry: () => ref.invalidate(myOrdersProvider)),
          data: (list) => list.isEmpty
              ? ListView(children: const [SizedBox(height: 160), Center(child: Text('No orders yet'))])
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final o = list[i];
                    return Card(
                      child: ListTile(
                        title: Text(o.restaurantName, style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text('#${o.shortCode} · ${formatNaira(o.breakdown?.totalKobo)}'),
                        trailing: StatusChip(o.status),
                        onTap: () => context.push('/orders/${o.id}'),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
