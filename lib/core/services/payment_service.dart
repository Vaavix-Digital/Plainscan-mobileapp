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

  factory PaymentOrderResult.fromJson(Map<String, dynamic> json) {
    final rawProvider = json['provider']?.toString().toLowerCase() ?? 'razorpay';

    return PaymentOrderResult(
      success: true,
      provider: rawProvider,
      orderId: json['order_id']?.toString(),
      amount: json['amount'] as num?,
      currency: json['currency']?.toString(),
      key: json['key']?.toString(),
      planName: json['plan_name']?.toString(),
      sessionId: json['session_id']?.toString(),
      publicKey: json['public_key']?.toString(),
      amountUsd: (json['amount_usd'] as num?)?.toDouble(),
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

  factory PaymentVerifyResult.fromJson(Map<String, dynamic> json) {
    final status = json['status']?.toString();
    final isOk = status == 'success' || json['success'] == true;
    return PaymentVerifyResult(
      success: isOk,
      status: status,
      message: json['message']?.toString() ?? 'Payment verified successfully',
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
  }) async {
    try {
      final token = await StorageService.getToken();
      final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.createOrder}');

      final response = await _client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'plan_id': planId,
          'billing_period': billingPeriod,
        }),
      );

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
      final token = await StorageService.getToken();
      final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.verifyPayment}');

      final response = await _client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'razorpay_payment_id': paymentId,
          'razorpay_order_id': orderId,
          'razorpay_signature': signature,
          'plan_id': planId,
          'billing_period': billingPeriod,
        }),
      );

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
      final token = await StorageService.getToken();
      final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.verifyStripePayment}');

      final response = await _client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'session_id': sessionId,
          'plan_id': planId,
          'billing_period': billingPeriod,
        }),
      );

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
