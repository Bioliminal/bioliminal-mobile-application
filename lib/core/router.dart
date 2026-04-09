import 'package:go_router/go_router.dart';

import '../features/camera/views/camera_view.dart';
import '../features/history/views/history_view.dart';
import '../features/onboarding/views/disclaimer_view.dart';
import '../features/report/views/report_view.dart';
import '../features/screening/views/screening_view.dart';

final goRouter = GoRouter(
  initialLocation: '/disclaimer',
  routes: [
    GoRoute(
      path: '/disclaimer',
      builder: (context, state) => const DisclaimerView(),
    ),
    GoRoute(
      path: '/camera',
      builder: (context, state) => const CameraView(),
    ),
    GoRoute(
      path: '/screening',
      builder: (context, state) => const ScreeningView(),
    ),
    GoRoute(
      path: '/report/:id',
      builder: (context, state) => ReportView(
        id: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/history',
      builder: (context, state) => const HistoryView(),
    ),
  ],
);
