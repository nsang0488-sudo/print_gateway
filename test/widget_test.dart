import 'package:flutter_test/flutter_test.dart';
import 'package:print_gateway/main.dart';

void main() {
  testWidgets('App loads title smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('KÍCH HOẠT THIẾT BỊ'), findsOneWidget);
  });
}
