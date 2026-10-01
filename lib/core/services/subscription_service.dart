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
/// updates reactive GetX controllers (ProfileController & PlanController), and displays
/// an immediate notification to the user without requiring logout and login.
class SubscriptionService extends GetxService with WidgetsBindingObserver {
  static SubscriptionService get to => Get.find<SubscriptionService>();

  Timer? _expirationTimer;
  Timer? _periodicCheckTimer;
  bool _isSyncing = false;

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
      // User resumed the app: check local expiry and sync with backend immediately
      checkSubscriptionStatus(syncBackend: true);
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
    // 1. Enforce local plan expiration immediately
    await checkSubscriptionStatus(syncBackend: false);

    // 2. Schedule periodic verification (every 15 seconds locally, backend every 3 mins)
    _periodicCheckTimer?.cancel();
    int tickCount = 0;
    _periodicCheckTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
      tickCount++;
      // Every 15 seconds: local check
      final expired = await StorageService.checkAndEnforcePlanExpiration();
      if (expired) {
        _applyExpirationEffects(notifyUser: true);
      } else {
        // Every 3 minutes (12 ticks * 15s = 180s): sync with backend if authenticated
        if (tickCount % 12 == 0) {
          await syncWithBackend();
        }
      }
    });

    // 3. Initial remote sync if token exists
    syncWithBackend();
  }

  /// Checks whether Pro plan has expired locally. If still active, schedules one-shot timer.
  Future<void> checkSubscriptionStatus({bool syncBackend = false}) async {
    final hasExpired = await StorageService.checkAndEnforcePlanExpiration();
    if (hasExpired) {
      _applyExpirationEffects(notifyUser: true);
      return;
    }

    final isPro = await StorageService.isProUser();
    if (isPro) {
      await _scheduleExactExpirationTimer();
    } else {
      _expirationTimer?.cancel();
      _expirationTimer = null;
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
      _applyExpirationEffects(notifyUser: true);
    } else {
      debugPrint('[SubscriptionService] Pro plan scheduled to expire in ${remaining.inSeconds}s (at $expiryDate)');
      _expirationTimer = Timer(remaining, () async {
        debugPrint('[SubscriptionService] Pro plan expiration timer fired! Revoking Pro access now.');
        await StorageService.expireProPlan();
        _applyExpirationEffects(notifyUser: true);
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

        if (!isPro) {
          // Backend determined user's Pro plan has expired or reverted to Free
          await StorageService.expireProPlan();
          _applyExpirationEffects(notifyUser: true);
        } else {
          // If server reports active Pro, update local timer
          await _scheduleExactExpirationTimer();
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

    // 3. User notification snackbar
    if (notifyUser && Get.overlayContext != null && !Get.testMode) {
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
  }

  /// Called by StorageService when subscription is updated (e.g. renewed, upgraded, or referral code redeemed)
  Future<void> onPlanUpdated() async {
    await checkSubscriptionStatus(syncBackend: false);
  }

  /// Called on logout
  void onLogout() {
    _expirationTimer?.cancel();
    _expirationTimer = null;
  }
}
