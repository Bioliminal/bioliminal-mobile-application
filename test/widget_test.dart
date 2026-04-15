import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bioliminal/features/onboarding/views/disclaimer_view.dart';

void main() {
  testWidgets('App renders disclaimer view', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: DisclaimerView()));
    await tester.pumpAndSettle();
    expect(find.byType(DisclaimerView), findsOneWidget);
  });
}
