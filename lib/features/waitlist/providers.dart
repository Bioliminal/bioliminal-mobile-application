import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'services/waitlist_service.dart';

final waitlistServiceProvider = Provider<WaitlistService>((ref) {
  return WaitlistService();
});
