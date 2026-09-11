import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:plainscan/core/services/permission_service.dart';
import 'package:plainscan/features/onboarding/screens/onboarding_screen.dart';
import 'package:plainscan/features/onboarding/screens/language_selection_screen.dart';
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

    expect(find.text('Choose Your Language'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('Spanish'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);

    // Enter search text
    await tester.enterText(find.byType(TextField), 'German');
    await tester.pumpAndSettle();

    expect(find.text('Deutsch'), findsOneWidget);
    expect(find.text('Spanish'), findsNothing);
  });

  test('AppPermissionService handles sequential permission requests without unhandled errors', () async {
    // 1. Notification first
    await AppPermissionService.requestNotificationPermission();

    // 2. Camera and Gallery after notification
    await AppPermissionService.requestCameraAndGalleryPermissions();

    // Combined open method
    await AppPermissionService.requestAppOpenPermissions();

    expect(true, isTrue);
  });
}
