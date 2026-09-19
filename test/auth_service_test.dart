import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:plainscan/core/controllers/alltool_controller.dart';
import 'package:plainscan/core/services/auth_service.dart';
import 'package:plainscan/core/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  group('Recent Tools User Isolation & Logout Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      Get.reset();
    });

    test('User A records tools, User B does not see User A tools', () async {
      // 1. User A logs in
      await StorageService.saveUser(
        email: 'usera@example.com',
        name: 'User A',
        userId: 'user_a_123',
      );

      final controller = Get.put(AllToolsController());
      await controller.loadRecentTools();

      // User A records tools
      await controller.recordToolUsage('pdf-to-ppt');
      await controller.recordToolUsage('ai-citation');
      await controller.recordToolUsage('flatten-pdf');

      expect(controller.recentTools.map((t) => t.slug).toList(), [
        'flatten-pdf',
        'ai-citation',
        'pdf-to-ppt',
      ]);

      final userATools = await StorageService.getRecentToolIds();
      expect(userATools, ['flatten-pdf', 'ai-citation', 'pdf-to-ppt']);

      // 2. User A logs out
      await StorageService.logout();
      await controller.loadRecentTools();

      // 3. User B (new user) logs in
      await StorageService.saveUser(
        email: 'userb@example.com',
        name: 'User B',
        userId: 'user_b_456',
      );
      await controller.loadRecentTools();

      // User B should have fresh (default or empty user) list, NOT User A's tools
      final userBTools = await StorageService.getRecentToolIds();
      expect(userBTools, isEmpty);
      expect(controller.recentTools.any((t) => t.slug == 'ai-citation'), isFalse);
      expect(controller.recentTools.any((t) => t.slug == 'flatten-pdf'), isFalse);

      // User B uses a different tool
      await controller.recordToolUsage('word-to-pdf');
      final userBUpdatedTools = await StorageService.getRecentToolIds();
      expect(userBUpdatedTools, ['word-to-pdf']);

      Get.delete<AllToolsController>();
    });

    test('clearRecentTools clears recent tools for current user', () async {
      await StorageService.saveUser(
        email: 'test@example.com',
        name: 'Test User',
        userId: 'test_123',
      );

      final controller = Get.put(AllToolsController());
      await controller.recordToolUsage('pdf-compress');
      expect(await StorageService.getRecentToolIds(), ['pdf-compress']);

      await controller.clearRecentTools();
      expect(await StorageService.getRecentToolIds(), isEmpty);

      Get.delete<AllToolsController>();
    });
  });
}
