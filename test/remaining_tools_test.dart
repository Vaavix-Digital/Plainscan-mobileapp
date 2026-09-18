import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:plainscan/core/controllers/alltool_controller.dart';
import 'package:plainscan/core/controllers/scan_controller.dart';
import 'package:plainscan/core/controllers/tool_executor_controller.dart';
import 'package:plainscan/models/tool_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Get.reset();
    Get.put(ScanController());
  });

  tearDown(() {
    Get.reset();
  });

  group('Remaining Tools Catalog Verification', () {
    test('All 15 requested tools are defined in allPlainscanTools with expected slugs', () {
      final expectedSlugs = [
        'html-to-pdf',
        'images-to-pdf',
        'convert-image',
        'bank-statement-to-excel',
        'receipt-to-excel',
        'csv-to-excel',
        'excel-to-csv',
        'id-templates',
        'flatten-pdf',
        'n-up-pdf',
        'pdf-to-grayscale',
        'print-optimize-pdf',
        'repair-pdf',
        'invoice-generator',
        'crop-pdf',
        'ai-email-writer',
        'ai-proofread',
        'ai-citation',
        'ai-flashcards',
        'ai-quiz',
        'chat-with-pdf',
        'ats-scanner',
        'word-counter',
        'character-counter',
        'image-to-base64',
        'base64-to-image',
        'favicon-generator',
        'metadata-editor',
        'remove-metadata',
        'read-metadata',
      ];

      for (final slug in expectedSlugs) {
        final tool = allPlainscanTools.firstWhereOrNull((t) => t.slug == slug || t.id == slug);
        expect(tool, isNotNull, reason: 'Tool with slug "$slug" should be present in allPlainscanTools');
      }
    });

    test('Tool properties match requirements', () {
      final htmlToPdf = allPlainscanTools.firstWhere((t) => t.slug == 'html-to-pdf');
      expect(htmlToPdf.name, 'HTML to PDF');
      expect(htmlToPdf.outputFormat, '.pdf');
      expect(htmlToPdf.categoryId, 'conversion');

      final imagesToPdf = allPlainscanTools.firstWhere((t) => t.slug == 'images-to-pdf');
      expect(imagesToPdf.name, 'Images to PDF');
      expect(imagesToPdf.isMultiFile, isTrue);
      expect(imagesToPdf.outputFormat, '.pdf');

      final convertImage = allPlainscanTools.firstWhere((t) => t.slug == 'convert-image');
      expect(convertImage.name, 'Convert Image');
      expect(convertImage.outputFormat, contains('.jpg'));

      final bankStatement = allPlainscanTools.firstWhere((t) => t.slug == 'bank-statement-to-excel');
      expect(bankStatement.name, 'Bank Statement to Excel');
      expect(bankStatement.outputFormat, '.xlsx');
      expect(bankStatement.isFree, isFalse);

      final receipt = allPlainscanTools.firstWhere((t) => t.slug == 'receipt-to-excel');
      expect(receipt.name, 'Receipt to Excel');
      expect(receipt.outputFormat, '.xlsx');
      expect(receipt.isFree, isFalse);

      final csvToExcel = allPlainscanTools.firstWhere((t) => t.slug == 'csv-to-excel');
      expect(csvToExcel.name, 'CSV to Excel');
      expect(csvToExcel.outputFormat, '.xlsx');

      final excelToCsv = allPlainscanTools.firstWhere((t) => t.slug == 'excel-to-csv');
      expect(excelToCsv.name, 'Excel to CSV');
      expect(excelToCsv.outputFormat, '.csv');

      final idTemplates = allPlainscanTools.firstWhere((t) => t.slug == 'id-templates');
      expect(idTemplates.name, 'ID Templates');
      expect(idTemplates.outputFormat, '.pdf');

      final flattenPdf = allPlainscanTools.firstWhere((t) => t.slug == 'flatten-pdf');
      expect(flattenPdf.name, 'Flatten PDF');
      expect(flattenPdf.outputFormat, '.pdf');

      final nUpPdf = allPlainscanTools.firstWhere((t) => t.slug == 'n-up-pdf');
      expect(nUpPdf.name, 'N-up PDF');
      expect(nUpPdf.outputFormat, '.pdf');

      final pdfToGrayscale = allPlainscanTools.firstWhere((t) => t.slug == 'pdf-to-grayscale');
      expect(pdfToGrayscale.name, 'PDF to Grayscale');
      expect(pdfToGrayscale.outputFormat, '.pdf');

      final printOptimizePdf = allPlainscanTools.firstWhere((t) => t.slug == 'print-optimize-pdf');
      expect(printOptimizePdf.name, 'Print Optimize PDF');
      expect(printOptimizePdf.outputFormat, '.pdf');

      final repairPdf = allPlainscanTools.firstWhere((t) => t.slug == 'repair-pdf');
      expect(repairPdf.name, 'Repair PDF');
      expect(repairPdf.outputFormat, '.pdf');

      final invoiceGenerator = allPlainscanTools.firstWhere((t) => t.slug == 'invoice-generator');
      expect(invoiceGenerator.name, 'Invoice Generator');
      expect(invoiceGenerator.outputFormat, '.pdf');

      final cropPdf = allPlainscanTools.firstWhere((t) => t.slug == 'crop-pdf');
      expect(cropPdf.name, 'Crop PDF');
      expect(cropPdf.outputFormat, '.pdf');

      // Batch 3 tools verification
      final aiEmail = allPlainscanTools.firstWhere((t) => t.slug == 'ai-email-writer');
      expect(aiEmail.name, 'AI Email Writer');
      expect(aiEmail.outputFormat, '.txt');

      final aiProofread = allPlainscanTools.firstWhere((t) => t.slug == 'ai-proofread');
      expect(aiProofread.name, 'AI Proofread');
      expect(aiProofread.outputFormat, '.docx');
      expect(aiProofread.isTextAllowed, isTrue);

      final aiCitation = allPlainscanTools.firstWhere((t) => t.slug == 'ai-citation');
      expect(aiCitation.name, 'AI Citation Generator');
      expect(aiCitation.outputFormat, '.txt');

      final aiFlashcards = allPlainscanTools.firstWhere((t) => t.slug == 'ai-flashcards');
      expect(aiFlashcards.name, 'AI Flashcards');
      expect(aiFlashcards.outputFormat, '.json');
      expect(aiFlashcards.isTextAllowed, isTrue);

      final aiQuiz = allPlainscanTools.firstWhere((t) => t.slug == 'ai-quiz');
      expect(aiQuiz.name, 'AI Quiz Generator');
      expect(aiQuiz.outputFormat, '.json');
      expect(aiQuiz.isTextAllowed, isTrue);

      final chatPdf = allPlainscanTools.firstWhere((t) => t.slug == 'chat-with-pdf');
      expect(chatPdf.name, 'Chat with PDF');
      expect(chatPdf.outputFormat, '.txt');

      final atsScanner = allPlainscanTools.firstWhere((t) => t.slug == 'ats-scanner');
      expect(atsScanner.name, 'ATS Resume Scanner');
      expect(atsScanner.outputFormat, '.json');

      final wordCounter = allPlainscanTools.firstWhere((t) => t.slug == 'word-counter');
      expect(wordCounter.name, 'Word Counter');
      expect(wordCounter.outputFormat, '.json');

      final charCounter = allPlainscanTools.firstWhere((t) => t.slug == 'character-counter');
      expect(charCounter.name, 'Character Counter');
      expect(charCounter.outputFormat, '.json');

      final imgToBase64 = allPlainscanTools.firstWhere((t) => t.slug == 'image-to-base64');
      expect(imgToBase64.name, 'Image to Base64');
      expect(imgToBase64.outputFormat, '.txt');

      final base64ToImg = allPlainscanTools.firstWhere((t) => t.slug == 'base64-to-image');
      expect(base64ToImg.name, 'Base64 to Image');
      expect(base64ToImg.outputFormat, '.png');

      final favicon = allPlainscanTools.firstWhere((t) => t.slug == 'favicon-generator');
      expect(favicon.name, 'Favicon Generator');
      expect(favicon.outputFormat, '.ico');

      final metaEditor = allPlainscanTools.firstWhere((t) => t.slug == 'metadata-editor');
      expect(metaEditor.name, 'Metadata Editor');
      expect(metaEditor.outputFormat, '.jpg');

      final removeMeta = allPlainscanTools.firstWhere((t) => t.slug == 'remove-metadata');
      expect(removeMeta.name, 'Remove Metadata');
      expect(removeMeta.outputFormat, '.pdf');

      final readMeta = allPlainscanTools.firstWhere((t) => t.slug == 'read-metadata');
      expect(readMeta.name, 'Read Metadata');
      expect(readMeta.outputFormat, '.json');
    });

    test('AllToolsController lists all tools including all 30 new tools', () {
      final controller = Get.put(AllToolsController());
      expect(controller.tools.length, 86);

      final found = controller.findToolByIdOrSlug('ai-email-writer');
      expect(found, isNotNull);
      expect(found!.name, 'AI Email Writer');
    });
  });

  group('ToolExecutorController Payload & Options Verification', () {
    test('1. HTML to PDF options & execution flow', () {
      final tool = allPlainscanTools.firstWhere((t) => t.slug == 'html-to-pdf');
      final controller = Get.put(ToolExecutorController(tool: tool));

      expect(controller.isNoUploadTool(), isTrue);
      expect(controller.getExpectedExtension(), 'pdf');

      // Default URL mode
      controller.setHtmlToPdfMode('url');
      controller.htmlToPdfUrlController.text = 'https://example.com';
      expect(controller.getOptionsJson(), {'url': 'https://example.com'});

      // Raw HTML mode
      controller.setHtmlToPdfMode('html');
      controller.htmlToPdfHtmlController.text = '<h1>Hello World</h1>';
      expect(controller.getOptionsJson(), {'html': '<h1>Hello World</h1>'});

      Get.delete<ToolExecutorController>();
    });

    test('2. Images to PDF options & multi-file handling', () {
      final tool = allPlainscanTools.firstWhere((t) => t.slug == 'images-to-pdf');
      final controller = Get.put(ToolExecutorController(tool: tool));

      expect(controller.isMultiFileTool(), isTrue);
      expect(controller.getOptionsJson(), isEmpty);
      expect(controller.getExpectedExtension(), 'pdf');

      Get.delete<ToolExecutorController>();
    });

    test('3. Convert Image options & quality/format settings', () {
      final tool = allPlainscanTools.firstWhere((t) => t.slug == 'convert-image');
      final controller = Get.put(ToolExecutorController(tool: tool));

      expect(controller.getExpectedExtension(), 'jpg');
      expect(controller.getOptionsJson(), {
        'target_format': 'jpg',
        'quality': 90,
      });

      controller.setConvertImageTargetFormat('png');
      controller.setConvertImageQuality(80);

      expect(controller.getExpectedExtension(), 'png');
      expect(controller.getOptionsJson(), {
        'target_format': 'png',
        'quality': 80,
      });

      Get.delete<ToolExecutorController>();
    });

    test('4. Bank Statement to Excel options & extension', () {
      final tool = allPlainscanTools.firstWhere((t) => t.slug == 'bank-statement-to-excel');
      final controller = Get.put(ToolExecutorController(tool: tool));

      expect(controller.getOptionsJson(), isEmpty);
      expect(controller.getExpectedExtension(), 'xlsx');

      Get.delete<ToolExecutorController>();
    });

    test('5. Receipt to Excel options & extension', () {
      final tool = allPlainscanTools.firstWhere((t) => t.slug == 'receipt-to-excel');
      final controller = Get.put(ToolExecutorController(tool: tool));

      expect(controller.getOptionsJson(), isEmpty);
      expect(controller.getExpectedExtension(), 'xlsx');

      Get.delete<ToolExecutorController>();
    });

    test('6. CSV to Excel delimiter options', () {
      final tool = allPlainscanTools.firstWhere((t) => t.slug == 'csv-to-excel');
      final controller = Get.put(ToolExecutorController(tool: tool));

      expect(controller.getExpectedExtension(), 'xlsx');
      expect(controller.getOptionsJson(), {'delimiter': ','});

      controller.setCsvDelimiter(';');
      expect(controller.getOptionsJson(), {'delimiter': ';'});

      Get.delete<ToolExecutorController>();
    });

    test('7. Excel to CSV sheet index options', () {
      final tool = allPlainscanTools.firstWhere((t) => t.slug == 'excel-to-csv');
      final controller = Get.put(ToolExecutorController(tool: tool));

      expect(controller.getExpectedExtension(), 'csv');
      expect(controller.getOptionsJson(), {'sheet_index': 0});

      controller.incrementExcelSheetIndex();
      expect(controller.excelSheetIndex, 1);
      expect(controller.getOptionsJson(), {'sheet_index': 1});

      controller.decrementExcelSheetIndex();
      expect(controller.excelSheetIndex, 0);

      Get.delete<ToolExecutorController>();
    });

    test('8. ID Templates options & no-upload flow', () {
      final tool = allPlainscanTools.firstWhere((t) => t.slug == 'id-templates');
      final controller = Get.put(ToolExecutorController(tool: tool));

      expect(controller.isNoUploadTool(), isTrue);
      expect(controller.getExpectedExtension(), 'pdf');

      final options = controller.getOptionsJson();
      expect(options['company_name'], 'PlainScan Corp');
      expect(options['employee_name'], 'John Doe');
      expect(options['employee_id'], 'EMP-001');
      expect(options['logo_url'], isNotEmpty);
      expect(options['photo_url'], isNotEmpty);

      Get.delete<ToolExecutorController>();
    });

    test('9. Flatten PDF options & extension', () {
      final tool = allPlainscanTools.firstWhere((t) => t.slug == 'flatten-pdf');
      final controller = Get.put(ToolExecutorController(tool: tool));

      expect(controller.getExpectedExtension(), 'pdf');
      expect(controller.getOptionsJson(), isEmpty);

      Get.delete<ToolExecutorController>();
    });

    test('10. N-up PDF options & pages/orientation settings', () {
      final tool = allPlainscanTools.firstWhere((t) => t.slug == 'n-up-pdf');
      final controller = Get.put(ToolExecutorController(tool: tool));

      expect(controller.getExpectedExtension(), 'pdf');
      expect(controller.getOptionsJson(), {'n': 2, 'orientation': 'portrait'});

      controller.setNUpPages(4);
      controller.setNUpOrientation('landscape');
      expect(controller.getOptionsJson(), {'n': 4, 'orientation': 'landscape'});

      Get.delete<ToolExecutorController>();
    });

    test('11. PDF to Grayscale options & extension', () {
      final tool = allPlainscanTools.firstWhere((t) => t.slug == 'pdf-to-grayscale');
      final controller = Get.put(ToolExecutorController(tool: tool));

      expect(controller.getExpectedExtension(), 'pdf');
      expect(controller.getOptionsJson(), isEmpty);

      Get.delete<ToolExecutorController>();
    });

    test('12. Print Optimize PDF options & preset configurations', () {
      final tool = allPlainscanTools.firstWhere((t) => t.slug == 'print-optimize-pdf');
      final controller = Get.put(ToolExecutorController(tool: tool));

      expect(controller.getExpectedExtension(), 'pdf');
      expect(controller.getOptionsJson(), {
        'optimization_type': 'standard',
        'dpi': 150,
        'quality': 75,
        'grayscale': false,
      });

      controller.setPrintOptType('prepress');
      controller.setPrintOptDpi(300);
      controller.setPrintOptQuality(90);
      controller.togglePrintOptGrayscale(true);

      expect(controller.getOptionsJson(), {
        'optimization_type': 'prepress',
        'dpi': 300,
        'quality': 90,
        'grayscale': true,
      });

      Get.delete<ToolExecutorController>();
    });

    test('13. Repair PDF options & extension', () {
      final tool = allPlainscanTools.firstWhere((t) => t.slug == 'repair-pdf');
      final controller = Get.put(ToolExecutorController(tool: tool));

      expect(controller.getExpectedExtension(), 'pdf');
      expect(controller.getOptionsJson(), isEmpty);

      Get.delete<ToolExecutorController>();
    });

    test('14. Invoice Generator options, items & no-upload flow', () {
      final tool = allPlainscanTools.firstWhere((t) => t.slug == 'invoice-generator');
      final controller = Get.put(ToolExecutorController(tool: tool));

      expect(controller.isNoUploadTool(), isTrue);
      expect(controller.getExpectedExtension(), 'pdf');

      final options = controller.getOptionsJson();
      expect(options['invoice_number'], 'INV-2026-001');
      expect(options['currency'], 'USD');
      expect(options['tax_type'], 'tax');
      expect(options['discount'], 5.0);
      expect(options['shipping'], 15.0);
      expect(options['items'], isNotEmpty);

      // Test item addition and deletion
      controller.addInvoiceItem('Custom API Integration', 2, 75.0, 5.0);
      expect(controller.invoiceItems.length, 3);
      expect(controller.invoiceItems.last['description'], 'Custom API Integration');

      controller.removeInvoiceItem(2);
      expect(controller.invoiceItems.length, 2);

      Get.delete<ToolExecutorController>();
    });

    test('15. Crop PDF options & margin adjustments', () {
      final tool = allPlainscanTools.firstWhere((t) => t.slug == 'crop-pdf');
      final controller = Get.put(ToolExecutorController(tool: tool));

      expect(controller.getExpectedExtension(), 'pdf');
      expect(controller.getOptionsJson(), {
        'top': 50,
        'bottom': 50,
        'left': 30,
        'right': 30,
      });

      controller.setCropTop(60);
      controller.setCropBottom(70);
      controller.setCropLeft(40);
      controller.setCropRight(40);

      expect(controller.getOptionsJson(), {
        'top': 60,
        'bottom': 70,
        'left': 40,
        'right': 40,
      });

      Get.delete<ToolExecutorController>();
    });

    test('16. AI Email Writer options, tones & no-upload flow', () {
      final tool = allPlainscanTools.firstWhere((t) => t.slug == 'ai-email-writer');
      final controller = Get.put(ToolExecutorController(tool: tool));

      expect(controller.isNoUploadTool(), isTrue);
      expect(controller.getExpectedExtension(), 'txt');

      controller.emailSubjectController.text = 'Meeting Request';
      controller.emailContextController.text = 'Discuss quarterly roadmaps';
      controller.setEmailTone('professional');

      expect(controller.getOptionsJson(), {
        'subject': 'Meeting Request',
        'context': 'Discuss quarterly roadmaps',
        'tone': 'professional',
      });

      controller.setEmailTone('casual');
      expect(controller.getOptionsJson()['tone'], 'casual');

      controller.setEmailTone('friendly');
      expect(controller.getOptionsJson()['tone'], 'friendly');

      // Extended fields: recipient, purpose, key_points, sender_name
      controller.emailRecipientController.text = 'HR Manager';
      controller.emailPurposeController.text = 'Follow up on interview';
      controller.emailKeyPointsController.text = 'Thank them, ask about next steps';
      controller.emailSenderNameController.text = 'Abhinav';
      controller.setEmailTone('Professional');

      final fullOptions = controller.getOptionsJson();
      expect(fullOptions['recipient'], 'HR Manager');
      expect(fullOptions['purpose'], 'Follow up on interview');
      expect(fullOptions['key_points'], 'Thank them, ask about next steps');
      expect(fullOptions['sender_name'], 'Abhinav');
      expect(fullOptions['subject'], 'Follow up on interview');

      // Test resetEmailWriter()
      controller.resetEmailWriter();
      expect(controller.emailRecipientController.text, isEmpty);
      expect(controller.emailPurposeController.text, isEmpty);
      expect(controller.emailKeyPointsController.text, isEmpty);
      expect(controller.emailSenderNameController.text, isEmpty);
      expect(controller.currentStep, 'idle');

      Get.delete<ToolExecutorController>();
    });

    test('17. AI Proofread options & dual mode support', () {
      final tool = allPlainscanTools.firstWhere((t) => t.slug == 'ai-proofread');
      final controller = Get.put(ToolExecutorController(tool: tool));

      expect(controller.isTextOptionSupported(), isTrue);
      expect(controller.getExpectedExtension(), 'docx');

      // Raw text mode
      controller.useRawText = true;
      controller.rawTextController.text = 'Text to proofread and correct.';
      expect(controller.getOptionsJson(), {
        'text': 'Text to proofread and correct.',
      });

      // File upload mode
      controller.useRawText = false;
      expect(controller.getOptionsJson(), isEmpty);

      // Dedicated Proofreader UI options
      controller.proofreadTextController.text = 'This is a test text with teh typo.';
      controller.setProofreadFocusArea('Grammar & Spelling');
      expect(controller.getOptionsJson(), {
        'text': 'This is a test text with teh typo.',
        'focus_area': 'Grammar & Spelling',
      });

      // Test resetProofreader()
      controller.resetProofreader();
      expect(controller.proofreadTextController.text, isEmpty);
      expect(controller.proofreadFocusArea, 'All');
      expect(controller.currentStep, 'idle');

      Get.delete<ToolExecutorController>();
    });

    test('18. AI Citation Generator options & citation styles', () {
      final tool = allPlainscanTools.firstWhere((t) => t.slug == 'ai-citation');
      final controller = Get.put(ToolExecutorController(tool: tool));

      expect(controller.isNoUploadTool(), isTrue);
      expect(controller.getExpectedExtension(), 'txt');

      controller.citationSourceController.text = 'Smith, J. (2024). AI Horizons.';
      controller.setCitationStyle('APA');

      expect(controller.getOptionsJson(), {
        'text': 'Smith, J. (2024). AI Horizons.',
        'style': 'APA',
      });

      controller.setCitationStyle('MLA');
      expect(controller.getOptionsJson()['style'], 'MLA');

      controller.setCitationStyle('Chicago');
      expect(controller.getOptionsJson()['style'], 'Chicago');

      controller.setCitationStyle('Harvard');
      expect(controller.getOptionsJson()['style'], 'Harvard');

      // Structured citation settings
      controller.citationTitleController.text = 'Artificial Intelligence in Education';
      controller.citationAuthorsController.text = 'Smith, J.';
      controller.citationYearController.text = '2005';
      controller.citationUrlController.text = 'https://example.com/ai';
      controller.citationDoiController.text = '10.1000/xyz123';
      controller.citationPublisherController.text = 'Tech Press';
      controller.citationJournalController.text = 'Journal of Technology';
      controller.citationVolumeController.text = '7';
      controller.citationPagesController.text = '25-40';
      controller.setCitationStyle('APA');

      final structuredOpts = controller.getOptionsJson();
      expect(structuredOpts['style'], 'APA');
      expect(structuredOpts['title'], 'Artificial Intelligence in Education');
      expect(structuredOpts['authors'], 'Smith, J.');
      expect(structuredOpts['year'], '2005');
      expect(structuredOpts['url'], 'https://example.com/ai');
      expect(structuredOpts['doi'], '10.1000/xyz123');
      expect(structuredOpts['publisher'], 'Tech Press');
      expect(structuredOpts['journal'], 'Journal of Technology');
      expect(structuredOpts['volume'], '7');
      expect(structuredOpts['pages'], '25-40');

      // Test resetCitationGenerator()
      controller.resetCitationGenerator();
      expect(controller.citationTitleController.text, isEmpty);
      expect(controller.citationAuthorsController.text, isEmpty);
      expect(controller.citationYearController.text, isEmpty);
      expect(controller.citationUrlController.text, isEmpty);
      expect(controller.citationDoiController.text, isEmpty);
      expect(controller.citationPublisherController.text, isEmpty);
      expect(controller.citationJournalController.text, isEmpty);
      expect(controller.citationVolumeController.text, isEmpty);
      expect(controller.citationPagesController.text, isEmpty);
      expect(controller.citationStyle, 'APA');
      expect(controller.currentStep, 'idle');

      Get.delete<ToolExecutorController>();
    });

    test('19. AI Flashcards options & count settings', () {
      final tool = allPlainscanTools.firstWhere((t) => t.slug == 'ai-flashcards');
      final controller = Get.put(ToolExecutorController(tool: tool));

      expect(controller.isTextOptionSupported(), isTrue);
      expect(controller.getExpectedExtension(), 'json');

      controller.setFlashcardsCount(15);

      // Raw text mode
      controller.useRawText = true;
      controller.rawTextController.text = 'Biology cell respiration summary.';
      expect(controller.getOptionsJson(), {
        'count': 15,
        'text': 'Biology cell respiration summary.',
      });

      // File mode
      controller.useRawText = false;
      expect(controller.getOptionsJson(), {
        'count': 15,
      });

      // Link mode
      controller.setFlashcardInputMode('link');
      controller.flashcardUrlController.text = 'https://example.com/guide';
      expect(controller.getOptionsJson(), {
        'count': 15,
        'url': 'https://example.com/guide',
      });

      // Paste text mode
      controller.setFlashcardInputMode('text');
      controller.flashcardTextController.text = 'WhatsApp Business Account Setup Guide notes';
      expect(controller.getOptionsJson(), {
        'count': 15,
        'text': 'WhatsApp Business Account Setup Guide notes',
      });

      // Test resetFlashcardGenerator()
      controller.resetFlashcardGenerator();
      expect(controller.flashcardUrlController.text, isEmpty);
      expect(controller.flashcardTextController.text, isEmpty);
      expect(controller.flashcardsCount, 10);
      expect(controller.flashcardInputMode, 'file');
      expect(controller.currentStep, 'idle');

      Get.delete<ToolExecutorController>();
    });

    test('20. AI Quiz Generator options, count & difficulty', () {
      final tool = allPlainscanTools.firstWhere((t) => t.slug == 'ai-quiz');
      final controller = Get.put(ToolExecutorController(tool: tool));

      expect(controller.isTextOptionSupported(), isTrue);
      expect(controller.getExpectedExtension(), 'json');

      controller.setQuizCount(10);
      controller.setQuizDifficulty('hard');

      // Link mode
      controller.setQuizInputMode('link');
      controller.quizUrlController.text = 'https://example.com/quiz-article';
      expect(controller.getOptionsJson(), {
        'count': 10,
        'difficulty': 'hard',
        'url': 'https://example.com/quiz-article',
      });

      // Text mode
      controller.setQuizInputMode('text');
      controller.quizTextController.text = 'Biology cell structure notes.';
      expect(controller.getOptionsJson(), {
        'count': 10,
        'difficulty': 'hard',
        'text': 'Biology cell structure notes.',
      });

      // Raw text mode (backward compatibility)
      controller.setQuizInputMode('file');
      controller.useRawText = true;
      controller.rawTextController.text = 'World History Chapter 4.';
      expect(controller.getOptionsJson(), {
        'count': 10,
        'difficulty': 'hard',
        'text': 'World History Chapter 4.',
      });

      // File mode without raw text
      controller.useRawText = false;
      expect(controller.getOptionsJson(), {
        'count': 10,
        'difficulty': 'hard',
      });

      // Test reset
      controller.resetQuizGenerator();
      expect(controller.quizInputMode, 'file');
      expect(controller.quizCount, 10);
      expect(controller.quizDifficulty, 'medium');
      expect(controller.quizUrlController.text, isEmpty);
      expect(controller.quizTextController.text, isEmpty);

      Get.delete<ToolExecutorController>();
    });

    test('21. Chat with PDF question options', () {
      final tool = allPlainscanTools.firstWhere((t) => t.slug == 'chat-with-pdf');
      final controller = Get.put(ToolExecutorController(tool: tool));

      expect(controller.getExpectedExtension(), 'txt');

      controller.chatPdfQuestionController.text = 'What is the quarterly growth?';
      expect(controller.getOptionsJson(), {
        'question': 'What is the quarterly growth?',
      });

      Get.delete<ToolExecutorController>();
    });

    test('22. ATS Resume Scanner options & job description', () {
      final tool = allPlainscanTools.firstWhere((t) => t.slug == 'ats-scanner');
      final controller = Get.put(ToolExecutorController(tool: tool));

      expect(controller.getExpectedExtension(), 'json');

      controller.atsJobDescriptionController.text = 'Senior Flutter Engineer with 5 years experience.';
      expect(controller.getOptionsJson(), {
        'job_description': 'Senior Flutter Engineer with 5 years experience.',
      });

      Get.delete<ToolExecutorController>();
    });

    test('23. Word Counter & Character Counter options', () {
      final wordTool = allPlainscanTools.firstWhere((t) => t.slug == 'word-counter');
      final wordController = Get.put(ToolExecutorController(tool: wordTool));

      expect(wordController.isNoUploadTool(), isTrue);
      expect(wordController.getExpectedExtension(), 'json');

      wordController.counterTextController.text = 'One two three four five.';
      expect(wordController.getOptionsJson(), {
        'text': 'One two three four five.',
      });

      Get.delete<ToolExecutorController>();

      final charTool = allPlainscanTools.firstWhere((t) => t.slug == 'character-counter');
      final charController = Get.put(ToolExecutorController(tool: charTool));

      expect(charController.isNoUploadTool(), isTrue);
      expect(charController.getExpectedExtension(), 'json');

      charController.counterTextController.text = 'Hello World';
      expect(charController.getOptionsJson(), {
        'text': 'Hello World',
      });

      Get.delete<ToolExecutorController>();
    });

    test('24. Image to Base64 & Base64 to Image options & extensions', () {
      final imgToBase64 = allPlainscanTools.firstWhere((t) => t.slug == 'image-to-base64');
      final imgController = Get.put(ToolExecutorController(tool: imgToBase64));

      expect(imgController.getExpectedExtension(), 'txt');
      expect(imgController.getOptionsJson(), isEmpty);

      Get.delete<ToolExecutorController>();

      final base64ToImg = allPlainscanTools.firstWhere((t) => t.slug == 'base64-to-image');
      final base64Controller = Get.put(ToolExecutorController(tool: base64ToImg));

      expect(base64Controller.isNoUploadTool(), isTrue);
      expect(base64Controller.getExpectedExtension(), 'png');

      base64Controller.base64InputController.text = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAAB...';
      expect(base64Controller.getOptionsJson(), {
        'base64_string': 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAAB...',
      });

      Get.delete<ToolExecutorController>();
    });

    test('25. Favicon Generator options & extension', () {
      final tool = allPlainscanTools.firstWhere((t) => t.slug == 'favicon-generator');
      final controller = Get.put(ToolExecutorController(tool: tool));

      expect(controller.getExpectedExtension(), 'ico');
      expect(controller.getOptionsJson(), isEmpty);

      Get.delete<ToolExecutorController>();
    });

    test('26. Metadata Editor, Remove Metadata & Read Metadata', () {
      final editorTool = allPlainscanTools.firstWhere((t) => t.slug == 'metadata-editor');
      final editorController = Get.put(ToolExecutorController(tool: editorTool));

      editorController.setMetadataAction('strip');
      expect(editorController.getExpectedExtension(), 'jpg');
      expect(editorController.getOptionsJson(), {'action': 'strip'});

      editorController.setMetadataAction('view');
      expect(editorController.getExpectedExtension(), 'json');
      expect(editorController.getOptionsJson(), {'action': 'view'});

      Get.delete<ToolExecutorController>();

      final removeTool = allPlainscanTools.firstWhere((t) => t.slug == 'remove-metadata');
      final removeController = Get.put(ToolExecutorController(tool: removeTool));

      expect(removeController.getExpectedExtension(), 'pdf');
      expect(removeController.getOptionsJson(), isEmpty);

      Get.delete<ToolExecutorController>();

      final readTool = allPlainscanTools.firstWhere((t) => t.slug == 'read-metadata');
      final readController = Get.put(ToolExecutorController(tool: readTool));

      expect(readController.getExpectedExtension(), 'json');
      expect(readController.getOptionsJson(), isEmpty);

      Get.delete<ToolExecutorController>();
    });
  });
}

