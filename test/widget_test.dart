import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:auralink/main.dart';

void main() {
  testWidgets('App renders splash view', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: AuraLinkApp()),
    );
    expect(find.text('SplashView'), findsOneWidget);
  });
}
