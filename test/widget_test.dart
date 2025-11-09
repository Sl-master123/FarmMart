import 'package:flutter_test/flutter_test.dart';
import 'package:newadd/main.dart';

void main() {
  testWidgets('App initializes successfully', (WidgetTester tester) async {
    // Test that the app builds without errors
    await tester.pumpWidget(const MyApp());

    // Verify app initializes
    expect(find.byType(MyApp), findsOneWidget);
  });
}
