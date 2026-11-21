import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gud_meal_core/gud_meal_core.dart';
import 'package:gud_meal_customer/features/support/support_screen.dart';
import 'package:gud_meal_customer/providers.dart';

Future<void> showSupport(WidgetTester tester, SupportContacts contacts) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
      supportContactsProvider.overrideWith((ref) async => contacts),
    ],
    child: MaterialApp(theme: buildGudMealTheme(Brightness.light), home: const SupportScreen()),
  ));
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('offers the real customer-care email while WhatsApp and phone are still coming soon', (tester) async {
    await showSupport(
      tester,
      const SupportContacts(email: 'customercare@yummy247.com', hours: 'Every day, 8am to 10pm'),
    );
    expect(find.text('customercare@yummy247.com'), findsOneWidget);
    expect(find.text('Coming soon. Use Yummy or open a ticket for now.'), findsNWidgets(2));
    final email = tester.widget<ListTile>(find.ancestor(of: find.text('Email'), matching: find.byType(ListTile)));
    expect(email.enabled, isTrue);
    final whatsapp = tester.widget<ListTile>(find.ancestor(of: find.text('WhatsApp'), matching: find.byType(ListTile)));
    expect(whatsapp.enabled, isFalse);
  });

  testWidgets('shows every contact once all three exist', (tester) async {
    await showSupport(
      tester,
      const SupportContacts(whatsapp: '+234 812 345 6789', phone: '+234 1 234 5678', email: 'customercare@yummy247.com', placeholders: false),
    );
    expect(find.text('+234 812 345 6789'), findsOneWidget);
    expect(find.text('+234 1 234 5678'), findsOneWidget);
    expect(find.text('Coming soon. Use Yummy or open a ticket for now.'), findsNothing);
  });
}
