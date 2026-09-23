import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
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

  final List<String> _productIds = [
    'com.plainscan_pro',
    'plainscan_premium_monthly',
    'plainscan_premium_anualy',
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
          Get.snackbar(
            'Purchase Failed',
            'Something went wrong: ${purchaseDetails.error?.message}',
          );
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          final txId = purchaseDetails.purchaseID ?? purchaseDetails.productID;
          if (_processingPurchases.contains(txId)) {
            if (purchaseDetails.pendingCompletePurchase) {
              try { await _iap.completePurchase(purchaseDetails); } catch (_) {}
            }
            continue;
          }
          _processingPurchases.add(txId);

          debugPrint(
            'Purchase Successful! Product: ${purchaseDetails.productID}',
          );

          final bool showUI = _isPurchaseInitiatedByUI || _isRestoreInitiatedByUI;

          if (showUI) {
            Get.snackbar(
              'Verifying...', 
              'Validating your purchase with store servers...',
              backgroundColor: Colors.blue,
              colorText: Colors.white,
              duration: const Duration(seconds: 2)
            );
          }

          final isYearly = purchaseDetails.productID == 'plainscan_premium_anualy';
          final planId = 'pro';
          final billingPeriod = isYearly ? 'yearly' : 'monthly';

          PaymentVerifyResult result;

          if (Platform.isAndroid) {
            final purchaseToken =
                purchaseDetails.verificationData.serverVerificationData;
            result = await PaymentService.verifyGooglePlayPayment(
              packageName: 'com.plainscan.app',
              productId: purchaseDetails.productID,
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
            await _unlockProLocally();

            if (showUI) {
              if (purchaseDetails.status == PurchaseStatus.restored) {
                Get.snackbar(
                  'Restored',
                  'Your Pro subscription has been restored!',
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                );
              } else {
                if (_isPurchaseInitiatedByUI) {
                  try { Get.back(); } catch (_) {}
                }
                Get.snackbar(
                  'Success',
                  'Welcome to PlainScan Pro!',
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                );
              }
              _isPurchaseInitiatedByUI = false;
              _isRestoreInitiatedByUI = false;
            }
          } else {
            // Unlock locally for valid store transaction
            await _unlockProLocally();

            if (showUI) {
              if (_isPurchaseInitiatedByUI) {
                try { Get.back(); } catch (_) {}
              }
              Get.snackbar(
                'Success',
                'Welcome to PlainScan Pro!',
                backgroundColor: Colors.green,
                colorText: Colors.white,
              );
              _isPurchaseInitiatedByUI = false;
              _isRestoreInitiatedByUI = false;
            }
          }
        }

        if (purchaseDetails.pendingCompletePurchase) {
          try {
            await _iap.completePurchase(purchaseDetails);
          } catch (e) {
            debugPrint('Error completing purchase: $e');
          }
        }
      }
    }
  }

  Future<void> _unlockProLocally() async {
    // Save to local storage so the app knows the user is Pro
    await StorageService.savePlan('pro');

    // Refresh the profile controller if it exists
    if (Get.isRegistered<ProfileController>()) {
      Get.find<ProfileController>().loadUserProfile();
    }
  }

  Future<void> buyProduct(String productId, {String? basePlanId}) async {
    _isPurchaseInitiatedByUI = true;
    if (!_isAvailable) {
      Get.snackbar('Error', 'In-App Purchases are not available right now.');
      return;
    }

    try {
      final ProductDetails productDetails = _products.firstWhere(
        (product) => product.id == productId,
        orElse: () => throw Exception('Product $productId not found in store'),
      );

      Get.dialog(
        const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
        barrierDismissible: false,
        barrierColor: Colors.black45,
      );

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
        'Error',
        'Could not start purchase: ${e.toString()}',
      );
    } finally {
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
    }
  }

  Future<void> restorePurchases() async {
    _isRestoreInitiatedByUI = true;
    if (!_isAvailable) {
      Get.snackbar('Error', 'In-App Purchases are not available right now.');
      return;
    }
    try {
      await _iap.restorePurchases();
    } catch (e) {
      debugPrint('Error restoring purchases: $e');
      Get.snackbar('Error', 'Could not restore purchases.');
    }
  }

  void dispose() {
    _subscription.cancel();
  }
}
