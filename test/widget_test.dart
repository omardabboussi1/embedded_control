import 'package:flutter_test/flutter_test.dart';
import 'package:embedded_control/main.dart';

void main() {
  testWidgets('EmbedControlApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const EmbedControlApp());
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Verify the splash screen renders with the app name
    expect(find.text('EmbedControl'), findsOneWidget);
  });
}
