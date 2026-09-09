import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:plainscan/features/onboarding/screens/onboarding_screen.dart';
import 'package:plainscan/features/onboarding/screens/language_selection_screen.dart';
import 'package:plainscan/features/onboarding/screens/consent_permissions_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('OnboardingScreen renders welcome slides and navigation buttons', (WidgetTester tester) async {
    await tester.pumpWidget(
      const GetMaterialApp(
        home: OnboardingScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('PlainScan'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(find.text('Professional HD Scanner'), findsOneWidget);
  });

  testWidgets('LanguageSelectionScreen renders search bar and language options', (WidgetTester tester) async {
    await tester.pumpWidget(
      const GetMaterialApp(
        home: LanguageSelectionScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Select Your Language'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('Spanish'), findsOneWidget);
    expect(find.text('Continue to Consent'), findsOneWidget);

    // Enter search text
    await tester.enterText(find.byType(TextField), 'German');
    await tester.pumpAndSettle();

    expect(find.text('Deutsch'), findsOneWidget);
    expect(find.text('Spanish'), findsNothing);
  });

  testWidgets('ConsentPermissionsScreen renders Camera, Gallery, and Privacy Guarantee', (WidgetTester tester) async {
    await tester.pumpWidget(
      const GetMaterialApp(
        home: ConsentPermissionsScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Permissions & Consent'), findsOneWidget);
    expect(find.text('Camera Access'), findsOneWidget);
    expect(find.text('Photos & Files Gallery'), findsOneWidget);
    expect(find.text('Live Tool Notifications'), findsOneWidget);
    expect(find.text('Our Privacy Guarantee'), findsOneWidget);
    expect(find.text('I Consent & Get Started'), findsOneWidget);
  });
}
