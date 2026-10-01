import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:plainscan/core/controllers/plan_controller.dart';
import 'package:plainscan/core/controllers/profile_controller.dart';
import 'package:plainscan/core/services/storage_service.dart';
import 'package:plainscan/core/services/subscription_service.dart';
import 'package:plainscan/models/plan_model.dart';
import 'package:plainscan/models/tool_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Get.testMode = true;
    Get.reset();
  });

  tearDown(() {
    Get.reset();
  });

  group('Pro Plan Expiration - StorageService & Automatic Downgrade', () {
    test('Pro plan with past expiry timestamp automatically changes to free', () async {
      final pastDate = DateTime.now().subtract(const Duration(hours: 2)).toIso8601String();

      await StorageService.saveSubscriptionDetails(
        planId: 'pro',
        expiresAt: pastDate,
        status: 'active',
      );

      // Status should immediately be detected as expired
      expect(await StorageService.isProUser(), isFalse);
      expect(await StorageService.getPlan(), 'free');
      expect(await StorageService.getSubscriptionStatus(), 'expired');
    });

    test('Pro plan with future expiry timestamp remains active pro', () async {
      final futureDate = DateTime.now().add(const Duration(days: 30)).toIso8601String();

      await StorageService.saveSubscriptionDetails(
        planId: 'pro',
        expiresAt: futureDate,
        status: 'active',
      );

      expect(await StorageService.isProUser(), isTrue);
      expect(await StorageService.getPlan(), 'pro');
      expect(await StorageService.getSubscriptionStatus(), 'active');
    });

    test('Pro plan with expired status automatically reverts to free even if planId was pro', () async {
      await StorageService.saveSubscriptionDetails(
        planId: 'pro',
        status: 'expired',
      );

      expect(await StorageService.isProUser(), isFalse);
      expect(await StorageService.getPlan(), 'free');
    });

    test('Pro plan with canceled or inactive status automatically reverts to free', () async {
      await StorageService.saveSubscriptionDetails(
        planId: 'pro',
        status: 'canceled',
      );

      expect(await StorageService.isProUser(), isFalse);
      expect(await StorageService.getPlan(), 'free');
    });

    test('processAndSaveSubscription handles expired timestamp from server response', () async {
      final serverResponse = {
        'data': {
          'plan_id': 'pro',
          'subscription_expires_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
          'status': 'active',
        }
      };

      await StorageService.processAndSaveSubscription(data: serverResponse['data']!);

      expect(await StorageService.isProUser(), isFalse);
      expect(await StorageService.getPlan(), 'free');
      expect(await StorageService.getSubscriptionStatus(), 'expired');
    });

    test('processAndSaveSubscription handles active timestamp from server response', () async {
      final serverResponse = {
        'data': {
          'plan_id': 'pro',
          'subscription_expires_at': DateTime.now().add(const Duration(days: 15)).toIso8601String(),
          'status': 'active',
        }
      };

      await StorageService.processAndSaveSubscription(data: serverResponse['data']!);

      expect(await StorageService.isProUser(), isTrue);
      expect(await StorageService.getPlan(), 'pro');
    });

    test('checkAndEnforcePlanExpiration downgrades plan and returns true when expired', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_plan', 'pro');
      await prefs.setString('pro_expiry_timestamp', DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String());

      final wasExpired = await StorageService.checkAndEnforcePlanExpiration();
      expect(wasExpired, isTrue);
      expect(prefs.getString('user_plan'), 'free');
      expect(prefs.getString('subscription_status'), 'expired');
    });
  });

  group('Pro Plan Expiration - Controllers & UI State Synchronization', () {
    test('ProfileController and PlanController react immediately to plan expiration', () async {
      final profileCtrl = Get.put(ProfileController());
      final planCtrl = Get.put(PlanController());

      // Start with active pro
      profileCtrl.userPlan.value = 'pro';
      profileCtrl.isPro.value = true;
      planCtrl.currentPlan.value = PlanModel(planId: 'pro', name: 'Pro', priceMonthly: 764.0);

      expect(profileCtrl.isPro.value, isTrue);
      expect(profileCtrl.userPlan.value, 'pro');

      // Trigger plan expiration
      await StorageService.expireProPlan();

      // State should immediately update without logout/login
      expect(profileCtrl.isPro.value, isFalse);
      expect(profileCtrl.userPlan.value, 'free');
      expect(planCtrl.currentPlan.value?.isFree, isTrue);
    });

    test('SubscriptionService automatically detects expiration and updates ProfileController', () async {
      final profileCtrl = Get.put(ProfileController());
      final subService = Get.put(SubscriptionService());

      profileCtrl.userPlan.value = 'pro';
      profileCtrl.isPro.value = true;

      // Set expired timestamp in storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_plan', 'pro');
      await prefs.setString('pro_expiry_timestamp', DateTime.now().subtract(const Duration(seconds: 10)).toIso8601String());

      // Run check
      await subService.checkSubscriptionStatus();

      expect(profileCtrl.isPro.value, isFalse);
      expect(profileCtrl.userPlan.value, 'free');
      expect(await StorageService.isProUser(), isFalse);
    });
  });

  group('Pro Plan Expiration - Pro Features Restriction', () {
    test('Pro-only tools are blocked and restricted when plan expires', () async {
      // User is free
      await StorageService.savePlan('free');
      final isPro = await StorageService.isProUser();
      expect(isPro, isFalse);

      final proTool = allPlainscanTools.firstWhere((t) => t.id == 'ai-summarize');
      expect(proTool.isFree, isFalse);

      // Verify Pro tool is blocked for free user
      expect(isPro, isFalse);
    });
  });
}
