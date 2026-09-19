import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plainscan/core/controllers/dashboard_controller.dart';
import 'package:plainscan/core/controllers/profile_controller.dart';
import 'package:plainscan/core/controllers/scan_controller.dart';
import 'package:plainscan/core/services/auth_service.dart';
import 'package:plainscan/core/services/referral_service.dart';
import 'package:plainscan/core/services/storage_service.dart';
import 'package:plainscan/features/home/widgets/dashboard_referral_card.dart';
import 'package:plainscan/features/profile/pages/referral_share_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Get.reset();
  });

  group('Referral & Unlimited Access Tests', () {
    test('getMyReferralCode returns unique code per user and persists', () async {
      final code1 = await StorageService.getMyReferralCode();
      expect(code1, isNotEmpty);
      expect(code1.length, equals(6));

      final code2 = await StorageService.getMyReferralCode();
      expect(code2, equals(code1));

      // Test unique code generation with different user seeds
      final userACode = StorageService.generateUniqueReferralCode(seed: 'user_111111');
      final userBCode = StorageService.generateUniqueReferralCode(seed: 'user_222222');
      expect(userACode, isNot(equals(userBCode)));
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

    test('AuthService.signUp sends name, email, password, and referral_code in payload', () async {
      late String capturedBody;
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/auth/signup')) {
          capturedBody = request.body;
          return http.Response(
            '{"success":true,"message":"Account created successfully","user_id":"u_new"}',
            201,
          );
        }
        return http.Response('Not Found', 404);
      });

      final result = await AuthService.signUp(
        email: 'user@example.com',
        password: 'securepassword',
        name: 'John Doe',
        referralCode: 'ABC12345',
        client: mockClient,
      );

      expect(result.success, isTrue);
      expect(capturedBody, contains('"email":"user@example.com"'));
      expect(capturedBody, contains('"password":"securepassword"'));
      expect(capturedBody, contains('"name":"John Doe"'));
      expect(capturedBody, contains('"referral_code":"ABC12345"'));
    });

    test('AuthService.googleLogin sends token and referral_code in payload', () async {
      late String capturedBody;
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/auth/google') || request.url.path.contains('/auth/session')) {
          capturedBody = request.body;
          return http.Response(
            '{"data":{"accessToken":"test_google_token","user":{"user_id":"u_google","name":"Bob"}}}',
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final result = await AuthService.googleLogin(
        token: 'eyJhbGciOiJSUzI1NiIs...',
        referralCode: 'ABC12345',
        client: mockClient,
      );

      expect(result.success, isTrue);
      expect(capturedBody, contains('"token":"eyJhbGciOiJSUzI1NiIs..."'));
      expect(capturedBody, contains('"referral_code":"ABC12345"'));
    });

    test('AuthService.appleLogin sends token and referral_code in payload', () async {
      late String capturedBody;
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/auth/apple')) {
          capturedBody = request.body;
          return http.Response(
            '{"data":{"accessToken":"test_apple_token","user":{"user_id":"u_apple","name":"Carol"}}}',
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final result = await AuthService.appleLogin(
        token: 'eyJraWQiOiI...',
        referralCode: 'ABC12345',
        client: mockClient,
      );

      expect(result.success, isTrue);
      expect(capturedBody, contains('"token":"eyJraWQiOiI..."'));
      expect(capturedBody, contains('"referral_code":"ABC12345"'));
    });

    test('AuthService.createSession sends session_id and referral_code in payload', () async {
      late String capturedBody;
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/auth/session')) {
          capturedBody = request.body;
          return http.Response(
            '{"data":{"accessToken":"test_token","user":{"user_id":"u1","name":"Alice"}}}',
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      await StorageService.setPendingReferralCode('XYZ987');
      final result = await AuthService.createSession(
        sessionId: 'oauth_session_id_here',
        client: mockClient,
      );

      expect(result.success, isTrue);
      expect(capturedBody, contains('"session_id":"oauth_session_id_here"'));
      expect(capturedBody, contains('"referral_code":"XYZ987"'));
    });

    testWidgets('Dashboard referral card renders Invite Link, Code, and Share button',
        (WidgetTester tester) async {
      await StorageService.saveReferralData(code: 'XYZ987', totalReferred: 0, creditsEarned: 0);
      await StorageService.saveInviteLink('https://plainscan.com/login?ref=XYZ987');
      await StorageService.saveReferralMessage('Share this link! If a friend signs up, you get 1 month of Pro automatically.');

      Get.put(ScanController());
      Get.put(ProfileController());
      final dashboardCtrl = Get.put(DashboardController());

      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: buildDashboardReferralCard(dashboardCtrl),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Refer a Friend'), findsOneWidget);
      expect(find.text('https://plainscan.com/login?ref=XYZ987'), findsOneWidget);
      expect(find.text('Code: '), findsOneWidget);
      expect(find.text('XYZ987'), findsOneWidget);
      expect(find.text('0 Referred'), findsOneWidget);
      expect(find.text('Share'), findsOneWidget);
      expect(find.text('Copy'), findsOneWidget);
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
      expect(find.text('Share Your Code'), findsOneWidget);
      expect(find.text('Redeem'), findsOneWidget);
    });
  });
}
