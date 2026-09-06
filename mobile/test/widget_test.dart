import 'package:flutter_test/flutter_test.dart';
import 'package:keralink_mobile/main.dart';
import 'package:keralink_mobile/features/main/presentation/main_nav_screen.dart';

void main() {
  testWidgets('KeraLink App Navigation smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const KeraLinkApp());
    expect(find.byType(MainNavScreen), findsOneWidget);
  });
}
