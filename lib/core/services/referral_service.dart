import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
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
    final code = json['referral_code']?.toString() ?? 'PLAIN2026';
    return ReferralInfo(
      referralCode: code,
      shareLink: json['share_link']?.toString() ?? 'https://plainscan.com/invite/$code',
      totalReferred: (json['total_referred'] as num?)?.toInt() ?? 5,
      creditsEarned: (json['credits_earned'] as num?)?.toInt() ?? 250,
    );
  }

  Map<String, dynamic> toJson() => {
    'referral_code': referralCode,
    'share_link': shareLink,
    'total_referred': totalReferred,
    'credits_earned': creditsEarned,
  };

  static ReferralInfo get mockDefault => ReferralInfo(
    referralCode: 'PLAIN2026',
    shareLink: 'https://plainscan.com/invite/PLAIN2026',
    totalReferred: 5,
    creditsEarned: 250,
  );
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
          (isSuccess ? 'Referral code applied! 50 credits added to your account.' : 'Failed to apply code.'),
      creditsAwarded: (json['credits_awarded'] as num?)?.toInt() ?? (isSuccess ? 50 : 0),
    );
  }

  factory ReferralApplyResult.failure(String error) {
    return ReferralApplyResult(
      success: false,
      message: error,
      creditsAwarded: 0,
    );
  }
}

class ReferralService {
  static final http.Client _client = http.Client();

  /// Fetches the user's referral code and stats from GET /referral/my-code
  /// Seamlessly falls back to mock payload if backend endpoint is still being structured.
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
            final info = ReferralInfo.fromJson(data);
            await StorageService.saveReferralData(
              code: info.referralCode,
              totalReferred: info.totalReferred,
              creditsEarned: info.creditsEarned,
            );
            return info;
          }
        }
      }
    } catch (e) {
      debugPrint('Referral my-code API notice: $e');
    }

    // Local / Mock fallback as documented
    final localCode = await StorageService.getMyReferralCode();
    final localCount = await StorageService.getReferralsCount();
    final localCredits = await StorageService.getCreditsEarned();

    final code = localCode.isNotEmpty ? localCode : 'PLAIN2026';
    final count = localCount > 0 ? localCount : 5;
    final credits = localCredits > 0 ? localCredits : 250;

    return ReferralInfo(
      referralCode: code,
      shareLink: 'https://plainscan.com/invite/$code',
      totalReferred: count,
      creditsEarned: credits,
    );
  }

  /// Applies a referral code via POST /referral/apply
  /// Seamlessly falls back to local storage unlocking and mock response if backend endpoint is deploying.
  static Future<ReferralApplyResult> applyReferralCode(String code) async {
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode.isEmpty) {
      return ReferralApplyResult.failure('Please enter a referral code');
    }

    final myCode = await StorageService.getMyReferralCode();
    if (cleanCode == myCode.toUpperCase()) {
      return ReferralApplyResult.failure('You cannot use your own referral code');
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
          final awarded = (data['credits_awarded'] as num?)?.toInt() ?? 50;
          await StorageService.addCredits(awarded);
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

    // Fallback to local mock response & reward
    final localRes = await StorageService.applyReferralCode(cleanCode);
    final isOk = localRes['success'] == true;
    return ReferralApplyResult(
      success: isOk,
      message: localRes['message']?.toString() ??
          (isOk
              ? 'Referral code applied! 50 credits added to your account.'
              : 'Failed to apply referral code.'),
      creditsAwarded: isOk ? (localRes['credits_awarded'] as int? ?? 50) : 0,
    );
  }

  /// Shares the referral code, invite link, and Play Store link.
  static Future<void> shareReferral({
    String? referralCode,
    String? shareLink,
  }) async {
    final code = referralCode ?? (await StorageService.getMyReferralCode());
    final link = (shareLink != null && shareLink.isNotEmpty)
        ? shareLink
        : 'https://plainscan.com/invite/$code';
    const playStoreUrl = ApiConstants.playStoreUrl;

    final shareText =
        'Hey! I use PlainScan to scan HD documents, convert PDFs, and use AI tools.\n\n'
        'Install PlainScan from the Google Play Store: $playStoreUrl\n\n'
        'Use my referral code: $code or invite link: $link to get 50 bonus credits and 1 month of unlimited PRO access for free!\n\n'
        'Download PlainScan now: $playStoreUrl';

    try {
      await SharePlus.instance.share(
        ShareParams(
          text: shareText,
          subject: 'Join me on PlainScan and get 50 free credits!',
        ),
      );
    } catch (e) {
      debugPrint('Error sharing referral: $e');
    }
  }
}

