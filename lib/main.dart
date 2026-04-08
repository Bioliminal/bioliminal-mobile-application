import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router.dart';
import 'core/theme.dart';

void main() {
  runApp(
    const ProviderScope(
      child: AuraLinkApp(),
    ),
  );
}

class AuraLinkApp extends StatelessWidget {
  const AuraLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'AuraLink',
      theme: AuraLinkTheme.lightTheme,
      routerConfig: goRouter,
    );
  }
}
