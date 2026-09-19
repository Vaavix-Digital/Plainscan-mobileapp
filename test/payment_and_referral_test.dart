import 'package:flutter_test/flutter_test.dart';
import 'package:plainscan/core/services/payment_service.dart';
import 'package:plainscan/core/services/referral_service.dart';
import 'package:plainscan/core/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Payment APIs tests', () {
    test('parses Indian IP Razorpay order payload accurately', () {
      final json = {
        'provider': 'razorpay',
        'order_id': 'order_123456',
        'amount': 9900,
        'currency': 'INR',
        'key': 'rzp_live_testkey',
        'plan_name': 'Pro Monthly',
      };

      final order = PaymentOrderResult.fromJson(json);

      expect(order.success, isTrue);
      expect(order.provider, 'razorpay');
      expect(order.isRazorpay, isTrue);
      expect(order.isStripe, isFalse);
      expect(order.orderId, 'order_123456');
      expect(order.amount, 9900);
      expect(order.currency, 'INR');
      expect(order.key, 'rzp_live_testkey');
      expect(order.planName, 'Pro Monthly');
      expect(order.formattedDisplayPrice, '₹99');
    });

    test('parses International IP Stripe order payload accurately', () {
      final json = {
        'provider': 'stripe',
        'session_id': 'cs_test_123456',
        'public_key': 'pk_live_testkey',
        'amount_usd': 10.0,
        'currency': 'USD',
      };

      final order = PaymentOrderResult.fromJson(json);

      expect(order.success, isTrue);
      expect(order.provider, 'stripe');
      expect(order.isRazorpay, isFalse);
      expect(order.isStripe, isTrue);
      expect(order.sessionId, 'cs_test_123456');
      expect(order.publicKey, 'pk_live_testkey');
      expect(order.amountUsd, 10.0);
      expect(order.currency, 'USD');
      expect(order.formattedDisplayPrice, '\$10');
    });

    test('parses payment verification response accurately', () {
      final json = {
        'status': 'success',
        'message': 'Payment verified and subscription activated',
      };

      final result = PaymentVerifyResult.fromJson(json);

      expect(result.success, isTrue);
      expect(result.status, 'success');
      expect(result.message, 'Payment verified and subscription activated');
    });
  });

  group('Referral APIs tests', () {
    test('parses referral info payload accurately from GET /api/auth/me/referral', () {
      final json = {
        'referral_code': 'ABC12345',
        'invite_link': 'https://play.google.com/store/apps/details?id=com.plainscan.app&referral=ABC12345',
        'play_store_link': 'https://play.google.com/store/apps/details?id=com.plainscan.app&referral=ABC12345',
        'app_store_link': 'https://apps.apple.com/app/id1234567890?referral=ABC12345',
        'web_link': 'https://plainscan.com/signup?ref=ABC12345',
        'referral_count': 0,
        'message': 'Share this link! If a friend signs up, you get 1 month of Pro automatically.',
      };

      final info = ReferralInfo.fromJson(json);

      expect(info.referralCode, 'ABC12345');
      expect(info.inviteLink, contains('details?id=com.plainscan.app&referral=ABC12345'));
      expect(info.playStoreLink, contains('details?id=com.plainscan.app&referral=ABC12345'));
      expect(info.appStoreLink, contains('id1234567890?referral=ABC12345'));
      expect(info.webLink, 'https://plainscan.com/signup?ref=ABC12345');
      expect(info.referralCount, 0);
      expect(info.totalReferred, 0);
      expect(info.message, 'Share this link! If a friend signs up, you get 1 month of Pro automatically.');
    });

    test('captures referral code from Play Store install referrer string and URLs', () async {
      // 1. Play Store raw install referrer string
      const rawPlayReferrer = 'utm_source=google-play&utm_medium=organic&referral=ABC12345';
      final parsed1 = StorageService.parseReferralCodeFromString(rawPlayReferrer);
      expect(parsed1, equals('ABC12345'));

      // 2. Play store full URL
      const playStoreUrl = 'https://play.google.com/store/apps/details?id=com.plainscan.app&referral=ABC12345';
      final parsed2 = StorageService.parseReferralCodeFromString(playStoreUrl);
      expect(parsed2, equals('ABC12345'));

      // 3. Web URL
      const webUrl = 'https://plainscan.com/login?ref=XYZ987';
      final uri = Uri.parse(webUrl);
      final captured = await StorageService.captureReferralFromUri(uri);
      expect(captured, equals('XYZ987'));
      expect(await StorageService.getPendingReferralCode(), equals('XYZ987'));
    });

    test('parses referral apply payload accurately', () {
      final json = {
        'status': 'success',
        'message': 'Referral code applied! 50 credits added to your account.',
        'credits_awarded': 50,
      };

      final result = ReferralApplyResult.fromJson(json);

      expect(result.success, isTrue);
      expect(result.creditsAwarded, 50);
      expect(result.message, contains('50 credits added'));
    });

    test('ReferralService.getMyReferralCode falls back gracefully to local code', () async {
      final info = await ReferralService.getMyReferralCode();
      expect(info.referralCode, isNotEmpty);
      expect(info.inviteLink, contains('plainscan.com/login?ref='));
    });
  });
}
