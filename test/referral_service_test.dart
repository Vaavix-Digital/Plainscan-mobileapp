import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:plainscan/core/services/storage_service.dart';
import 'package:plainscan/features/profile/pages/referral_share_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Referral & Unlimited Access Tests', () {
    test('getMyReferralCode returns mock code PLAIN2026 and persists', () async {
      final code1 = await StorageService.getMyReferralCode();
      expect(code1, equals('PLAIN2026'));

      final code2 = await StorageService.getMyReferralCode();
      expect(code2, equals(code1));
    });

    test('grantUnlimitedAccess enables PRO and sets 30-day expiry', () async {
      expect(await StorageService.isProUser(), isFalse);

      await StorageService.grantUnlimitedAccess(days: 30);

      expect(await StorageService.isProUser(), isTrue);
      final expiry = await StorageService.getProExpiryDate();
      expect(expiry, isNotNull);
      expect(expiry!.isAfter(DateTime.now().add(const Duration(days: 28))), isTrue);
    });

    test('applyReferralCode rejects own code, awards 50 credits, and rejects duplicates', () async {
      final myCode = await StorageService.getMyReferralCode();

      // Applying own code should fail
      final resOwn = await StorageService.applyReferralCode(myCode);
      expect(resOwn['success'], isFalse);
      expect(resOwn['message'], contains('cannot use your own'));

      // Initial credits
      final initialCredits = await StorageService.getUserCredits();

      // Applying valid friend code should succeed and award 50 credits
      const friendCode = 'PLAIN-FRIEND1';
      final resFriend = await StorageService.applyReferralCode(friendCode);
      expect(resFriend['success'], isTrue);
      expect(resFriend['credits_awarded'], equals(50));
      expect(await StorageService.getUserCredits(), equals(initialCredits + 50));
      expect(await StorageService.isProUser(), isTrue);
      expect(await StorageService.getReferralsCount(), equals(6));

      // Redeeming same code twice should fail
      final resDuplicate = await StorageService.applyReferralCode(friendCode);
      expect(resDuplicate['success'], isFalse);
      expect(resDuplicate['message'], contains('already redeemed'));
    });

    testWidgets('ReferralShareScreen renders referral UI, Play Store share button, and apply field',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const GetMaterialApp(
          home: ReferralShareScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Share & Refer PlainScan'), findsOneWidget);
      expect(find.text('Refer Friends & Earn Credits'), findsOneWidget);
      expect(find.text('Share PlainScan via Google Play'), findsOneWidget);
      expect(find.text('Apply Code'), findsOneWidget);
    });
  });
}
