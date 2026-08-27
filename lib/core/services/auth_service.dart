import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:plainscan/core/constants/api_constants.dart';
import 'package:plainscan/core/services/storage_service.dart';

class AuthResult {
  final bool success;
  final String? errorMessage;
  final bool requires2Fa;
  final bool requiresVerification;
  final String? token;
  final String? refreshToken;
  final String? userId;
  final String? message;

  AuthResult({
    required this.success,
    this.errorMessage,
    this.requires2Fa = false,
    this.requiresVerification = false,
    this.token,
    this.refreshToken,
    this.userId,
    this.message,
  });
}

class AuthService {
  static final http.Client _client = http.Client();

  static Future<AuthResult> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.signUp}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final requiresVerification = data['requires_verification'] ?? false;
        final userId = data['user_id'] ?? '';
        final msg = data['message'] ?? '';

        return AuthResult(
          success: true,
          requiresVerification: requiresVerification,
          userId: userId,
          message: msg,
        );
      } else {
        final errorMsg = _parseError(response.body);
        return AuthResult(success: false, errorMessage: errorMsg);
      }
    } catch (e) {
      return AuthResult(success: false, errorMessage: 'Connection failed: ${e.toString()}');
    }
  }

  static Future<AuthResult> verifyEmail({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.verifyEmail}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'otp': otp,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        final data = responseData['data'] ?? {};
        final token = data['accessToken'] ?? '';
        final refreshToken = data['refreshToken'] ?? '';
        final userName = data['user']?['name'] ?? 'User';

        await StorageService.saveTokens(token: token, refreshToken: refreshToken);
        await StorageService.saveUser(email: email, name: userName);

        return AuthResult(success: true, token: token, refreshToken: refreshToken);
      } else {
        final errorMsg = _parseError(response.body);
        return AuthResult(success: false, errorMessage: errorMsg);
      }
    } catch (e) {
      return AuthResult(success: false, errorMessage: 'Connection failed: ${e.toString()}');
    }
  }

  static Future<AuthResult> resendVerification({
    required String email,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.resendVerification}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return AuthResult(success: true, message: data['message']);
      } else {
        final errorMsg = _parseError(response.body);
        return AuthResult(success: false, errorMessage: errorMsg);
      }
    } catch (e) {
      return AuthResult(success: false, errorMessage: 'Connection failed: ${e.toString()}');
    }
  }

  static Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.login}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        final data = responseData['data'] ?? {};
        final token = data['accessToken'] ?? '';
        final refreshToken = data['refreshToken'] ?? '';
        final userName = data['user']?['name'] ?? 'User';

        await StorageService.saveTokens(token: token, refreshToken: refreshToken);
        await StorageService.saveUser(email: email, name: userName);

        return AuthResult(success: true, token: token, refreshToken: refreshToken);
      } else if (response.statusCode == 202) {
        return AuthResult(success: true, requires2Fa: true);
      } else {
        final errorMsg = _parseError(response.body);
        return AuthResult(success: false, errorMessage: errorMsg);
      }
    } catch (e) {
      return AuthResult(success: false, errorMessage: 'Connection failed: ${e.toString()}');
    }
  }

  static Future<AuthResult> verify2Fa({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.verify2Fa}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'otp': otp,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        final data = responseData['data'] ?? {};
        final token = data['accessToken'] ?? '';
        final refreshToken = data['refreshToken'] ?? '';
        final userName = data['user']?['name'] ?? 'User';

        await StorageService.saveTokens(token: token, refreshToken: refreshToken);
        await StorageService.saveUser(email: email, name: userName);

        return AuthResult(success: true, token: token, refreshToken: refreshToken);
      } else {
        final errorMsg = _parseError(response.body);
        return AuthResult(success: false, errorMessage: errorMsg);
      }
    } catch (e) {
      return AuthResult(success: false, errorMessage: 'Connection failed: ${e.toString()}');
    }
  }

  static Future<AuthResult> googleLogin({
    required String token,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.googleLogin}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': token,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        final data = responseData['data'] ?? {};
        final tokenVal = data['accessToken'] ?? '';
        final refreshTokenVal = data['refreshToken'] ?? '';
        final email = data['user']?['email'] ?? '';
        final name = data['user']?['name'] ?? 'User';

        await StorageService.saveTokens(token: tokenVal, refreshToken: refreshTokenVal);
        await StorageService.saveUser(email: email, name: name);

        return AuthResult(success: true, token: tokenVal, refreshToken: refreshTokenVal);
      } else {
        final errorMsg = _parseError(response.body);
        return AuthResult(success: false, errorMessage: errorMsg);
      }
    } catch (e) {
      return AuthResult(success: false, errorMessage: 'Connection failed: ${e.toString()}');
    }
  }

  static Future<AuthResult> refreshToken() async {
    try {
      final localRefreshToken = await StorageService.getRefreshToken();
      if (localRefreshToken == null) {
        return AuthResult(success: false, errorMessage: 'No local refresh token found.');
      }

      final response = await _client.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.refreshToken}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'refreshToken': localRefreshToken,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        final data = responseData['data'] ?? {};
        final token = data['accessToken'] ?? '';
        final refreshToken = data['refreshToken'] ?? localRefreshToken;

        await StorageService.saveTokens(token: token, refreshToken: refreshToken);

        return AuthResult(success: true, token: token, refreshToken: refreshToken);
      } else {
        final errorMsg = _parseError(response.body);
        return AuthResult(success: false, errorMessage: errorMsg);
      }
    } catch (e) {
      return AuthResult(success: false, errorMessage: 'Connection failed: ${e.toString()}');
    }
  }

  static Future<void> logout() async {
    try {
      await _client.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.logout}'),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (_) {}
    await StorageService.logout();
  }

  static String _parseError(String body) {
    try {
      final parsed = jsonDecode(body);
      return parsed['error'] ?? parsed['message'] ?? 'An unknown error occurred.';
    } catch (_) {
      return 'Request failed. Please try again.';
    }
  }
}
