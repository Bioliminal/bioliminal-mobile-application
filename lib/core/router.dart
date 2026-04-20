import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers.dart';
import '../features/bicep_curl/models/compensation_reference.dart';
import '../features/bicep_curl/views/bicep_curl_debrief_view.dart';
import '../features/bicep_curl/views/bicep_curl_view.dart';
import '../features/dev/views/ble_debug_view.dart';
import '../features/sets/views/set_picker_view.dart';
import '../features/history/views/history_view.dart';
import '../features/landing/views/code_view.dart';
import '../features/landing/views/demo_view.dart';
import '../features/landing/views/landing_page_view.dart';
import '../features/landing/views/science_view.dart';
import '../features/landing/views/system_view.dart';
import '../features/onboarding/views/disclaimer_view.dart';
import '../features/onboarding/views/auth_options_view.dart';
import '../features/waitlist/views/waitlist_view.dart';
import '../features/report/views/report_view.dart';
import '../features/settings/views/login_view.dart';
import '../features/settings/views/settings_view.dart';
import '../features/settings/views/profile_view.dart';
import '../features/settings/views/sign_in_view.dart';
import '../features/settings/views/sign_up_view.dart';
import '../features/settings/views/calibration_view.dart';
import 'widgets/main_scaffold.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorHistoryKey = GlobalKey<NavigatorState>();
final _shellNavigatorSettingsKey = GlobalKey<NavigatorState>();

/// Direction-free page transition matching the instrument-panel aesthetic:
/// pure fade, no scale, no slide. Symmetric on forward and reverse so
/// `context.go` (replace) and `context.pop` read identically — neither
/// can feel like it's animating in the "wrong direction" because there
/// is no direction.
Page<dynamic> _instrumentPage({
  required LocalKey key,
  required Widget child,
  String? name,
}) {
  return CustomTransitionPage<void>(
    key: key,
    name: name,
    child: child,
    transitionDuration: const Duration(milliseconds: 220),
    reverseTransitionDuration: const Duration(milliseconds: 180),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(opacity: curved, child: child);
    },
  );
}

final goRouter = GoRouter(
  initialLocation: kIsWeb ? '/' : '/disclaimer',
  navigatorKey: _rootNavigatorKey,
  redirect: (context, state) async {
    // Only redirect on initial launch for mobile.
    if (!kIsWeb && state.uri.path == '/disclaimer') {
      final container = ProviderScope.containerOf(context);
      final storage = container.read(localStorageServiceProvider);
      final records = await storage.listSessionRecords();

      // If they have sessions, they have already completed onboarding.
      if (records.isNotEmpty) {
        return '/history';
      }
    }
    return null;
  },
  routes: [
    // Marketing routes — web-style navigation (no transition).
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

    // App routes — unified instrument-panel fade transition.
    GoRoute(
      path: '/disclaimer',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _instrumentPage(
        key: state.pageKey,
        child: const DisclaimerView(),
      ),
    ),
    GoRoute(
      path: '/auth-options',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _instrumentPage(
        key: state.pageKey,
        child: const AuthOptionsView(),
      ),
    ),
    GoRoute(
      path: '/report/:id',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _instrumentPage(
        key: state.pageKey,
        child: ReportView(id: state.pathParameters['id']!),
      ),
    ),
    GoRoute(
      path: '/login',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _instrumentPage(
        key: state.pageKey,
        child: const LoginView(),
      ),
    ),
    GoRoute(
      path: '/sign-up',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _instrumentPage(
        key: state.pageKey,
        child: const SignUpView(),
      ),
    ),
    GoRoute(
      path: '/sign-in',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _instrumentPage(
        key: state.pageKey,
        child: const SignInView(),
      ),
    ),
    GoRoute(
      path: '/profile',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _instrumentPage(
        key: state.pageKey,
        child: const ProfileView(),
      ),
    ),
    GoRoute(
      path: '/calibration',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _instrumentPage(
        key: state.pageKey,
        child: const CalibrationView(),
      ),
    ),
    GoRoute(
      path: '/ble-debug',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _instrumentPage(
        key: state.pageKey,
        child: const BleDebugView(),
      ),
    ),
    GoRoute(
      path: '/sets',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _instrumentPage(
        key: state.pageKey,
        child: const SetPickerView(),
      ),
    ),
    GoRoute(
      path: '/bicep-curl',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) {
        final side = state.uri.queryParameters['side'] == 'left'
            ? ArmSide.left
            : ArmSide.right;
        return _instrumentPage(
          key: state.pageKey,
          child: BicepCurlView(armSide: side),
        );
      },
    ),
    GoRoute(
      path: '/bicep-curl/debrief/:id',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _instrumentPage(
        key: state.pageKey,
        child: BicepCurlDebriefView(sessionId: state.pathParameters['id']!),
      ),
    ),

    // Shell routes for bottom nav — branches cross-fade instead of hard-cut.
    StatefulShellRoute(
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state, navigationShell) {
        return MainScaffold(navigationShell: navigationShell);
      },
      navigatorContainerBuilder: (context, navigationShell, children) {
        return _ShellCrossfade(
          currentIndex: navigationShell.currentIndex,
          children: children,
        );
      },
      branches: [
        StatefulShellBranch(
          navigatorKey: _shellNavigatorHistoryKey,
          routes: [
            GoRoute(
              path: '/history',
              pageBuilder: (context, state) => _instrumentPage(
                key: state.pageKey,
                child: const HistoryView(),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _shellNavigatorSettingsKey,
          routes: [
            GoRoute(
              path: '/settings',
              pageBuilder: (context, state) => _instrumentPage(
                key: state.pageKey,
                child: const SettingsView(),
              ),
            ),
          ],
        ),
      ],
    ),
  ],
);

/// Stacks all shell branches at once and cross-fades between them when the
/// bottom nav index changes. Keeps every branch mounted so scroll/state is
/// preserved (same guarantee as `StatefulShellRoute.indexedStack`).
class _ShellCrossfade extends StatelessWidget {
  const _ShellCrossfade({
    required this.currentIndex,
    required this.children,
  });

  final int currentIndex;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        for (var i = 0; i < children.length; i++)
          IgnorePointer(
            ignoring: currentIndex != i,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              opacity: currentIndex == i ? 1.0 : 0.0,
              child: children[i],
            ),
          ),
      ],
    );
  }
}
