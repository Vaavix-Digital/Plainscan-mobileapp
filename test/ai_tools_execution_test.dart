import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:plainscan/core/controllers/alltool_controller.dart';
import 'package:plainscan/core/controllers/scan_controller.dart';
import 'package:plainscan/core/controllers/tool_executor_controller.dart';
import 'package:plainscan/core/services/background_job_service.dart';
import 'package:plainscan/core/utils/local_document_generators.dart';
import 'package:plainscan/features/alltools/tool_executor_page.dart';
import 'package:plainscan/models/file_model.dart';
import 'package:plainscan/models/tool_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({'user_plan': 'pro'});
    Get.reset();
    Get.put(ScanController());
    Get.put(BackgroundJobService());
    Get.put(AllToolsController());
  });

  tearDown(() {
    Get.reset();
  });

  group('LocalDocumentPdfGenerator AI & DOCX Generators', () {
    test('generateDocx creates valid Word file with content', () async {
      final tempDir = Directory.systemTemp;
      final outPath = '${tempDir.path}/test_output_${DateTime.now().millisecondsSinceEpoch}.docx';

      final file = await LocalDocumentPdfGenerator.generateDocx(
        outputFilePath: outPath,
        text: 'This is a test paragraph.\nSecond line of the document.',
        title: 'Test Document Title',
      );

      expect(await file.exists(), isTrue);
      final bytes = await file.readAsBytes();
      expect(bytes.length, greaterThan(200));
      // First 2 bytes of a ZIP/DOCX file are PK (0x50, 0x4B)
      expect(bytes[0], equals(0x50));
      expect(bytes[1], equals(0x4B));
    });

    test('generateAiSummaryText generates comprehensive summary text', () {
      final summary = LocalDocumentPdfGenerator.generateAiSummaryText(
        inputSource: 'Quarterly_Report_2026.pdf',
        text: 'PlainScan document intelligence provides fast scanning and conversion operations.',
        length: 'detailed',
      );

      expect(summary.contains('PLAINSCAN AI DOCUMENT SUMMARY'), isTrue);
      expect(summary.contains('EXECUTIVE SUMMARY'), isTrue);
      expect(summary.contains('CORE THEMES'), isTrue);
      expect(summary.contains('ACTIONABLE RECOMMENDATIONS'), isTrue);
    });

    test('generateAiDetectionJson generates valid JSON with scores and classification', () {
      final jsonStr = LocalDocumentPdfGenerator.generateAiDetectionJson(
        inputSource: 'Essay.pdf',
        text: 'In conclusion, it is important to note that delving into this tapestry is crucial. Furthermore, we must act.',
      );

      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      expect(decoded['tool'], equals('ai-detector'));
      expect(decoded['status'], equals('completed'));
      expect(decoded['ai_probability_percentage'], isNotNull);
      expect(decoded['classification'], isNotNull);
      expect(decoded['metrics'], isNotNull);
    });

    test('generateHumanizedText rewrites cliches naturally', () {
      const input = 'In conclusion, delving into this tapestry plays a crucial role in our success. It is important to note that we cannot fail.';
      final humanized = LocalDocumentPdfGenerator.generateHumanizedText(
        text: input,
        style: 'casual',
      );

      expect(humanized.contains('delve into'), isFalse);
      expect(humanized.contains("can't"), isTrue);
      expect(humanized.contains('Overall,'), isTrue);
    });

    test('generateGrammarCorrectedText fixes grammar and punctuation errors', () {
      const input = 'this are a example of bad grammar';
      final corrected = LocalDocumentPdfGenerator.generateGrammarCorrectedText(
        text: input,
      );

      expect(corrected.contains('This is an example'), isTrue);
      expect(corrected.endsWith('.'), isTrue);
    });
  });

  group('ToolExecutorController AI Tools Execution (Fix Tool Not Found)', () {
    test('AI Summarize Long PDF executes successfully without Tool not found error', () async {
      final tool = allPlainscanTools.firstWhere((t) => t.id == 'summarize-long-pdfs');
      final controller = Get.put(ToolExecutorController(tool: tool));

      controller.selectedFile = FileModel(
        id: 'test_doc_1',
        name: 'AI_Tools_Test_Document.pdf',
        createdDate: DateTime.now(),
        sizeKb: 120.0,
        fileType: 'PDF',
      );

      await controller.executeJobFlow();

      expect(controller.currentStep, equals('success'));
      expect(controller.errorMessage.toLowerCase().contains('not found'), isFalse);
      expect(controller.errorMessage.toLowerCase().contains('success'), isTrue);
      expect(controller.convertedFile, isNotNull);
      expect(controller.convertedFile!.fileType, equals('TXT'));
      expect(controller.generatedSummaryContent.isNotEmpty, isTrue);
    });

    test('AI Detector executes successfully without Tool not found error', () async {
      final tool = allPlainscanTools.firstWhere((t) => t.id == 'ai-detector');
      final controller = Get.put(ToolExecutorController(tool: tool));

      controller.useRawText = true;
      controller.rawTextController.text = 'Furthermore, delving into this complex subject is a testament to innovation.';

      await controller.executeJobFlow();

      expect(controller.currentStep, equals('success'));
      expect(controller.errorMessage.toLowerCase().contains('not found'), isFalse);
      expect(controller.errorMessage.toLowerCase().contains('success'), isTrue);
      expect(controller.convertedFile, isNotNull);
      expect(controller.convertedFile!.fileType, equals('JSON'));
      expect(controller.detectorResultMap, isNotNull);
      expect(controller.detectorResultMap!['tool'], equals('ai-detector'));
    });

    test('AI Humanize Content executes successfully without Tool not found error', () async {
      final tool = allPlainscanTools.firstWhere((t) => t.id == 'humanize-ai-content');
      final controller = Get.put(ToolExecutorController(tool: tool));

      controller.useRawText = true;
      controller.rawTextController.text = 'It is important to note that artificial intelligence provides a tapestry of options.';
      controller.setAiHumanizeStyle('casual');

      await controller.executeJobFlow();

      expect(controller.currentStep, equals('success'));
      expect(controller.errorMessage.toLowerCase().contains('not found'), isFalse);
      expect(controller.errorMessage.toLowerCase().contains('success'), isTrue);
      expect(controller.convertedFile, isNotNull);
      expect(controller.convertedFile!.fileType, equals('DOCX'));
      expect(controller.generatedHumanizeContent.isNotEmpty, isTrue);
    });

    test('Grammar Checker / Correction executes successfully without Tool not found error', () async {
      final tool = allPlainscanTools.firstWhere((t) => t.id == 'grammar-checker');
      final controller = Get.put(ToolExecutorController(tool: tool));

      controller.useRawText = true;
      controller.rawTextController.text = 'this are a example with poor grammar';

      await controller.executeJobFlow();

      expect(controller.currentStep, equals('success'));
      expect(controller.errorMessage.toLowerCase().contains('not found'), isFalse);
      expect(controller.errorMessage.toLowerCase().contains('success'), isTrue);
      expect(controller.convertedFile, isNotNull);
      expect(controller.convertedFile!.fileType, equals('DOCX'));
      expect(controller.generatedGrammarContent.isNotEmpty, isTrue);
      expect(controller.generatedGrammarContent.contains('This is an example'), isTrue);
    });
  });

  group('AllToolsController Slug Aliasing', () {
    test('findToolByIdOrSlug resolves both frontend and backend slugs correctly', () {
      final allToolsCtrl = Get.find<AllToolsController>();

      // Summarize
      final sumFrontend = allToolsCtrl.findToolByIdOrSlug('summarize-long-pdfs');
      final sumBackend = allToolsCtrl.findToolByIdOrSlug('summarize-pdf');
      expect(sumFrontend, isNotNull);
      expect(sumBackend, isNotNull);
      expect(sumFrontend!.id, equals(sumBackend!.id));

      // Detector
      final detFrontend = allToolsCtrl.findToolByIdOrSlug('ai-detector');
      final detBackend = allToolsCtrl.findToolByIdOrSlug('ai-detection');
      expect(detFrontend, isNotNull);
      expect(detBackend, isNotNull);
      expect(detFrontend!.id, equals(detBackend!.id));

      // Humanize
      final humFrontend = allToolsCtrl.findToolByIdOrSlug('humanize-ai-content');
      final humBackend = allToolsCtrl.findToolByIdOrSlug('humanize-ai');
      expect(humFrontend, isNotNull);
      expect(humBackend, isNotNull);
      expect(humFrontend!.id, equals(humBackend!.id));

      // Grammar
      final gramFrontend = allToolsCtrl.findToolByIdOrSlug('grammar-checker');
      final gramBackend = allToolsCtrl.findToolByIdOrSlug('grammar-correction');
      expect(gramFrontend, isNotNull);
      expect(gramBackend, isNotNull);
      expect(gramFrontend!.id, equals(gramBackend!.id));
    });
  });

  group('ToolExecutorPage Widgets for AI Tools', () {
    testWidgets('renders AI Summarize Long PDF page correctly', (tester) async {
      final tool = allPlainscanTools.firstWhere((t) => t.id == 'summarize-long-pdfs');

      await tester.pumpWidget(
        GetMaterialApp(
          home: ToolExecutorPage(tool: tool),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('AI Summarize Long PDF'), findsWidgets);
      expect(find.text('Run AI Summarize Long PDF'), findsOneWidget);
      expect(find.text('Summary Detail Length'), findsOneWidget);
    });
  });
}
