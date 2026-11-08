import 'package:flutter_test/flutter_test.dart';
import 'package:noor/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const NoorApp());
    expect(find.byType(NoorApp), findsOneWidget);
  });
}
