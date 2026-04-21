import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'core/router.dart';
import 'core/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  // Firebase init skipped: this build is personal-signed with a bundle ID
  // not registered in the Firebase project, and the iOS SDK throws during
  // native init. Cloud sync is opt-in, so the offline-first flow is unaffected.
  runApp(const ProviderScope(child: BioliminalApp()));
}

class BioliminalApp extends StatelessWidget {
  const BioliminalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Bioliminal',
      theme: BioliminalTheme.darkTheme,
      routerConfig: goRouter,
    );
  }
}
