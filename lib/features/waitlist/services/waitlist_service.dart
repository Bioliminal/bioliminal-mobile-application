import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

enum WaitlistSource { home, system, science, demo }

extension WaitlistSourceX on WaitlistSource {
  String get wire => switch (this) {
        WaitlistSource.home => 'home',
        WaitlistSource.system => 'system',
        WaitlistSource.science => 'science',
        WaitlistSource.demo => 'demo',
      };
}

sealed class WaitlistResult {
  const WaitlistResult();
}

class WaitlistSuccess extends WaitlistResult {
  const WaitlistSuccess();
}

class WaitlistInvalid extends WaitlistResult {
  const WaitlistInvalid(this.reason);
  final String reason;
}

class WaitlistFailure extends WaitlistResult {
  const WaitlistFailure(this.message);
  final String message;
}

// Matches the email regex enforced in firestore.rules. Kept intentionally loose
// — real validation happens server-side; this is just to bounce obvious typos
// before a network round trip.
final _emailPattern = RegExp(r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');

class WaitlistService {
  WaitlistService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<WaitlistResult> submit({
    required String email,
    required WaitlistSource source,
  }) async {
    final trimmed = email.trim();
    if (trimmed.isEmpty) {
      return const WaitlistInvalid('Enter an email to continue.');
    }
    if (!_emailPattern.hasMatch(trimmed)) {
      return const WaitlistInvalid("That doesn't look like an email.");
    }

    try {
      await _firestore.collection('waitlist').add({
        'email': trimmed,
        'source': source.wire,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return const WaitlistSuccess();
    } on FirebaseException catch (e) {
      debugPrint('waitlist firestore error: ${e.code} ${e.message}');
      return const WaitlistFailure(
        'Could not reach the server. Try again in a moment.',
      );
    } catch (e) {
      debugPrint('waitlist unexpected error: $e');
      return const WaitlistFailure('Something went wrong. Try again.');
    }
  }
}
