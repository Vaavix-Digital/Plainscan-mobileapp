import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _keyToken = 'auth_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyEmail = 'user_email';
  static const String _keyName = 'user_name';
  static const String _keyPlan = 'user_plan';
  static const String _keyProExpiry = 'pro_expiry_timestamp';
  static const String _keyReferralCode = 'user_referral_code';
  static const String _keyInviteLink = 'user_invite_link';
  static const String _keyReferralMessage = 'user_referral_message';
  static const String _keyReferralsCount = 'referrals_count';
  static const String _keyCreditsEarned = 'referral_credits_earned';
  static const String _keyUserCredits = 'user_credits';
  static const String _keyRedeemedCodes = 'redeemed_referral_codes';
  static const String _keyPendingReferralCode = 'pending_referral_code';
  static const String _keyUserId = 'user_id';
  static const String _keyPicture = 'user_picture';
  static const String _keyRole = 'user_role';

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
    String? userId,
    String? picture,
    String? role,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyEmail, email);
    await prefs.setString(_keyName, name);
    if (userId != null && userId.isNotEmpty) {
      await prefs.setString(_keyUserId, userId);
    }
    if (picture != null && picture.isNotEmpty) {
      await prefs.setString(_keyPicture, picture);
    }
    if (role != null && role.isNotEmpty) {
      await prefs.setString(_keyRole, role);
    }
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
      code = 'PLAIN2026';
      await prefs.setString(_keyReferralCode, code);
    }
    return code;
  }

  static Future<void> saveMyReferralCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyReferralCode, code);
  }

  static Future<int> getUserCredits() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyUserCredits) ?? 250;
  }

  static Future<void> addCredits(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getUserCredits();
    await prefs.setInt(_keyUserCredits, current + amount);
  }

  static Future<int> getCreditsEarned() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyCreditsEarned) ?? 250;
  }

  static Future<void> saveReferralData({
    required String code,
    required int totalReferred,
    required int creditsEarned,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyReferralCode, code);
    await prefs.setInt(_keyReferralsCount, totalReferred);
    await prefs.setInt(_keyCreditsEarned, creditsEarned);
  }

  static Future<void> setPendingReferralCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPendingReferralCode, code.trim().toUpperCase());
  }

  static Future<String?> getPendingReferralCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPendingReferralCode);
  }

  static Future<void> clearPendingReferralCode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPendingReferralCode);
  }

  static Future<String?> captureReferralFromUri([Uri? uri]) async {
    try {
      final targetUri = uri ?? Uri.base;
      final ref = targetUri.queryParameters['ref'] ??
          targetUri.queryParameters['referral'] ??
          targetUri.queryParameters['referral_code'] ??
          targetUri.queryParameters['code'];
      if (ref != null && ref.trim().isNotEmpty) {
        final cleanRef = ref.trim().toUpperCase();
        await setPendingReferralCode(cleanRef);
        return cleanRef;
      }
    } catch (_) {}
    return null;
  }

  static Future<void> saveInviteLink(String link) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyInviteLink, link);
  }

  static Future<String?> getInviteLink() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyInviteLink);
  }

  static Future<void> saveReferralMessage(String msg) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyReferralMessage, msg);
  }

  static Future<String?> getReferralMessage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyReferralMessage);
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
    return prefs.getInt(_keyReferralsCount) ?? 5;
  }

  static Future<void> incrementReferralsCount() async {
    final prefs = await SharedPreferences.getInstance();
    final count = await getReferralsCount();
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

  /// Applies a referral code to award 50 credits and unlock 1 month unlimited PRO access.
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

    // Award 50 credits
    await addCredits(50);
    // Award 30 days of unlimited PRO access
    await grantUnlimitedAccess(days: 30);
    await incrementReferralsCount();

    redeemedList.add(cleanCode);
    await prefs.setStringList(_keyRedeemedCodes, redeemedList);

    return {
      'status': 'success',
      'success': true,
      'message': 'Referral code applied! 50 credits added to your account.',
      'credits_awarded': 50,
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

  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserId);
  }

  static Future<String?> getPicture() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPicture);
  }

  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRole);
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
    final userKey = _getUserRecentToolsKey(prefs);
    await prefs.remove(userKey);
    await prefs.remove(_keyRecentTools);
    await prefs.remove(_keyToken);
    await prefs.remove(_keyRefreshToken);
    await prefs.remove(_keyEmail);
    await prefs.remove(_keyName);
    await prefs.remove(_keyPlan);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyPicture);
    await prefs.remove(_keyRole);
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

  static const String _keyPermissionsRequested = 'has_requested_initial_permissions';

  static Future<bool> hasRequestedInitialPermissions() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyPermissionsRequested) ?? false;
  }

  static Future<void> setRequestedInitialPermissions(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPermissionsRequested, value);
  }

  static const String _keyRecentTools = 'recent_tools';

  static String _getUserRecentToolsKey(SharedPreferences prefs) {
    final userId = prefs.getString(_keyUserId);
    if (userId != null && userId.isNotEmpty) {
      return 'recent_tools_$userId';
    }
    final email = prefs.getString(_keyEmail);
    if (email != null && email.isNotEmpty) {
      return 'recent_tools_${email.toLowerCase().trim()}';
    }
    return _keyRecentTools;
  }

  static Future<List<String>> getRecentToolIds() async {
    final prefs = await SharedPreferences.getInstance();
    final userKey = _getUserRecentToolsKey(prefs);
    return prefs.getStringList(userKey) ?? [];
  }

  static Future<void> addRecentToolId(String toolId) async {
    final prefs = await SharedPreferences.getInstance();
    final userKey = _getUserRecentToolsKey(prefs);
    final list = prefs.getStringList(userKey) ?? [];
    list.remove(toolId);
    list.insert(0, toolId);
    if (list.length > 10) {
      list.removeRange(10, list.length);
    }
    await prefs.setStringList(userKey, list);
  }

  static Future<void> clearRecentTools() async {
    final prefs = await SharedPreferences.getInstance();
    final userKey = _getUserRecentToolsKey(prefs);
    await prefs.remove(userKey);
    await prefs.remove(_keyRecentTools);
  }
}
