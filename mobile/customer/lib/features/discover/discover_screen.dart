import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gud_meal_core/gud_meal_core.dart';

import '../../providers.dart';
import '../../ui/components.dart';
import '../../widgets.dart';

/// Discover: search everything (food and beauty) and see what's in demand near you.
class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  String _query = '';
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final top = MediaQuery.paddingOf(context).top;
    final food = ref.watch(merchantsProvider((vertical: 'food', category: null, pickup: false, sort: 'rating', query: null, cuisine: null)));
    final beauty = ref.watch(merchantsProvider((vertical: 'beauty', category: null, pickup: false, sort: 'rating', query: null, cuisine: null)));
    final demand = [...?food.value, ...?beauty.value]
      ..sort((a, b) => (b.rating * b.ratingCount.clamp(1, 2000)).compareTo(a.rating * a.ratingCount.clamp(1, 2000)));

    return Scaffold(
      body: CustomScrollView(slivers: [
        SliverToBoxAdapter(
          child: ClipPath(
            clipper: const WaveClipper(),
            child: Container(
              height: top + 150,
              padding: EdgeInsets.fromLTRB(20, top + 28, 20, 0),
              decoration: const BoxDecoration(gradient: brandGradient),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: Text('Discover', style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w900, color: Colors.white))),
                const Icon(Icons.travel_explore_rounded, size: 72, color: Colors.white70),
              ]),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              textInputAction: TextInputAction.search,
              onChanged: (v) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 350), () => setState(() => _query = v.trim()));
              },
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded),
                hintText: 'Search Gud Meal',
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(999), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(999), borderSide: BorderSide.none),
              ),
            ),
          ),
        ),
        if (_query.length >= 2)
          SliverToBoxAdapter(child: _Results(query: _query))
        else ...[
          const SliverToBoxAdapter(child: SectionTitle('Most in demand', info: 'Where everyone is ordering, available now')),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text('Where everyone’s ordering, available now', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
            ),
          ),
          if (food.isLoading && demand.isEmpty)
            const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator())))
          else if (food.hasError && demand.isEmpty)
            SliverToBoxAdapter(child: ErrorRetry(error: food.error!, onRetry: () => ref.invalidate(merchantsProvider)))
          else
            SliverList.builder(itemCount: demand.length.clamp(0, 12), itemBuilder: (_, i) => _DemandRow(merchant: demand[i])),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 96)),
      ]),
    );
  }
}

class _DemandRow extends StatelessWidget {
  const _DemandRow({required this.merchant});
  final RestaurantCard merchant;

  @override
  Widget build(BuildContext context) {
    final r = merchant;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Material(
        color: theme.colorScheme.surface,
        elevation: 1,
        borderRadius: BorderRadius.circular(GmRadius.lg),
        child: InkWell(
          borderRadius: BorderRadius.circular(GmRadius.lg),
          onTap: () => context.push('/restaurants/${r.id}'),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              ClipRRect(borderRadius: BorderRadius.circular(GmRadius.md), child: SizedBox(width: 72, height: 72, child: MerchantArt(merchant: r, height: 72, compact: true))),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(r.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.thumb_up_alt_outlined, size: 16, color: Color(0xFF1D754E)),
                    const SizedBox(width: 4),
                    Text(ratingPercent(r.rating)),
                    if (deliveryLabel(r).isNotEmpty) ...[
                      const Text('  ·  '),
                      const Icon(Icons.delivery_dining_rounded, size: 16),
                      const SizedBox(width: 4),
                      Flexible(child: Text(deliveryLabel(r), overflow: TextOverflow.ellipsis)),
                    ],
                  ]),
                  if (r.promotions.isNotEmpty) ...[const SizedBox(height: 6), PromoTag(r.promotions.first.label)],
                  if (r.vertical == 'beauty')
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('Beauty & Skin care', style: TextStyle(color: theme.colorScheme.secondary, fontWeight: FontWeight.w700, fontSize: 12)),
                    ),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _Results extends ConsumerWidget {
  const _Results({required this.query});
  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final found = ref.watch(searchProvider((query: query, vertical: null)));
    return found.when(
      loading: () => const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator())),
      error: (e, _) => ErrorRetry(error: e, onRetry: () => ref.invalidate(searchProvider((query: query, vertical: null)))),
      data: (res) {
        if (res.items.isEmpty && res.merchants.isEmpty) {
          return const EmptyState(icon: Icons.search_off_rounded, title: 'No results', body: 'Try a dish, a product or a store name.');
        }
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (res.merchants.isNotEmpty) ...[
            const SectionTitle('Stores'),
            for (final m in res.merchants.take(5)) _DemandRow(merchant: m),
          ],
          if (res.items.isNotEmpty) ...[
            const SectionTitle('Dishes & products'),
            for (final hit in res.items.take(10))
              ListTile(
                leading: Icon(hit['vertical'] == 'beauty' ? Icons.spa_rounded : Icons.restaurant_rounded, color: brandOrange),
                title: Text('${(hit['item'] as Map)['name']}'),
                subtitle: Text('${hit['restaurant_name']}'),
                trailing: Text(formatNaira((hit['item'] as Map)['price_kobo'] as int), style: const TextStyle(fontWeight: FontWeight.w700)),
                onTap: () => context.push('/restaurants/${hit['restaurant_id']}'),
              ),
          ],
        ]);
      },
    );
  }
}
