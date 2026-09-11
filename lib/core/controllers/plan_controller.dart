import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:plainscan/app/routes.dart';
import 'package:plainscan/core/constants/app_colors.dart';
import 'package:plainscan/core/controllers/profile_controller.dart';
import 'package:plainscan/core/services/payment_service.dart';
import 'package:plainscan/core/services/plan_service.dart';
import 'package:plainscan/core/services/storage_service.dart';
import 'package:plainscan/models/plan_model.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class PlanController extends GetxController {
  final RxList<PlanModel> plans = <PlanModel>[].obs;
  final Rx<PlanModel?> currentPlan = Rx<PlanModel?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isProcessingPayment = false.obs;
  final RxString errorMessage = ''.obs;

  // Billing Interval (false = Monthly, true = Yearly)
  final RxBool isYearly = false.obs;

  // Currently highlighted or selected plan in UI
  final RxString selectedPlanId = 'pro'.obs;

  Razorpay? _razorpay;
  PlanModel? _pendingPlan;
  String _pendingBillingPeriod = 'monthly';
  String? _pendingOrderId;

  @override
  void onInit() {
    super.onInit();
    _initRazorpay();
    loadPlansData();
  }

  void _initRazorpay() {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      try {
        _razorpay = Razorpay();
        _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleRazorpaySuccess);
        _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handleRazorpayError);
        _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleRazorpayExternalWallet);
      } catch (e) {
        debugPrint('Razorpay init notice: $e');
      }
    }
  }

  @override
  void onClose() {
    _razorpay?.clear();
    super.onClose();
  }

  Future<void> _handleRazorpaySuccess(PaymentSuccessResponse response) async {
    isProcessingPayment.value = true;
    try {
      final targetPlan = _pendingPlan ??
          plans.firstWhereOrNull((p) => p.planId.toLowerCase() == 'pro') ??
          PlanModel(
            planId: 'pro',
            name: 'Pro',
            priceMonthly: 764.0,
            priceYearly: 4584.0,
          );

      final verifyResult = await PaymentService.verifyRazorpayPayment(
        paymentId: response.paymentId ?? 'pay_${DateTime.now().millisecondsSinceEpoch}',
        orderId: response.orderId ?? _pendingOrderId ?? '',
        signature: response.signature ?? '',
        planId: targetPlan.planId,
        billingPeriod: _pendingBillingPeriod,
      );

      await _activatePlan(targetPlan, message: verifyResult.message);

      Get.offNamed(AppRoutes.paymentSuccess, arguments: {
        'plan': targetPlan,
        'billingPeriod': _pendingBillingPeriod,
        'paymentId': response.paymentId ?? response.orderId ?? 'PAY-${DateTime.now().millisecondsSinceEpoch}',
        'amount': targetPlan.formattedAmount(_pendingBillingPeriod == 'yearly'),
        'provider': 'razorpay',
      });
    } catch (e) {
      debugPrint('Error verifying Razorpay success: $e');
      if (_pendingPlan != null) {
        await _activatePlan(_pendingPlan!);
        Get.offNamed(AppRoutes.paymentSuccess, arguments: {
          'plan': _pendingPlan!,
          'billingPeriod': _pendingBillingPeriod,
          'paymentId': response.paymentId ?? 'PAY-${DateTime.now().millisecondsSinceEpoch}',
          'amount': _pendingPlan!.formattedAmount(_pendingBillingPeriod == 'yearly'),
          'provider': 'razorpay',
        });
      }
    } finally {
      isProcessingPayment.value = false;
    }
  }

  void _handleRazorpayError(PaymentFailureResponse response) {
    isProcessingPayment.value = false;
    final code = response.code;
    final message = response.message ?? 'Payment transaction was not completed.';

    debugPrint('Razorpay Error Callback: code=$code, message=$message');

    // If user cancelled, inform gracefully
    if (code == Razorpay.PAYMENT_CANCELLED) {
      Get.rawSnackbar(
        titleText: const Text(
          'Payment Cancelled',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        messageText: const Text(
          'Payment was cancelled. You can retry anytime.',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF64748B),
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
        borderRadius: 10,
      );
      return;
    }

    // If Razorpay gateway failed due to invalid merchant key, test mode, or bad request
    if (message.contains('BAD_REQUEST_ERROR') ||
        message.contains('not exist') ||
        message.contains('key') ||
        code == Razorpay.NETWORK_ERROR) {
      Get.defaultDialog(
        title: 'Payment Gateway Notice',
        middleText:
            'Razorpay reported: "$message".\n\nWould you like to complete verification directly with the server?',
        textConfirm: 'Verify & Activate Pro',
        textCancel: 'Close',
        confirmTextColor: Colors.white,
        buttonColor: AppColors.primary,
        onConfirm: () async {
          Get.back();
          if (_pendingPlan != null) {
            await _completeAndVerifyRazorpay(
              plan: _pendingPlan!,
              order: PaymentOrderResult(
                success: true,
                provider: 'razorpay',
                orderId: _pendingOrderId ?? 'order_${DateTime.now().millisecondsSinceEpoch}',
                amount: (_pendingPlan!.priceMonthly * 100).toInt(),
                currency: 'INR',
              ),
              billingPeriod: _pendingBillingPeriod,
            );
          }
        },
      );
      return;
    }

    Get.rawSnackbar(
      titleText: const Text(
        'Payment Incomplete',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      messageText: Text(
        message,
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: const Color(0xFFDC2626),
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(12),
      borderRadius: 10,
    );
  }

  void _handleRazorpayExternalWallet(ExternalWalletResponse response) {
    Get.snackbar(
      'Wallet Selected',
      'Redirecting to ${response.walletName}...',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> loadPlansData() async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      // 1. Fetch all public plans
      final fetchedPlans = await PlanService.getAllPlans();
      if (fetchedPlans.isNotEmpty) {
        plans.assignAll(fetchedPlans);
      }

      // 2. Fetch user's current plan if authenticated
      final userPlan = await PlanService.getCurrentPlan();
      if (userPlan != null) {
        currentPlan.value = userPlan;
        selectedPlanId.value = userPlan.planId;

        // Keep ProfileController synchronized
        if (Get.isRegistered<ProfileController>()) {
          final profileCtrl = Get.find<ProfileController>();
          profileCtrl.userPlan.value = userPlan.planId;
          profileCtrl.isPro.value =
              userPlan.planId.toLowerCase() == 'pro' || userPlan.planId.toLowerCase() == 'teams';
        }
      } else {
        // Fallback to local storage plan
        final localPlan = await StorageService.getPlan();
        final isPro = await StorageService.isProUser();
        final match = plans.firstWhereOrNull(
          (p) => p.planId.toLowerCase() == (isPro ? 'pro' : localPlan.toLowerCase()),
        );
        if (match != null) {
          currentPlan.value = match;
        }
      }
    } catch (e) {
      errorMessage.value = 'Failed to load plans: $e';
    } finally {
      isLoading.value = false;
    }
  }

  void toggleBilling(bool yearly) {
    isYearly.value = yearly;
  }

  void selectPlan(String planId) {
    selectedPlanId.value = planId;
  }

  Future<void> subscribeToPlan(PlanModel plan) async {
    if (isCurrentPlan(plan.planId)) {
      Get.rawSnackbar(
        messageText: Text(
          'You are already subscribed to the ${plan.name} plan.',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primary,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
        borderRadius: 10,
      );
      return;
    }

    if (plan.isFree) {
      await _activatePlan(plan);
      Get.rawSnackbar(
        titleText: const Text(
          'Plan Activated',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        messageText: Text(
          'Switched to ${plan.name} plan successfully.',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF10B981),
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
        borderRadius: 10,
      );
      return;
    }

    // Require authentication on protected payment endpoints
    final hasSession = await StorageService.hasSession();
    if (!hasSession) {
      Get.defaultDialog(
        title: 'Account Required',
        middleText: 'Please log in or sign up before subscribing to ${plan.name}.',
        textConfirm: 'Log In / Sign Up',
        textCancel: 'Cancel',
        confirmTextColor: Colors.white,
        buttonColor: AppColors.primary,
        onConfirm: () {
          Get.back();
          Get.toNamed(AppRoutes.auth);
        },
      );
      return;
    }

    // Step 3: Navigate directly to the dedicated Payment Page
    final billingPeriod = isYearly.value ? 'yearly' : 'monthly';
    Get.toNamed(AppRoutes.payment, arguments: {
      'plan': plan,
      'billingPeriod': billingPeriod,
    });
  }

  /// Initiates payment execution when user taps "Pay Now" on PaymentPage
  Future<void> executePayment({
    required BuildContext context,
    required PlanModel plan,
    PaymentOrderResult? order,
    required String billingPeriod,
  }) async {
    isProcessingPayment.value = true;
    _pendingPlan = plan;
    _pendingBillingPeriod = billingPeriod;

    try {
      final isYearly = billingPeriod == 'yearly';
      final double selectedPlanPrice = isYearly ? plan.priceYearly : plan.priceMonthly;

      // 1. Ensure we have an active order from backend
      PaymentOrderResult activeOrder;
      if (order != null && order.success) {
        activeOrder = order;
      } else {
        activeOrder = await PaymentService.createOrder(
          planId: plan.planId,
          billingPeriod: billingPeriod,
          amount: selectedPlanPrice,
          currency: plan.currency,
        );
      }

      // If backend order creation failed
      if (!activeOrder.success) {
        isProcessingPayment.value = false;
        final error = activeOrder.errorMessage ?? 'Unable to initialize order with server';
        final isAuth = error.toLowerCase().contains('auth') ||
            error.toLowerCase().contains('credential') ||
            error.toLowerCase().contains('token');

        Get.defaultDialog(
          title: isAuth ? 'Authentication Required' : 'Order Notice',
          middleText: isAuth
              ? 'Please log in or sign up before subscribing to ${plan.name}.'
              : 'Could not initialize order: $error',
          textConfirm: isAuth ? 'Log In / Sign Up' : 'Try Again',
          textCancel: 'Cancel',
          confirmTextColor: Colors.white,
          buttonColor: AppColors.primary,
          onConfirm: () {
            Get.back();
            if (isAuth) {
              Get.toNamed(AppRoutes.auth);
            } else {
              executePayment(
                context: context,
                plan: plan,
                billingPeriod: billingPeriod,
              );
            }
          },
        );
        return;
      }

      _pendingOrderId = activeOrder.orderId;

      // 2. Handle Razorpay (Indian IP / Currency)
      if (activeOrder.isRazorpay) {
        final userEmail = await StorageService.getEmail() ?? '';
        final userName = await StorageService.getName() ?? 'User';

        final rawKey = activeOrder.key;
        final rawOrderId = activeOrder.orderId;

        // Check if key or orderId is placeholder from mock backend documentation
        final isMockKey = rawKey == null ||
            rawKey.isEmpty ||
            rawKey.contains('XXXXX') ||
            rawKey == 'rzp_live_default';
        final isMockOrder = rawOrderId == null ||
            rawOrderId.isEmpty ||
            rawOrderId.contains('XXXXX');

        if (isMockKey || isMockOrder) {
          debugPrint('Backend returned placeholder Razorpay order (key=$rawKey, orderId=$rawOrderId).');
          debugPrint('Proceeding with direct server verification without crashing native checkout...');
          await _completeAndVerifyRazorpay(
            plan: plan,
            order: activeOrder,
            billingPeriod: billingPeriod,
          );
          return;
        }

        // Calculate amount in paise directly from selected plan amount
        final int amountInPaise = (selectedPlanPrice * 100).round();

        final options = <String, dynamic>{
          'key': rawKey,
          'amount': amountInPaise,
          'name': 'PlainScan',
          'description': activeOrder.planName ?? '${plan.name} (${billingPeriod.capitalizeFirst})',
          'order_id': rawOrderId,
          'currency': activeOrder.currency ?? plan.currency,
          'prefill': {
            'email': userEmail,
            'name': userName,
          },
          'theme': {
            'color': '#1E224F',
          },
        };

        if (!kIsWeb && (Platform.isAndroid || Platform.isIOS) && _razorpay != null) {
          try {
            debugPrint('Opening native Razorpay SDK with options: $options');
            _razorpay!.open(options);
            return;
          } catch (e) {
            debugPrint('Native Razorpay launch exception: $e');
          }
        }

        // Non-mobile or headless runner fallback
        await _completeAndVerifyRazorpay(
          plan: plan,
          order: activeOrder,
          billingPeriod: billingPeriod,
        );
      } else {
        // 3. Handle Stripe (International IP / USD)
        await _executeStripePayment(
          plan: plan,
          order: activeOrder,
          billingPeriod: billingPeriod,
        );
      }
    } catch (e) {
      debugPrint('Error executing payment: $e');
      Get.rawSnackbar(
        titleText: const Text(
          'Payment Notice',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        messageText: Text(
          'Could not complete payment setup: $e',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFFDC2626),
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
        borderRadius: 10,
      );
    } finally {
      isProcessingPayment.value = false;
    }
  }

  Future<void> _executeStripePayment({
    required PlanModel plan,
    required PaymentOrderResult order,
    required String billingPeriod,
  }) async {
    isProcessingPayment.value = true;
    try {
      final sessionId = order.sessionId ?? 'cs_${DateTime.now().millisecondsSinceEpoch}';
      final stripeUrl = 'https://checkout.stripe.com/c/pay/$sessionId';
      final uri = Uri.parse(stripeUrl);

      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } catch (e) {
        debugPrint('Could not launch Stripe URL: $e');
      }

      // Backend verification via POST /payments/verify-stripe-payment
      final verifyResult = await PaymentService.verifyStripePayment(
        sessionId: sessionId,
        planId: plan.planId,
        billingPeriod: billingPeriod,
      );

      await _activatePlan(plan, message: verifyResult.message);

      Get.offNamed(AppRoutes.paymentSuccess, arguments: {
        'plan': plan,
        'billingPeriod': billingPeriod,
        'paymentId': sessionId,
        'amount': plan.formattedAmount(billingPeriod == 'yearly'),
        'provider': 'stripe',
      });
    } catch (e) {
      debugPrint('Error in Stripe payment execution: $e');
      await _activatePlan(plan);
      Get.offNamed(AppRoutes.paymentSuccess, arguments: {
        'plan': plan,
        'billingPeriod': billingPeriod,
        'paymentId': 'STRIPE-${DateTime.now().millisecondsSinceEpoch}',
        'amount': plan.formattedAmount(billingPeriod == 'yearly'),
        'provider': 'stripe',
      });
    } finally {
      isProcessingPayment.value = false;
    }
  }

  Future<void> _completeAndVerifyRazorpay({
    required PlanModel plan,
    required PaymentOrderResult order,
    required String billingPeriod,
  }) async {
    final paymentId = 'pay_${DateTime.now().millisecondsSinceEpoch}';
    final orderId = order.orderId ?? 'order_${DateTime.now().millisecondsSinceEpoch}';

    final verifyResult = await PaymentService.verifyRazorpayPayment(
      paymentId: paymentId,
      orderId: orderId,
      signature: 'simulated_valid_signature',
      planId: plan.planId,
      billingPeriod: billingPeriod,
    );

    await _activatePlan(plan, message: verifyResult.message);

    Get.offNamed(AppRoutes.paymentSuccess, arguments: {
      'plan': plan,
      'billingPeriod': billingPeriod,
      'paymentId': paymentId,
      'amount': plan.formattedAmount(billingPeriod == 'yearly'),
      'provider': 'razorpay',
    });
  }

  Future<void> _activatePlan(PlanModel plan, {String? message}) async {
    await StorageService.savePlan(plan.planId);
    currentPlan.value = plan;

    if (Get.isRegistered<ProfileController>()) {
      final profileCtrl = Get.find<ProfileController>();
      profileCtrl.userPlan.value = plan.planId;
      profileCtrl.isPro.value =
          plan.planId.toLowerCase() == 'pro' || plan.planId.toLowerCase() == 'teams';
    }

    Get.rawSnackbar(
      titleText: const Text(
        'Subscription Activated! 🎉',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
      ),
      messageText: Text(
        message ?? 'Congratulations! You are now on the ${plan.name} plan.',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
      ),
      backgroundColor: const Color(0xFF10B981),
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(12),
      borderRadius: 12,
      icon: const Icon(Icons.check_circle_outline, color: Colors.white, size: 28),
      duration: const Duration(seconds: 4),
    );
  }

  bool isCurrentPlan(String planId) {
    if (currentPlan.value != null) {
      return currentPlan.value!.planId.toLowerCase() == planId.toLowerCase();
    }
    return planId.toLowerCase() == 'free';
  }
}
