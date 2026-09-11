import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _keyToken = 'auth_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyEmail = 'user_email';
  static const String _keyName = 'user_name';
  static const String _keyPlan = 'user_plan';
  static const String _keyProExpiry = 'pro_expiry_timestamp';
  static const String _keyReferralCode = 'user_referral_code';
  static const String _keyReferralsCount = 'referrals_count';
  static const String _keyRedeemedCodes = 'redeemed_referral_codes';

  static Future<void> saveTokens({
    required String token,
    required String refreshToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
    await prefs.setString(_keyRefreshToken, refreshToken);
  }

  static Future<void> saveUser({
    required String email,
    required String name,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyEmail, email);
    await prefs.setString(_keyName, name);
  }

  static Future<void> savePlan(String plan) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPlan, plan);
  }

  static Future<String> getPlan() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPlan) ?? 'free';
  }

  static Future<String> getMyReferralCode() async {
    final prefs = await SharedPreferences.getInstance();
    var code = prefs.getString(_keyReferralCode);
    if (code == null || code.isEmpty) {
      const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
      final rand = Random();
      final buffer = StringBuffer('PLAIN-');
      for (int i = 0; i < 5; i++) {
        buffer.write(chars[rand.nextInt(chars.length)]);
      }
      code = buffer.toString();
      await prefs.setString(_keyReferralCode, code);
    }
    return code;
  }

  static Future<void> grantUnlimitedAccess({int days = 30}) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final currentExpiryStr = prefs.getString(_keyProExpiry);
    DateTime expiryDate;
    if (currentExpiryStr != null) {
      final current = DateTime.tryParse(currentExpiryStr);
      if (current != null && current.isAfter(now)) {
        expiryDate = current.add(Duration(days: days));
      } else {
        expiryDate = now.add(Duration(days: days));
      }
    } else {
      expiryDate = now.add(Duration(days: days));
    }
    await prefs.setString(_keyProExpiry, expiryDate.toIso8601String());
    await savePlan('pro');
  }

  static Future<DateTime?> getProExpiryDate() async {
    final prefs = await SharedPreferences.getInstance();
    final expiryStr = prefs.getString(_keyProExpiry);
    if (expiryStr != null) {
      return DateTime.tryParse(expiryStr);
    }
    return null;
  }

  static Future<int> getReferralsCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyReferralsCount) ?? 0;
  }

  static Future<void> incrementReferralsCount() async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(_keyReferralsCount) ?? 0;
    await prefs.setInt(_keyReferralsCount, count + 1);
  }

  static Future<bool> isProUser() async {
    final prefs = await SharedPreferences.getInstance();
    final expiryStr = prefs.getString(_keyProExpiry);
    if (expiryStr != null) {
      final expiry = DateTime.tryParse(expiryStr);
      if (expiry != null && DateTime.now().isBefore(expiry)) {
        return true;
      }
    }
    final plan = await getPlan();
    return plan.toLowerCase() == 'pro' || plan.toLowerCase().contains('pro');
  }

  /// Applies a referral code to unlock 1 month unlimited PRO access.
  static Future<Map<String, dynamic>> applyReferralCode(String inputCode) async {
    final cleanCode = inputCode.trim().toUpperCase();
    if (cleanCode.isEmpty) {
      return {'success': false, 'message': 'Please enter a referral code'};
    }

    final myCode = await getMyReferralCode();
    if (cleanCode == myCode.toUpperCase()) {
      return {'success': false, 'message': 'You cannot use your own referral code'};
    }

    final prefs = await SharedPreferences.getInstance();
    final redeemedList = prefs.getStringList(_keyRedeemedCodes) ?? [];
    if (redeemedList.contains(cleanCode)) {
      return {'success': false, 'message': 'You have already redeemed this referral code'};
    }

    // Award 30 days of unlimited PRO access
    await grantUnlimitedAccess(days: 30);
    await incrementReferralsCount();

    redeemedList.add(cleanCode);
    await prefs.setStringList(_keyRedeemedCodes, redeemedList);

    return {
      'success': true,
      'message': 'Congratulations! 1 Month of Unlimited PRO access unlocked.',
    };
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRefreshToken);
  }

  static Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyEmail);
  }

  static Future<String?> getName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyName);
  }

  static Future<bool> hasSession() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyRefreshToken);
  }

  static const String _keyIsOnboarded = 'is_onboarded';

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyRefreshToken);
    await prefs.remove(_keyEmail);
    await prefs.remove(_keyName);
    await prefs.remove(_keyPlan);
    await prefs.remove('is_guest');
  }

  static const String _keyLanguage = 'app_language';

  static Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLanguage) ?? 'en';
  }

  static Future<void> setLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLanguage, languageCode);
  }

  static Future<bool> isOnboarded() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsOnboarded) ?? false;
  }

  static Future<void> setOnboarded(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsOnboarded, value);
  }

  static const String _keyRecentTools = 'recent_tools';

  static Future<List<String>> getRecentToolIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keyRecentTools) ?? [];
  }

  static Future<void> addRecentToolId(String toolId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_keyRecentTools) ?? [];
    list.remove(toolId);
    list.insert(0, toolId);
    if (list.length > 10) {
      list.removeRange(10, list.length);
    }
    await prefs.setStringList(_keyRecentTools, list);
  }
}
