import 'package:flutter_test/flutter_test.dart';
import 'package:ourwatch/main.dart';

void main() {
  testWidgets('OurWatch app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const OurWatchApp());

    expect(find.text('OURWATCH'), findsWidgets);
  });
}
