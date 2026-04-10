import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers.dart';
import '../features/history/views/history_view.dart';
import '../features/onboarding/views/disclaimer_view.dart';
import '../features/report/views/report_view.dart';
import '../features/screening/views/screening_view.dart';
import '../features/settings/views/login_view.dart';
import '../features/settings/views/settings_view.dart';
import '../features/settings/views/profile_view.dart';
import '../features/settings/views/ai_model_settings_view.dart';
import '../features/settings/views/calibration_view.dart';
import 'widgets/main_scaffold.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorHistoryKey = GlobalKey<NavigatorState>();
final _shellNavigatorSettingsKey = GlobalKey<NavigatorState>();

final goRouter = GoRouter(
  initialLocation: '/disclaimer',
  navigatorKey: _rootNavigatorKey,
  redirect: (context, state) async {
    // Only redirect on initial launch.
    if (state.uri.path != '/disclaimer') return null;

    final container = ProviderScope.containerOf(context);
    final storage = container.read(localStorageServiceProvider);
    final assessments = await storage.listAssessments();

    if (assessments.isNotEmpty) {
      return '/history';
    }
    return null;
  },
  routes: [
    // Full-screen routes
    GoRoute(
      path: '/disclaimer',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const DisclaimerView(),
    ),
    GoRoute(
      path: '/screening',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ScreeningView(),
    ),
    GoRoute(
      path: '/report/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => ReportView(
        id: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/login',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const LoginView(),
    ),
    GoRoute(
      path: '/profile',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ProfileView(),
    ),
    GoRoute(
      path: '/ai-settings',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AIModelSettingsView(),
    ),
    GoRoute(
      path: '/calibration',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const CalibrationView(),
    ),

    // Shell routes for bottom nav
    StatefulShellRoute.indexedStack(
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state, navigationShell) {
        return MainScaffold(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          navigatorKey: _shellNavigatorHistoryKey,
          routes: [
            GoRoute(
              path: '/history',
              builder: (context, state) => const HistoryView(),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _shellNavigatorSettingsKey,
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsView(),
            ),
          ],
        ),
      ],
    ),
  ],
);
