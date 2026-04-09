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

  Future<String> signIn() async {
    final current = _auth.currentUser;
    if (current != null) return current.uid;

    final credential = await _auth.signInAnonymously();
    return credential.user!.uid;
  }

  String? get uid => _auth.currentUser?.uid;

  Stream<String?> get authStateChanges =>
      _auth.authStateChanges().map((user) => user?.uid);

  Future<void> signOut() => _auth.signOut();

  bool get isSignedIn => uid != null;
}
