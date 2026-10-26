import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:plainscan/app/routes.dart';
import 'package:plainscan/core/controllers/alltool_controller.dart';
import 'package:plainscan/core/controllers/dashboard_controller.dart';
import 'package:plainscan/core/controllers/profile_controller.dart';
import 'package:plainscan/core/controllers/scan_controller.dart';
import 'package:plainscan/core/controllers/tool_executor_controller.dart';
import 'package:plainscan/core/services/storage_service.dart';
import 'package:plainscan/core/utils/guest_dialog_helper.dart';
import 'package:plainscan/features/alltools/tool_executor_page.dart';
import 'package:plainscan/models/file_model.dart';
import 'package:plainscan/models/tool_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    Get.testMode = true;
    Get.reset();
  });

  tearDown(() {
    Get.reset();
  });

  group('Guest Scan Flow & Access Control Tests', () {
    test('1. First-time user can enter guest mode and skip login', () async {
      final initialGuest = await StorageService.isGuestMode();
      expect(initialGuest, isFalse);

      await StorageService.setGuestMode(true);
      await StorageService.setOnboarded(true);

      expect(await StorageService.isGuestMode(), isTrue);
      expect(await StorageService.isOnboarded(), isTrue);
      expect(await StorageService.hasSession(), isFalse);
    });

    test('2. Guest gets one free scan allowance that is tracked locally', () async {
      await StorageService.setGuestMode(true);

      // Initially allowance is not used
      expect(await StorageService.hasGuestUsedFreeScan(), isFalse);

      // Incomplete or failed scan does not set allowance to true
      // Only when PDF is successfully generated and saved:
      await StorageService.setGuestFreeScanUsed(true);

      // Allowance is marked as used
      expect(await StorageService.hasGuestUsedFreeScan(), isTrue);
    });

    test('3. App restart persists guest free scan allowance without reset', () async {
      await StorageService.setGuestMode(true);
      await StorageService.setGuestFreeScanUsed(true);

      // Check values
      expect(await StorageService.hasGuestUsedFreeScan(), isTrue);
      expect(await StorageService.isGuestMode(), isTrue);

      // Token operations (e.g. clearTokens) do not wipe guest scan status
      await StorageService.clearTokens();
      expect(await StorageService.hasGuestUsedFreeScan(), isTrue);
    });

    test('4. Guest can preview and reorder scanned pages in ToolExecutorController', () {
      final jpgToPdfTool = allPlainscanTools.firstWhere((t) => t.id == 'jpg-to-pdf');
      final file1 = FileModel(
        id: 'scan_1',
        name: 'Page1.jpg',
        fileType: 'JPG',
        sizeKb: 150.0,
        createdDate: DateTime.now(),
      );
      final file2 = FileModel(
        id: 'scan_2',
        name: 'Page2.jpg',
        fileType: 'JPG',
        sizeKb: 150.0,
        createdDate: DateTime.now(),
      );
      final file3 = FileModel(
        id: 'scan_3',
        name: 'Page3.jpg',
        fileType: 'JPG',
        sizeKb: 150.0,
        createdDate: DateTime.now(),
      );

      final scanController = Get.put(ScanController());
      final controller = Get.put(ToolExecutorController(
        tool: jpgToPdfTool,
        initialFiles: [file1, file2, file3],
        autoExecute: false,
      ));

      expect(controller.selectedFiles.length, 3);
      expect(controller.selectedFiles[0].id, 'scan_1');
      expect(controller.selectedFiles[1].id, 'scan_2');
      expect(controller.selectedFiles[2].id, 'scan_3');

      // Reorder: move Page 1 down to index 1
      controller.moveSelectedFile(0, 1);
      expect(controller.selectedFiles[0].id, 'scan_2');
      expect(controller.selectedFiles[1].id, 'scan_1');
      expect(controller.selectedFiles[2].id, 'scan_3');

      // Reorder: move Page 3 up to index 0
      controller.moveSelectedFile(2, 0);
      expect(controller.selectedFiles[0].id, 'scan_3');
      expect(controller.selectedFiles[1].id, 'scan_2');
      expect(controller.selectedFiles[2].id, 'scan_1');
    });

    test('5. Migrating guest scanned files to user when authenticating', () async {
      // Create guest scans
      final guestFile = FileModel(
        id: 'guest_scan_101',
        name: 'My_Scanned_Doc.pdf',
        fileType: 'PDF',
        sizeKb: 300.0,
        path: '/storage/emulated/0/Download/My_Scanned_Doc.pdf',
        createdDate: DateTime.now(),
      );

      // Save as guest (when no userId or email is saved)
      await StorageService.saveUserScannedFiles([guestFile]);
      final guestFiles = await StorageService.getUserScannedFiles();
      expect(guestFiles.length, 1);
      expect(guestFiles.first.id, 'guest_scan_101');

      // Now user signs in with account
      await StorageService.saveTokens(token: 'test_token', refreshToken: 'test_ref');
      await StorageService.saveUser(email: 'user@example.com', name: 'User One', userId: 'usr_123');

      // Run migration
      await StorageService.migrateGuestFilesToUser();
      await StorageService.setGuestMode(false);

      // Scanned files should now be in the user's files and accessible
      final userFiles = await StorageService.getUserScannedFiles();
      expect(userFiles.any((f) => f.id == 'guest_scan_101'), isTrue);
      expect(await StorageService.isGuestMode(), isFalse);
    });

    testWidgets('6. Guest Login Required Dialog displays Sign In, Sign Up, and Return to Dashboard', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showGuestLoginRequiredDialog(
                      context: context,
                      toolName: 'PDF Merge',
                    );
                  },
                  child: const Text('Open Dialog'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Verify Dialog header and message
      expect(find.textContaining('Sign In Required'), findsOneWidget);
      expect(find.textContaining('PDF Merge is available for registered accounts'), findsOneWidget);

      // Verify buttons
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Sign Up'), findsOneWidget);
      expect(find.text('Return to Dashboard'), findsOneWidget);

      // Tap Return to Dashboard closes dialog
      await tester.tap(find.text('Return to Dashboard'));
      await tester.pumpAndSettle();
      expect(find.text('Sign In'), findsNothing);
    });

    testWidgets('7. Free Guest Scan Used Dialog displays scan limit message', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showGuestLoginRequiredDialog(
                      context: context,
                      isScanLimit: true,
                    );
                  },
                  child: const Text('Open Limit Dialog'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Limit Dialog'));
      await tester.pumpAndSettle();

      // Verify Dialog Title and explanation
      expect(find.text('Free Guest Scan Used'), findsOneWidget);
      expect(
        find.textContaining('You have already used your 1 free guest scan'),
        findsOneWidget,
      );

      // Verify Sign In & Sign Up buttons present
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Sign Up'), findsOneWidget);
      expect(find.text('Return to Dashboard'), findsOneWidget);
    });
  });
}
