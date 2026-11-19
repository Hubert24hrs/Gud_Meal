import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gud_meal_core/gud_meal_core.dart';

import '../../providers.dart';
import '../../ui/components.dart';
import '../../widgets.dart';
import 'dish_orbit_carousel.dart';

/// Dish-first feed for the Discover tab near the selected area: most loved, new kitchens, top rated.
final discoverFeedProvider = FutureProvider<DiscoverFeed>((ref) {
  final area = ref.watch(areaProvider);
  return ref.watch(apiProvider).discover(city: area.city, near: area.location);
});

/// Discover: the dish carousel (most loved dishes, new kitchens, top-rated kitchens), search across
/// food and beauty, and the stores most in demand near you.
class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  String _query = '';
  Timer? _debounce;
  String? _section;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final top = MediaQuery.paddingOf(context).top;
    // Every kind of shop near the customer, as on the website's Discover page.
    final shops = ref.watch(merchantsProvider((vertical: 'all', category: null, pickup: false, sort: 'rating', query: null, cuisine: null)));
    final demand = [...?shops.value]
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
                hintText: 'Search Yummy Chops',
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
          SliverToBoxAdapter(child: _dishFeed(context)),
          const SliverToBoxAdapter(child: SectionTitle('Most in demand', info: 'Where everyone is ordering, available now')),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text('Where everyone’s ordering, available now', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
            ),
          ),
          if (shops.isLoading && demand.isEmpty)
            const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator())))
          else if (shops.hasError && demand.isEmpty)
            SliverToBoxAdapter(child: ErrorRetry(error: shops.error!, onRetry: () => ref.invalidate(merchantsProvider)))
          else
            SliverList.builder(itemCount: demand.length.clamp(0, 12), itemBuilder: (_, i) => _DemandRow(merchant: demand[i])),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 96)),
      ]),
    );
  }

  /// Section chips + the dish orbit carousel. If the feed can't load, the stores below still work.
  Widget _dishFeed(BuildContext context) {
    final theme = Theme.of(context);
    final feed = ref.watch(discoverFeedProvider);
    return feed.when(
      loading: () => const _FeedPlaceholder(),
      error: (e, _) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: ErrorRetry(error: e, onRetry: () => ref.invalidate(discoverFeedProvider)),
      ),
      data: (data) {
        final sections = data.nonEmpty;
        if (sections.isEmpty) return const SizedBox.shrink();
        final selected = sections.firstWhere((s) => s.id == _section, orElse: () => sections.first);
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final s in sections)
                  FilterPill(
                    label: s.shortTitle,
                    icon: switch (s.id) {
                      'most_loved' => Icons.local_fire_department_rounded,
                      'new_kitchens' => Icons.storefront_rounded,
                      _ => Icons.star_rounded,
                    },
                    selected: s.id == selected.id,
                    onTap: () => setState(() => _section = s.id),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text(selected.title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          ),
          if (selected.subtitle.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
              child: Text(selected.subtitle, style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
            ),
          DishOrbitCarousel(
            dishes: selected.dishes,
            onOrder: (dish) => context.push('/restaurants/${dish.restaurantId}?item=${Uri.encodeQueryComponent(dish.itemId)}'),
            onAskGudy: (dish) => context.push(
              '/assistant?q=${Uri.encodeQueryComponent('Tell me about the ${dish.name} from ${dish.restaurantName}. What does it come with, and what would it cost delivered to me?')}',
            ),
          ),
        ]);
      },
    );
  }
}

/// Shown while the dish feed loads: a soft plate and title placeholders.
class _FeedPlaceholder extends StatelessWidget {
  const _FeedPlaceholder();

  @override
  Widget build(BuildContext context) {
    final tone = Theme.of(context).colorScheme.onSurface.withValues(alpha: .06);
    Widget bar(double w, double h) => Container(width: w, height: h, decoration: BoxDecoration(color: tone, borderRadius: BorderRadius.circular(8)));
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Column(children: [
        Container(width: 190, height: 190, decoration: BoxDecoration(color: tone, shape: BoxShape.circle)),
        const SizedBox(height: 18),
        bar(120, 12),
        const SizedBox(height: 10),
        bar(200, 28),
        const SizedBox(height: 8),
        bar(160, 34),
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
                    const Icon(Icons.thumb_up_alt_outlined, size: 16, color: Color(0xFF2E8B1E)),
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
                  if (r.vertical != 'food')
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(serviceCopy(r.vertical).title, style: TextStyle(color: theme.colorScheme.secondary, fontWeight: FontWeight.w700, fontSize: 12)),
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
                leading: Icon(serviceCopy('${hit['vertical'] ?? 'food'}').icon, color: brandRed),
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
