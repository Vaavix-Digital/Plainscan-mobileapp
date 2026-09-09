import 'package:flutter_test/flutter_test.dart';
import 'package:plainscan/core/services/auth_service.dart';

void main() {
  group('AuthService.parseError', () {
    test('parses FastAPI detail string correctly', () {
      const response = '{"detail":"Gmail addresses must be at least 6 characters before the \'@\'."}';
      expect(
        AuthService.parseError(response),
        "Gmail addresses must be at least 6 characters before the '@'.",
      );
    });

    test('parses FastAPI detail list of validation errors', () {
      const response = '{"detail":[{"loc":["body","email"],"msg":"value is not a valid email address","type":"value_error"}]}';
      expect(
        AuthService.parseError(response),
        'value is not a valid email address',
      );
    });

    test('parses standard message field', () {
      const response = '{"message":"User already exists."}';
      expect(
        AuthService.parseError(response),
        'User already exists.',
      );
    });

    test('parses standard error field', () {
      const response = '{"error":"Unauthorized request"}';
      expect(
        AuthService.parseError(response),
        'Unauthorized request',
      );
    });

    test('falls back safely for invalid json string', () {
      const response = 'Server Error: Bad Gateway';
      expect(
        AuthService.parseError(response),
        'Server Error: Bad Gateway',
      );
    });
  });
}
