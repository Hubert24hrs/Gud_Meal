import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gud_meal_core/gud_meal_core.dart';

import '../../providers.dart';
import '../../ui/components.dart';

/// Profile: who you are, your addresses, deals, payments, settings and help.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final theme = Theme.of(context);
    final top = MediaQuery.paddingOf(context).top;
    final name = (user?.name?.trim().isNotEmpty ?? false) ? user!.name!.trim() : null;
    return Scaffold(
      body: ListView(padding: EdgeInsets.zero, children: [
        Container(
          decoration: const BoxDecoration(gradient: brandGradient),
          padding: EdgeInsets.fromLTRB(16, top + 12, 16, 36),
          child: Column(children: [
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonalIcon(
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1D754E), foregroundColor: Colors.white),
                onPressed: () => context.go('/support'),
                icon: const Icon(Icons.help_outline_rounded, size: 18),
                label: const Text('Help'),
              ),
            ),
            const SizedBox(height: 8),
            Row(children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: const Color(0xFFFDE7DE),
                child: name == null
                    ? const Icon(Icons.person_rounded, size: 36, color: Color(0xFFC9471F))
                    : Text(name[0].toUpperCase(), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFFC9471F))),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name ?? 'Welcome to Gud Meal',
                      style: theme.textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 2),
                  Text(user == null ? 'Sign in to order, track and save addresses' : (user.email ?? user.phone ?? ''),
                      style: const TextStyle(color: Colors.white)),
                ]),
              ),
            ]),
            if (user == null) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: brandOrange),
                  onPressed: () => context.push('/sign-in?next=/profile'),
                  child: const Text('Sign in or create account'),
                ),
              ),
            ],
          ]),
        ),
        Transform.translate(
          offset: const Offset(0, -20),
          child: Container(
            decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
            padding: const EdgeInsets.only(top: 12, bottom: 96),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text('Profile', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
              ),
              if (user != null) ...[
                ListTile(
                  leading: const Icon(Icons.shopping_bag_outlined),
                  title: const Text('Order history'),
                  trailing: FilledButton.tonal(onPressed: () => context.go('/orders'), child: const Text('View in Orders')),
                ),
                _tile(context, Icons.person_outline_rounded, 'Account', onTap: () => _account(context, user)),
                _tile(context, Icons.location_on_outlined, 'Saved addresses', onTap: () => _addresses(context)),
                _tile(context, Icons.account_balance_wallet_outlined, 'Gud Meal wallet',
                    badge: ref.watch(walletProvider).asData?.value.balanceKobo == null
                        ? null
                        : formatNaira(ref.watch(walletProvider).asData!.value.balanceKobo),
                    onTap: () => context.push('/wallet')),
              ],
              _tile(context, Icons.local_offer_outlined, 'Promo codes', onTap: () => _promos(context, ref)),
              _tile(context, Icons.credit_card_outlined, 'Payments', onTap: () => _payments(context)),
              _tile(context, Icons.workspace_premium_outlined, 'Gud Meal Plus', badge: 'Free delivery', onTap: () => context.push('/plus')),
              _tile(context, Icons.card_giftcard_rounded, 'Gud points and invite friends', onTap: () => context.push('/rewards')),
              _tile(context, Icons.groups_outlined, 'Group orders', onTap: () => context.push('/group')),
              _tile(context, Icons.settings_outlined, 'App settings', onTap: () => _settings(context, ref)),
              _tile(context, Icons.quiz_outlined, 'FAQ', onTap: () => context.go('/support')),
              if (user != null)
                _tile(context, Icons.logout_rounded, 'Sign out', danger: true, onTap: () => ref.read(authRepositoryProvider).signOut()),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _tile(BuildContext context, IconData icon, String title, {required VoidCallback onTap, String? badge, bool danger = false}) {
    final color = danger ? Theme.of(context).colorScheme.error : null;
    return Column(children: [
      ListTile(
        leading: Icon(icon, color: color),
        title: Row(children: [
          Text(title, style: TextStyle(color: color, fontSize: 16)),
          if (badge != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: const Color(0xFFDDF0E6), borderRadius: BorderRadius.circular(6)),
              child: Text(badge, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF1D754E))),
            ),
          ],
        ]),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
      const Divider(height: 1, indent: 16, endIndent: 16),
    ]);
  }

  void _account(BuildContext context, GmUser user) => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (_) => SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(leading: const Icon(Icons.badge_outlined), title: const Text('Name'), subtitle: Text(user.name ?? 'Not set')),
            ListTile(leading: const Icon(Icons.mail_outline_rounded), title: const Text('Email'), subtitle: Text(user.email ?? 'Not set')),
            ListTile(leading: const Icon(Icons.phone_outlined), title: const Text('Phone'), subtitle: Text(user.phone ?? 'Not set')),
          ]),
        ),
      );

  void _payments(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (_) => const SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Payments', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              SizedBox(height: 8),
              ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.lock_outline_rounded), title: Text('Card, bank transfer or USSD'), subtitle: Text('Paid on a secure payment page. Gud Meal never stores your card.')),
              ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.account_balance_wallet_outlined), title: Text('Gud Meal wallet'), subtitle: Text('Top up once, pay in one tap, and get refunds instantly. Open it from your profile.')),
              ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.payments_outlined), title: Text('Pay on delivery'), subtitle: Text('Pay the rider in cash for food and beauty orders, after your first completed order.')),
            ]),
          ),
        ),
      );

  void _promos(BuildContext context, WidgetRef ref) => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (_) => Consumer(builder: (context, ref, _) {
          final deals = [
            ...?ref.watch(merchantsProvider((vertical: 'food', category: 'promotions', pickup: false, sort: 'recommended', query: null, cuisine: null))).value,
            ...?ref.watch(merchantsProvider((vertical: 'beauty', category: 'promotions', pickup: false, sort: 'recommended', query: null, cuisine: null))).value,
          ];
          return SafeArea(
            child: SizedBox(
              height: MediaQuery.sizeOf(context).height * .6,
              child: ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), children: [
                const Text('Deals near you', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                const Text('Enter the code at checkout.'),
                const SizedBox(height: 8),
                if (deals.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('No deals in your area right now'))),
                for (final m in deals)
                  for (final p in m.promotions)
                    Card(
                      child: ListTile(
                        title: Text(p.label, style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(m.name),
                        trailing: Chip(label: Text(p.code, style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: .5))),
                        onTap: () {
                          Navigator.pop(context);
                          context.push('/restaurants/${m.id}');
                        },
                      ),
                    ),
              ]),
            ),
          );
        }),
      );

  void _settings(BuildContext context, WidgetRef ref) => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (_) => Consumer(builder: (context, ref, _) {
          final mode = ref.watch(themeModeProvider);
          return SafeArea(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const ListTile(title: Text('Appearance', style: TextStyle(fontWeight: FontWeight.w800))),
              RadioGroup<ThemeMode>(
                groupValue: mode,
                onChanged: (m) => ref.read(themeModeProvider.notifier).set(m ?? ThemeMode.system),
                child: const Column(children: [
                  RadioListTile(value: ThemeMode.system, title: Text('Match my phone')),
                  RadioListTile(value: ThemeMode.light, title: Text('Light')),
                  RadioListTile(value: ThemeMode.dark, title: Text('Dark')),
                ]),
              ),
              ListTile(
                leading: const Icon(Icons.location_city_outlined),
                title: const Text('Delivery area'),
                subtitle: Text('${ref.watch(areaProvider).name}, ${ref.watch(areaProvider).cityName}'),
                onTap: () => showAreaPicker(context, ref),
              ),
            ]),
          );
        }),
      );

  void _addresses(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (_) => const _AddressBook(),
      );
}

class _AddressBook extends ConsumerStatefulWidget {
  const _AddressBook();

  @override
  ConsumerState<_AddressBook> createState() => _AddressBookState();
}

class _AddressBookState extends ConsumerState<_AddressBook> {
  final _line = TextEditingController();
  final _label = TextEditingController(text: 'Home');
  bool _adding = false;
  String? _error;

  @override
  void dispose() {
    _line.dispose();
    _label.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final area = ref.read(areaProvider);
    if (_line.text.trim().length < 3) {
      setState(() => _error = 'Enter the street address');
      return;
    }
    try {
      await ref.read(apiProvider).saveAddress(DeliveryAddress(
            label: _label.text.trim().isEmpty ? null : _label.text.trim(),
            line1: _line.text.trim(),
            area: area.name,
            city: area.cityName,
            state: area.cityName,
            location: area.location,
          ));
      ref.invalidate(addressesProvider);
      setState(() {
        _adding = false;
        _line.clear();
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final saved = ref.watch(addressesProvider);
    final area = ref.watch(areaProvider);
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.viewInsetsOf(context).bottom + 16),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('Saved addresses', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        saved.when(
          loading: () => const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator())),
          error: (e, _) => Text('$e'),
          data: (list) => Column(children: [
            if (list.isEmpty) const Padding(padding: EdgeInsets.all(8), child: Text('No saved addresses yet')),
            for (final a in list)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.place_rounded),
                title: Text(a.label ?? a.line1),
                subtitle: Text([a.line1, a.area, a.city].whereType<String>().join(', ')),
              ),
          ]),
        ),
        if (_adding) ...[
          Text('In ${area.name}, ${area.cityName}', style: Theme.of(context).textTheme.bodySmall),
          TextButton(onPressed: () => showAreaPicker(context, ref), child: const Text('Change area')),
          TextField(controller: _label, decoration: const InputDecoration(labelText: 'Label (Home, Work…)')),
          const SizedBox(height: 8),
          TextField(controller: _line, decoration: const InputDecoration(labelText: 'Street address and landmark')),
          if (_error != null) Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          const SizedBox(height: 8),
          FilledButton(onPressed: _save, child: const Text('Save address')),
        ] else
          OutlinedButton.icon(onPressed: () => setState(() => _adding = true), icon: const Icon(Icons.add_rounded), label: const Text('Add address')),
      ]),
    );
  }
}
