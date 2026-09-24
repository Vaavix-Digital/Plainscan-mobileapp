import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:plainscan/core/constants/api_constants.dart';
import 'package:plainscan/core/services/auth_service.dart';
import 'package:plainscan/core/services/storage_service.dart';

class PaymentOrderResult {
  final bool success;
  final String provider; // 'razorpay' | 'stripe'
  final String? orderId;
  final num? amount; // Amount in Paise if Razorpay
  final String? currency;
  final String? key; // Razorpay Key ID
  final String? planName;
  final String? sessionId; // Stripe session ID
  final String? publicKey; // Stripe publishable key
  final double? amountUsd;
  final String? errorMessage;

  PaymentOrderResult({
    required this.success,
    this.provider = 'razorpay',
    this.orderId,
    this.amount,
    this.currency,
    this.key,
    this.planName,
    this.sessionId,
    this.publicKey,
    this.amountUsd,
    this.errorMessage,
  });

  bool get isRazorpay => provider.toLowerCase() == 'razorpay';
  bool get isStripe => provider.toLowerCase() == 'stripe';

  String get formattedDisplayPrice {
    if (isRazorpay && amount != null) {
      final inr = (amount! / 100);
      return '₹${inr % 1 == 0 ? inr.toInt() : inr.toStringAsFixed(2)}';
    } else if (isStripe && amountUsd != null) {
      return '\$${amountUsd! % 1 == 0 ? amountUsd!.toInt() : amountUsd!.toStringAsFixed(2)}';
    }
    return '${currency ?? ''} ${amount ?? amountUsd ?? ''}'.trim();
  }

  factory PaymentOrderResult.fromJson(Map<String, dynamic> rawJson) {
    final json = (rawJson['data'] is Map<String, dynamic>)
        ? rawJson['data'] as Map<String, dynamic>
        : (rawJson['order'] is Map<String, dynamic>)
            ? rawJson['order'] as Map<String, dynamic>
            : rawJson;

    final rawProvider = (json['provider'] ?? rawJson['provider'] ?? 'razorpay')
        .toString()
        .toLowerCase();

    // Parse amount safely regardless of type
    num? parsedAmount;
    final rawAmount = json['amount'] ?? rawJson['amount'];
    if (rawAmount != null) {
      if (rawAmount is num) {
        parsedAmount = rawAmount;
      } else {
        parsedAmount = num.tryParse(rawAmount.toString());
      }
    }

    // Parse amountUsd safely
    double? parsedAmountUsd;
    final rawUsd = json['amount_usd'] ??
        json['amountUsd'] ??
        rawJson['amount_usd'] ??
        rawJson['amountUsd'];
    if (rawUsd != null) {
      if (rawUsd is num) {
        parsedAmountUsd = rawUsd.toDouble();
      } else {
        parsedAmountUsd = double.tryParse(rawUsd.toString());
      }
    }

    final orderId = (json['order_id'] ??
            json['orderId'] ??
            json['id'] ??
            json['razorpay_order_id'] ??
            rawJson['order_id'] ??
            rawJson['orderId'] ??
            rawJson['id'])
        ?.toString();

    final key = (json['key'] ??
            json['key_id'] ??
            json['keyId'] ??
            json['razorpay_key'] ??
            rawJson['key'] ??
            rawJson['key_id'] ??
            rawJson['keyId'])
        ?.toString();

    final sessionId = (json['session_id'] ??
            json['sessionId'] ??
            rawJson['session_id'] ??
            rawJson['sessionId'] ??
            json['id'])
        ?.toString();

    final publicKey = (json['public_key'] ??
            json['publicKey'] ??
            json['publishable_key'] ??
            rawJson['public_key'] ??
            rawJson['publicKey'])
        ?.toString();

    final currency = (json['currency'] ?? rawJson['currency'] ?? 'INR')?.toString();
    final planName = (json['plan_name'] ?? json['planName'] ?? rawJson['plan_name'])?.toString();

    return PaymentOrderResult(
      success: true,
      provider: rawProvider,
      orderId: orderId,
      amount: parsedAmount,
      currency: currency,
      key: key,
      planName: planName,
      sessionId: sessionId,
      publicKey: publicKey,
      amountUsd: parsedAmountUsd,
    );
  }

  factory PaymentOrderResult.failure(String error) {
    return PaymentOrderResult(
      success: false,
      errorMessage: error,
    );
  }
}

class PaymentVerifyResult {
  final bool success;
  final int? statusCode;
  final String? status;
  final String? message;
  final String? errorMessage;
  final String? planId;
  final String? expiresAt;
  final String? productId;
  final Map<String, dynamic>? user;
  final Map<String, dynamic>? rawData;

  PaymentVerifyResult({
    required this.success,
    this.statusCode,
    this.status,
    this.message,
    this.errorMessage,
    this.planId,
    this.expiresAt,
    this.productId,
    this.user,
    this.rawData,
  });

  factory PaymentVerifyResult.fromJson(Map<String, dynamic> rawJson, {int? statusCode}) {
    final json = (rawJson['data'] is Map<String, dynamic>)
        ? rawJson['data'] as Map<String, dynamic>
        : rawJson;

    final status = (json['status'] ?? rawJson['status'])?.toString();
    final isOk = status == 'success' ||
        status == 'active' ||
        json['success'] == true ||
        rawJson['success'] == true;

    final user = (json['user'] is Map<String, dynamic>)
        ? json['user'] as Map<String, dynamic>
        : (rawJson['user'] is Map<String, dynamic>
            ? rawJson['user'] as Map<String, dynamic>
            : null);

    final planId = (json['plan_id'] ?? rawJson['plan_id'] ?? user?['plan_id'])?.toString();
    final expiresAt = (json['expires_at'] ??
            json['subscription_expires_at'] ??
            rawJson['expires_at'] ??
            rawJson['subscription_expires_at'] ??
            user?['subscription_expires_at'] ??
            user?['subscription_end_date'])
        ?.toString();

    final productId = (json['product_id'] ??
            rawJson['product_id'] ??
            user?['google_play_product_id'])
        ?.toString();

    return PaymentVerifyResult(
      success: isOk,
      statusCode: statusCode ?? (isOk ? 200 : 400),
      status: status,
      message: (json['message'] ?? rawJson['message'])?.toString() ??
          'Subscription verified and Pro plan activated successfully!',
      planId: planId,
      expiresAt: expiresAt,
      productId: productId,
      user: user,
      rawData: rawJson,
    );
  }

  factory PaymentVerifyResult.failure(String error, {int? statusCode, Map<String, dynamic>? rawData}) {
    return PaymentVerifyResult(
      success: false,
      statusCode: statusCode,
      errorMessage: error,
      rawData: rawData,
    );
  }
}

class PaymentService {
  static final http.Client _client = http.Client();

  /// Initiates order creation with the backend.
  /// Backend auto-detects user IP: returns Razorpay (India) or Stripe (International).
  static Future<PaymentOrderResult> createOrder({
    required String planId,
    required String billingPeriod, // 'monthly' or 'yearly'
    num? amount,
    String? currency,
  }) async {
    try {
      String? token = await StorageService.getToken();
      final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.createOrder}');

      final payloadMap = <String, dynamic>{
        'plan_id': planId,
        'billing_period': billingPeriod,
        if (amount != null) ...{
          'amount': amount,
          'amount_paise': (amount * 100).round(),
        },
        if (currency != null && currency.isNotEmpty) 'currency': currency,
      };
      final payload = jsonEncode(payloadMap);

      debugPrint('POST $uri with payload: $payload (token: ${token != null && token.isNotEmpty ? 'present' : 'none'})');

      var response = await _client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
        body: payload,
      );

      debugPrint('createOrder response: ${response.statusCode} - ${response.body}');

      // If 401/403, attempt token refresh and retry once
      if ((response.statusCode == 401 || response.statusCode == 403) &&
          token != null &&
          token.isNotEmpty) {
        debugPrint('createOrder got 401/403, attempting token refresh...');
        final refresh = await AuthService.refreshToken();
        if (refresh.success && refresh.token != null) {
          token = refresh.token!;
          response = await _client.post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: payload,
          );
          debugPrint('createOrder retry response: ${response.statusCode} - ${response.body}');
        }
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          return PaymentOrderResult.fromJson(data);
        }
      }

      final errorMsg = AuthService.parseError(response.body);
      return PaymentOrderResult.failure(errorMsg);
    } catch (e) {
      debugPrint('Error creating payment order: $e');
      return PaymentOrderResult.failure('Network connection failed: $e');
    }
  }

  /// Verifies Razorpay payment signature
  static Future<PaymentVerifyResult> verifyRazorpayPayment({
    required String paymentId,
    required String orderId,
    required String signature,
    required String planId,
    required String billingPeriod,
  }) async {
    try {
      String? token = await StorageService.getToken();
      final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.verifyPayment}');

      final payload = jsonEncode({
        'razorpay_payment_id': paymentId,
        'razorpay_order_id': orderId,
        'razorpay_signature': signature,
        'plan_id': planId,
        'billing_period': billingPeriod,
      });

      debugPrint('POST $uri with payload: $payload');

      var response = await _client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
        body: payload,
      );

      debugPrint('verifyRazorpay response: ${response.statusCode} - ${response.body}');

      if ((response.statusCode == 401 || response.statusCode == 403) &&
          token != null &&
          token.isNotEmpty) {
        final refresh = await AuthService.refreshToken();
        if (refresh.success && refresh.token != null) {
          token = refresh.token!;
          response = await _client.post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: payload,
          );
          debugPrint('verifyRazorpay retry response: ${response.statusCode} - ${response.body}');
        }
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          return PaymentVerifyResult.fromJson(data);
        }
      }

      final errorMsg = AuthService.parseError(response.body);
      return PaymentVerifyResult.failure(errorMsg);
    } catch (e) {
      debugPrint('Error verifying Razorpay payment: $e');
      return PaymentVerifyResult.failure('Network connection failed: $e');
    }
  }

  /// Verifies Stripe payment session
  static Future<PaymentVerifyResult> verifyStripePayment({
    required String sessionId,
    required String planId,
    required String billingPeriod,
  }) async {
    try {
      String? token = await StorageService.getToken();
      final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.verifyStripePayment}');

      final payload = jsonEncode({
        'session_id': sessionId,
        'plan_id': planId,
        'billing_period': billingPeriod,
      });

      debugPrint('POST $uri with payload: $payload');

      var response = await _client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
        body: payload,
      );

      debugPrint('verifyStripe response: ${response.statusCode} - ${response.body}');

      if ((response.statusCode == 401 || response.statusCode == 403) &&
          token != null &&
          token.isNotEmpty) {
        final refresh = await AuthService.refreshToken();
        if (refresh.success && refresh.token != null) {
          token = refresh.token!;
          response = await _client.post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: payload,
          );
        }
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          return PaymentVerifyResult.fromJson(data);
        }
      }

      final errorMsg = AuthService.parseError(response.body);
      return PaymentVerifyResult.failure(errorMsg);
    } catch (e) {
      debugPrint('Error verifying Stripe payment: $e');
      return PaymentVerifyResult.failure('Network connection failed: $e');
    }
  }

  /// Verifies Apple In-App Purchase receipt
  static Future<PaymentVerifyResult> verifyApplePayment({
    required String receiptData,
    required String planId,
    required String billingPeriod,
  }) async {
    try {
      String? token = await StorageService.getToken();
      final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.verifyApplePayment}');

      final payload = jsonEncode({
        'receipt_data': receiptData,
        'receipt-data': receiptData,
        'plan_id': planId,
        'billing_period': billingPeriod,
      });

      debugPrint('POST $uri with payload (receipt length: ${receiptData.length})');

      var response = await _client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
        body: payload,
      );

      debugPrint('verifyApple response: ${response.statusCode} - ${response.body}');

      if ((response.statusCode == 401 || response.statusCode == 403) &&
          token != null &&
          token.isNotEmpty) {
        final refresh = await AuthService.refreshToken();
        if (refresh.success && refresh.token != null) {
          token = refresh.token!;
          response = await _client.post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: payload,
          );
        }
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          return PaymentVerifyResult.fromJson(data);
        }
      }

      final errorMsg = AuthService.parseError(response.body);
      return PaymentVerifyResult.failure(errorMsg);
    } catch (e) {
      debugPrint('Error verifying Apple payment: $e');
      return PaymentVerifyResult.failure('Network connection failed: $e');
    }
  }

  /// Verifies Google Play In-App Purchase token
  static Future<PaymentVerifyResult> verifyGooglePlayPayment({
    String packageName = 'com.plainscan.app',
    required String productId,
    required String purchaseToken,
    String planId = 'pro',
    required String billingPeriod,
  }) async {
    try {
      String? token = await StorageService.getToken();
      if (token == null || token.isEmpty) {
        debugPrint('verifyGooglePlayPayment: No JWT token found in storage.');
        return PaymentVerifyResult.failure(
          'Authentication required. Please log in to activate your Pro subscription.',
          statusCode: 401,
        );
      }

      final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.verifyGooglePlayPayment}');

      final payload = jsonEncode({
        'package_name': packageName,
        'product_id': productId,
        'purchase_token': purchaseToken,
        'plan_id': planId,
        'billing_period': billingPeriod,
      });

      debugPrint('POST $uri with payload: $payload');

      var response = await _client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: payload,
      );

      debugPrint('verifyGooglePlay response: ${response.statusCode} - ${response.body}');

      if ((response.statusCode == 401 || response.statusCode == 403)) {
        final refresh = await AuthService.refreshToken();
        if (refresh.success && refresh.token != null) {
          token = refresh.token!;
          response = await _client.post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: payload,
          );
          debugPrint('verifyGooglePlay retry response: ${response.statusCode} - ${response.body}');
        }
      }

      Map<String, dynamic>? responseJson;
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          responseJson = decoded;
        }
      } catch (_) {}

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (responseJson != null) {
          return PaymentVerifyResult.fromJson(responseJson, statusCode: response.statusCode);
        }
        return PaymentVerifyResult(
          success: true,
          statusCode: response.statusCode,
          message: 'Subscription verified and Pro plan activated successfully!',
          planId: planId,
        );
      }

      // Handle specific error codes based on Google Play backend reference:
      // 400: Missing product_id or purchase_token
      // 402: Payment not received / Google verification failed / subscription expired
      // 409: This purchase_token is already linked to a different account (token hijack attempt)
      // 500: Server misconfiguration (Google service account not set up yet)
      String errorMsg = responseJson?['message']?.toString() ??
          responseJson?['error']?.toString() ??
          AuthService.parseError(response.body);

      switch (response.statusCode) {
        case 400:
          if (errorMsg.isEmpty || errorMsg == 'An error occurred') {
            errorMsg = 'Missing product ID or purchase token. Please try again.';
          }
          break;
        case 401:
          errorMsg = 'Session expired. Please log in again to verify your purchase.';
          break;
        case 402:
          if (errorMsg.isEmpty || errorMsg == 'An error occurred') {
            errorMsg = 'Purchase could not be verified. Payment was not received or subscription expired.';
          }
          break;
        case 409:
          if (errorMsg.isEmpty || errorMsg == 'An error occurred') {
            errorMsg = 'This purchase is already linked to a different account.';
          }
          break;
        case 500:
          if (errorMsg.isEmpty || errorMsg == 'An error occurred') {
            errorMsg = 'Server issue during verification. Please try again later.';
          }
          break;
        default:
          if (errorMsg.isEmpty) {
            errorMsg = 'Failed to verify Google Play purchase (Status ${response.statusCode}).';
          }
      }

      return PaymentVerifyResult.failure(
        errorMsg,
        statusCode: response.statusCode,
        rawData: responseJson,
      );
    } catch (e) {
      debugPrint('Error verifying Google Play payment: $e');
      return PaymentVerifyResult.failure('Network connection failed: $e');
    }
  }
}
