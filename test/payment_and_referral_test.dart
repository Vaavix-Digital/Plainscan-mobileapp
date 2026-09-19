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
        'referral_code': 'XYZ987',
        'invite_link': 'https://plainscan.com/login?ref=XYZ987',
        'referral_count': 0,
        'message': 'Share this link! If a friend signs up, you get 1 month of Pro automatically.',
      };

      final info = ReferralInfo.fromJson(json);

      expect(info.referralCode, 'XYZ987');
      expect(info.inviteLink, 'https://plainscan.com/login?ref=XYZ987');
      expect(info.shareLink, 'https://plainscan.com/login?ref=XYZ987');
      expect(info.referralCount, 0);
      expect(info.totalReferred, 0);
      expect(info.message, 'Share this link! If a friend signs up, you get 1 month of Pro automatically.');
    });

    test('captures referral code from invite URL (e.g. https://plainscan.com/login?ref=XYZ987)', () async {
      final uri = Uri.parse('https://plainscan.com/login?ref=XYZ987');
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
