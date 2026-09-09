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
        final plan = data['user']?['plan_id'] ?? data['plan'] ?? 'free';

        await StorageService.saveTokens(token: token, refreshToken: refreshToken);
        await StorageService.saveUser(email: email, name: userName);
        await StorageService.savePlan(plan.toString());

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
        final plan = data['user']?['plan_id'] ?? data['plan'] ?? 'free';

        await StorageService.saveTokens(token: token, refreshToken: refreshToken);
        await StorageService.saveUser(email: email, name: userName);
        await StorageService.savePlan(plan.toString());

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
        final plan = data['user']?['plan_id'] ?? data['plan'] ?? 'free';

        await StorageService.saveTokens(token: tokenVal, refreshToken: refreshTokenVal);
        await StorageService.saveUser(email: email, name: name);
        await StorageService.savePlan(plan.toString());

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

  static Future<Map<String, dynamic>?> getProfile() async {
    try {
      final token = await StorageService.getToken();
      if (token == null || token.isEmpty) return null;

      final response = await _client.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.profile}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          final plan = data['plan_id'] ?? data['plan'] ?? 'free';
          await StorageService.savePlan(plan.toString());
          final name = data['name']?.toString();
          if (name != null && name.isNotEmpty) {
            final email = data['email']?.toString() ?? await StorageService.getEmail() ?? '';
            await StorageService.saveUser(email: email, name: name);
          }
          return data;
        }
      }
      return null;
    } catch (_) {
      return null;
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

  static String parseError(String body) => _parseError(body);

  static String _parseError(String body) {
    try {
      final parsed = jsonDecode(body);
      if (parsed is Map) {
        // 1. FastAPI detail field (string, list of validation errors, or object)
        if (parsed['detail'] != null) {
          final detail = parsed['detail'];
          if (detail is String && detail.trim().isNotEmpty) {
            return detail.trim();
          } else if (detail is List && detail.isNotEmpty) {
            final messages = detail
                .map((item) {
                  if (item is Map) {
                    return (item['msg'] ?? item['message'] ?? item['detail'] ?? item.toString()).toString();
                  }
                  return item.toString();
                })
                .where((m) => m.isNotEmpty)
                .toList();
            if (messages.isNotEmpty) {
              return messages.join('\n');
            }
          } else if (detail is Map) {
            return (detail['msg'] ?? detail['message'] ?? detail['error'] ?? detail.toString()).toString();
          }
        }

        // 2. Standard message field
        if (parsed['message'] != null && parsed['message'].toString().trim().isNotEmpty) {
          return parsed['message'].toString().trim();
        }

        // 3. Error field (string or map with message)
        if (parsed['error'] != null) {
          final error = parsed['error'];
          if (error is String && error.trim().isNotEmpty) {
            return error.trim();
          } else if (error is Map && error['message'] != null) {
            return error['message'].toString().trim();
          }
        }

        // 4. Short msg field
        if (parsed['msg'] != null && parsed['msg'].toString().trim().isNotEmpty) {
          return parsed['msg'].toString().trim();
        }

        // 5. Errors field (list or map)
        if (parsed['errors'] != null) {
          final errors = parsed['errors'];
          if (errors is List && errors.isNotEmpty) {
            return errors
                .map((item) => item is Map ? (item['msg'] ?? item['message'] ?? item.toString()) : item.toString())
                .join('\n');
          } else if (errors is Map && errors.isNotEmpty) {
            final firstVal = errors.values.first;
            if (firstVal is List && firstVal.isNotEmpty) {
              return firstVal.first.toString();
            }
            return firstVal.toString();
          }
        }
      } else if (parsed is List && parsed.isNotEmpty) {
        return parsed
            .map((item) => item is Map ? (item['msg'] ?? item['message'] ?? item.toString()) : item.toString())
            .join('\n');
      } else if (parsed is String && parsed.trim().isNotEmpty) {
        return parsed.trim();
      }
      return 'An unknown error occurred.';
    } catch (_) {
      if (body.isNotEmpty && body.length < 200 && !body.contains('<html') && !body.contains('<!DOCTYPE')) {
        return body.trim();
      }
      return 'Request failed. Please try again.';
    }
  }
}
