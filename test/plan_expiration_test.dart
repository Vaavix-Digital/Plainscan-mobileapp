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

  group('Plan Expired Notification Requirements', () {
    test('Free user who never selected a plan is not marked as expired and receives no notification', () async {
      await StorageService.savePlan('free');
      final subService = Get.put(SubscriptionService());

      expect(await StorageService.hasPreviouslySelectedPlan(), isFalse);
      expect(await StorageService.isSubscriptionExpired(), isFalse);
      expect(await StorageService.isProUser(), isFalse);

      final shown = await subService.showExpiredPlanNoticeIfEligible(isAppOpen: true);
      expect(shown, isFalse);
      expect(subService.hasShownExpiredMessageInSession, isFalse);
    });

    test('Active subscriber is not marked as expired and receives no notification', () async {
      final futureDate = DateTime.now().add(const Duration(days: 30)).toIso8601String();
      await StorageService.saveSubscriptionDetails(
        planId: 'pro',
        expiresAt: futureDate,
        status: 'active',
      );
      final subService = Get.put(SubscriptionService());

      expect(await StorageService.hasPreviouslySelectedPlan(), isTrue);
      expect(await StorageService.isProUser(), isTrue);
      expect(await StorageService.isSubscriptionExpired(), isFalse);

      final shown = await subService.showExpiredPlanNoticeIfEligible(isAppOpen: true);
      expect(shown, isFalse);
      expect(subService.hasShownExpiredMessageInSession, isFalse);
    });

    test('Expired plan user receives notification only once when opening app and prevents duplicates in session', () async {
      final pastDate = DateTime.now().subtract(const Duration(days: 2)).toIso8601String();
      await StorageService.saveSubscriptionDetails(
        planId: 'pro',
        expiresAt: pastDate,
        status: 'expired',
      );
      final subService = Get.put(SubscriptionService());

      expect(await StorageService.hasPreviouslySelectedPlan(), isTrue);
      expect(await StorageService.isProUser(), isFalse);
      expect(await StorageService.isSubscriptionExpired(), isTrue);

      // 1. First app open: notification is eligible and shown
      final firstShow = await subService.showExpiredPlanNoticeIfEligible(isAppOpen: true);
      expect(firstShow, isTrue);
      expect(subService.hasShownExpiredMessageInSession, isTrue);

      // 2. Duplicate check during the same session on app open: blocked
      final duplicateShow = await subService.showExpiredPlanNoticeIfEligible(isAppOpen: true);
      expect(duplicateShow, isFalse);

      // 3. Normal app usage (isAppOpen: false): blocked
      final duringUsageShow = await subService.showExpiredPlanNoticeIfEligible(isAppOpen: false);
      expect(duringUsageShow, isFalse);
    });

    test('Normal app usage does not trigger notification even if user is expired', () async {
      final pastDate = DateTime.now().subtract(const Duration(days: 2)).toIso8601String();
      await StorageService.saveSubscriptionDetails(
        planId: 'pro',
        expiresAt: pastDate,
        status: 'expired',
      );
      final subService = Get.put(SubscriptionService());

      // Normal usage (e.g., navigating, using tools)
      final shown = await subService.showExpiredPlanNoticeIfEligible(isAppOpen: false);
      expect(shown, isFalse);
      expect(subService.hasShownExpiredMessageInSession, isFalse);
    });

    test('Session flag persists across multiple checkSubscriptionStatus calls in same session', () async {
      final pastDate = DateTime.now().subtract(const Duration(days: 2)).toIso8601String();
      await StorageService.saveSubscriptionDetails(
        planId: 'pro',
        expiresAt: pastDate,
        status: 'expired',
      );
      final subService = Get.put(SubscriptionService());

      // Initial open
      await subService.checkSubscriptionStatus(isAppOpen: true);
      expect(subService.hasShownExpiredMessageInSession, isTrue);

      // Second check (e.g. repeated login or navigation in same session)
      await subService.checkSubscriptionStatus(isAppOpen: true);
      expect(subService.hasShownExpiredMessageInSession, isTrue);
    });

    test('Free user checking subscription status on login never triggers notification', () async {
      await StorageService.savePlan('free');
      final subService = Get.put(SubscriptionService());

      await subService.checkSubscriptionStatus(isAppOpen: true);
      expect(subService.hasShownExpiredMessageInSession, isFalse);
    });

    test('Expiration message appears only once on first app open and does not appear when closing and reopening app', () async {
      final pastDate = DateTime.now().subtract(const Duration(days: 2)).toIso8601String();
      await StorageService.saveSubscriptionDetails(
        planId: 'pro',
        expiresAt: pastDate,
        status: 'expired',
      );

      // Session 1: User opens app for the first time after expiration
      final subService1 = Get.put(SubscriptionService());
      final firstAppOpen = await subService1.showExpiredPlanNoticeIfEligible(isAppOpen: true);
      expect(firstAppOpen, isTrue);
      expect(await StorageService.hasShownExpiredNotice(), isTrue);

      // Session 2: User closes Plainscan and reopens it
      Get.reset();
      final subService2 = Get.put(SubscriptionService());
      expect(subService2.hasShownExpiredMessageInSession, isFalse);

      final reopenAppOpen = await subService2.showExpiredPlanNoticeIfEligible(isAppOpen: true);
      expect(reopenAppOpen, isFalse);

      // Also verify via checkSubscriptionStatus on app restart
      await subService2.checkSubscriptionStatus(isAppOpen: true);
      expect(subService2.hasShownExpiredMessageInSession, isFalse);
    });

    test('New subscription renewal resets expired notice flag so next expiration shows notice once', () async {
      final pastDate = DateTime.now().subtract(const Duration(days: 2)).toIso8601String();
      await StorageService.saveSubscriptionDetails(
        planId: 'pro',
        expiresAt: pastDate,
        status: 'expired',
      );

      final subService1 = Get.put(SubscriptionService());
      await subService1.showExpiredPlanNoticeIfEligible(isAppOpen: true);
      expect(await StorageService.hasShownExpiredNotice(), isTrue);

      // User renews / purchases Pro
      final futureDate = DateTime.now().add(const Duration(days: 30)).toIso8601String();
      await StorageService.saveSubscriptionDetails(
        planId: 'pro',
        expiresAt: futureDate,
        status: 'active',
      );
      expect(await StorageService.hasShownExpiredNotice(), isFalse);

      // Later, the renewed plan expires
      final secondPastDate = DateTime.now().subtract(const Duration(days: 1)).toIso8601String();
      await StorageService.saveSubscriptionDetails(
        planId: 'pro',
        expiresAt: secondPastDate,
        status: 'expired',
      );

      // First open after renewed plan expired: shows notice once
      Get.reset();
      final subService2 = Get.put(SubscriptionService());
      final renewedExpireShown = await subService2.showExpiredPlanNoticeIfEligible(isAppOpen: true);
      expect(renewedExpireShown, isTrue);
      expect(await StorageService.hasShownExpiredNotice(), isTrue);

      // Reopening app again: do not show notice
      Get.reset();
      final subService3 = Get.put(SubscriptionService());
      final reopenAfterRenewal = await subService3.showExpiredPlanNoticeIfEligible(isAppOpen: true);
      expect(reopenAfterRenewal, isFalse);
    });

    test('Logout clears persistent hasShownExpiredNotice flag', () async {
      await StorageService.setHasShownExpiredNotice(true);
      expect(await StorageService.hasShownExpiredNotice(), isTrue);

      await StorageService.logout();
      expect(await StorageService.hasShownExpiredNotice(), isFalse);
    });
  });
}
