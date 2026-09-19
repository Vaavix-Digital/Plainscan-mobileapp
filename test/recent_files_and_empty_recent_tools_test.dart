import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:plainscan/core/controllers/alltool_controller.dart';
import 'package:plainscan/core/controllers/dashboard_controller.dart';
import 'package:plainscan/core/controllers/profile_controller.dart';
import 'package:plainscan/core/controllers/scan_controller.dart';
import 'package:plainscan/core/services/storage_service.dart';
import 'package:plainscan/features/home/widgets/dashboard_recent_tools.dart';
import 'package:plainscan/models/file_model.dart';
import 'package:plainscan/models/tool_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.testMode = true;
    SharedPreferences.setMockInitialValues({});
    Get.reset();
    Get.put(ProfileController());
  });

  tearDown(() {
    Get.reset();
  });

  group('User Files Isolation Tests', () {
    test('New user starts with empty scannedFiles list', () async {
      final scanController = Get.put(ScanController());
      await scanController.loadUserFiles();

      expect(scanController.scannedFiles, isEmpty);
    });

    test('Files added by User A are saved per user and isolated from User B', () async {
      // 1. User A logs in
      await StorageService.saveUser(
        email: 'userA@plainscan.com',
        name: 'User A',
        userId: 'user_a_123',
      );

      final scanController = Get.put(ScanController());
      await scanController.loadUserFiles();
      expect(scanController.scannedFiles, isEmpty);

      // User A adds a scanned file
      scanController.addScan('/path/to/usera_doc.pdf', customName: 'UserA_Doc.pdf');
      expect(scanController.scannedFiles.length, 1);
      expect(scanController.scannedFiles.first.name, 'UserA_Doc.pdf');

      // 2. User A logs out
      final profileController = Get.put(ProfileController());
      await profileController.logout();
      expect(scanController.scannedFiles, isEmpty);

      // 3. User B (newly created user) logs in
      await StorageService.saveUser(
        email: 'userB@plainscan.com',
        name: 'User B',
        userId: 'user_b_456',
      );
      await scanController.loadUserFiles();

      // User B should NOT see User A's files
      expect(scanController.scannedFiles, isEmpty);

      // User B adds their own file
      scanController.addScan('/path/to/userb_doc.pdf', customName: 'UserB_Doc.pdf');
      expect(scanController.scannedFiles.length, 1);
      expect(scanController.scannedFiles.first.name, 'UserB_Doc.pdf');

      // 4. User B logs out and User A logs back in
      await profileController.logout();
      expect(scanController.scannedFiles, isEmpty);

      await StorageService.saveUser(
        email: 'userA@plainscan.com',
        name: 'User A',
        userId: 'user_a_123',
      );
      await scanController.loadUserFiles();

      // User A's files are restored and User B's files are not present
      expect(scanController.scannedFiles.length, 1);
      expect(scanController.scannedFiles.first.name, 'UserA_Doc.pdf');
    });

    test('File modifications and deletions persist to user storage', () async {
      await StorageService.saveUser(
        email: 'userA@plainscan.com',
        name: 'User A',
        userId: 'user_a_123',
      );

      final scanController = Get.put(ScanController());
      scanController.addScan('/path/to/file1.pdf', customName: 'Initial_Name.pdf');
      final fileId = scanController.scannedFiles.first.id;

      // Rename file
      scanController.renameFile(fileId, 'Renamed_Name.pdf');
      expect(scanController.scannedFiles.first.name, 'Renamed_Name.pdf');

      // Favorite file
      scanController.toggleFavorite(fileId);
      expect(scanController.scannedFiles.first.isFavorite, isTrue);

      // Reload from storage
      await scanController.loadUserFiles();
      expect(scanController.scannedFiles.length, 1);
      expect(scanController.scannedFiles.first.name, 'Renamed_Name.pdf');
      expect(scanController.scannedFiles.first.isFavorite, isTrue);

      // Delete file
      scanController.deleteFile(fileId);
      expect(scanController.scannedFiles, isEmpty);

      await scanController.loadUserFiles();
      expect(scanController.scannedFiles, isEmpty);
    });
  });

  group('Recent Tools Animated Empty State Widget Tests', () {
    testWidgets('Displays animated empty state with "There is no tool selected" when recent tools is empty',
        (WidgetTester tester) async {
      final allToolsCtrl = Get.put(AllToolsController());
      allToolsCtrl.recentTools.clear();
      Get.put(DashboardController());

      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: buildDashboardRecentTools(),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify "There is no tool selected" is visible
      expect(find.text('There is no tool selected'), findsOneWidget);
      expect(find.text('Select a tool from above to get started'), findsOneWidget);
      expect(find.byIcon(Icons.handyman_outlined), findsOneWidget);
    });

    testWidgets('Displays recent tools list when recentTools has items',
        (WidgetTester tester) async {
      await StorageService.addRecentToolId('pdf-to-word');

      final dashboardCtrl = Get.put(DashboardController());
      final allToolsCtrl = dashboardCtrl.allToolsController;
      await allToolsCtrl.loadRecentTools();

      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: buildDashboardRecentTools(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify recent tool item is displayed and empty state is NOT displayed
      expect(find.text('PDF to Word'), findsOneWidget);
      expect(find.text('There is no tool selected'), findsNothing);
    });
  });
}
