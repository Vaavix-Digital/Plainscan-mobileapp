import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:plainscan/core/controllers/scan_controller.dart';
import 'package:plainscan/core/controllers/tool_executor_controller.dart';
import 'package:plainscan/features/alltools/tool_executor_page.dart';
import 'package:plainscan/features/files/pages/files_page.dart';
import 'package:plainscan/features/files/pages/pdf_viewer_page.dart';
import 'package:plainscan/features/home/screens/home_screen.dart';
import 'package:plainscan/models/file_model.dart';
import 'package:plainscan/models/tool_model.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PDF Tools - View in File Tests', () {
    late ScanController scanController;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      Get.reset();
      scanController = Get.put(ScanController());
      Get.put(HomeScreenController());
    });

    tearDown(() {
      Get.reset();
    });

    testWidgets('FilesPage renders and highlights generated file with NEW badge', (WidgetTester tester) async {
      final fileId = 'test_pdf_file_1';
      scanController.scannedFiles.value = [
        FileModel(
          id: fileId,
          name: 'merged_document.pdf',
          createdDate: DateTime.now(),
          sizeKb: 1024,
          fileType: 'PDF',
          path: '/mock/path/merged_document.pdf',
        ),
        FileModel(
          id: 'test_pdf_file_2',
          name: 'other_doc.pdf',
          createdDate: DateTime.now(),
          sizeKb: 512,
          fileType: 'PDF',
          path: '/mock/path/other_doc.pdf',
        ),
      ];

      await tester.pumpWidget(
        GetMaterialApp(
          home: FilesPage(highlightFileId: fileId),
        ),
      );
      await tester.pumpAndSettle();

      // Verify file is visible
      expect(find.text('merged_document.pdf'), findsOneWidget);
      // Verify "NEW" badge is displayed on the highlighted item
      expect(find.text('NEW'), findsOneWidget);

      // Tap on the file to open details bottom sheet
      await tester.tap(find.text('merged_document.pdf'));
      await tester.pumpAndSettle();

      // Verify details bottom sheet options are rendered
      expect(find.text('Share'), findsOneWidget);
      expect(find.text('Save / Export'), findsOneWidget);
      expect(find.text('Rename'), findsOneWidget);
    });

    testWidgets('showToolUpdateAlertDialog renders Dismiss and Open buttons and Open views the PDF', (WidgetTester tester) async {
      final mergeTool = const ToolModel(
        id: 'pdf-merge',
        name: 'PDF Merge',
        icon: Icons.merge_type,
        color: Colors.red,
        categoryId: 'pdf_tools',
        category: 'PDF Tools',
      );

      final controller = Get.put(ToolExecutorController(
        tool: mergeTool,
      ));

      final testFile = FileModel(
        id: 'merged_123',
        name: 'merged_output.pdf',
        createdDate: DateTime.now(),
        sizeKb: 2048,
        fileType: 'PDF',
        path: '/mock/merged_output.pdf',
      );
      scanController.scannedFiles.add(testFile);
      controller.convertedFile = testFile;

      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    controller.showToolUpdateAlertDialog(
                      '/mock/merged_output.pdf',
                      'merged_output.pdf',
                      'PDF',
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );

      // Trigger the dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify Dialog contents
      expect(find.text('PDF Merge Completed'), findsOneWidget);
      expect(find.text('File generated successfully'), findsOneWidget);
      expect(find.text('Dismiss'), findsOneWidget);
      expect(find.text('Open'), findsOneWidget);

      // Tap "Open"
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Verify that navigation reached PdfViewerPage and displays the document
      expect(find.text('merged_output.pdf'), findsWidgets);
      expect(find.text('PDF Document • Ready'), findsOneWidget);
      expect(find.text('PlainScan Document Engine'), findsOneWidget);
    });

    testWidgets('Converted file card switches Download button to View button when downloaded', (WidgetTester tester) async {
      final mergeTool = const ToolModel(
        id: 'pdf-merge',
        name: 'PDF Merge',
        icon: Icons.merge_type,
        color: Colors.red,
        categoryId: 'pdf_tools',
        category: 'PDF Tools',
      );

      final controller = Get.put(ToolExecutorController(
        tool: mergeTool,
      ));

      final testFile = FileModel(
        id: 'merged_123',
        name: 'merged_output.pdf',
        createdDate: DateTime.now(),
        sizeKb: 2048,
        fileType: 'PDF',
        path: '/mock/merged_output.pdf',
      );
      controller.convertedFile = testFile;
      controller.currentStep = 'success';

      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: GetBuilder<ToolExecutorController>(
              builder: (ctrl) {
                // Simulate the converted file card UI
                return Column(
                  children: [
                    Text(ctrl.convertedFile!.name),
                    ctrl.isFileDownloaded
                        ? ElevatedButton.icon(
                            key: const ValueKey('view_btn'),
                            onPressed: () {
                              Get.to(() => PdfViewerPage(
                                file: ctrl.convertedFile,
                                filePath: ctrl.convertedFile?.path,
                                fileName: ctrl.convertedFile?.name,
                                fileType: ctrl.convertedFile?.fileType ?? 'PDF',
                              ));
                            },
                            icon: const Icon(Icons.visibility_outlined),
                            label: const Text('View'),
                          )
                        : OutlinedButton.icon(
                            key: const ValueKey('download_btn'),
                            onPressed: () {
                              ctrl.markFileDownloaded();
                            },
                            icon: const Icon(Icons.download),
                            label: const Text('Download'),
                          ),
                  ],
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially, "Download" button is rendered and "View" is not
      expect(find.text('Download'), findsOneWidget);
      expect(find.text('View'), findsNothing);

      // Tap Download (triggers download & markFileDownloaded)
      await tester.tap(find.text('Download'));
      await tester.pumpAndSettle();

      // Now "Download" button has transitioned to "View"
      expect(find.text('Download'), findsNothing);
      expect(find.text('View'), findsOneWidget);

      // Tap "View" opens the PDF viewer
      await tester.tap(find.text('View'));
      await tester.pumpAndSettle();

      expect(find.text('merged_output.pdf'), findsWidgets);
      expect(find.text('PDF Document • Ready'), findsOneWidget);
    });

    testWidgets('Converted file card renders Share button alongside Download and Rename', (WidgetTester tester) async {
      final mergeTool = const ToolModel(
        id: 'pdf-merge',
        name: 'PDF Merge',
        icon: Icons.merge_type,
        color: Colors.red,
        categoryId: 'pdf_tools',
        category: 'PDF Tools',
      );

      final controller = Get.put(ToolExecutorController(
        tool: mergeTool,
      ));

      final testFile = FileModel(
        id: 'merged_123',
        name: 'merged_output.pdf',
        createdDate: DateTime.now(),
        sizeKb: 2048,
        fileType: 'PDF',
        path: '/mock/merged_output.pdf',
      );
      controller.convertedFile = testFile;

      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.download),
                  label: const Text('Download'),
                ),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Rename'),
                ),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.share_outlined),
                  label: const Text('Share'),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Download'), findsOneWidget);
      expect(find.text('Rename'), findsOneWidget);
      expect(find.text('Share'), findsOneWidget);
      expect(find.text('Open'), findsNothing);
    });

    testWidgets('PDF Unlock hides password field and disables Run button when selected PDF is not password-protected', (WidgetTester tester) async {
      final unlockTool = const ToolModel(
        id: 'pdf-unlock',
        name: 'PDF Unlock (Remove Password)',
        icon: Icons.lock_open,
        color: Colors.red,
        categoryId: 'pdf_tools',
        category: 'PDF Tools',
      );

      final unencryptedFile = FileModel(
        id: 'unlocked_file_1',
        name: 'Statement_Public.pdf',
        createdDate: DateTime.now(),
        sizeKb: 1024,
        fileType: 'PDF',
      );

      await tester.pumpWidget(
        GetMaterialApp(
          home: ToolExecutorPage(
            tool: unlockTool,
            initialFiles: [unencryptedFile],
          ),
        ),
      );
      await tester.pumpAndSettle();

      final controller = Get.find<ToolExecutorController>();
      expect(controller.selectedFile, isNotNull);
      expect(controller.isPdfLocked, isFalse);
      expect(controller.isExecutionDisabled, isTrue);

      // Verify Note that document has no password protection is displayed
      expect(find.text('Note: This document has no password protection. Unlocking is not needed.'), findsOneWidget);

      // Verify Password TextField is NOT displayed
      expect(find.text('Enter Document Password'), findsNothing);
      expect(find.byType(TextField), findsNothing);

      // Verify disabled state of Run button
      expect(find.text('Document Already Unlocked'), findsOneWidget);
      final runButton = tester.widget<ElevatedButton>(find.byType(ElevatedButton).last);
      expect(runButton.onPressed, isNull);
    });

    testWidgets('PDF Unlock hides password field when no file is selected yet', (WidgetTester tester) async {
      final unlockTool = const ToolModel(
        id: 'pdf-unlock',
        name: 'PDF Unlock (Remove Password)',
        icon: Icons.lock_open,
        color: Colors.red,
        categoryId: 'pdf_tools',
        category: 'PDF Tools',
      );

      await tester.pumpWidget(
        GetMaterialApp(
          home: ToolExecutorPage(
            tool: unlockTool,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final controller = Get.find<ToolExecutorController>();
      expect(controller.selectedFile, isNull);

      // Verify Password TextField is NOT displayed
      expect(find.text('Enter Document Password'), findsNothing);
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Upload a password-protected PDF file to check its security status and remove encryption.'), findsOneWidget);
    });

    testWidgets('PDF Unlock displays password field only when a password-protected PDF is selected', (WidgetTester tester) async {
      final unlockTool = const ToolModel(
        id: 'pdf-unlock',
        name: 'PDF Unlock (Remove Password)',
        icon: Icons.lock_open,
        color: Colors.red,
        categoryId: 'pdf_tools',
        category: 'PDF Tools',
      );

      final lockedFile = FileModel(
        id: 'locked_file_1',
        name: 'Financial_Report_Locked.pdf',
        createdDate: DateTime.now(),
        sizeKb: 512,
        fileType: 'PDF',
      );

      await tester.pumpWidget(
        GetMaterialApp(
          home: ToolExecutorPage(
            tool: unlockTool,
            initialFiles: [lockedFile],
          ),
        ),
      );
      await tester.pumpAndSettle();

      final controller = Get.find<ToolExecutorController>();
      expect(controller.selectedFile, isNotNull);
      expect(controller.isPdfLocked, isTrue);
      expect(controller.isExecutionDisabled, isFalse);

      // Verify Password-Protected PDF Recognized banner is displayed
      expect(find.text('Password-Protected PDF Recognized'), findsOneWidget);

      // Verify Password TextField IS displayed
      expect(find.text('Enter Document Password'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Enter password to unlock'), findsOneWidget);
    });
  });
}

