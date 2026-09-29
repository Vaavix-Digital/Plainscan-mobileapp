import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:plainscan/core/controllers/scan_controller.dart';
import 'package:plainscan/core/controllers/tool_executor_controller.dart';
import 'package:plainscan/core/services/background_job_service.dart';
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

  group('Plagiarism Check - Raw Text switching and previous result clearing', () {
    const plagiarismTool = ToolModel(
      id: 'plagiarism-check',
      name: 'Plagiarism Check',
      description: 'Scan content against web and publication databases to produce a plagiarism report.',
      icon: Icons.find_in_page_outlined,
      color: Colors.deepPurple,
      categoryId: 'ai',
      isFree: false,
    );

    test('Toggling to Raw Text after processing a document clears previous result', () async {
      final initialFile = FileModel(
        id: 'file_orig_1',
        name: 'AI_Tools_Test_Document.pdf',
        path: '/tmp/AI_Tools_Test_Document.pdf',
        fileType: 'PDF',
        sizeKb: 1200,
        createdDate: DateTime.now(),
      );

      final controller = Get.put(
        ToolExecutorController(
          tool: plagiarismTool,
          initialFiles: [initialFile],
        ),
      );

      expect(controller.useRawText, isFalse);
      expect(controller.selectedFile, isNotNull);

      // Simulate a finished document processing execution
      controller.currentStep = 'success';
      controller.outputFileName = 'AI_Tools_Test_Document_processed.pdf';
      controller.convertedFile = FileModel(
        id: 'file_processed_1',
        name: 'AI_Tools_Test_Document_processed.pdf',
        path: '/tmp/AI_Tools_Test_Document_processed.pdf',
        fileType: 'PDF',
        sizeKb: 1200,
        createdDate: DateTime.now(),
      );

      expect(controller.convertedFile, isNotNull);
      expect(controller.currentStep, equals('success'));

      // User selects "Raw Text" mode
      controller.toggleUseRawText(true);

      // Previous result should now be cleared
      expect(controller.useRawText, isTrue);
      expect(controller.convertedFile, isNull);
      expect(controller.currentStep, equals('idle'));
      expect(controller.outputFileName, isEmpty);
    });

    test('Modifying raw text after processing clears previous result', () async {
      final controller = Get.put(
        ToolExecutorController(
          tool: plagiarismTool,
        ),
      );

      controller.toggleUseRawText(true);
      controller.rawTextController.text = 'First text snippet to analyze';

      // Simulate a finished execution
      controller.currentStep = 'success';
      controller.outputFileName = 'Plagiarism_Report.pdf';
      controller.convertedFile = FileModel(
        id: 'file_processed_2',
        name: 'Plagiarism_Report.pdf',
        path: '/tmp/Plagiarism_Report.pdf',
        fileType: 'PDF',
        sizeKb: 500,
        createdDate: DateTime.now(),
      );

      expect(controller.convertedFile, isNotNull);
      expect(controller.currentStep, equals('success'));

      // User enters new row of text / edits the text field
      controller.rawTextController.text = 'New updated text content for plagiarism scan';

      // Previous result must be cleared
      expect(controller.convertedFile, isNull);
      expect(controller.currentStep, equals('idle'));
      expect(controller.outputFileName, isEmpty);
    });

    test('Toggling from Raw Text back to Document File clears previous result', () async {
      final controller = Get.put(
        ToolExecutorController(
          tool: plagiarismTool,
        ),
      );

      controller.toggleUseRawText(true);
      controller.rawTextController.text = 'Some raw text';

      // Simulate finished execution
      controller.currentStep = 'success';
      controller.convertedFile = FileModel(
        id: 'file_processed_3',
        name: 'Plagiarism_Report.pdf',
        path: '/tmp/Plagiarism_Report.pdf',
        fileType: 'PDF',
        sizeKb: 500,
        createdDate: DateTime.now(),
      );

      // User toggles back to Document File
      controller.toggleUseRawText(false);

      expect(controller.useRawText, isFalse);
      expect(controller.convertedFile, isNull);
      expect(controller.currentStep, equals('idle'));
    });
  });
}
