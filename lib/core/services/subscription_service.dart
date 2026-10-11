import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:plainscan/core/controllers/plan_controller.dart';
import 'package:plainscan/core/controllers/profile_controller.dart';
import 'package:plainscan/core/services/auth_service.dart';
import 'package:plainscan/core/services/storage_service.dart';

/// SubscriptionService monitors and enforces subscription plan status in real time.
/// 
/// When a user's Pro plan expires (by expiration timestamp, server state, or cancellation),
/// it automatically changes the subscription status to 'Free', restricts all Pro features,
/// and updates reactive GetX controllers (ProfileController & PlanController).
/// 
/// The "Plan Expired" notification is displayed:
/// - ONLY to users who previously selected a plan and whose subscription has expired.
/// - ONLY once, the first time the user opens the app after their plan has expired.
/// - NEVER repeatedly every time the user closes and reopens the app.
/// - NEVER to active subscribers or users who have never selected a plan.
/// - NEVER repeatedly at random intervals or during normal app usage.
class SubscriptionService extends GetxService with WidgetsBindingObserver {
  static SubscriptionService get to => Get.find<SubscriptionService>();

  Timer? _expirationTimer;
  Timer? _periodicCheckTimer;
  bool _isSyncing = false;
  bool _hasShownExpiredMessageInSession = false;

  bool get hasShownExpiredMessageInSession => _hasShownExpiredMessageInSession;

  /// Resets the in-session notification flag (primarily for testing or fresh app sessions)
  void resetSessionNotification() {
    _hasShownExpiredMessageInSession = false;
  }

  /// Resets the persistent notification flag in storage (primarily for testing or plan renewal)
  Future<void> resetExpiredNoticeFlag() async {
    _hasShownExpiredMessageInSession = false;
    await StorageService.setHasShownExpiredNotice(false);
  }

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    init();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _cancelTimers();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // User resumed the app during normal usage: check silently, do not show popups
      checkSubscriptionStatus(syncBackend: true, isAppOpen: false);
    }
  }

  void _cancelTimers() {
    _expirationTimer?.cancel();
    _expirationTimer = null;
    _periodicCheckTimer?.cancel();
    _periodicCheckTimer = null;
  }

  /// Initializes local checks and background polling timers
  Future<void> init() async {
    // 1. Enforce local plan expiration silently
    await checkSubscriptionStatus(syncBackend: false, isAppOpen: false);

    // 2. Schedule periodic verification (silent background checks, no notifications during app usage)
    _periodicCheckTimer?.cancel();
    int tickCount = 0;
    _periodicCheckTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
      tickCount++;
      // Every 15 seconds: local check silently without popups
      final expired = await StorageService.checkAndEnforcePlanExpiration();
      if (expired) {
        _applyExpirationEffects(notifyUser: false);
      } else {
        // Every 3 minutes (12 ticks * 15s = 180s): sync with backend if authenticated silently
        if (tickCount % 12 == 0) {
          await syncWithBackend();
        }
      }
    });

    // 3. Initial remote sync if token exists
    syncWithBackend();
  }

  /// Displays the 'Plan Expired' notification only to eligible users who previously
  /// selected a plan and whose subscription has expired.
  /// Shows the message only once, the first time the user opens the app after their plan has expired.
  /// Does not show the message again every time the user closes and reopens the app.
  Future<bool> showExpiredPlanNoticeIfEligible({bool isAppOpen = false}) async {
    // 1. Prevent duplicate notifications or repeated pop-ups during the same app session
    if (_hasShownExpiredMessageInSession) {
      return false;
    }

    // 2. Show only when opening the app, not repeatedly at random intervals or during normal app usage
    if (!isAppOpen) {
      return false;
    }

    // 3. Do not display to users who have never selected a plan
    final hadPlan = await StorageService.hasPreviouslySelectedPlan();
    if (!hadPlan) {
      return false;
    }

    // 4. Do not display to users with an active subscription
    final isPro = await StorageService.isProUser();
    if (isPro) {
      return false;
    }

    // 5. Ensure the message is triggered based on the user's actual subscription status
    final isExpired = await StorageService.isSubscriptionExpired();
    if (!isExpired) {
      return false;
    }

    // 6. Display the expiration message only once after plan has expired, not every time the user closes and reopens the app
    final alreadyShown = await StorageService.hasShownExpiredNotice();
    if (alreadyShown) {
      return false;
    }

    // Mark as shown in this session and persist to storage so it is not shown on future app opens
    _hasShownExpiredMessageInSession = true;
    await StorageService.setHasShownExpiredNotice(true);

    // Display the notification
    _showExpiredSnackbar();
    return true;
  }

  /// Checks whether Pro plan has expired locally. If still active, schedules one-shot timer.
  Future<void> checkSubscriptionStatus({bool syncBackend = false, bool isAppOpen = false}) async {
    final hasExpired = await StorageService.checkAndEnforcePlanExpiration();
    if (hasExpired) {
      _applyExpirationEffects(notifyUser: isAppOpen);
      return;
    }

    final isPro = await StorageService.isProUser();
    if (isPro) {
      await _scheduleExactExpirationTimer();
    } else {
      _expirationTimer?.cancel();
      _expirationTimer = null;
      if (isAppOpen) {
        await showExpiredPlanNoticeIfEligible(isAppOpen: true);
      }
    }

    if (syncBackend) {
      await syncWithBackend();
    }
  }

  /// Schedules a high-precision timer to fire the exact second the Pro plan expires
  Future<void> _scheduleExactExpirationTimer() async {
    final expiryDate = await StorageService.getProExpiryDate();
    if (expiryDate == null) return;

    final now = DateTime.now();
    final remaining = expiryDate.difference(now);

    _expirationTimer?.cancel();
    _expirationTimer = null;

    if (remaining.isNegative || remaining == Duration.zero) {
      // Expiration time already passed
      await StorageService.expireProPlan();
      _applyExpirationEffects(notifyUser: false);
    } else {
      debugPrint('[SubscriptionService] Pro plan scheduled to expire in ${remaining.inSeconds}s (at $expiryDate)');
      _expirationTimer = Timer(remaining, () async {
        debugPrint('[SubscriptionService] Pro plan expiration timer fired! Revoking Pro access now.');
        await StorageService.expireProPlan();
        _applyExpirationEffects(notifyUser: false);
      });
    }
  }

  /// Syncs with the backend API (/auth/me) while the user is logged in
  Future<void> syncWithBackend() async {
    if (_isSyncing) return;
    final token = await StorageService.getToken();
    if (token == null || token.isEmpty) return;

    _isSyncing = true;
    try {
      final profile = await AuthService.getProfile();
      if (profile != null) {
        final serverPlan = profile['plan_id']?.toString() ?? profile['plan']?.toString() ?? 'free';
        final isPro = serverPlan.toLowerCase() == 'pro' ||
            serverPlan.toLowerCase().contains('pro') ||
            serverPlan.toLowerCase() == 'teams';

        if (isPro) {
          // Active Pro reported by server: record plan selection and update timer
          await StorageService.setHasPreviouslySelectedPlan(true);
          await StorageService.setHasShownExpiredNotice(false);
          await _scheduleExactExpirationTimer();
        } else {
          // Server reports free: only downgrade if user was previously Pro or server status is expired
          final wasPro = await StorageService.isProUser();
          final hadPlan = await StorageService.hasPreviouslySelectedPlan();
          final serverStatus = profile['status']?.toString().toLowerCase();

          if (wasPro || (hadPlan && serverStatus == 'expired')) {
            await StorageService.expireProPlan();
            _applyExpirationEffects(notifyUser: false);
          }
        }
      }
    } catch (e) {
      debugPrint('[SubscriptionService] Backend sync error: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Immediately updates controllers and revokes access to Pro features across the app
  void _applyExpirationEffects({bool notifyUser = false}) {
    _expirationTimer?.cancel();
    _expirationTimer = null;

    // 1. Immediately update ProfileController state
    if (Get.isRegistered<ProfileController>()) {
      final profileCtrl = Get.find<ProfileController>();
      profileCtrl.userPlan.value = 'free';
      profileCtrl.isPro.value = false;
      profileCtrl.update();
    }

    // 2. Immediately update PlanController state
    if (Get.isRegistered<PlanController>()) {
      final planCtrl = Get.find<PlanController>();
      planCtrl.handlePlanExpired();
    }

    // 3. User notification snackbar - only if requested and eligible
    if (notifyUser) {
      showExpiredPlanNoticeIfEligible(isAppOpen: true);
    }
  }

  /// Renders the user-facing expired plan snackbar notification
  void _showExpiredSnackbar() {
    void show() {
      if (Get.overlayContext == null || Get.testMode) return;
      try {
        Get.rawSnackbar(
          titleText: const Text(
            'Pro Plan Expired',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          messageText: const Text(
            'Your Pro subscription has expired. Your account has returned to the Free plan and Pro features are restricted.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF1E224F),
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(12),
          borderRadius: 12,
          icon: const Icon(Icons.info_outline, color: Colors.amber, size: 28),
          duration: const Duration(seconds: 4),
        );
      } catch (_) {}
    }

    if (Get.overlayContext != null) {
      show();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        show();
      });
    }
  }

  /// Called by StorageService when subscription is updated (e.g. renewed, upgraded, or referral code redeemed)
  Future<void> onPlanUpdated() async {
    _hasShownExpiredMessageInSession = false;
    await checkSubscriptionStatus(syncBackend: false, isAppOpen: false);
  }

  /// Called on logout
  void onLogout() {
    _expirationTimer?.cancel();
    _expirationTimer = null;
    _hasShownExpiredMessageInSession = false;
  }
}
