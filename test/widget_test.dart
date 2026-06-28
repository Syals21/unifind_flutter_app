import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unifind_flutter_app/main.dart';

void main() {
  testWidgets('UniFind splash screen loads', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const UniFindApp());

    expect(find.text('Campus Lost & Found'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('Welcome to UniFind'), findsOneWidget);
  });
}
