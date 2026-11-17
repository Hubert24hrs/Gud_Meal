import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers.dart';

/// Accepts 0803…, 803… or +234803… and returns E.164 (+234…), or null if not a Nigerian mobile number.
String? normaliseNigerianPhone(String input) {
  final digits = input.replaceAll(RegExp(r'[^\d+]'), '');
  if (RegExp(r'^\+234[789][01]\d{8}$').hasMatch(digits)) return digits;
  if (RegExp(r'^0[789][01]\d{8}$').hasMatch(digits)) return '+234${digits.substring(1)}';
  if (RegExp(r'^[789][01]\d{8}$').hasMatch(digits)) return '+234$digits';
  return null;
}

/// Phone OTP (primary in Nigeria) and email sign-in. Router redirects away once signed in.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _phone = TextEditingController();
  final _code = TextEditingController();
  String? _verificationId;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // The router rebuilds its pages when the sign-in state changes. That can replace this screen with a fresh
    // copy while the sign-in call is still returning, and the old copy can no longer close itself. A copy that
    // opens when the customer is already signed in therefore leaves at once.
    WidgetsBinding.instance.addPostFrameCallback((_) => _leaveIfSignedIn());
  }

  /// Leave once signed in: back to the screen that opened sign-in (the Orders or Profile tab), or to `next`.
  /// (Pushed routes don't change the web URL, so the router's redirect alone can't do this.)
  void _leaveIfSignedIn() {
    if (!mounted || ref.read(authRepositoryProvider).currentUser == null) return;
    final next = GoRouterState.of(context).uri.queryParameters['next'];
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(next ?? '/');
    }
  }

  @override
  void dispose() {
    for (final c in [_email, _password, _phone, _code]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      _leaveIfSignedIn();
    } catch (e) {
      setState(() => _error = 'Sign-in failed. Please check your details and try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authRepositoryProvider);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(title: const Text('Sign in'), bottom: const TabBar(tabs: [Tab(text: 'Phone'), Tab(text: 'Email')])),
        body: TabBarView(children: [
          ListView(padding: const EdgeInsets.all(20), children: [
            if (_verificationId == null) ...[
              TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone number', hintText: '0803 000 0000', prefixText: '🇳🇬  '),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _busy
                    ? null
                    : () {
                        final phone = normaliseNigerianPhone(_phone.text);
                        if (phone == null) {
                          setState(() => _error = 'Enter a valid Nigerian mobile number');
                          return;
                        }
                        _run(() async {
                          final id = await auth.startPhoneSignIn(phone);
                          if (mounted && id.isNotEmpty) setState(() => _verificationId = id);
                        });
                      },
                child: const Text('Send code'),
              ),
            ] else ...[
              TextField(controller: _code, keyboardType: TextInputType.number, maxLength: 6, decoration: const InputDecoration(labelText: '6-digit code')),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _busy ? null : () => _run(() => auth.confirmPhoneCode(_verificationId!, _code.text.trim())),
                child: const Text('Verify & continue'),
              ),
            ],
          ]),
          ListView(padding: const EdgeInsets.all(20), children: [
            TextField(controller: _email, keyboardType: TextInputType.emailAddress, autofillHints: const [AutofillHints.email], decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 12),
            TextField(controller: _password, obscureText: true, autofillHints: const [AutofillHints.password], decoration: const InputDecoration(labelText: 'Password')),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : () => _run(() => auth.signInWithEmail(_email.text.trim(), _password.text)),
              child: const Text('Sign in'),
            ),
            TextButton(
              onPressed: _busy ? null : () => _run(() => auth.signUpWithEmail('Gud Meal customer', _email.text.trim(), _password.text)),
              child: const Text('Create an account'),
            ),
          ]),
        ]),
        bottomNavigationBar: _error == null
            ? null
            : SafeArea(child: Padding(padding: const EdgeInsets.all(16), child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)))),
      ),
    );
  }
}
