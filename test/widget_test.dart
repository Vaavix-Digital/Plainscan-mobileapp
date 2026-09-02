import 'package:flutter_test/flutter_test.dart';
import 'package:plainscan/app/app.dart';

void main() {
  testWidgets('Splash screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const PlainScanApp());

    // Verify that the splash screen shows the app title.
    expect(find.text('Plain'), findsOneWidget);
    expect(find.text('scan'), findsOneWidget);
  });
}
