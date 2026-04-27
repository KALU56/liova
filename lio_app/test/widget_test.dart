import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lio_app/main.dart';

void main() {
  testWidgets('shows onboarding on first launch', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(ProviderScope(child: LiovaApp(prefs: prefs)));
    await tester.pumpAndSettle();

    expect(find.text('Read Ingredient Labels Faster'), findsOneWidget);
    expect(find.text('Create your Liova account'), findsNothing);
  });
}
