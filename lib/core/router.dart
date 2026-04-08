import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final goRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const _SplashView(),
    ),
    GoRoute(
      path: '/camera',
      builder: (context, state) => const _CameraView(),
    ),
    GoRoute(
      path: '/screening',
      builder: (context, state) => const _ScreeningView(),
    ),
    GoRoute(
      path: '/report/:id',
      builder: (context, state) => _ReportView(
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

class _CameraView extends StatelessWidget {
  const _CameraView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('CameraView')),
    );
  }
}

class _ScreeningView extends StatelessWidget {
  const _ScreeningView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('ScreeningView')),
    );
  }
}

class _ReportView extends StatelessWidget {
  const _ReportView({required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('ReportView: $id')),
    );
  }
}
