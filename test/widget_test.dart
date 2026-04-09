import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:auralink/main.dart';

void main() {
  testWidgets('App renders disclaimer view', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: AuraLinkApp()),
    );
    expect(find.text('Before We Begin'), findsOneWidget);
  });
}
