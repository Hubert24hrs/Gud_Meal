import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gud_meal_core/gud_meal_core.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers.dart';
import '../../ui/components.dart';
import '../../ui/gudy.dart';

const _faqs = [
  ('How do refunds work?',
      'If a store rejects your order, or you cancel before it is accepted (or before a rider is assigned to your package), you get a full refund automatically. For anything else, open a ticket and our team reviews it within 24 hours.'),
  ('How do I pay?',
      'Card, bank transfer or USSD on Paystack’s secure page. Gud Meal never sees your card details. The Gud Meal wallet and pay on delivery are coming soon.'),
  ('What is the delivery code?',
      'A 4-digit code in your order. Only give it to the rider once you have your order. For packages, share it with the person receiving it.'),
  ('Where do you deliver?', 'Lagos and Enugu for now. Choose your area at the top of Home; more cities are coming.'),
  ('Can I schedule a delivery?', 'Package pickups can be scheduled up to 7 days ahead, between 7am and 9pm.'),
  ('Is Gudy a real person?',
      'Gudy is Gud Meal’s AI assistant. It always asks you to approve before placing an order or creating a payment, and you can ask for a person at any time.'),
];

const _ticketCategories = {
  'missing_item': 'Missing item',
  'wrong_order': 'Wrong order',
  'late_delivery': 'Late delivery',
  'payment': 'Payment',
  'quality': 'Food or product quality',
  'rider': 'Rider',
  'account': 'Account',
  'other': 'Something else',
};

class SupportScreen extends ConsumerWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final contacts = ref.watch(supportContactsProvider).value;
    return Scaffold(
      appBar: AppBar(title: Text('Support', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900))),
      body: ListView(padding: const EdgeInsets.only(bottom: 96), children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Text('How can we help?', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 16)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Material(
            color: const Color(0xFFEAF0FF),
            borderRadius: BorderRadius.circular(GmRadius.lg),
            child: InkWell(
              borderRadius: BorderRadius.circular(GmRadius.lg),
              onTap: () => context.push('/assistant'),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  const GudyAvatar(size: 56, pulse: true),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Chat with Gudy', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: const Color(0xFF1546C9))),
                      const SizedBox(height: 2),
                      const Text('Instant answers in English, Pidgin, Igbo, Yoruba or Hausa', style: TextStyle(color: Color(0xFF3B4A6B))),
                    ]),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Color(0xFF1546C9)),
                ]),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        ListTile(
          leading: CircleAvatar(backgroundColor: theme.colorScheme.primaryContainer, child: Icon(Icons.support_agent_rounded, color: brandOrange)),
          title: const Text('Talk to a person', style: TextStyle(fontWeight: FontWeight.w700)),
          subtitle: const Text('Open a ticket; our team replies in the app'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => _openTicket(context, ref),
        ),
        const Divider(indent: 16, endIndent: 16),
        _ContactTile(
          icon: Icons.chat_rounded,
          color: const Color(0xFF1D754E),
          title: 'WhatsApp',
          value: contacts?.whatsapp,
          placeholder: contacts?.placeholders ?? true,
          uri: contacts == null ? null : Uri.parse('https://wa.me/${contacts.whatsapp.replaceAll(RegExp(r'[^0-9]'), '')}'),
        ),
        _ContactTile(
          icon: Icons.call_rounded,
          color: brandOrange,
          title: 'Call us',
          value: contacts?.phone,
          placeholder: contacts?.placeholders ?? true,
          uri: contacts == null ? null : Uri(scheme: 'tel', path: contacts.phone.replaceAll(' ', '')),
        ),
        _ContactTile(
          icon: Icons.mail_rounded,
          color: const Color(0xFF2D6AA6),
          title: 'Email',
          value: contacts?.email,
          placeholder: contacts?.placeholders ?? true,
          uri: contacts == null ? null : Uri(scheme: 'mailto', path: contacts.email),
        ),
        if (contacts != null && contacts.hours.isNotEmpty)
          Padding(padding: const EdgeInsets.fromLTRB(72, 0, 16, 8), child: Text(contacts.hours, style: theme.textTheme.bodySmall)),
        const SectionTitle('Frequently asked'),
        for (final (q, a) in _faqs)
          ExpansionTile(
            title: Text(q, style: const TextStyle(fontWeight: FontWeight.w600)),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            children: [Text(a)],
          ),
      ]),
    );
  }

  Future<void> _openTicket(BuildContext context, WidgetRef ref) async {
    if (ref.read(authStateProvider).value == null) {
      context.push('/sign-in?next=/support');
      return;
    }
    final sent = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _TicketForm(),
    );
    if (sent == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ticket opened. A Gud Meal support agent will reply in the app.')));
    }
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({required this.icon, required this.color, required this.title, required this.value, required this.placeholder, required this.uri});
  final IconData icon;
  final Color color;
  final String title;
  final String? value;
  final bool placeholder;
  final Uri? uri;

  @override
  Widget build(BuildContext context) {
    final live = !placeholder && uri != null;
    return ListTile(
      enabled: live,
      leading: CircleAvatar(backgroundColor: color.withValues(alpha: .14), child: Icon(icon, color: color)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(live ? (value ?? '') : 'Coming soon. Use Gudy or open a ticket for now.'),
      trailing: live ? const Icon(Icons.open_in_new_rounded, size: 20) : null,
      onTap: live ? () => launchUrl(uri!, mode: LaunchMode.externalApplication) : null,
    );
  }
}

class _TicketForm extends ConsumerStatefulWidget {
  const _TicketForm();

  @override
  ConsumerState<_TicketForm> createState() => _TicketFormState();
}

class _TicketFormState extends ConsumerState<_TicketForm> {
  String _category = 'other';
  String? _orderId;
  final _text = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_text.text.trim().length < 5) {
      setState(() => _error = 'Tell us a little more (at least 5 characters)');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(apiProvider).openSupportTicket(category: _category, description: _text.text.trim(), orderId: _orderId);
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(myOrdersProvider).value ?? const <Order>[];
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.viewInsetsOf(context).bottom + 16),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Talk to a person', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _category,
          decoration: const InputDecoration(labelText: 'What is it about?'),
          items: [for (final e in _ticketCategories.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
          onChanged: (v) => setState(() => _category = v ?? 'other'),
        ),
        if (orders.isNotEmpty) ...[
          const SizedBox(height: 8),
          DropdownButtonFormField<String?>(
            initialValue: _orderId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Which order? (optional)'),
            items: [
              const DropdownMenuItem(value: null, child: Text('Not about an order')),
              for (final o in orders.take(10)) DropdownMenuItem(value: o.id, child: Text('#${o.shortCode} · ${o.restaurantName}')),
            ],
            onChanged: (v) => setState(() => _orderId = v),
          ),
        ],
        const SizedBox(height: 8),
        TextField(controller: _text, minLines: 3, maxLines: 6, maxLength: 1500, decoration: const InputDecoration(labelText: 'What happened?')),
        if (_error != null) Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        const SizedBox(height: 8),
        FilledButton(onPressed: _busy ? null : _send, child: Text(_busy ? 'Sending…' : 'Send to support')),
      ]),
    );
  }
}
