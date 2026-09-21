import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:plainscan/core/controllers/scan_controller.dart';
import 'package:plainscan/core/controllers/tool_executor_controller.dart';
import 'package:plainscan/core/services/background_job_service.dart';
import 'package:plainscan/features/alltools/tool_executor_page.dart';
import 'package:plainscan/models/file_model.dart';
import 'package:plainscan/models/tool_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Get.reset();
    Get.testMode = true;
    Get.put(ScanController());
    Get.put(BackgroundJobService());
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('Tool opens as a fresh/new session after navigating back from completed job', (WidgetTester tester) async {
    const tool = ToolModel(
      id: 'pdf-compress',
      name: 'Compress PDF',
      description: 'Compress PDF documents',
      icon: Icons.compress,
      color: Colors.blue,
      categoryId: 'pdf',
    );

    final testFile = FileModel(
      id: 'file_1',
      name: 'sample_doc.pdf',
      path: '/tmp/sample_doc.pdf',
      fileType: 'PDF',
      sizeKb: 2048,
      createdDate: DateTime.now(),
    );

    // 1. First session: User opens tool and executes a job
    await tester.pumpWidget(
      GetMaterialApp(
        home: ToolExecutorPage(
          tool: tool,
          initialFiles: [testFile],
        ),
      ),
    );
    await tester.pumpAndSettle();

    final controller = Get.find<ToolExecutorController>();
    expect(controller.selectedFile, isNotNull);
    expect(controller.selectedFile!.name, equals('sample_doc.pdf'));

    // Simulate completion
    controller.currentStep = 'success';
    controller.errorMessage = 'Success! File processed with Compress PDF.';
    controller.convertedFile = FileModel(
      id: 'converted_1',
      name: 'sample_doc_compressed.pdf',
      path: '/tmp/sample_doc_compressed.pdf',
      fileType: 'PDF',
      sizeKb: 1024,
      createdDate: DateTime.now(),
    );
    controller.update();
    await tester.pumpAndSettle();

    // Success UI is displayed
    expect(find.text('Converted File'), findsOneWidget);
    expect(find.text('sample_doc_compressed.pdf'), findsOneWidget);

    // 2. User navigates back (pops the page)
    await tester.pumpWidget(
      const GetMaterialApp(
        home: Scaffold(body: Text('Home Screen')),
      ),
    );
    await tester.pumpAndSettle();

    // Verify controller was disposed
    expect(Get.isRegistered<ToolExecutorController>(), isFalse);

    // 3. User opens the SAME tool again
    await tester.pumpWidget(
      const GetMaterialApp(
        home: ToolExecutorPage(
          tool: tool,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final freshController = Get.find<ToolExecutorController>();

    // 4. Verify it is a fresh/new tool session
    expect(freshController.currentStep, isEmpty);
    expect(freshController.convertedFile, isNull);
    expect(freshController.selectedFile, isNull);
    expect(freshController.selectedFiles, isEmpty);
    expect(freshController.isRunning, isFalse);

    // Previous success message and downloaded file are NOT displayed
    expect(find.text('Converted File'), findsNothing);
    expect(find.text('sample_doc_compressed.pdf'), findsNothing);
    expect(find.text('Run Compress PDF'), findsOneWidget);
    expect(find.text('Device Upload'), findsOneWidget);
  });

  testWidgets('When navigating back during active execution (e.g. PDF Sign), reopening tool starts as a fresh execution flow', (WidgetTester tester) async {
    const pdfSignTool = ToolModel(
      id: 'pdf-sign',
      name: 'PDF Sign / E-Sign',
      description: 'Sign PDF documents digitally',
      icon: Icons.draw,
      color: Colors.purple,
      categoryId: 'pdf',
    );

    final testFile = FileModel(
      id: 'file_sign_1',
      name: 'contract.pdf',
      path: '/tmp/contract.pdf',
      fileType: 'PDF',
      sizeKb: 1024,
      createdDate: DateTime.now(),
    );

    // 1. User opens PDF Sign and starts execution
    await tester.pumpWidget(
      GetMaterialApp(
        home: ToolExecutorPage(
          tool: pdfSignTool,
          initialFiles: [testFile],
        ),
      ),
    );
    await tester.pumpAndSettle();

    final controller = Get.find<ToolExecutorController>();
    controller.isRunning = true;
    controller.currentStep = 'uploading';
    controller.errorMessage = 'Uploading input documents...';
    controller.update();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify running state: options locked and executing job flow visible
    expect(find.text('Options locked during processing'), findsOneWidget);
    expect(find.text('Executing Job Flow'), findsOneWidget);

    // 2. User navigates back to Dashboard BEFORE job completes
    await tester.pumpWidget(
      const GetMaterialApp(
        home: Scaffold(body: Text('Dashboard Screen')),
      ),
    );
    await tester.pumpAndSettle();

    expect(Get.isRegistered<ToolExecutorController>(), isFalse);

    // 3. User selects the SAME tool again
    await tester.pumpWidget(
      const GetMaterialApp(
        home: ToolExecutorPage(
          tool: pdfSignTool,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final reopenedController = Get.find<ToolExecutorController>();

    // 4. Verify it starts as a fresh execution flow without being affected by previous session
    expect(reopenedController.isRunning, isFalse);
    expect(reopenedController.currentStep, isEmpty);
    expect(reopenedController.convertedFile, isNull);

    expect(find.text('Options locked during processing'), findsNothing);
    expect(find.text('Executing Job Flow'), findsNothing);
    expect(find.text('Run PDF Sign / E-Sign'), findsOneWidget);

    // Signature text field is enabled and editable
    final signatureField = tester.widget<TextField>(
      find.widgetWithText(TextField, 'John Doe — Signed via Plainscan').first,
    );
    expect(signatureField.enabled, isTrue);
  });
}
