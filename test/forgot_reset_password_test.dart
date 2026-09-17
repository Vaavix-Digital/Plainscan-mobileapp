import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plainscan/core/constants/api_constants.dart';
import 'package:plainscan/core/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthService - Forgot Password and Reset Password Tests', () {
    test('ApiConstants defines correct endpoints', () {
      expect(ApiConstants.forgotPassword, '/auth/forgot-password');
      expect(ApiConstants.resetPassword, '/auth/reset-password');
      expect('${ApiConstants.baseUrl}${ApiConstants.forgotPassword}',
          'https://api.plainscan.com/api/auth/forgot-password');
      expect('${ApiConstants.baseUrl}${ApiConstants.resetPassword}',
          'https://api.plainscan.com/api/auth/reset-password');
    });

    test('forgotPassword succeeds when valid email is provided', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.toString(),
            'https://api.plainscan.com/api/auth/forgot-password');
        expect(request.headers['Content-Type'], 'application/json');

        final body = jsonDecode(request.body);
        expect(body['email'], 'you@example.com');

        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Password reset link sent to your email.',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final result = await AuthService.forgotPassword(
        email: 'you@example.com',
        client: mockClient,
      );

      expect(result.success, true);
      expect(result.message, 'Password reset link sent to your email.');
      expect(result.errorMessage, isNull);
    });

    test('forgotPassword handles Google user error message properly', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'detail':
                'This account is registered using Google Sign-In. Please log in directly with Google.',
          }),
          400,
          headers: {'content-type': 'application/json'},
        );
      });

      final result = await AuthService.forgotPassword(
        email: 'googleuser@gmail.com',
        client: mockClient,
      );

      expect(result.success, false);
      expect(result.errorMessage,
          'This account is registered using Google Sign-In. Please log in directly with Google.');
    });

    test('resetPassword succeeds when valid token and new password are provided',
        () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.toString(),
            'https://api.plainscan.com/api/auth/reset-password');
        expect(request.headers['Content-Type'], 'application/json');

        final body = jsonDecode(request.body);
        expect(body['token'], 'VALID_32_BYTE_URL_SAFE_TOKEN');
        expect(body['new_password'], 'new_secure_password123');

        return http.Response(
          jsonEncode({
            'success': true,
            'message':
                'Password reset successfully. You can now log in with your new password.',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final result = await AuthService.resetPassword(
        token: 'VALID_32_BYTE_URL_SAFE_TOKEN',
        newPassword: 'new_secure_password123',
        client: mockClient,
      );

      expect(result.success, true);
      expect(result.message,
          'Password reset successfully. You can now log in with your new password.');
      expect(result.errorMessage, isNull);
    });

    test('resetPassword handles expired token error properly', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'detail':
                'Password reset token has expired. Please request a new password reset link.',
          }),
          400,
          headers: {'content-type': 'application/json'},
        );
      });

      final result = await AuthService.resetPassword(
        token: 'EXPIRED_TOKEN',
        newPassword: 'new_secure_password123',
        client: mockClient,
      );

      expect(result.success, false);
      expect(result.errorMessage,
          'Password reset token has expired. Please request a new password reset link.');
    });
  });
}
