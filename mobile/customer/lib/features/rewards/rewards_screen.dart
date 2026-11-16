import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gud_meal_core/gud_meal_core.dart';

import '../../providers.dart';

/// Gud points, voucher redemption, personal vouchers and the referral code.
class RewardsScreen extends ConsumerStatefulWidget {
  const RewardsScreen({super.key});

  @override
  ConsumerState<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends ConsumerState<RewardsScreen> {
  final _code = TextEditingController();
  String _redeemKey = newIdempotencyKey('redeem');
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _run(Future<String> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final message = await action();
      ref.invalidate(rewardsProvider);
      ref.invalidate(myVouchersProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String> _redeem(int points) async {
    final v = await ref.read(apiProvider).redeemPoints(points, _redeemKey);
    _redeemKey = newIdempotencyKey('redeem');
    return 'Your ${formatNaira(v.valueKobo)} voucher ${v.code} is ready. Pick it at checkout.';
  }

  Future<String> _apply() async {
    final v = await ref.read(apiProvider).applyReferral(_code.text.trim());
    _code.clear();
    return v == null ? 'Code applied.' : 'Welcome! ${formatNaira(v.valueKobo)} off your first order is waiting at checkout.';
  }

  @override
  Widget build(BuildContext context) {
    final rewards = ref.watch(rewardsProvider);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Rewards')),
      body: rewards.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e is ApiException ? e.message : 'Could not load your rewards')),
        data: (r) {
          final steps = (r.redeem.redeemablePoints ~/ r.redeem.stepPoints).clamp(0, 10);
          return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 32), children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF2B5D4A), Color(0xFF1D754E)]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: DefaultTextStyle(
                style: const TextStyle(color: Colors.white),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Gud points', style: TextStyle(fontWeight: FontWeight.w700)),
                  Text('${r.points}', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900)),
                  Text('Worth ${formatNaira(r.pointsValueKobo)} · 1 point per ₦100 on completed orders'),
                  if (steps == 0 && r.redeem.enabled)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text('${r.redeem.pointsToNext} more points to your next ${formatNaira(r.redeem.stepValueKobo)} voucher'),
                    ),
                ]),
              ),
            ),
            if (steps > 0) ...[
              const SizedBox(height: 16),
              Text('Turn points into a voucher', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              Wrap(spacing: 8, children: [
                for (var i = 1; i <= steps; i++)
                  ActionChip(
                    key: ValueKey('redeem-${i * r.redeem.stepPoints}'),
                    label: Text('${i * r.redeem.stepPoints} points → ${formatNaira(i * r.redeem.stepValueKobo)}'),
                    onPressed: _busy ? null : () => _run(() => _redeem(i * r.redeem.stepPoints)),
                  ),
              ]),
            ],
            if (r.vouchers.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Your vouchers', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              for (final v in r.vouchers)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.local_offer_rounded),
                  title: Text('${formatNaira(v.valueKobo)} off · ${v.code}', style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('${v.description} · orders from ${formatNaira(v.minSubtotalKobo)}'),
                ),
            ],
            if (r.referral.enabled) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Invite friends', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                    Text('Friends get ${formatNaira(r.referral.friendGetsKobo)} off their first order; you get '
                        '${formatNaira(r.referral.youGetKobo)} when it\'s delivered.'),
                    const SizedBox(height: 8),
                    Wrap(spacing: 12, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                      SelectableText(r.referral.code,
                          key: const ValueKey('referral-code'),
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 3)),
                      FilledButton.tonalIcon(
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: r.referral.shareText));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied. Paste it in a chat with friends.')));
                          }
                        },
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        label: const Text('Copy invite'),
                      ),
                    ]),
                    if (r.referral.friendsRewarded > 0) Text('${r.referral.friendsRewarded} friends rewarded so far.'),
                  ]),
                ),
              ),
            ],
            if (r.referral.canApply) ...[
              const SizedBox(height: 16),
              Text('Got a friend\'s code?', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              Row(children: [
                Expanded(
                  child: TextField(controller: _code, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(labelText: 'Referral code')),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: _busy ? null : () => _run(_apply), child: const Text('Apply')),
              ]),
            ],
            if (_error != null)
              Padding(padding: const EdgeInsets.only(top: 12), child: Text(_error!, style: TextStyle(color: theme.colorScheme.error))),
            if (r.history.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('History', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              for (final e in r.history)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(switch (e.kind) { 'earned' => 'Order completed', 'redeemed' => 'Voucher ${e.voucherCode ?? ''}', _ => 'Refund' }),
                  subtitle: Text(formatLagosDateTime(e.at)),
                  trailing: Text('${e.points > 0 ? '+' : ''}${e.points}', style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
            ],
          ]);
        },
      ),
    );
  }
}
