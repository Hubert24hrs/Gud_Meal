import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gud_meal_core/gud_meal_core.dart';

import '../../providers.dart';
import '../../ui/bubbles.dart';
import '../../ui/components.dart';
import '../../ui/gudy.dart';
import '../../ui/illustrations.dart';
import '../../widgets.dart';

/// Home: Gud Meal's six services as animated, draggable bubbles on an orange header, then personal picks.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final first = user?.name?.trim().split(' ').first;
    final forYou = ref.watch(forYouProvider);
    final area = ref.watch(areaProvider);
    final top = MediaQuery.paddingOf(context).top;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(forYouProvider);
          ref.invalidate(merchantsProvider);
          await ref.read(forYouProvider.future).catchError((_) => <RestaurantCard>[]);
        },
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(
            child: ClipPath(
              clipper: const WaveClipper(),
              child: Container(
                decoration: const BoxDecoration(gradient: brandGradient),
                padding: EdgeInsets.only(top: top + 12, bottom: 40),
                child: Column(children: [
                  const Center(child: AddressPill(onDark: true)),
                  const SizedBox(height: 8),
                  ServiceBubbleField(
                    height: 372,
                    layout: sixBubbleLayout,
                    bubbles: [
                      BubbleSpec(id: 'food', label: 'Food', art: const FoodIllustration(), relSize: 1.1, onTap: () => context.push('/food')),
                      BubbleSpec(id: 'grocery', label: 'Groceries', art: const GroceryIllustration(), onTap: () => context.push('/groceries')),
                      BubbleSpec(id: 'pharmacy', label: 'Pharmacy', art: const PharmacyIllustration(), onTap: () => context.push('/pharmacy')),
                      BubbleSpec(id: 'market', label: 'Market Shopping', art: const MarketIllustration(), onTap: () => context.push('/market')),
                      BubbleSpec(id: 'beauty', label: 'Beauty & Skin care', art: const BeautyIllustration(), onTap: () => context.push('/beauty')),
                      BubbleSpec(id: 'parcel', label: 'Package Delivery', art: const ParcelIllustration(), onTap: () => context.push('/send')),
                    ],
                  ),
                ]),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SectionTitle(first == null ? 'These are for you' : '$first, these are for you',
                info: 'Top-rated places near ${area.name}, picked for you'),
          ),
          SliverToBoxAdapter(
            child: forYou.when(
              loading: () => const SizedBox(height: 150, child: Center(child: CircularProgressIndicator())),
              error: (e, _) => ErrorRetry(error: e, onRetry: () => ref.invalidate(forYouProvider)),
              data: (list) => list.isEmpty
                  ? EmptyState(
                      icon: Icons.storefront_outlined,
                      title: 'Nothing nearby yet',
                      body: 'We are adding partners in ${area.cityName}. Try another area.',
                      action: OutlinedButton(onPressed: () => showAreaPicker(context, ref), child: const Text('Change area')),
                    )
                  : SizedBox(
                      height: 168,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        scrollDirection: Axis.horizontal,
                        itemCount: list.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 12),
                        itemBuilder: (_, i) => BrandTile(merchant: list[i], onTap: () => context.push('/restaurants/${list[i].id}')),
                      ),
                    ),
            ),
          ),
          SliverToBoxAdapter(child: _Promos(forYou: forYou.value ?? const [])),
          SliverToBoxAdapter(child: _AskGudy(onAsk: (q) => context.push('/assistant?q=${Uri.encodeComponent(q)}'))),
          const SliverToBoxAdapter(child: SizedBox(height: 96)),
        ]),
      ),
    );
  }
}

class _Promos extends StatelessWidget {
  const _Promos({required this.forYou});
  final List<RestaurantCard> forYou;

  @override
  Widget build(BuildContext context) {
    final promo = forYou.where((r) => r.promotions.isNotEmpty).firstOrNull;
    return Column(children: [
      if (promo != null)
        PromoBanner(
          title: promo.promotions.first.label,
          body: 'Use code ${promo.promotions.first.code} at ${promo.name}.',
          badge: 'Deal',
          onTap: () => context.push('/restaurants/${promo.id}'),
        ),
      _SendBanner(onTap: () => context.push('/send')),
    ]);
  }
}

class _SendBanner extends StatelessWidget {
  const _SendBanner({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(GmRadius.lg),
        child: InkWell(
          borderRadius: BorderRadius.circular(GmRadius.lg),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              const SizedBox(width: 74, height: 64, child: CustomPaint(painter: ParcelIllustration())),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Send a package', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  const Text('Bike delivery across Lagos or Enugu: now, or at a time you choose.'),
                ]),
              ),
              const Icon(Icons.chevron_right_rounded),
            ]),
          ),
        ),
      ),
    );
  }
}

class _AskGudy extends StatelessWidget {
  const _AskGudy({required this.onAsk});
  final ValueChanged<String> onAsk;

  static const _ideas = [
    'I have ₦10,000. Best meal for two before 8pm?',
    'Find me a good sunscreen',
    'How much have I spent?',
    'Abeg, wetin una dey sell?',
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF0FF),
        borderRadius: BorderRadius.circular(GmRadius.lg),
        border: Border.all(color: const Color(0xFFCFDBFF)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const GudyAvatar(size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Ask Gudy', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: const Color(0xFF1546C9))),
              const Text('Your AI assistant. English, Pidgin, Igbo, Yoruba or Hausa.', style: TextStyle(color: Color(0xFF3B4A6B))),
            ]),
          ),
        ]),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final idea in _ideas)
            ActionChip(
              label: Text(idea),
              backgroundColor: scheme.surface,
              onPressed: () => onAsk(idea),
            ),
        ]),
      ]),
    );
  }
}
