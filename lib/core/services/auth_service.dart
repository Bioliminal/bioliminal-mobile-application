import 'package:firebase_auth/firebase_auth.dart';

/// Firebase authentication wrapper. Opt-in only — not part of the default
/// provider graph. Only instantiated when the user enables cloud sync in
/// settings. See [cloudSyncEnabledProvider] in providers.dart.
class AuthService {
  AuthService(this._auth);

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
