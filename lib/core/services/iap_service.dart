import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'dart:io';
import 'package:plainscan/core/controllers/profile_controller.dart';
import 'package:plainscan/core/services/storage_service.dart';
import 'package:plainscan/core/services/payment_service.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';

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
    'plainscan_premium_monthly',
    'plainscan_premium_anualy',
  ];

  Future<void> init() async {
    _isAvailable = await _iap.isAvailable();
    if (_isAvailable) {
      // Get the product details from Apple
      debugPrint('Querying Apple for products: $_productIds');
      final ProductDetailsResponse response = await _iap.queryProductDetails(
        _productIds.toSet(),
      );

      if (response.error != null) {
        debugPrint('Apple IAP Error: ${response.error?.message}');
      }

      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('Apple could not find these IDs: ${response.notFoundIDs}');
      }

      _products = response.productDetails;
      debugPrint('Successfully loaded ${_products.length} products from Apple');

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

          // Use localVerificationData to get the traditional StoreKit 1 receipt (MI...)
          // because serverVerificationData gives the new StoreKit 2 JWT (eyJ...)
          final localData = purchaseDetails.verificationData.localVerificationData;
          var receiptData = localData;
          
          if (Platform.isIOS && (receiptData.startsWith('{') || receiptData.startsWith('eyJ'))) {
            try {
              final addition = _iap.getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
              final verificationData = await addition.refreshPurchaseVerificationData();
              if (verificationData != null && verificationData.localVerificationData.isNotEmpty) {
                receiptData = verificationData.localVerificationData;
              }
            } catch (e) {
              debugPrint('Failed to refresh App Store Receipt: $e');
            }
          }

          if (receiptData.isEmpty || receiptData.startsWith('{')) {
            Get.snackbar('Error', 'No receipt data found from Apple.', backgroundColor: Colors.red, colorText: Colors.white);
            _processingPurchases.remove(purchaseDetails.purchaseID ?? purchaseDetails.productID);
            continue;
          }

          final bool showUI = _isPurchaseInitiatedByUI || _isRestoreInitiatedByUI;

          if (showUI) {
            Get.snackbar(
              'Verifying...', 
              'Validating your purchase with our servers...',
              backgroundColor: Colors.blue,
              colorText: Colors.white,
              duration: const Duration(seconds: 2)
            );
          }

          final isYearly = purchaseDetails.productID == 'plainscan_premium_anualy';
          final planId = isYearly ? 'plainscan_premium_anualy' : 'plainscan_premium_monthly';
          final billingPeriod = isYearly ? 'yearly' : 'monthly';

          final result = await PaymentService.verifyApplePayment(
            receiptData: receiptData,
            planId: planId,
            billingPeriod: billingPeriod,
          );

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
              // Reset flags to prevent showing UI for subsequent transactions in this batch
              _isPurchaseInitiatedByUI = false;
              _isRestoreInitiatedByUI = false;
            }
          } else {
            if (showUI) {
              Get.snackbar(
                'Verification Failed',
                result.errorMessage ?? 'Could not verify purchase with our servers.',
                backgroundColor: Colors.red,
                colorText: Colors.white,
                duration: const Duration(seconds: 4),
              );
              // Only reset on failure if we don't want to show errors for every failed past transaction
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

  Future<void> buyProduct(String productId) async {
    _isPurchaseInitiatedByUI = true;
    if (!_isAvailable) {
      Get.snackbar('Error', 'In-App Purchases are not available right now.');
      return;
    }

    try {
      final ProductDetails productDetails = _products.firstWhere(
        (product) => product.id == productId,
        orElse: () => throw Exception('Product $productId not found'),
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

      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: productDetails,
      );
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      debugPrint('Error starting purchase: $e');
      Get.snackbar(
        'Error',
        'Could not start purchase: Product might not be approved by Apple yet.',
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
