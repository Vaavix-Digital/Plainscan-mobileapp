import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:plainscan/core/controllers/scan_controller.dart';
import 'package:plainscan/core/controllers/tool_executor_controller.dart';
import 'package:plainscan/core/utils/local_image_to_pdf_generator.dart';
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
  });

  tearDown(() {
    Get.reset();
  });

  group('Scanner Preview & JPG to PDF Integration Tests', () {
    test('JPG to PDF tool model has isMultiFile enabled', () {
      final tool = allPlainscanTools.firstWhere((t) => t.id == 'jpg-to-pdf');
      expect(tool.isMultiFile, isTrue);
      expect(tool.name, 'JPG to PDF');
      expect(tool.slug, 'jpg-to-pdf');
    });

    test('ToolExecutorController correctly pre-populates multi-image input files', () {
      final tool = allPlainscanTools.firstWhere((t) => t.id == 'jpg-to-pdf');
      final testFiles = [
        FileModel(
          id: 'scan_1',
          name: 'Scan_Page_1.jpg',
          createdDate: DateTime.now(),
          sizeKb: 500,
          fileType: 'JPG',
          path: '/mock/path/page1.jpg',
        ),
        FileModel(
          id: 'scan_2',
          name: 'Scan_Page_2.jpg',
          createdDate: DateTime.now(),
          sizeKb: 600,
          fileType: 'JPG',
          path: '/mock/path/page2.jpg',
        ),
      ];

      final controller = Get.put(ToolExecutorController(
        tool: tool,
        initialFiles: testFiles,
      ));

      expect(controller.isMultiFileTool(), isTrue);
      expect(controller.selectedFiles.length, 2);
      expect(controller.selectedFiles[0].name, 'Scan_Page_1.jpg');
      expect(controller.selectedFiles[1].name, 'Scan_Page_2.jpg');
    });

    testWidgets('ScanController openScanner captures images and directly opens JPG to PDF tool', (WidgetTester tester) async {
      await tester.pumpWidget(
        const GetMaterialApp(
          home: Scaffold(body: Center(child: Text('Home'))),
        ),
      );
      await tester.pumpAndSettle();

      final scanController = Get.find<ScanController>();
      await scanController.openScanner();
      await tester.pumpAndSettle();

      // Verify that ToolExecutorPage for JPG to PDF tool is launched directly
      expect(find.byType(ToolExecutorPage), findsOneWidget);
      expect(find.text('JPG to PDF'), findsWidgets);

      final executorController = Get.find<ToolExecutorController>();
      expect(executorController.selectedFiles.isNotEmpty, isTrue);
      expect(executorController.selectedFiles.first.fileType, 'JPG');
      expect(executorController.tool.id, 'jpg-to-pdf');
    });

    test('ToolExecutorController scanDocumentWithCamera captures images and uploads to tool', () async {
      final tool = allPlainscanTools.firstWhere((t) => t.id == 'jpg-to-pdf');
      final controller = Get.put(ToolExecutorController(tool: tool));

      expect(controller.selectedFiles, isEmpty);

      // Trigger camera scan upload
      await controller.scanDocumentWithCamera(true);

      expect(controller.selectedFiles.isNotEmpty, isTrue);
      expect(controller.selectedFiles.first.fileType, 'JPG');
      expect(controller.selectedFiles.first.name, contains('Scan_'));
    });

    testWidgets('ToolExecutorPage displays Scan Document action button', (WidgetTester tester) async {
      final tool = allPlainscanTools.firstWhere((t) => t.id == 'jpg-to-pdf');

      await tester.pumpWidget(
        GetMaterialApp(
          home: ToolExecutorPage(tool: tool),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Device Upload'), findsOneWidget);
      expect(find.text('Scan Document'), findsOneWidget);
    });

    test('JPG to PDF executeJobFlow successfully converts multiple scanned JPGs to PDF', () async {
      final tool = allPlainscanTools.firstWhere((t) => t.id == 'jpg-to-pdf');
      final testFiles = [
        FileModel(
          id: 'scan_1',
          name: 'Scan_1789818376757_Page1.jpg',
          createdDate: DateTime.now(),
          sizeKb: 500,
          fileType: 'JPG',
          path: 'Scan_1789818376757_Page1.jpg',
        ),
        FileModel(
          id: 'scan_2',
          name: 'Scan_1789818398786_Page1.jpg',
          createdDate: DateTime.now(),
          sizeKb: 600,
          fileType: 'JPG',
          path: 'Scan_1789818398786_Page1.jpg',
        ),
      ];

      final controller = Get.put(ToolExecutorController(
        tool: tool,
        initialFiles: testFiles,
      ));
      controller.tokenController.text = 'test_token';

      await controller.executeJobFlow();

      expect(controller.currentStep, 'success');
      expect(controller.convertedFile, isNotNull);
      expect(controller.convertedFile!.fileType, 'PDF');
      expect(controller.convertedFile!.name, contains('.pdf'));
    });

    test('LocalImageToPdfGenerator creates PDF with correct page count for multiple images', () async {
      final tempDir = Directory.systemTemp;
      final img1 = File('${tempDir.path}/test_img1.jpg');
      final img2 = File('${tempDir.path}/test_img2.jpg');
      await img1.writeAsBytes(LocalImageToPdfGenerator.minimalJpegBytes);
      await img2.writeAsBytes(LocalImageToPdfGenerator.minimalJpegBytes);

      final outPdf = '${tempDir.path}/test_multi_out.pdf';
      final pdfFile = await LocalImageToPdfGenerator.convertImagesToPdf(
        imageFiles: [img1, img2],
        outputFilePath: outPdf,
        pageSize: 'A4',
      );

      expect(await pdfFile.exists(), isTrue);
      final pdfContent = await pdfFile.readAsString(encoding: latin1);
      expect(pdfContent, contains('/Count 2'));
      expect(pdfContent, contains('/Type /Page'));
      expect(pdfContent, contains('/Type /Pages'));
      expect(pdfContent, contains('startxref'));
    });
  });
}
