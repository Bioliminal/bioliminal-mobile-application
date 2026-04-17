import 'package:firebase_auth/firebase_auth.dart';

/// Firebase authentication wrapper. Opt-in only — not part of the default
/// provider graph. Only instantiated after explicit user opt-in to cloud sync
/// in settings. No Firebase SDK calls occur until this service is created.
/// See [cloudSyncEnabledProvider] in providers.dart.
class AuthService {
  AuthService(this._auth);

  /// Creates an [AuthService] using the default [FirebaseAuth] instance.
  /// This is the only call site that touches [FirebaseAuth.instance],
  /// ensuring Firebase Auth SDK is not initialized until opt-in.
  factory AuthService.withFirebase() => AuthService(FirebaseAuth.instance);

  final FirebaseAuth _auth;

  Future<String> signInAnonymously() async {
    final current = _auth.currentUser;
    if (current != null) return current.uid;

    final credential = await _auth.signInAnonymously();
    return credential.user!.uid;
  }

  Future<User> createAccount({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await credential.user!.updateDisplayName(displayName.trim());
    await credential.user!.reload();
    return _auth.currentUser!;
  }

  Future<User> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return credential.user!;
  }

  Future<void> updateDisplayName(String displayName) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No authenticated user to update.');
    }
    await user.updateDisplayName(displayName.trim());
    await user.reload();
  }

  User? get currentUser => _auth.currentUser;
  String? get uid => _auth.currentUser?.uid;
  bool get isSignedIn => uid != null;
  bool get isAnonymous => currentUser?.isAnonymous ?? false;

  Stream<String?> get authStateChanges =>
      _auth.authStateChanges().map((user) => user?.uid);

  /// Fires on sign-in, sign-out, and profile updates (displayName, email, etc.).
  /// Use this when downstream UI needs to reflect profile changes.
  Stream<User?> get userChanges => _auth.userChanges();

  Future<void> signOut() => _auth.signOut();
}
