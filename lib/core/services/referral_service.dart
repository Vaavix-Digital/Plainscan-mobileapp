import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:plainscan/core/constants/api_constants.dart';
import 'package:plainscan/core/services/auth_service.dart';
import 'package:plainscan/core/services/storage_service.dart';

class ReferralInfo {
  final String referralCode;
  final String shareLink;
  final int totalReferred;
  final int creditsEarned;

  ReferralInfo({
    required this.referralCode,
    required this.shareLink,
    required this.totalReferred,
    required this.creditsEarned,
  });

  factory ReferralInfo.fromJson(Map<String, dynamic> json) {
    final code = json['referral_code']?.toString() ?? 'PLAIN-APP';
    return ReferralInfo(
      referralCode: code,
      shareLink: json['share_link']?.toString() ?? 'https://plainscan.com/invite/$code',
      totalReferred: (json['total_referred'] as num?)?.toInt() ?? 0,
      creditsEarned: (json['credits_earned'] as num?)?.toInt() ?? 0,
    );
  }
}

class ReferralApplyResult {
  final bool success;
  final String message;
  final int creditsAwarded;

  ReferralApplyResult({
    required this.success,
    required this.message,
    this.creditsAwarded = 0,
  });

  factory ReferralApplyResult.fromJson(Map<String, dynamic> json) {
    final status = json['status']?.toString().toLowerCase();
    final isSuccess = status == 'success' || json['success'] == true;
    return ReferralApplyResult(
      success: isSuccess,
      message: json['message']?.toString() ??
          (isSuccess ? 'Referral code applied successfully!' : 'Failed to apply code.'),
      creditsAwarded: (json['credits_awarded'] as num?)?.toInt() ?? 0,
    );
  }

  factory ReferralApplyResult.failure(String error) {
    return ReferralApplyResult(
      success: false,
      message: error,
    );
  }
}

class ReferralService {
  static final http.Client _client = http.Client();

  /// Fetches the user's referral code and stats from GET /referral/my-code
  /// Seamlessly falls back to mock/local storage if backend endpoint is still deploying.
  static Future<ReferralInfo> getMyReferralCode() async {
    try {
      final token = await StorageService.getToken();
      if (token != null && token.isNotEmpty) {
        final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.myReferralCode}');
        final response = await _client.get(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data is Map<String, dynamic>) {
            return ReferralInfo.fromJson(data);
          }
        }
      }
    } catch (e) {
      debugPrint('Referral my-code API notice: $e');
    }

    // Local / Mock fallback as documented
    final localCode = await StorageService.getMyReferralCode();
    final localCount = await StorageService.getReferralsCount();
    return ReferralInfo(
      referralCode: localCode,
      shareLink: 'https://plainscan.com/invite/$localCode',
      totalReferred: localCount,
      creditsEarned: localCount * 50,
    );
  }

  /// Applies a referral code via POST /referral/apply
  /// Seamlessly falls back to local storage unlocking if backend endpoint is deploying.
  static Future<ReferralApplyResult> applyReferralCode(String code) async {
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode.isEmpty) {
      return ReferralApplyResult.failure('Please enter a referral code');
    }

    try {
      final token = await StorageService.getToken();
      final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.applyReferral}');

      final response = await _client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'referral_code': cleanCode,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          // Grant 1 month PRO upon successful referral application
          await StorageService.grantUnlimitedAccess(days: 30);
          return ReferralApplyResult.fromJson(data);
        }
      } else if (response.statusCode != 404 && response.statusCode != 502) {
        final error = AuthService.parseError(response.body);
        return ReferralApplyResult.failure(error);
      }
    } catch (e) {
      debugPrint('Referral apply API notice: $e');
    }

    // Fallback to local referral verification & reward
    final localRes = await StorageService.applyReferralCode(cleanCode);
    final isOk = localRes['success'] == true;
    return ReferralApplyResult(
      success: isOk,
      message: localRes['message']?.toString() ?? '',
      creditsAwarded: isOk ? 50 : 0,
    );
  }
}
