import 'package:flutter_test/flutter_test.dart';
import 'package:sos/main.dart';

void main() {
  testWidgets('SOS Game setup screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SosGameApp());

    // Verify that the title 'SOS MATCH' is displayed on the setup screen.
    expect(find.text('SOS MATCH'), findsOneWidget);
    expect(find.text('START MATCH'), findsOneWidget);
  });
}
