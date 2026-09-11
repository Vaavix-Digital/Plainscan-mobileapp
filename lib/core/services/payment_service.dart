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
  final String? status;
  final String? message;
  final String? errorMessage;

  PaymentVerifyResult({
    required this.success,
    this.status,
    this.message,
    this.errorMessage,
  });

  factory PaymentVerifyResult.fromJson(Map<String, dynamic> rawJson) {
    final json = (rawJson['data'] is Map<String, dynamic>)
        ? rawJson['data'] as Map<String, dynamic>
        : rawJson;

    final status = (json['status'] ?? rawJson['status'])?.toString();
    final isOk = status == 'success' ||
        json['success'] == true ||
        rawJson['success'] == true;

    return PaymentVerifyResult(
      success: isOk,
      status: status,
      message: (json['message'] ?? rawJson['message'])?.toString() ??
          'Payment verified successfully',
    );
  }

  factory PaymentVerifyResult.failure(String error) {
    return PaymentVerifyResult(
      success: false,
      errorMessage: error,
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
}
