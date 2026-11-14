import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gud_meal_core/gud_meal_core.dart';

import '../../providers.dart';
import '../../widgets.dart';
import '../cart/cart_controller.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _query = '';
  String? _cuisine;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final area = ref.watch(areaProvider);
    final restaurants = ref.watch(restaurantsProvider);
    final cart = ref.watch(cartProvider);
    final user = ref.watch(authStateProvider).value;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: InkWell(
          onTap: () => _pickArea(context),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.location_on_rounded, color: theme.colorScheme.primary),
            const SizedBox(width: 4),
            Text(area.name, style: const TextStyle(fontWeight: FontWeight.w700)),
            const Icon(Icons.keyboard_arrow_down_rounded),
          ]),
        ),
        actions: [
          IconButton(
            tooltip: user == null ? 'Sign in' : 'My orders',
            icon: Icon(user == null ? Icons.person_outline_rounded : Icons.receipt_long_rounded),
            onPressed: () => context.push(user == null ? '/sign-in' : '/orders'),
          ),
        ],
      ),
      floatingActionButton: cart.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push('/checkout'),
              icon: const Icon(Icons.shopping_bag_rounded),
              label: Text('${cart.count} · ${formatNaira(cart.subtotalKobo)}'),
            ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(restaurantsProvider.future),
        child: CustomScrollView(slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            sliver: SliverList.list(children: [
              Text('What are you craving?', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 12),
              _AskCard(onAsk: (q) => context.push('/assistant?q=${Uri.encodeComponent(q)}')),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(prefixIcon: Icon(Icons.search_rounded), hintText: 'Search jollof, suya, shawarma…'),
                onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              ),
              const SizedBox(height: 12),
            ]),
          ),
          ...restaurants.when(
            loading: () => [const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))],
            error: (e, _) => [SliverFillRemaining(child: ErrorRetry(error: e, onRetry: () => ref.invalidate(restaurantsProvider)))],
            data: (list) {
              final cuisines = {for (final r in list) ...r.cuisines}.toList()..sort();
              final shown = list.where((r) {
                final matchesQuery = _query.isEmpty || r.name.toLowerCase().contains(_query) || r.cuisines.any((c) => c.toLowerCase().contains(_query));
                return matchesQuery && (_cuisine == null || r.cuisines.contains(_cuisine));
              }).toList();
              return [
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 44,
                    child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), children: [
                      for (final c in [null, ...cuisines])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(label: Text(c ?? 'All'), selected: _cuisine == c, onSelected: (_) => setState(() => _cuisine = c)),
                        ),
                    ]),
                  ),
                ),
                if (shown.isEmpty)
                  const SliverFillRemaining(hasScrollBody: false, child: Center(child: Text('No restaurants match your search')))
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                    sliver: SliverList.separated(
                      itemCount: shown.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemBuilder: (_, i) => RestaurantTile(restaurant: shown[i], onTap: () => context.push('/restaurants/${shown[i].id}')),
                    ),
                  ),
              ];
            },
          ),
        ]),
      ),
    );
  }

  Future<void> _pickArea(BuildContext context) async {
    final picked = await showModalBottomSheet<Area>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: ListView(shrinkWrap: true, children: [
          for (final a in lagosAreas) ListTile(title: Text(a.name), onTap: () => Navigator.pop(context, a)),
        ]),
      ),
    );
    if (picked != null) ref.read(areaProvider.notifier).select(picked);
  }
}

class _AskCard extends StatefulWidget {
  const _AskCard({required this.onAsk});
  final ValueChanged<String> onAsk;

  @override
  State<_AskCard> createState() => _AskCardState();
}

class _AskCardState extends State<_AskCard> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: scheme.secondary, borderRadius: BorderRadius.circular(GmRadius.lg)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.auto_awesome_rounded, color: scheme.onSecondary),
          const SizedBox(width: 8),
          Text('Ask Gud Meal', style: TextStyle(color: scheme.onSecondary, fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 8),
        TextField(
          controller: _controller,
          textInputAction: TextInputAction.send,
          onSubmitted: (v) => v.trim().isEmpty ? null : widget.onAsk(v.trim()),
          decoration: const InputDecoration(hintText: 'I have ₦10,000 — best meal for two before 8pm'),
        ),
      ]),
    );
  }
}
