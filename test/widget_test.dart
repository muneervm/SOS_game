import 'package:flutter_test/flutter_test.dart';
import 'package:sos/main.dart';

void main() {
  testWidgets('SOS Game setup screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SosGameApp());

    expect(find.text('SOS MATCH'), findsOneWidget);
    expect(find.text('START MATCH'), findsOneWidget);
  });
}
