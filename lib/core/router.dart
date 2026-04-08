import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/camera/views/camera_view.dart';
import '../features/onboarding/views/disclaimer_view.dart';
import '../features/report/views/report_view.dart';
import '../features/screening/views/screening_view.dart';

final goRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const _SplashView(),
    ),
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
  ],
);

class _SplashView extends StatelessWidget {
  const _SplashView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('SplashView')),
    );
  }
}


