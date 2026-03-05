import 'package:flutter_test/flutter_test.dart';
import 'package:mana_kiraa/app.dart';

void main() {
  testWidgets('App should launch', (WidgetTester tester) async {
    await tester.pumpWidget(ManaKiraaApp());
    expect(find.text('WELCOME'), findsOneWidget);
  });
}
