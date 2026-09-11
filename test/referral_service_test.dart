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
    test('getMyReferralCode generates and persists unique code', () async {
      final code1 = await StorageService.getMyReferralCode();
      expect(code1, startsWith('PLAIN-'));
      expect(code1.length, greaterThanOrEqualTo(10));

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

    test('applyReferralCode rejects own code and already redeemed code', () async {
      final myCode = await StorageService.getMyReferralCode();

      // Applying own code should fail
      final resOwn = await StorageService.applyReferralCode(myCode);
      expect(resOwn['success'], isFalse);
      expect(resOwn['message'], contains('cannot use your own'));

      // Applying valid friend code should succeed
      const friendCode = 'PLAIN-FRIEND1';
      final resFriend = await StorageService.applyReferralCode(friendCode);
      expect(resFriend['success'], isTrue);
      expect(await StorageService.isProUser(), isTrue);
      expect(await StorageService.getReferralsCount(), equals(1));

      // Redeeming same code twice should fail
      final resDuplicate = await StorageService.applyReferralCode(friendCode);
      expect(resDuplicate['success'], isFalse);
      expect(resDuplicate['message'], contains('already redeemed'));
    });

    testWidgets('ReferralShareScreen renders referral UI, share button, and redeem field',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const GetMaterialApp(
          home: ReferralShareScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Share & Get Free Month'), findsOneWidget);
      expect(find.text('Get 1 Month Unlimited Free'), findsOneWidget);
      expect(find.text('Share PlainScan with Friends'), findsOneWidget);
      expect(find.text('Redeem'), findsOneWidget);
    });
  });
}
