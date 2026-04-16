import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers.dart';
import '../features/camera/views/hardware_setup_view.dart';
import '../features/dev/views/ble_debug_view.dart';
import '../features/history/views/history_view.dart';
import '../features/landing/views/code_view.dart';
import '../features/landing/views/demo_view.dart';
import '../features/landing/views/landing_page_view.dart';
import '../features/landing/views/science_view.dart';
import '../features/landing/views/system_view.dart';
import '../features/onboarding/views/disclaimer_view.dart';
import '../features/onboarding/views/auth_options_view.dart';
import '../features/waitlist/views/waitlist_view.dart';
import '../features/rep_capture/views/rep_capture_view.dart';
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
  initialLocation: kIsWeb ? '/' : '/disclaimer',
  navigatorKey: _rootNavigatorKey,
  redirect: (context, state) async {
    // Only redirect on initial launch for mobile.
    if (!kIsWeb && state.uri.path == '/disclaimer') {
      final container = ProviderScope.containerOf(context);
      final storage = container.read(localStorageServiceProvider);
      final assessments = await storage.listAssessments();

      // If they have assessments, they have already completed onboarding.
      if (assessments.isNotEmpty) {
        return '/history';
      }
    }
    return null;
  },
  routes: [
    // Marketing routes — web-style navigation (no mobile slide transition).
    GoRoute(
      path: '/',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) =>
          const NoTransitionPage(child: LandingPageView()),
    ),
    GoRoute(
      path: '/system',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) =>
          const NoTransitionPage(child: SystemView()),
    ),
    GoRoute(
      path: '/science',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) =>
          const NoTransitionPage(child: ScienceView()),
    ),
    GoRoute(
      path: '/demo',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) =>
          const NoTransitionPage(child: DemoView()),
    ),
    GoRoute(
      path: '/code',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) =>
          const NoTransitionPage(child: CodeView()),
    ),
    GoRoute(
      path: '/waitlist',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) =>
          const NoTransitionPage(child: WaitlistView()),
    ),
    GoRoute(
      path: '/disclaimer',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const DisclaimerView(),
    ),
    GoRoute(
      path: '/auth-options',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AuthOptionsView(),
    ),
    GoRoute(
      path: '/hardware-setup',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const HardwareSetupView(),
    ),
    GoRoute(
      path: '/capture',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const RepCaptureView(),
    ),
    // Dormant until post-demo — no user-reachable entrypoint. See #30.
    GoRoute(
      path: '/screening',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ScreeningView(),
    ),
    GoRoute(
      path: '/report/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => ReportView(id: state.pathParameters['id']!),
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
    GoRoute(
      path: '/ble-debug',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const BleDebugView(),
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
