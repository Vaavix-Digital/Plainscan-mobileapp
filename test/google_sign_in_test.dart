import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plainscan/core/constants/api_constants.dart';
import 'package:plainscan/core/services/auth_service.dart';
import 'package:plainscan/core/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Google Sign-In API Integration Tests', () {
    test('ApiConstants defines correct Google Login endpoint and baseUrl', () {
      expect(ApiConstants.googleLogin, '/auth/google');
      final fullUrl = '${ApiConstants.baseUrl}${ApiConstants.googleLogin}';
      expect(fullUrl, 'https://api.plainscan.com/api/auth/google');
    });

    test('googleLogin successfully parses backend response and saves user data', () async {
      const mockGoogleIdToken = 'eyJhbGciOiJSUzI1NiIsImtp.mockToken';

      final mockResponseData = {
        'data': {
          'accessToken': 'mock_access_jwt_123',
          'refreshToken': 'mock_refresh_jwt_456',
          'user': {
            'user_id': 'user_abc123',
            'email': 'user@gmail.com',
            'name': 'John Doe',
            'picture': 'https://lh3.googleusercontent.com/sample_pic',
            'role': 'user',
            'plan_id': 'free',
          },
          'plan': 'free',
        }
      };

      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(
          request.url.path.contains('/api/auth/session') ||
              request.url.path.contains('/api/auth/google'),
          isTrue,
        );
        expect(request.headers['Content-Type'], 'application/json');

        final body = jsonDecode(request.body);
        expect(body.containsKey('token') || body.containsKey('session_id'), isTrue);

        return http.Response(
          jsonEncode(mockResponseData),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final result = await AuthService.googleLogin(
        token: mockGoogleIdToken,
        client: mockClient,
      );

      expect(result.success, isTrue);
      expect(result.token, 'mock_access_jwt_123');
      expect(result.refreshToken, 'mock_refresh_jwt_456');
      expect(result.userId, 'user_abc123');
      expect(result.picture, 'https://lh3.googleusercontent.com/sample_pic');
      expect(result.role, 'user');

      // Verify data is correctly persisted in StorageService
      expect(await StorageService.getToken(), 'mock_access_jwt_123');
      expect(await StorageService.getRefreshToken(), 'mock_refresh_jwt_456');
      expect(await StorageService.getEmail(), 'user@gmail.com');
      expect(await StorageService.getName(), 'John Doe');
      expect(await StorageService.getUserId(), 'user_abc123');
      expect(await StorageService.getPicture(), 'https://lh3.googleusercontent.com/sample_pic');
      expect(await StorageService.getRole(), 'user');
      expect(await StorageService.getPlan(), 'free');
    });

    test('googleLogin handles backend error response properly', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'detail': 'Invalid or expired Google token.'}),
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      final result = await AuthService.googleLogin(
        token: 'invalid_token',
        client: mockClient,
      );

      expect(result.success, isFalse);
      expect(result.errorMessage, 'Invalid or expired Google token.');
      expect(await StorageService.getToken(), isNull);
    });

    test('StorageService.logout clears stored Google user details', () async {
      await StorageService.saveTokens(token: 't', refreshToken: 'rt');
      await StorageService.saveUser(
        email: 'test@gmail.com',
        name: 'Test',
        userId: 'uid_1',
        picture: 'https://example.com/pic.png',
        role: 'user',
      );

      expect(await StorageService.getUserId(), 'uid_1');
      expect(await StorageService.getPicture(), 'https://example.com/pic.png');
      expect(await StorageService.getRole(), 'user');

      await StorageService.logout();

      expect(await StorageService.getToken(), isNull);
      expect(await StorageService.getRefreshToken(), isNull);
      expect(await StorageService.getEmail(), isNull);
      expect(await StorageService.getName(), isNull);
      expect(await StorageService.getUserId(), isNull);
      expect(await StorageService.getPicture(), isNull);
      expect(await StorageService.getRole(), isNull);
    });
  });
}
