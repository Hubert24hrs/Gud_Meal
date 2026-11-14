import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fb;

class GmUser {
  const GmUser({required this.uid, this.email, this.name, this.phone});
  final String uid;
  final String? email;
  final String? name;
  final String? phone;
}

/// Authentication port. The Firebase implementation is used in the apps; tests use a fake.
abstract class AuthRepository {
  Stream<GmUser?> authStateChanges();
  GmUser? get currentUser;
  Future<String?> idToken();
  Future<void> signInWithEmail(String email, String password);
  Future<void> signUpWithEmail(String name, String email, String password);

  /// Starts phone sign-in (Nigerian numbers in E.164, e.g. +2348012345678). Returns a verification id.
  Future<String> startPhoneSignIn(String phoneNumber);
  Future<void> confirmPhoneCode(String verificationId, String smsCode);
  Future<void> signOut();
}

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth);
  final fb.FirebaseAuth _auth;

  GmUser? _map(fb.User? u) => u == null ? null : GmUser(uid: u.uid, email: u.email, name: u.displayName, phone: u.phoneNumber);

  @override
  Stream<GmUser?> authStateChanges() => _auth.idTokenChanges().map(_map);

  @override
  GmUser? get currentUser => _map(_auth.currentUser);

  @override
  Future<String?> idToken() async => _auth.currentUser?.getIdToken();

  @override
  Future<void> signInWithEmail(String email, String password) => _auth.signInWithEmailAndPassword(email: email, password: password);

  @override
  Future<void> signUpWithEmail(String name, String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    await cred.user?.updateDisplayName(name);
  }

  @override
  Future<String> startPhoneSignIn(String phoneNumber) {
    final completer = Completer<String>();
    _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (credential) async {
        await _auth.signInWithCredential(credential); // Android auto-retrieval
        if (!completer.isCompleted) completer.complete('');
      },
      verificationFailed: (e) {
        if (!completer.isCompleted) completer.completeError(e);
      },
      codeSent: (verificationId, _) {
        if (!completer.isCompleted) completer.complete(verificationId);
      },
      codeAutoRetrievalTimeout: (_) {},
    );
    return completer.future;
  }

  @override
  Future<void> confirmPhoneCode(String verificationId, String smsCode) =>
      _auth.signInWithCredential(fb.PhoneAuthProvider.credential(verificationId: verificationId, smsCode: smsCode));

  @override
  Future<void> signOut() => _auth.signOut();
}

/// In-memory auth for tests and screenshots.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository([GmUser? user]) : _user = user;
  GmUser? _user;
  final _controller = StreamController<GmUser?>.broadcast();

  @override
  Stream<GmUser?> authStateChanges() async* {
    yield _user;
    yield* _controller.stream;
  }

  @override
  GmUser? get currentUser => _user;

  @override
  Future<String?> idToken() async => _user == null ? null : 'fake-token-${_user!.uid}';

  @override
  Future<void> signInWithEmail(String email, String password) async {
    if (password.length < 6) throw Exception('Invalid credentials');
    _user = GmUser(uid: 'u-$email', email: email);
    _controller.add(_user);
  }

  @override
  Future<void> signUpWithEmail(String name, String email, String password) => signInWithEmail(email, password);

  @override
  Future<String> startPhoneSignIn(String phoneNumber) async => 'verification-$phoneNumber';

  @override
  Future<void> confirmPhoneCode(String verificationId, String smsCode) async {
    _user = GmUser(uid: 'u-${verificationId.split('-').last}', phone: verificationId.split('-').last);
    _controller.add(_user);
  }

  @override
  Future<void> signOut() async {
    _user = null;
    _controller.add(null);
  }
}
