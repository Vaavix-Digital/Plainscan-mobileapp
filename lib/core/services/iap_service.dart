import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:plainscan/app/routes.dart';
import 'package:plainscan/core/constants/app_colors.dart';
import 'package:plainscan/core/controllers/plan_controller.dart';
import 'package:plainscan/core/controllers/profile_controller.dart';
import 'package:plainscan/core/services/payment_service.dart';
import 'package:plainscan/core/services/storage_service.dart';

class IAPService {
  static final IAPService _instance = IAPService._internal();
  factory IAPService() => _instance;
  IAPService._internal();

  final InAppPurchase _iap = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;

  bool _isAvailable = false;
  List<ProductDetails> _products = [];
  List<ProductDetails> get products => _products;
  final Set<String> _processingPurchases = {};
  bool _isPurchaseInitiatedByUI = false;
  bool _isRestoreInitiatedByUI = false;

  /// Google Play Product IDs (must match exact IDs in Google Play Console)
  static const String monthlySubscriptionId = 'plainscan_premium_monthly';
  static const String yearlySubscriptionId = 'plainscan_premium_anualy';
  static const String androidPackageName = 'com.plainscan.app';

  final List<String> _productIds = [
    monthlySubscriptionId,
    yearlySubscriptionId,
    'com.plainscan_pro',
    'plainscan_pro',
  ];

  Future<void> init() async {
    _isAvailable = await _iap.isAvailable();
    if (_isAvailable) {
      debugPrint('Querying store for products: $_productIds');
      final ProductDetailsResponse response = await _iap.queryProductDetails(
        _productIds.toSet(),
      );

      if (response.error != null) {
        debugPrint('IAP Query Error: ${response.error?.message}');
      }

      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('Store could not find these IDs: ${response.notFoundIDs}');
      }

      _products = response.productDetails;
      debugPrint('Successfully loaded ${_products.length} products from store');

      // Listen to the purchase stream
      final Stream<List<PurchaseDetails>> purchaseUpdated = _iap.purchaseStream;
      _subscription = purchaseUpdated.listen(
        (purchaseDetailsList) {
          _listenToPurchaseUpdated(purchaseDetailsList);
        },
        onDone: () {
          _subscription.cancel();
        },
        onError: (error) {
          debugPrint('Purchase Stream Error: $error');
        },
      );
    }
  }

  void _listenToPurchaseUpdated(
    List<PurchaseDetails> purchaseDetailsList,
  ) async {
    for (var purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        debugPrint('Purchase is pending for: ${purchaseDetails.productID}');
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          debugPrint('Purchase error: ${purchaseDetails.error}');
          _processingPurchases.remove(purchaseDetails.purchaseID ?? purchaseDetails.productID);
          if (_isPurchaseInitiatedByUI) {
            _isPurchaseInitiatedByUI = false;
            final msg = purchaseDetails.error?.message ?? '';
            final details = purchaseDetails.error?.details?.toString() ?? '';
            final errCombined = '$msg $details'.toLowerCase();

            final isDevError = errCombined.contains('developererror') ||
                errCombined.contains('signed correctly') ||
                errCombined.contains('not configured for billing') ||
                errCombined.contains('responsecode: 5') ||
                msg == 'BillingResponse.developerError';

            if (isDevError) {
              Get.defaultDialog(
                title: 'Google Play Setup Notice',
                titleStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                content: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Column(
                    children: const [
                      Text(
                        'This application build is not configured with Google Play App Signing key or is running in debug mode.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Would you like to complete your Pro subscription via standard Online Checkout (Card / UPI / NetBanking) instead?',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
                textConfirm: 'Online Checkout',
                textCancel: 'Close',
                confirmTextColor: Colors.white,
                buttonColor: AppColors.primary,
                onConfirm: () {
                  Get.back();
                  final plan = Get.isRegistered<PlanController>()
                      ? Get.find<PlanController>()
                          .plans
                          .firstWhereOrNull((p) => p.planId == 'pro')
                      : null;
                  if (plan != null) {
                    Get.toNamed(AppRoutes.payment, arguments: {
                      'plan': plan,
                      'billingPeriod': 'monthly',
                    });
                  }
                },
              );
            } else {
              Get.snackbar(
                'Purchase Incomplete',
                msg.isNotEmpty ? msg : 'Payment transaction was not completed.',
                backgroundColor: const Color(0xFFDC2626),
                colorText: Colors.white,
                snackPosition: SnackPosition.BOTTOM,
              );
            }
          }
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          final txId = purchaseDetails.purchaseID ?? purchaseDetails.productID;
          if (_processingPurchases.contains(txId)) {
            if (purchaseDetails.pendingCompletePurchase) {
              try {
                await _iap.completePurchase(purchaseDetails);
              } catch (_) {}
            }
            continue;
          }
          _processingPurchases.add(txId);

          debugPrint(
            'Purchase Successful in store! Product: ${purchaseDetails.productID}',
          );

          final bool showUI = _isPurchaseInitiatedByUI || _isRestoreInitiatedByUI;

          if (showUI) {
            Get.snackbar(
              'Verifying Subscription...',
              'Validating your purchase with Google Play...',
              backgroundColor: const Color(0xFF1E224F),
              colorText: Colors.white,
              duration: const Duration(seconds: 4),
              icon: const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              snackPosition: SnackPosition.BOTTOM,
            );
          }

          final rawProductId = purchaseDetails.productID;
          final cleanProductId = rawProductId.split(':').first;
          final isYearly = cleanProductId == yearlySubscriptionId ||
              cleanProductId.contains('anualy') ||
              cleanProductId.contains('yearly');

          final planId = 'pro';
          final billingPeriod = isYearly ? 'yearly' : 'monthly';
          final targetProductId = isYearly ? yearlySubscriptionId : monthlySubscriptionId;

          PaymentVerifyResult result;

          if (Platform.isAndroid) {
            final purchaseToken =
                purchaseDetails.verificationData.serverVerificationData;
            debugPrint('Verifying Google Play token for $targetProductId ($billingPeriod)...');
            result = await PaymentService.verifyGooglePlayPayment(
              packageName: androidPackageName,
              productId: targetProductId,
              purchaseToken: purchaseToken,
              planId: planId,
              billingPeriod: billingPeriod,
            );
          } else {
            final localData =
                purchaseDetails.verificationData.localVerificationData;
            var receiptData = localData;

            if (Platform.isIOS &&
                (receiptData.startsWith('{') || receiptData.startsWith('eyJ'))) {
              try {
                final addition = _iap.getPlatformAddition<
                  InAppPurchaseStoreKitPlatformAddition
                >();
                final verificationData =
                    await addition.refreshPurchaseVerificationData();
                if (verificationData != null &&
                    verificationData.localVerificationData.isNotEmpty) {
                  receiptData = verificationData.localVerificationData;
                }
              } catch (e) {
                debugPrint('Failed to refresh App Store Receipt: $e');
              }
            }

            result = await PaymentService.verifyApplePayment(
              receiptData: receiptData,
              planId: planId,
              billingPeriod: billingPeriod,
            );
          }

          if (result.success) {
            // ✅ Pro activated successfully!
            await _onVerificationSuccess(result);

            if (showUI) {
              if (purchaseDetails.status == PurchaseStatus.restored) {
                Get.snackbar(
                  'Subscription Restored',
                  result.message ?? 'Your Pro subscription has been restored successfully!',
                  backgroundColor: const Color(0xFF10B981),
                  colorText: Colors.white,
                  snackPosition: SnackPosition.BOTTOM,
                  icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                );
              } else {
                if (_isPurchaseInitiatedByUI) {
                  try {
                    Get.back();
                  } catch (_) {}
                }
                Get.snackbar(
                  'Pro Activated 🎉',
                  result.message ?? 'Welcome to PlainScan Pro! Pro features unlocked.',
                  backgroundColor: const Color(0xFF10B981),
                  colorText: Colors.white,
                  snackPosition: SnackPosition.BOTTOM,
                  duration: const Duration(seconds: 4),
                  icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                );
              }
              _isPurchaseInitiatedByUI = false;
              _isRestoreInitiatedByUI = false;
            }

            // Complete purchase in Google Play Billing client now that backend acknowledged it
            if (purchaseDetails.pendingCompletePurchase) {
              try {
                await _iap.completePurchase(purchaseDetails);
              } catch (e) {
                debugPrint('Error completing purchase: $e');
              }
            }
          } else {
            // ❌ Server verification failed
            debugPrint('Subscription verification failed: status=${result.statusCode}, msg=${result.errorMessage}');
            _processingPurchases.remove(txId);

            if (showUI) {
              _showVerificationErrorDialog(result);
              _isPurchaseInitiatedByUI = false;
              _isRestoreInitiatedByUI = false;
            }

            // Acknowledge fatal errors on client so they don't loop endlessly
            if (result.statusCode == 400 || result.statusCode == 402 || result.statusCode == 409) {
              if (purchaseDetails.pendingCompletePurchase) {
                try {
                  await _iap.completePurchase(purchaseDetails);
                } catch (_) {}
              }
            }
          }
        }

        if (purchaseDetails.pendingCompletePurchase &&
            purchaseDetails.status != PurchaseStatus.purchased &&
            purchaseDetails.status != PurchaseStatus.restored) {
          try {
            await _iap.completePurchase(purchaseDetails);
          } catch (e) {
            debugPrint('Error completing purchase: $e');
          }
        }
      }
    }
  }

  Future<void> _onVerificationSuccess(PaymentVerifyResult result) async {
    // 1. Save subscription details in persistent storage
    await StorageService.saveSubscriptionDetails(
      planId: result.planId ?? 'pro',
      expiresAt: result.expiresAt,
      status: result.status ?? 'active',
      platform: 'google_play',
      aiCreditsLimit: (result.user?['ai_credits_limit'] is num)
          ? (result.user!['ai_credits_limit'] as num).toInt()
          : null,
    );

    // 2. Refresh ProfileController
    if (Get.isRegistered<ProfileController>()) {
      final profileCtrl = Get.find<ProfileController>();
      profileCtrl.userPlan.value = result.planId ?? 'pro';
      profileCtrl.isPro.value = true;
      await profileCtrl.loadUserProfile();
    }

    // 3. Refresh PlanController
    if (Get.isRegistered<PlanController>()) {
      Get.find<PlanController>().loadPlansData();
    }
  }

  void _showVerificationErrorDialog(PaymentVerifyResult result) {
    String title = 'Verification Notice';
    String message = result.errorMessage ?? 'Could not verify your purchase with the server.';

    switch (result.statusCode) {
      case 400:
        title = 'Invalid Request';
        message = 'Missing purchase details. Please try again.';
        break;
      case 401:
        title = 'Login Required';
        message = 'Your session has expired. Please log in again to link your Pro subscription.';
        break;
      case 402:
        title = 'Verification Failed';
        message = 'Google Play verification failed. Payment was not received or subscription is expired.';
        break;
      case 409:
        title = 'Subscription Already Linked';
        message = 'This Google Play purchase is already linked to another PlainScan account.';
        break;
      case 500:
        title = 'Server Error';
        message = 'A server issue occurred while verifying your subscription. Please try again later.';
        break;
    }

    Get.defaultDialog(
      title: title,
      titleStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      middleText: message,
      textConfirm: 'OK',
      confirmTextColor: Colors.white,
      buttonColor: AppColors.primary,
      onConfirm: () => Get.back(),
    );
  }

  ProductDetails? _findProduct(String productId) {
    if (_products.isEmpty) return null;

    // 1. Direct match by ID or ID prefix
    var match = _products.firstWhereOrNull(
      (product) =>
          product.id == productId ||
          product.id.startsWith('$productId:') ||
          (product is GooglePlayProductDetails &&
              product.productDetails.productId == productId),
    );
    if (match != null) return match;

    // 2. Match by Base Plan ID or Offer ID in GooglePlayProductDetails
    for (var p in _products) {
      if (p is GooglePlayProductDetails) {
        final offers = p.productDetails.subscriptionOfferDetails;
        if (offers != null &&
            p.subscriptionIndex != null &&
            p.subscriptionIndex! < offers.length) {
          final offer = offers[p.subscriptionIndex!];
          if (offer.basePlanId == productId ||
              offer.offerId == productId ||
              (productId.contains('monthly') &&
                  (offer.basePlanId.contains('monthly') ||
                      offer.basePlanId == 'p1m')) ||
              (productId.contains('anualy') &&
                  (offer.basePlanId.contains('anualy') ||
                      offer.basePlanId.contains('yearly') ||
                      offer.basePlanId == 'p1y'))) {
            return p;
          }
        }
      }
    }

    // 3. Match by billing period keyword (monthly vs yearly)
    final isYearly =
        productId.contains('anualy') || productId.contains('yearly');
    match = _products.firstWhereOrNull((p) {
      final id = p.id.toLowerCase();
      if (isYearly) {
        return id.contains('anualy') ||
            id.contains('yearly') ||
            id.contains('annual');
      } else {
        return id.contains('monthly') || id.contains('month');
      }
    });
    if (match != null) return match;

    // 4. Fallback to any pro product in store
    match = _products.firstWhereOrNull(
      (p) =>
          p.id == 'com.plainscan_pro' ||
          p.id.contains('pro') ||
          p.id.contains('premium'),
    );

    return match;
  }

  Future<void> buyProduct(String productId, {String? basePlanId}) async {
    _isPurchaseInitiatedByUI = true;

    // Check if user is authenticated before purchasing
    final hasSession = await StorageService.hasSession();
    if (!hasSession) {
      Get.defaultDialog(
        title: 'Account Required',
        middleText:
            'Please log in or sign up before subscribing so your Pro plan is linked to your account.',
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

    try {
      _isAvailable = await _iap.isAvailable();
    } catch (_) {}

    if (!_isAvailable) {
      Get.defaultDialog(
        title: 'Google Play Unavailable',
        middleText:
            'Google Play Billing is not supported or not available on this device.\n\nWould you like to complete payment via Card / UPI checkout instead?',
        textConfirm: 'Online Checkout',
        textCancel: 'Cancel',
        confirmTextColor: Colors.white,
        buttonColor: AppColors.primary,
        onConfirm: () {
          Get.back();
          final plan = Get.isRegistered<PlanController>()
              ? Get.find<PlanController>()
                  .plans
                  .firstWhereOrNull((p) => p.planId == 'pro')
              : null;
          if (plan != null) {
            Get.toNamed(AppRoutes.payment, arguments: {
              'plan': plan,
              'billingPeriod': basePlanId ?? 'monthly',
            });
          }
        },
      );
      return;
    }

    Get.dialog(
      const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
      barrierDismissible: false,
      barrierColor: Colors.black45,
    );

    try {
      debugPrint('IAP: buyProduct called for productId: $productId');
      debugPrint('IAP: Current cached products: ${_products.map((p) => p.id).toList()}');

      // Query or refresh products if not cached or matching product is not found
      if (_products.isEmpty || _findProduct(productId) == null) {
        debugPrint('IAP: Querying store for product IDs: $_productIds');
        final resp = await _iap.queryProductDetails(_productIds.toSet());
        debugPrint(
            'IAP: Store query response: found=${resp.productDetails.map((p) => p.id).toList()}, notFound=${resp.notFoundIDs}, error=${resp.error?.message}');
        if (resp.productDetails.isNotEmpty) {
          _products = resp.productDetails;
        }
      }

      final ProductDetails? productDetails = _findProduct(productId);

      if (productDetails == null) {
        if (Get.isDialogOpen ?? false) {
          Get.back();
        }

        final foundIds = _products.map((p) => p.id).toList();
        debugPrint(
            'IAP: Product $productId could not be found. Available in store: $foundIds');

        Get.defaultDialog(
          title: 'Product Not Found in Play Store',
          titleStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          middleText:
              'Google Play Store could not find subscription "$productId".\n\n'
              '• If recently created in Google Play Console, it can take 2-24 hours to propagate.\n'
              '• Ensure the Base Plan in Play Console is set to "Active" (not Draft).\n'
              '• Ensure your Google account is added as a License Tester.\n\n'
              'Would you like to complete payment via standard Online Checkout instead?',
          textConfirm: 'Online Checkout',
          textCancel: 'Close',
          confirmTextColor: Colors.white,
          buttonColor: AppColors.primary,
          onConfirm: () {
            Get.back();
            final plan = Get.isRegistered<PlanController>()
                ? Get.find<PlanController>()
                    .plans
                    .firstWhereOrNull((p) => p.planId == 'pro')
                : null;
            if (plan != null) {
              Get.toNamed(AppRoutes.payment, arguments: {
                'plan': plan,
                'billingPeriod': basePlanId ?? 'monthly',
              });
            }
          },
        );
        return;
      }

      debugPrint(
          'IAP: Launching billing flow for: ${productDetails.id} (${productDetails.title}, ${productDetails.price})');

      PurchaseParam purchaseParam;

      if (Platform.isAndroid && productDetails is GooglePlayProductDetails) {
        purchaseParam = GooglePlayPurchaseParam(
          productDetails: productDetails,
          changeSubscriptionParam: null,
        );
      } else {
        purchaseParam = PurchaseParam(
          productDetails: productDetails,
        );
      }

      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      debugPrint('Error starting purchase: $e');
      Get.snackbar(
        'Purchase Error',
        'Could not initiate Google Play purchase: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
    }
  }

  Future<void> restorePurchases() async {
    _isRestoreInitiatedByUI = true;

    final hasSession = await StorageService.hasSession();
    if (!hasSession) {
      Get.defaultDialog(
        title: 'Account Required',
        middleText: 'Please log in to restore your subscription.',
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

    if (!_isAvailable) {
      Get.snackbar('Error', 'In-App Purchases are not available right now.');
      return;
    }

    try {
      Get.snackbar(
        'Restoring...',
        'Checking with Google Play for your active subscriptions...',
        backgroundColor: const Color(0xFF1E224F),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
      await _iap.restorePurchases();
    } catch (e) {
      debugPrint('Error restoring purchases: $e');
      Get.snackbar('Error', 'Could not restore purchases: $e', snackPosition: SnackPosition.BOTTOM);
    }
  }

  void dispose() {
    _subscription.cancel();
  }
}
