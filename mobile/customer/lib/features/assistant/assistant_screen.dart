import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gud_meal_core/gud_meal_core.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers.dart';

class _Turn {
  _Turn(this.fromUser, this.text, {this.cards = const [], this.approval});
  final bool fromUser;
  final String text;
  final List<Map<String, dynamic>> cards;
  ChatApproval? approval;
}

/// AI food concierge (LangGraph agents service). Sensitive actions arrive as approval cards.
class AssistantScreen extends ConsumerStatefulWidget {
  const AssistantScreen({super.key, this.initial});
  final String? initial;

  @override
  ConsumerState<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends ConsumerState<AssistantScreen> {
  final _turns = <_Turn>[];
  final _input = TextEditingController();
  final _speech = SpeechToText();
  String? _threadId;
  bool _busy = false;
  bool _listening = false;

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) WidgetsBinding.instance.addPostFrameCallback((_) => _send(widget.initial!));
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _apply(ChatResponse res) => setState(() {
        _threadId = res.threadId;
        _turns.add(_Turn(false, res.status == 'approval_required' ? 'Please review and approve:' : (res.reply ?? ''),
            cards: res.cards, approval: res.approval));
      });

  Future<void> _send(String text) async {
    if (text.trim().isEmpty || _busy) return;
    setState(() {
      _turns.add(_Turn(true, text.trim()));
      _busy = true;
    });
    _input.clear();
    try {
      final area = ref.read(areaProvider);
      final address = DeliveryAddress(label: area.name, line1: '${area.name}, Lagos', area: area.name, location: area.location);
      _apply(await ref.read(agentsApiProvider).chat(text.trim(), threadId: _threadId, address: address));
    } on ApiException catch (e) {
      setState(() => _turns.add(_Turn(false, e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _decide(_Turn turn, bool approved) async {
    final approval = turn.approval!;
    setState(() {
      turn.approval = null;
      _busy = true;
    });
    try {
      _apply(await ref.read(agentsApiProvider).decide(_threadId!, approved: approved, toolCallId: approval.toolCallId));
    } on ApiException catch (e) {
      setState(() => _turns.add(_Turn(false, e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _listen() async {
    if (_listening) {
      await _speech.stop();
      setState(() => _listening = false);
      return;
    }
    final ok = await _speech.initialize();
    if (!ok) return;
    setState(() => _listening = true);
    await _speech.listen(onResult: (r) {
      _input.text = r.recognizedWords;
      if (r.finalResult) setState(() => _listening = false);
    }, listenOptions: SpeechListenOptions(localeId: 'en_NG'));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Ask Gud Meal')),
      body: Column(children: [
        Expanded(
          child: ListView(padding: const EdgeInsets.all(16), children: [
            if (_turns.isEmpty)
              const Text('Tell me your budget, how many people and when you want to eat — I’ll find the best options and you approve before paying.'),
            for (final t in _turns)
              Align(
                alignment: t.fromUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 340),
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: t.fromUser ? scheme.primary : scheme.surface,
                    borderRadius: BorderRadius.circular(GmRadius.lg),
                    border: t.fromUser ? null : Border.all(color: scheme.outline),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (t.text.isNotEmpty) Text(t.text, style: TextStyle(color: t.fromUser ? scheme.onPrimary : scheme.onSurface)),
                    for (final card in t.cards) _CardView(card: card),
                    if (t.approval != null) _ApprovalView(approval: t.approval!, onDecide: (ok) => _decide(t, ok)),
                  ]),
                ),
              ),
            if (_busy) const Padding(padding: EdgeInsets.all(8), child: LinearProgressIndicator()),
          ]),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              IconButton(tooltip: 'Speak', onPressed: _listen, icon: Icon(_listening ? Icons.mic_rounded : Icons.mic_none_rounded)),
              Expanded(
                child: TextField(
                  controller: _input,
                  textInputAction: TextInputAction.send,
                  onSubmitted: _send,
                  decoration: const InputDecoration(hintText: 'What are you craving?'),
                ),
              ),
              IconButton.filled(tooltip: 'Send', onPressed: _busy ? null : () => _send(_input.text), icon: const Icon(Icons.send_rounded)),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _CardView extends StatelessWidget {
  const _CardView({required this.card});
  final Map<String, dynamic> card;

  @override
  Widget build(BuildContext context) {
    switch (card['type']) {
      case 'meal_plans':
        final plans = (card['plans'] as List).cast<Map>();
        return Column(children: [
          for (final p in plans)
            Card(
              margin: const EdgeInsets.only(top: 8),
              child: ListTile(
                title: Text('${p['restaurant']} · ${p['total']}', style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('${(p['items'] as List).join(' · ')}${p['arrives_around'] != null ? '\nArrives ~${p['arrives_around']}' : ''}'),
              ),
            ),
        ]);
      case 'payment_link':
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: FilledButton.icon(
            onPressed: () => launchUrl(Uri.parse('${card['url']}'), mode: LaunchMode.inAppBrowserView),
            icon: const Icon(Icons.lock_rounded),
            label: Text('Pay ${card['amount']} securely'),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _ApprovalView extends StatelessWidget {
  const _ApprovalView({required this.approval, required this.onDecide});
  final ChatApproval approval;
  final ValueChanged<bool> onDecide;

  @override
  Widget build(BuildContext context) {
    final preview = approval.preview;
    final order = preview['order'] is Map ? Map<String, dynamic>.from(preview['order'] as Map) : null;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2), borderRadius: BorderRadius.circular(GmRadius.md)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${preview['title'] ?? 'Approve this action?'}', style: const TextStyle(fontWeight: FontWeight.w800)),
        if (order != null) ...[
          for (final item in (order['items'] as List? ?? const [])) Text('$item'),
          Text('Total ${order['total']}', style: const TextStyle(fontWeight: FontWeight.w800)),
          if (order['estimated_arrival'] != null) Text('Arrives ~${order['estimated_arrival']}'),
        ],
        if (preview['message'] != null) Text('${preview['message']}', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        Row(children: [
          FilledButton(onPressed: () => onDecide(true), child: const Text('Approve')),
          const SizedBox(width: 8),
          OutlinedButton(onPressed: () => onDecide(false), child: const Text('Not now')),
        ]),
      ]),
    );
  }
}
