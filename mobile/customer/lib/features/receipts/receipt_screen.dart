import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gud_meal_core/gud_meal_core.dart';

import '../../providers.dart';
import '../../ui/components.dart';
import '../../widgets.dart';
import 'receipt_printer.dart';

/// The receipt printer for one paid order (ADR-0019). The red PRINT button prints the receipt of what was just
/// paid for and keeps it under "My receipts" on the customer's account.
class ReceiptScreen extends ConsumerStatefulWidget {
  const ReceiptScreen({super.key, required this.orderId});
  final String orderId;

  @override
  ConsumerState<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends ConsumerState<ReceiptScreen> {
  bool _saved = false;
  String? _notice;

  /// PRINT was pressed: keep the receipt on the account (the server counts every copy).
  Future<void> _save() async {
    try {
      final kept = await ref.read(apiProvider).printReceipt(widget.orderId);
      if (!mounted) return;
      setState(() {
        _saved = kept.saved;
        _notice = null;
      });
      ref.invalidate(receiptsProvider);
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _notice = 'Could not save the receipt. Check your connection, then press PRINT again',
      );
    }
  }

  void _read(Receipt r) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: const Color(0xFFDCD8CF),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        builder: (_, scroll) => SingleChildScrollView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          child: Center(child: ReceiptPaper(receipt: r)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final receipt = ref.watch(receiptProvider(widget.orderId));
    return Scaffold(
      backgroundColor: const Color(0xFFDCD8CF),
      body: receipt.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) {
          final unpaid = e is ApiException && e.code == 'order_not_paid';
          return SafeArea(
            child: EmptyState(
              icon: Icons.receipt_long_outlined,
              title: unpaid ? 'No receipt yet' : 'Receipt unavailable',
              body: unpaid
                  ? 'The receipt is ready as soon as this order is paid for.'
                  : (e is ApiException
                        ? e.message
                        : 'Please check your connection and try again.'),
              action: FilledButton(
                onPressed: () => context.go('/orders/${widget.orderId}'),
                child: const Text('Back to the order'),
              ),
            ),
          );
        },
        // The printer fills the screen; the buttons sit over its top edge.
        data: (r) {
          final saved = (_saved || r.saved) && _notice == null;
          return Stack(
            fit: StackFit.expand,
            children: [
              ReceiptPrinter(receipt: r, onPrint: _save, notice: _notice),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Wraps onto a second line on narrow phones and with large text.
                        SizedBox(
                          width: double.infinity,
                          child: Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _Pill(
                                label: 'Track my order',
                                onTap: () =>
                                    context.go('/orders/${widget.orderId}'),
                              ),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _Pill(
                                    label: 'Read receipt',
                                    onTap: () => _read(r),
                                  ),
                                  // Where the receipt is kept: green with a tick once this one is in there.
                                  _Pill(
                                    label: saved
                                        ? 'Saved in My receipts'
                                        : 'My receipts',
                                    done: saved,
                                    onTap: () => context.push('/receipts'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.onTap, this.done = false});
  final String label;
  final VoidCallback onTap;

  /// Green with a tick: the receipt is saved.
  final bool done;

  @override
  Widget build(BuildContext context) {
    final ink = done ? Colors.white : const Color(0xFF2B2A27);
    return Material(
      color: done ? const Color(0xFF1F7A4D) : const Color(0xE6FFFFFF),
      shape: const StadiumBorder(side: BorderSide(color: Color(0x0D000000))),
      elevation: 1,
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (done) ...[
                Icon(Icons.check_rounded, size: 16, color: ink),
                const SizedBox(width: 4),
              ],
              Semantics(
                liveRegion: done,
                child: Text(
                  label,
                  style: TextStyle(
                    color: ink,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// My receipts (ADR-0019): every receipt the customer printed after paying, on any device.
class ReceiptsScreen extends ConsumerWidget {
  const ReceiptsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receipts = ref.watch(receiptsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('My receipts')),
      body: receipts.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorRetry(
          error: e,
          onRetry: () => ref.invalidate(receiptsProvider),
        ),
        data: (list) => list.isEmpty
            ? const EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'No receipts yet',
                body: 'After you pay for an order, press the red PRINT button on the receipt printer. Your receipt is then kept here.',
              )
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(receiptsProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final r = list[i];
                    return Card(
                      margin: EdgeInsets.zero,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .primaryContainer,
                          child: Icon(
                            Icons.receipt_long_rounded,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        title: Text(
                          r.seller,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          '${r.serviceName} · ${r.number}\n${formatLagosDateTime(r.paidAt ?? r.issuedAt)}'
                          '${r.refundedKobo > 0 ? ' · refunded ${formatNaira(r.refundedKobo)}' : ''}',
                        ),
                        isThreeLine: true,
                        trailing: Text(
                          formatNaira(r.totalKobo),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        onTap: () =>
                            context.push('/orders/${r.orderId}/receipt'),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}
