import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:take_home/app/app.dart';
import 'package:take_home/app/di/injection.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await setupInjection();
  });

  testWidgets('App boots to the dashboard tab with nav shell', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    expect(find.text('Smart Workspace'), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Notes'), findsOneWidget);
    expect(find.text('Search'), findsOneWidget);
  });
}
