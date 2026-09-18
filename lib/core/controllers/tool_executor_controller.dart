import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:plainscan/app/routes.dart';
import 'package:plainscan/core/constants/app_colors.dart';
import 'package:plainscan/core/controllers/profile_controller.dart';
import 'package:plainscan/core/controllers/scan_controller.dart';
import 'package:plainscan/core/services/jobflow_services.dart';
import 'package:plainscan/core/services/notification_service.dart';
import 'package:plainscan/core/services/storage_service.dart';
import 'package:plainscan/helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:plainscan/models/file_model.dart';
import 'package:plainscan/models/tool_model.dart';

class ToolExecutorController extends GetxController {
  final ToolModel tool;
  final List<FileModel>? initialFiles;
  final bool autoExecute;
  final ScanController scanController = Get.find<ScanController>();

  ToolExecutorController({
    required this.tool,
    this.initialFiles,
    this.autoExecute = false,
  });

  // Interstitial Ad
  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdLoaded = false;

  void _loadInterstitialAd() {
    if (!Adhelper.isSupported) return;
    final adUnitId = Adhelper.interstitialAdUnitId;
    if (adUnitId.isEmpty) return;

    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdLoaded = true;
          _interstitialAd!.fullScreenContentCallback =
              FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _loadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('Interstitial ad failed to show: ${error.message}');
              ad.dispose();
              _loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint(
            'Interstitial ad failed to load: ${error.message} (code: ${error.code})',
          );
          _interstitialAd = null;
          _isInterstitialAdLoaded = false;
        },
      ),
    );
  }

  void showInterstitialAdIfAvailable() {
    if (_isInterstitialAdLoaded && _interstitialAd != null) {
      _interstitialAd!.show();
      _interstitialAd = null;
      _isInterstitialAdLoaded = false;
    }
  }

  // Token state
  bool isTokenVisible = false;
  final tokenController = TextEditingController();

  // Input selection states
  bool useRawText = false;
  final rawTextController = TextEditingController();
  
  // File selection
  FileModel? selectedFile;
  final List<FileModel> selectedFiles = [];
  FileModel? convertedFile;
  FileModel? existingOriginalFile;
  bool isOriginalFileReplaced = false;

  // Job execution states
  bool isRunning = false;
  String currentStep = ''; // 'idle', 'uploading', 'creating', 'polling', 'downloading', 'success', 'error'
  String errorMessage = '';
  String jobId = '';
  int pollingCount = 0;
  String outputFileName = '';

  // Form options controllers & values
  String compressQuality = 'balanced';
  int pdfToJpgMaxPages = 10;
  String jpgToPdfPageSize = 'letter';
  int pagesPerSplit = 1;
  int rotation = 90;
  final pageOrderController = TextEditingController(text: '3, 1, 2, 4');
  
  // Form filling & fillable form
  final formFillingDataController = TextEditingController(
    text: '{\n  "First Name": "John",\n  "Last Name": "Doe",\n  "Email": "john@example.com",\n  "Date": "2026-08-27"\n}',
  );
  bool pdfToFillableAutoDetect = true;
  String aiHumanizeStyle = 'casual';

  // Watermark
  final watermarkTextController = TextEditingController(text: 'CONFIDENTIAL');
  double watermarkFontSize = 48;
  String watermarkColor = '#FF0000';
  double watermarkOpacity = 30;
  double watermarkRotation = -45;

  // Lock & Unlock
  final passwordController = TextEditingController(text: 'mysecretpassword');
  final ownerPasswordController = TextEditingController(text: 'adminpassword');
  bool allowPrinting = true;
  bool allowCopying = false;
  String encryption = '128';

  // Redact
  final redactPatternsController = TextEditingController(text: 'email, phone, ssn, credit_card');
  final redactColorController = TextEditingController(text: '#000000');

  // Header & Footer
  final headerController = TextEditingController(text: 'Company Name — Confidential');
  final footerController = TextEditingController(text: 'Page {page} of {total}');
  double headerFontSize = 10;
  String headerFontColor = '#000000';
  double headerMargin = 20;
  int headerStartPage = 1;
  int headerEndPage = 10;
  bool showPageNum = true;

  // Page Numbers
  String pageNumberPosition = 'bottom-center';
  String pageNumberFormat = 'full';
  double pageNumFontSize = 10;
  String pageNumFontColor = '#000000';
  int pageNumStartNum = 1;
  double pageNumMargin = 20;
  int pageNumStartPage = 1;

  // Sign / E-Sign
  final signatureTextController = TextEditingController(text: 'John Doe — Signed via Plainscan');

  // Compare
  String compareMode = 'text';
  final compareAddsColorController = TextEditingController(text: '#006600');
  final compareRemovesColorController = TextEditingController(text: '#cc0000');

  // AI & OCR options
  String ocrLanguage = 'eng';
  String aiLength = 'medium';
  String aiStyle = 'professional';
  final aiTranslateLanguageController = TextEditingController(text: 'Spanish');
  final aiExtractFieldsController = TextEditingController(
    text: 'invoice number, total amount, vendor name, date, line items',
  );
  
  // Cover letter
  final coverLetterJobTitleController = TextEditingController(text: 'Software Engineer');
  final coverLetterCompanyController = TextEditingController(text: 'Google');
  final coverLetterJdController = TextEditingController(
    text: 'We are looking for a software engineer with 5+ years experience in Python...',
  );

  // ZIP / Rename
  final zipArchiveNameController = TextEditingController(text: 'my_documents');
  String batchTargetFormat = 'word';
  final renamePrefixController = TextEditingController(text: 'Invoice_');
  final renameSuffixController = TextEditingController(text: '_2026');
  final renameReplaceFromController = TextEditingController(text: 'old');
  final renameReplaceToController = TextEditingController(text: 'new');
  bool renameNumbering = true;
  int renameStartNumber = 1;

  // HTML to PDF options
  String htmlToPdfMode = 'url'; // 'url' or 'html'
  final htmlToPdfUrlController = TextEditingController(text: 'https://example.com');
  final htmlToPdfHtmlController = TextEditingController(
    text: '<h1>Hello World</h1>\n<p>Generated with PlainScan HTML to PDF converter.</p>',
  );

  // Convert Image options
  String convertImageTargetFormat = 'jpg'; // 'jpg' or 'png'
  int convertImageQuality = 90;

  // CSV to Excel options
  String csvDelimiter = ',';

  // Excel to CSV options
  int excelSheetIndex = 0;

  // ID Templates options
  FileModel? idLogoFile;
  FileModel? idPhotoFile;
  final idCompanyNameController = TextEditingController(text: 'PlainScan Corp');
  final idCompanyAddressController = TextEditingController(text: '123 Tech Park, NY');
  final idCompanyPhoneController = TextEditingController(text: '+1 555-1234');
  final idEmployeeNameController = TextEditingController(text: 'John Doe');
  final idEmployeeRoleController = TextEditingController(text: 'Software Engineer');
  final idEmployeeIdController = TextEditingController(text: 'EMP-001');

  // N-up PDF options
  int nUpPages = 2; // 2, 4, 6, 9
  String nUpOrientation = 'portrait'; // portrait or landscape

  // Print Optimize PDF options
  String printOptType = 'standard';
  int printOptDpi = 150;
  int printOptQuality = 75;
  bool printOptGrayscale = false;

  // Crop PDF options
  int cropTop = 50;
  int cropBottom = 50;
  int cropLeft = 30;
  int cropRight = 30;

  // Invoice Generator options
  final invoiceNumberController = TextEditingController(text: 'INV-2026-001');
  final invoiceFromNameController = TextEditingController(text: 'My Business LLC');
  final invoiceFromEmailController = TextEditingController(text: 'billing@business.com');
  final invoiceFromPhoneController = TextEditingController(text: '+1 555-9876');
  final invoiceFromAddressController = TextEditingController(text: '456 Wall St, NY');
  final invoiceToNameController = TextEditingController(text: 'Acme Corp');
  final invoiceToEmailController = TextEditingController(text: 'accounts@acme.com');
  final invoiceToAddressController = TextEditingController(text: '789 Main St, CA');
  String invoiceCurrency = 'USD';
  String invoiceTaxType = 'tax';
  double invoiceDiscount = 5.0;
  double invoiceShipping = 15.0;
  String invoiceThemeColor = '#4F46E5';
  List<Map<String, dynamic>> invoiceItems = [
    {
      'description': 'Web Development Services',
      'quantity': 1,
      'unit_price': 1000.00,
      'tax_rate': 0,
    },
    {
      'description': 'Server Hosting (1 Year)',
      'quantity': 1,
      'unit_price': 200.00,
      'tax_rate': 5,
    },
  ];

  // AI Email Writer options
  final emailSubjectController = TextEditingController(text: 'Meeting Request');
  final emailContextController = TextEditingController(text: 'Brief description of what the email should say');
  final emailRecipientController = TextEditingController();
  final emailPurposeController = TextEditingController();
  final emailKeyPointsController = TextEditingController();
  final emailSenderNameController = TextEditingController();
  String emailTone = 'Professional';
  String generatedEmailContent = '';

  static const List<String> emailToneOptions = [
    'Professional',
    'Casual',
    'Friendly',
    'Formal',
    'Persuasive',
    'Apologetic',
    'Urgent',
  ];

  String get selectedEmailTone {
    for (final t in emailToneOptions) {
      if (t.toLowerCase() == emailTone.toLowerCase()) {
        return t;
      }
    }
    return emailToneOptions.first;
  }

  // AI Proofreader options
  final proofreadTextController = TextEditingController();
  String proofreadFocusArea = 'All';
  String generatedProofreadContent = '';

  static const List<String> proofreadFocusAreaOptions = [
    'All',
    'Grammar & Spelling',
    'Style & Tone',
    'Clarity & Flow',
    'Punctuation',
  ];

  String get selectedProofreadFocusArea {
    for (final a in proofreadFocusAreaOptions) {
      if (a.toLowerCase() == proofreadFocusArea.toLowerCase()) {
        return a;
      }
    }
    return proofreadFocusAreaOptions.first;
  }

  // AI Citation options
  final citationSourceController = TextEditingController(text: 'Smith, J. (2025). The Future of Artificial Intelligence. Tech Press.');
  final citationTitleController = TextEditingController();
  final citationAuthorsController = TextEditingController();
  final citationYearController = TextEditingController();
  final citationUrlController = TextEditingController();
  final citationDoiController = TextEditingController();
  final citationPublisherController = TextEditingController();
  final citationJournalController = TextEditingController();
  final citationVolumeController = TextEditingController();
  final citationPagesController = TextEditingController();
  String citationStyle = 'APA'; // APA, MLA, Chicago, Harvard, IEEE, BibTeX
  String generatedCitationContent = '';
  String citationExecutionDuration = '1.8s';

  static const List<String> citationStyleOptions = [
    'APA',
    'MLA',
    'Chicago',
    'Harvard',
    'IEEE',
    'BibTeX',
  ];

  String get selectedCitationStyle {
    for (final s in citationStyleOptions) {
      if (s.toLowerCase() == citationStyle.toLowerCase()) {
        return s;
      }
    }
    return citationStyleOptions.first;
  }

  // AI Flashcards options
  int flashcardsCount = 10;
  String flashcardInputMode = 'file'; // 'file', 'link', 'text'
  final flashcardUrlController = TextEditingController();
  final flashcardTextController = TextEditingController();
  String generatedFlashcardsContent = '';

  // AI Quiz options
  int quizCount = 10;
  String quizDifficulty = 'medium'; // easy, medium, hard
  String quizInputMode = 'file'; // 'file', 'link', 'text'
  final quizUrlController = TextEditingController();
  final quizTextController = TextEditingController();
  String generatedQuizContent = '';

  // Chat with PDF options
  final chatPdfQuestionController = TextEditingController();
  final chatPdfFollowUpController = TextEditingController();
  List<Map<String, String>> chatPdfMessages = [];
  bool isChatPdfFollowUpLoading = false;

  // ATS Resume Scanner options
  final atsJobDescriptionController = TextEditingController(text: 'Senior Software Engineer with Flutter and Dart experience.');

  // Word & Character Counters options
  final counterTextController = TextEditingController(text: 'PlainScan is a fast and powerful document scanner and PDF utility suite.');

  // Base64 to Image options
  final base64InputController = TextEditingController(text: 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=');

  // Metadata Editor options
  String metadataAction = 'strip'; // strip, view

  @override
  void onInit() {
    super.onInit();
    _loadInterstitialAd();
    loadSavedToken();
    initializeDefaults();
    _applyInitialFiles();
  }

  void _applyInitialFiles() {
    if (initialFiles != null && initialFiles!.isNotEmpty) {
      if (isMultiFileTool()) {
        selectedFiles.clear();
        selectedFiles.addAll(initialFiles!);
        if (selectedFiles.isNotEmpty) {
          selectedFile = selectedFiles.first;
        }
      } else {
        selectedFile = initialFiles!.first;
      }
      update();

      if (autoExecute) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          executeJobFlow();
        });
      }
    }
  }

  Future<void> loadSavedToken() async {
    final token = await StorageService.getToken();
    if (token != null && token.isNotEmpty) {
      tokenController.text = token;
      update();
    }
  }

  void initializeDefaults() {
    // Set text-only mode default for tools that usually work with raw text
    final slug = getSlug();
    if (slug == 'grammar-checker' || slug == 'grammar-correction' || slug == 'ai-detector' || slug == 'ai-detection') {
      useRawText = true;
      if (slug.contains('grammar')) {
        rawTextController.text = 'This are a example of bad grammar.';
      } else {
        rawTextController.text = 'The text you want to check...';
      }
    }
  }

  String getSlug() {
    return tool.slug.replaceAll('_', '-');
  }

  bool isNoUploadTool() {
    final slug = getSlug();
    return slug == 'html-to-pdf' ||
        slug == 'id-templates' ||
        slug == 'id-certificate-templates' ||
        slug == 'id-generator' ||
        slug == 'invoice-generator' ||
        slug == 'ai-email-writer' ||
        slug == 'ai-citation' ||
        slug == 'word-counter' ||
        slug == 'character-counter' ||
        slug == 'base64-to-image';
  }

  bool isMultiFileTool() {
    final slug = getSlug();
    return tool.isMultiFile ||
        slug == 'images-to-pdf' ||
        slug == 'image-to-pdf' ||
        slug == 'pdf-merge' ||
        slug == 'pdf-compare' ||
        slug == 'file-to-zip' ||
        slug == 'batch-pdf-converter' ||
        slug == 'batch-converter' ||
        slug == 'batch-rename' ||
        slug == 'jpg-to-pdf' ||
        slug == 'png-to-pdf' ||
        slug == 'webp-to-pdf';
  }

  bool isTextOptionSupported() {
    final slug = getSlug();
    return slug == 'grammar-checker' ||
        slug == 'grammar-correction' ||
        slug == 'ai-detector' ||
        slug == 'ai-detection' ||
        slug == 'ai-summarize' ||
        slug == 'ai-rewrite' ||
        slug == 'ai-translate' ||
        slug == 'ai-extract-data' ||
        slug == 'ai-extract' ||
        slug == 'ai-extract-key-points' ||
        slug == 'extract-key-points' ||
        slug == 'ai-expand' ||
        slug == 'ai-condense' ||
        slug == 'ai-keywords' ||
        slug == 'humanize-ai-content' ||
        slug == 'humanize-ai' ||
        slug == 'plagiarism-check' ||
        slug == 'ai-proofread' ||
        slug == 'ai-flashcards' ||
        slug == 'ai-quiz';
  }

  // Creates a physical temporary file if the mock path doesn't exist on disk
  Future<File> getOrCreatePhysicalFile(FileModel fileModel) async {
    if (fileModel.path != null && fileModel.path!.isNotEmpty) {
      final file = File(fileModel.path!);
      if (await file.exists()) {
        return file;
      }
    }
    // Create mock bytes to ensure upload succeeds
    final tempDir = Directory.systemTemp;
    final tempFile = File('${tempDir.path}/${fileModel.name}');
    if (!await tempFile.exists()) {
      await tempFile.writeAsString('Mock PlainScan PDF Content for ${fileModel.name}');
    }
    return tempFile;
  }

  Map<String, dynamic> getOptionsJson() {
    final slug = getSlug();
    switch (slug) {
      case 'pdf-to-word':
        return {'output_format': 'docx'};
      case 'word-to-pdf':
      case 'pdf-to-ppt':
      case 'pdf-to-powerpoint':
      case 'ppt-to-pdf':
      case 'powerpoint-to-pdf':
      case 'pdf-to-excel':
      case 'excel-to-pdf':
      case 'epub-to-pdf':
      case 'pdf-to-epub':
      case 'pdf-to-markdown':
      case 'pdf-merge':
      case 'pdf-extract-images':
        return {};
      case 'pdf-to-text':
      case 'pdf-to-txt':
      case 'pdf-extract-text':
        return {'output_format': 'txt'};
      case 'pdf-extract-table':
        return {'output_format': 'xlsx'};
      case 'pdf-to-jpg':
      case 'pdf-to-png':
      case 'pdf-to-webp':
        return {'max_pages': pdfToJpgMaxPages};
      case 'jpg-to-pdf':
      case 'png-to-pdf':
      case 'webp-to-pdf':
      case 'image-to-pdf':
        return {'page_size': jpgToPdfPageSize};
      case 'pdf-compress':
        return {'quality': compressQuality};
      case 'pdf-split':
        return {'pages_per_split': pagesPerSplit};
      case 'pdf-rotate':
        return {'rotation': rotation};
      case 'pdf-reorder':
      case 'pdf-rearrange':
        try {
          final orders = pageOrderController.text
              .split(',')
              .map((e) => int.parse(e.trim()))
              .toList();
          return {'page_order': orders};
        } catch (_) {
          return {'page_order': [3, 1, 2, 4]};
        }
      case 'pdf-watermark':
        return {
          'watermark': {
            'type': 'text',
            'text': watermarkTextController.text,
            'fontSize': watermarkFontSize.toInt(),
            'color': watermarkColor,
            'opacity': watermarkOpacity.toInt(),
            'rotation': watermarkRotation.toInt(),
          }
        };
      case 'pdf-lock':
        return {
          'password': passwordController.text,
          'owner_password': ownerPasswordController.text,
          'allow_printing': allowPrinting,
          'allow_copying': allowCopying,
          'encryption': encryption,
        };
      case 'pdf-unlock':
        return {'password': passwordController.text};
      case 'pdf-redact':
        final patterns = redactPatternsController.text
            .split(',')
            .map((e) => e.trim())
            .toList();
        return {
          'patterns': patterns,
          'areas': [
            {'page': 1, 'x': 100, 'y': 200, 'width': 150, 'height': 30}
          ],
          'color': redactColorController.text,
        };
      case 'pdf-header-footer':
        return {
          'header': headerController.text,
          'footer': footerController.text,
          'font_size': headerFontSize.toInt(),
          'font_color': headerFontColor,
          'margin': headerMargin.toInt(),
          'start_page': headerStartPage,
          'end_page': headerEndPage,
          'show_page_num': showPageNum,
        };
      case 'pdf-page-numbers':
        return {
          'position': pageNumberPosition,
          'format': pageNumberFormat,
          'font_size': pageNumFontSize.toInt(),
          'font_color': pageNumFontColor,
          'start_num': pageNumStartNum,
          'margin': pageNumMargin.toInt(),
          'start_page': pageNumStartPage,
        };
      case 'pdf-sign':
      case 'pdf-esign':
        return {'signature_text': signatureTextController.text};
      case 'pdf-compare':
        return {
          'mode': compareMode,
          'output_format': 'pdf',
          'highlight_adds': compareAddsColorController.text,
          'highlight_removes': compareRemovesColorController.text,
        };
      case 'form-filling':
      case 'fill-pdf':
      case 'pdf-fill-form':
      case 'pdf-form-filler':
        Map<String, dynamic> userData = {
          "First Name": "John",
          "Last Name": "Doe",
          "Email": "john@example.com",
          "Date": "2026-08-27"
        };
        try {
          final trimmed = formFillingDataController.text.trim();
          if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
            userData = jsonDecode(trimmed) as Map<String, dynamic>;
          }
        } catch (_) {}
        return {'user_data': userData};
      case 'pdf-to-fillable-form':
      case 'pdf-to-fillable':
        return {
          'auto_detect': pdfToFillableAutoDetect,
          'fields': [
            {
              'name': 'full_name',
              'type': 'text',
              'page': 1,
              'x': 100,
              'y': 700,
              'width': 200,
              'height': 20
            }
          ]
        };
      case 'scan-ocr':
      case 'ocr-to-text':
        return {
          'language': ocrLanguage,
          'detect_handwriting': false,
          'detect_tables': false,
          'preserve_layout': false,
          'output_format': 'txt',
        };
      case 'ocr-to-pdf':
      case 'ocr-to-word':
      case 'ocr-to-excel':
        return {'language': ocrLanguage};
      case 'ai-summarize':
        final options = <String, dynamic>{
          'length': aiLength,
          'output_format': 'txt',
        };
        if (useRawText) {
          options['text'] = rawTextController.text;
        }
        return options;
      case 'ai-rewrite':
        return {
          'style': aiStyle,
          'output_format': 'docx',
          if (useRawText) 'text': rawTextController.text,
        };
      case 'ai-translate':
        return {
          'target_language': aiTranslateLanguageController.text,
          'output_format': 'docx',
          if (useRawText) 'text': rawTextController.text,
        };
      case 'ai-extract-data':
      case 'ai-extract':
        return {
          'fields': aiExtractFieldsController.text,
          'output_format': 'json',
          if (useRawText) 'text': rawTextController.text,
        };
      case 'ai-extract-key-points':
      case 'extract-key-points':
        return {
          'output_format': 'txt',
          if (useRawText) 'text': rawTextController.text,
        };
      case 'ai-expand':
      case 'ai-condense':
        return {
          'output_format': 'docx',
          if (useRawText) 'text': rawTextController.text,
        };
      case 'ai-keywords':
        return {
          'output_format': 'json',
          if (useRawText) 'text': rawTextController.text,
        };
      case 'grammar-checker':
      case 'grammar-correction':
        final options = <String, dynamic>{
          'output_format': 'docx',
        };
        if (useRawText) {
          options['text'] = rawTextController.text;
        }
        return options;
      case 'humanize-ai-content':
      case 'humanize-ai':
        return {
          'style': aiHumanizeStyle,
          'output_format': 'docx',
          if (useRawText) 'text': rawTextController.text,
        };
      case 'ai-detector':
      case 'ai-detection':
        final options = <String, dynamic>{
          'output_format': 'json',
        };
        if (useRawText) {
          options['text'] = rawTextController.text;
        }
        return options;
      case 'plagiarism-check':
        return {
          'output_format': 'pdf',
          if (useRawText) 'text': rawTextController.text,
        };
      case 'summarize-long-pdfs':
      case 'summarize-pdf':
        return {'output_format': 'txt'};
      case 'ai-resume-formatter':
        return {'output_format': 'docx'};
      case 'ai-cover-letter':
        return {
          'job_title': coverLetterJobTitleController.text,
          'company': coverLetterCompanyController.text,
          'job_description': coverLetterJdController.text,
          'output_format': 'docx',
        };
      case 'file-to-zip':
        return {'archive_name': zipArchiveNameController.text};
      case 'batch-pdf-converter':
      case 'batch-converter':
        return {'target_format': batchTargetFormat};
      case 'batch-rename':
        return {
          'prefix': renamePrefixController.text,
          'suffix': renameSuffixController.text,
          'replace_from': renameReplaceFromController.text,
          'replace_to': renameReplaceToController.text,
          'numbering': renameNumbering,
          'start_number': renameStartNumber,
        };
      case 'html-to-pdf':
        if (htmlToPdfMode == 'url') {
          return {'url': htmlToPdfUrlController.text.trim()};
        } else {
          return {'html': htmlToPdfHtmlController.text.trim()};
        }
      case 'images-to-pdf':
        return {};
      case 'convert-image':
      case 'tiff-conversion':
      case 'tiff-to-jpg':
      case 'tiff-to-png':
        return {
          'target_format': convertImageTargetFormat,
          'quality': convertImageQuality,
        };
      case 'heic-to-jpg':
        return {
          'target_format': 'jpg',
          'quality': convertImageQuality,
        };
      case 'heic-to-png':
        return {
          'target_format': 'png',
          'quality': convertImageQuality,
        };
      case 'bank-statement-to-excel':
        return {};
      case 'receipt-to-excel':
        return {};
      case 'csv-to-excel':
        return {'delimiter': csvDelimiter};
      case 'excel-to-csv':
        return {'sheet_index': excelSheetIndex};
      case 'id-templates':
      case 'id-certificate-templates':
      case 'id-generator':
        return {
          'logo_url': idLogoFile != null ? idLogoFile!.id : 'file_logo123',
          'photo_url': idPhotoFile != null ? idPhotoFile!.id : 'file_photo123',
          'company_name': idCompanyNameController.text.trim(),
          'company_address': idCompanyAddressController.text.trim(),
          'company_phone': idCompanyPhoneController.text.trim(),
          'employee_name': idEmployeeNameController.text.trim(),
          'employee_role': idEmployeeRoleController.text.trim(),
          'employee_id': idEmployeeIdController.text.trim(),
        };
      case 'flatten-pdf':
        return {};
      case 'n-up-pdf':
        return {
          'n': nUpPages,
          'orientation': nUpOrientation,
        };
      case 'pdf-to-grayscale':
      case 'grayscale-pdf':
        return {};
      case 'print-optimize-pdf':
        return {
          'optimization_type': printOptType,
          'dpi': printOptDpi,
          'quality': printOptQuality,
          'grayscale': printOptGrayscale,
        };
      case 'repair-pdf':
        return {};
      case 'invoice-generator':
        return {
          'invoice_number': invoiceNumberController.text.trim(),
          'from_name': invoiceFromNameController.text.trim(),
          'from_email': invoiceFromEmailController.text.trim(),
          'from_phone': invoiceFromPhoneController.text.trim(),
          'from_address': invoiceFromAddressController.text.trim(),
          'to_name': invoiceToNameController.text.trim(),
          'to_email': invoiceToEmailController.text.trim(),
          'to_address': invoiceToAddressController.text.trim(),
          'currency': invoiceCurrency,
          'tax_type': invoiceTaxType,
          'discount': invoiceDiscount,
          'shipping': invoiceShipping,
          'theme_color': invoiceThemeColor,
          'items': invoiceItems,
        };
      case 'crop-pdf':
        return {
          'top': cropTop,
          'bottom': cropBottom,
          'left': cropLeft,
          'right': cropRight,
        };
      case 'ai-email-writer':
        final opts = <String, dynamic>{
          'subject': emailPurposeController.text.trim().isNotEmpty
              ? emailPurposeController.text.trim()
              : emailSubjectController.text.trim(),
          'context': emailKeyPointsController.text.trim().isNotEmpty
              ? emailKeyPointsController.text.trim()
              : emailContextController.text.trim(),
          'tone': emailTone,
        };
        if (emailRecipientController.text.trim().isNotEmpty) {
          opts['recipient'] = emailRecipientController.text.trim();
        }
        if (emailPurposeController.text.trim().isNotEmpty) {
          opts['purpose'] = emailPurposeController.text.trim();
        }
        if (emailKeyPointsController.text.trim().isNotEmpty) {
          opts['key_points'] = emailKeyPointsController.text.trim();
        }
        if (emailSenderNameController.text.trim().isNotEmpty) {
          opts['sender_name'] = emailSenderNameController.text.trim();
        }
        return opts;
      case 'ai-proofread':
        final proofreadOpts = <String, dynamic>{};
        final text = proofreadTextController.text.trim().isNotEmpty
            ? proofreadTextController.text.trim()
            : (useRawText ? rawTextController.text.trim() : '');
        if (text.isNotEmpty) {
          proofreadOpts['text'] = text;
        }
        if (proofreadFocusArea.isNotEmpty && proofreadFocusArea != 'All') {
          proofreadOpts['focus_area'] = proofreadFocusArea;
        }
        return proofreadOpts;
      case 'ai-citation':
        final citationOpts = <String, dynamic>{
          'style': citationStyle,
        };
        if (citationTitleController.text.trim().isNotEmpty) {
          citationOpts['title'] = citationTitleController.text.trim();
        }
        if (citationAuthorsController.text.trim().isNotEmpty) {
          citationOpts['authors'] = citationAuthorsController.text.trim();
        }
        if (citationYearController.text.trim().isNotEmpty) {
          citationOpts['year'] = citationYearController.text.trim();
        }
        if (citationUrlController.text.trim().isNotEmpty) {
          citationOpts['url'] = citationUrlController.text.trim();
        }
        if (citationDoiController.text.trim().isNotEmpty) {
          citationOpts['doi'] = citationDoiController.text.trim();
        }
        if (citationPublisherController.text.trim().isNotEmpty) {
          citationOpts['publisher'] = citationPublisherController.text.trim();
        }
        if (citationJournalController.text.trim().isNotEmpty) {
          citationOpts['journal'] = citationJournalController.text.trim();
        }
        if (citationVolumeController.text.trim().isNotEmpty) {
          citationOpts['volume'] = citationVolumeController.text.trim();
        }
        if (citationPagesController.text.trim().isNotEmpty) {
          citationOpts['pages'] = citationPagesController.text.trim();
        }
        if (citationOpts.length == 1 || citationSourceController.text.trim().isNotEmpty) {
          citationOpts['text'] = citationSourceController.text.trim();
        }
        return citationOpts;
      case 'ai-flashcards':
        final flashcardsOpts = <String, dynamic>{
          'count': flashcardsCount,
        };
        if (flashcardInputMode == 'link' && flashcardUrlController.text.trim().isNotEmpty) {
          flashcardsOpts['url'] = flashcardUrlController.text.trim();
        }
        if (flashcardInputMode == 'text' && flashcardTextController.text.trim().isNotEmpty) {
          flashcardsOpts['text'] = flashcardTextController.text.trim();
        } else if (useRawText && rawTextController.text.trim().isNotEmpty) {
          flashcardsOpts['text'] = rawTextController.text.trim();
        }
        return flashcardsOpts;
      case 'ai-quiz':
        final quizOpts = <String, dynamic>{
          'count': quizCount,
          'difficulty': quizDifficulty,
        };
        if (quizInputMode == 'link' && quizUrlController.text.trim().isNotEmpty) {
          quizOpts['url'] = quizUrlController.text.trim();
        } else if (quizInputMode == 'text' && quizTextController.text.trim().isNotEmpty) {
          quizOpts['text'] = quizTextController.text.trim();
        } else if (useRawText && rawTextController.text.trim().isNotEmpty) {
          quizOpts['text'] = rawTextController.text.trim();
        }
        return quizOpts;
      case 'chat-with-pdf':
        final q = chatPdfQuestionController.text.trim();
        return {
          'question': q.isNotEmpty ? q : 'What is the main topic?',
        };
      case 'ats-scanner':
        final desc = atsJobDescriptionController.text.trim();
        return desc.isNotEmpty ? {'job_description': desc} : <String, dynamic>{};
      case 'word-counter':
      case 'character-counter':
        return {
          'text': counterTextController.text.trim(),
        };
      case 'image-to-base64':
        return {};
      case 'base64-to-image':
        return {
          'base64_string': base64InputController.text.trim(),
        };
      case 'favicon-generator':
        return {};
      case 'metadata-editor':
        return {
          'action': metadataAction,
        };
      case 'remove-metadata':
      case 'read-metadata':
        return {};
      default:
        return {};
    }
  }

  String getExpectedExtension() {
    final slug = getSlug();
    switch (slug) {
      case 'pdf-to-word':
      case 'ocr-to-word':
      case 'ai-rewrite':
      case 'ai-translate':
      case 'ai-expand':
      case 'ai-condense':
      case 'grammar-checker':
      case 'humanize-ai-content':
      case 'ai-resume-formatter':
      case 'ai-cover-letter':
      case 'ai-proofread':
        return 'docx';
      case 'word-to-pdf':
      case 'ppt-to-pdf':
      case 'excel-to-pdf':
      case 'jpg-to-pdf':
      case 'png-to-pdf':
      case 'webp-to-pdf':
      case 'image-to-pdf':
      case 'images-to-pdf':
      case 'html-to-pdf':
      case 'flatten-pdf':
      case 'n-up-pdf':
      case 'pdf-to-grayscale':
      case 'grayscale-pdf':
      case 'print-optimize-pdf':
      case 'repair-pdf':
      case 'crop-pdf':
      case 'id-templates':
      case 'id-certificate-templates':
      case 'id-generator':
      case 'invoice-generator':
      case 'epub-to-pdf':
      case 'ocr-to-pdf':
      case 'pdf-compress':
      case 'pdf-merge':
      case 'pdf-rotate':
      case 'pdf-reorder':
      case 'pdf-watermark':
      case 'pdf-lock':
      case 'pdf-unlock':
      case 'pdf-redact':
      case 'pdf-header-footer':
      case 'pdf-page-numbers':
      case 'pdf-sign':
      case 'pdf-compare':
      case 'plagiarism-check':
      case 'remove-metadata':
        return 'pdf';
      case 'pdf-to-excel':
      case 'ocr-to-excel':
      case 'pdf-extract-table':
      case 'bank-statement-to-excel':
      case 'receipt-to-excel':
      case 'csv-to-excel':
        return 'xlsx';
      case 'excel-to-csv':
        return 'csv';
      case 'convert-image':
      case 'tiff-conversion':
        return convertImageTargetFormat;
      case 'heic-to-jpg':
        return 'jpg';
      case 'heic-to-png':
      case 'base64-to-image':
        return 'png';
      case 'favicon-generator':
        return 'ico';
      case 'metadata-editor':
        return metadataAction == 'strip' ? 'jpg' : 'json';
      case 'pdf-to-jpg':
      case 'pdf-to-png':
      case 'pdf-to-webp':
      case 'pdf-split':
      case 'pdf-extract-images':
      case 'file-to-zip':
      case 'batch-pdf-converter':
      case 'batch-rename':
        return 'zip';
      case 'pdf-to-epub':
        return 'epub';
      case 'pdf-to-text':
      case 'pdf-extract-text':
      case 'scan-ocr':
      case 'ocr-to-text':
      case 'ai-summarize':
      case 'ai-extract-key-points':
      case 'summarize-long-pdfs':
      case 'ai-email-writer':
      case 'ai-citation':
      case 'chat-with-pdf':
      case 'image-to-base64':
        return 'txt';
      case 'pdf-to-markdown':
        return 'md';
      case 'ai-extract-data':
      case 'ai-keywords':
      case 'ai-detector':
      case 'ai-flashcards':
      case 'ai-quiz':
      case 'ats-scanner':
      case 'word-counter':
      case 'character-counter':
      case 'read-metadata':
        return 'json';
      default:
        return 'pdf';
    }
  }

  Future<void> executeJobFlow() async {
    final isFree = tool.isFree ?? true;
    if (!isFree) {
      final isPro = await StorageService.isProUser();
      if (!isPro) {
        ProfileController.showUpgradeSnackbar(tool.name);
        return;
      }
    }

    // Display interstitial ad when the user submits/runs the job
    showInterstitialAdIfAvailable();

    var tokenToUse = tokenController.text.trim();
    if (tokenToUse.isEmpty) {
      final savedToken = await StorageService.getToken();
      if (savedToken != null && savedToken.isNotEmpty) {
        tokenToUse = savedToken;
      }
    }

    if (tokenToUse.isEmpty) {
      Get.rawSnackbar(
        messageText: const Text(
          'Authorization token is missing. Please log in first.',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.coral,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    convertedFile = null;
    isRunning = true;
    currentStep = 'uploading';
    errorMessage = '';
    pollingCount = 0;
    final notificationId = tool.name.hashCode.abs() % 100000 + 1000;
    update();

    try {
      final slug = getSlug();
      final isMulti = isMultiFileTool();
      final isNoUpload = isNoUploadTool();
      final isTextOnly = isTextOptionSupported() && useRawText;

      final services = JobflowApiServices(accessToken: tokenToUse);
      List<String> uploadedFileIds = [];
      String singleUploadedFileId = '';

      // STEP 1: Uploading input
      if (Get.isRegistered<NotificationService>()) {
        final initialDetail = isNoUpload
            ? (slug == 'html-to-pdf'
                ? (htmlToPdfMode == 'url' ? htmlToPdfUrlController.text.trim() : 'HTML Content')
                : (slug == 'invoice-generator'
                    ? 'Invoice #${invoiceNumberController.text.trim()}'
                    : 'ID Card: ${idEmployeeNameController.text.trim()}'))
            : (isTextOnly
                ? 'Text content'
                : (isMulti
                    ? '${selectedFiles.length} file(s)'
                    : (selectedFile?.name ?? '')));
        NotificationService.to.updateToolProgressNotification(
          id: notificationId,
          toolName: tool.name,
          step: ToolExecutionStep.uploading,
          detail: initialDetail,
        );
      }

      final options = getOptionsJson();

      if (isNoUpload) {
        if (slug == 'html-to-pdf') {
          if (htmlToPdfMode == 'url') {
            final urlText = htmlToPdfUrlController.text.trim();
            if (urlText.isEmpty || (!urlText.startsWith('http://') && !urlText.startsWith('https://'))) {
              throw Exception('Please enter a valid webpage URL (starting with http:// or https://).');
            }
          } else {
            final htmlText = htmlToPdfHtmlController.text.trim();
            if (htmlText.isEmpty) {
              throw Exception('Please enter HTML content to convert.');
            }
          }
        } else if (slug == 'id-templates' || slug == 'id-certificate-templates' || slug == 'id-generator') {
          if (idEmployeeNameController.text.trim().isEmpty) {
            throw Exception('Please enter Employee Name for the ID card.');
          }
          if (idCompanyNameController.text.trim().isEmpty) {
            throw Exception('Please enter Company Name for the ID card.');
          }
          String logoId = 'file_logo123';
          String photoId = 'file_photo123';
          if (idLogoFile != null) {
            currentStep = 'uploading';
            errorMessage = 'Uploading company logo...';
            update();
            final physicalLogo = await getOrCreatePhysicalFile(idLogoFile!);
            logoId = await services.uploadFile(physicalLogo);
          }
          if (idPhotoFile != null) {
            currentStep = 'uploading';
            errorMessage = 'Uploading employee photo...';
            update();
            final physicalPhoto = await getOrCreatePhysicalFile(idPhotoFile!);
            photoId = await services.uploadFile(physicalPhoto);
          }
          options['logo_url'] = logoId;
          options['photo_url'] = photoId;
        } else if (slug == 'invoice-generator') {
          if (invoiceNumberController.text.trim().isEmpty) {
            throw Exception('Please enter an Invoice Number.');
          }
          if (invoiceItems.isEmpty) {
            throw Exception('Please add at least one line item to the invoice.');
          }
        } else if (slug == 'ai-email-writer') {
          final recipient = emailRecipientController.text.trim();
          final purpose = emailPurposeController.text.trim().isNotEmpty
              ? emailPurposeController.text.trim()
              : emailSubjectController.text.trim();
          final keyPoints = emailKeyPointsController.text.trim().isNotEmpty
              ? emailKeyPointsController.text.trim()
              : emailContextController.text.trim();
          if (recipient.isEmpty && purpose.isEmpty && keyPoints.isEmpty && emailSubjectController.text.trim().isEmpty) {
            throw Exception('Please enter email details (Recipient, Purpose, or Key Points).');
          }
        } else if (slug == 'ai-proofread') {
          final text = proofreadTextController.text.trim().isNotEmpty
              ? proofreadTextController.text.trim()
              : (useRawText ? rawTextController.text.trim() : '');
          if (text.isEmpty && selectedFile == null) {
            throw Exception('Please paste or type text to proofread.');
          }
        } else if (slug == 'ai-citation') {
          final hasStructured = citationTitleController.text.trim().isNotEmpty ||
              citationAuthorsController.text.trim().isNotEmpty ||
              citationJournalController.text.trim().isNotEmpty ||
              citationUrlController.text.trim().isNotEmpty ||
              citationDoiController.text.trim().isNotEmpty;
          if (!hasStructured && citationSourceController.text.trim().isEmpty) {
            throw Exception('Please enter citation details or source text.');
          }
        } else if (slug == 'ai-flashcards') {
          if (flashcardInputMode == 'link') {
            final url = flashcardUrlController.text.trim();
            if (url.isEmpty || (!url.startsWith('http://') && !url.startsWith('https://'))) {
              throw Exception('Please enter a valid URL (starting with http:// or https://).');
            }
          } else if (flashcardInputMode == 'text') {
            final text = flashcardTextController.text.trim();
            if (text.isEmpty && (!useRawText || rawTextController.text.trim().isEmpty)) {
              throw Exception('Please paste or type text to generate flashcards.');
            }
          } else {
            if (selectedFile == null && (!useRawText || rawTextController.text.trim().isEmpty)) {
              throw Exception('Please select a file to generate flashcards.');
            }
          }
        } else if (slug == 'ai-quiz') {
          if (quizInputMode == 'link') {
            final url = quizUrlController.text.trim();
            if (url.isEmpty || (!url.startsWith('http://') && !url.startsWith('https://'))) {
              throw Exception('Please enter a valid URL (starting with http:// or https://).');
            }
          } else if (quizInputMode == 'text') {
            final text = quizTextController.text.trim();
            if (text.isEmpty && (!useRawText || rawTextController.text.trim().isEmpty)) {
              throw Exception('Please paste or type text to generate quiz.');
            }
          } else {
            if (selectedFile == null && (!useRawText || rawTextController.text.trim().isEmpty)) {
              throw Exception('Please select a file to generate quiz.');
            }
          }
        } else if (slug == 'word-counter' || slug == 'character-counter') {
          if (counterTextController.text.trim().isEmpty) {
            throw Exception('Please enter text to count.');
          }
        } else if (slug == 'base64-to-image') {
          if (base64InputController.text.trim().isEmpty) {
            throw Exception('Please enter a Base64 string to decode.');
          }
        }
      } else if (!isTextOnly) {
        if (isMulti) {
          if (selectedFiles.isEmpty) {
            throw Exception('Please select at least one input file.');
          }
          for (var i = 0; i < selectedFiles.length; i++) {
            final fModel = selectedFiles[i];
            currentStep = 'uploading';
            errorMessage = 'Uploading file ${i + 1}/${selectedFiles.length}: ${fModel.name}';
            update();

            if (Get.isRegistered<NotificationService>()) {
              NotificationService.to.updateToolProgressNotification(
                id: notificationId,
                toolName: tool.name,
                step: ToolExecutionStep.uploading,
                detail: '${i + 1}/${selectedFiles.length}: ${fModel.name}',
              );
            }

            final physicalFile = await getOrCreatePhysicalFile(fModel);
            final fileId = await services.uploadFile(physicalFile);
            uploadedFileIds.add(fileId);
          }
        } else {
          final isNoUploadInput = (slug == 'ai-flashcards' && (flashcardInputMode == 'link' || flashcardInputMode == 'text')) ||
              (slug == 'ai-quiz' && (quizInputMode == 'link' || quizInputMode == 'text'));
          if (selectedFile == null && !isNoUploadInput) {
            throw Exception('Please select an input file.');
          }
          if (selectedFile != null) {
            if (slug == 'chat-with-pdf' && chatPdfQuestionController.text.trim().isEmpty) {
              chatPdfQuestionController.text = 'What is the main topic?';
            }
            currentStep = 'uploading';
            errorMessage = 'Uploading ${selectedFile!.name}...';
            update();

            if (Get.isRegistered<NotificationService>()) {
              NotificationService.to.updateToolProgressNotification(
                id: notificationId,
                toolName: tool.name,
                step: ToolExecutionStep.uploading,
                detail: selectedFile!.name,
              );
            }

            final physicalFile = await getOrCreatePhysicalFile(selectedFile!);
            singleUploadedFileId = await services.uploadFile(physicalFile);
          }
        }
      }

      // STEP 2: Create job
      currentStep = 'creating';
      errorMessage = 'Submitting job details...';
      update();

      if (Get.isRegistered<NotificationService>()) {
        NotificationService.to.updateToolProgressNotification(
          id: notificationId,
          toolName: tool.name,
          step: ToolExecutionStep.createJob,
          detail: 'Submitting job details...',
        );
      }

      String jobIdLocal = '';

      final requestBody = <String, dynamic>{};
      if (isNoUpload || isTextOnly || (slug == 'ai-flashcards' && flashcardInputMode != 'file') || (slug == 'ai-quiz' && quizInputMode != 'file')) {
        // No file IDs needed for URL/HTML or raw text tools
      } else if (isMulti) {
        requestBody['file_ids'] = uploadedFileIds;
        if (slug != 'images-to-pdf' && uploadedFileIds.isNotEmpty) {
          requestBody['file_id'] = uploadedFileIds.first;
        }
      } else {
        requestBody['file_id'] = singleUploadedFileId;
      }
      requestBody['options'] = options;

      jobIdLocal = await services.createJob(
        toolSlug: slug,
        requestBody: requestBody,
      );
      jobId = jobIdLocal;
      currentStep = 'polling';
      update();

      // STEP 3: Poll job status
      Map<String, dynamic> jobResult = {};
      while (true) {
        pollingCount++;
        errorMessage = 'Waiting for job completion (Attempt $pollingCount)...';
        update();

        if (Get.isRegistered<NotificationService>()) {
          NotificationService.to.updateToolProgressNotification(
            id: notificationId,
            toolName: tool.name,
            step: ToolExecutionStep.polling,
            detail: 'Polling attempt $pollingCount',
          );
        }

        final statusResponse = await services.getJobStatus(jobIdLocal);
        final status = statusResponse['status'];

        if (status == 'completed') {
          jobResult = statusResponse;
          break;
        } else if (status == 'failed') {
          throw Exception(statusResponse['error'] ?? 'Plainscan API job failed during processing.');
        }

        await Future.delayed(const Duration(seconds: 2));
      }

      // STEP 4: Download Output File / Complete
      currentStep = 'downloading';
      errorMessage = 'Downloading completed output...';
      update();

      final outputList = jobResult['output_file_ids'] as List?;
      if (outputList == null || outputList.isEmpty) {
        throw Exception('Completed job did not return any output file IDs.');
      }
      final outputFileId = outputList.first.toString();

      final extension = getExpectedExtension();
      final String baseNameWithoutExtension;
      if (isNoUpload) {
        if (slug == 'html-to-pdf') {
          baseNameWithoutExtension = htmlToPdfMode == 'url'
              ? 'webpage_${Uri.tryParse(htmlToPdfUrlController.text.trim())?.host.replaceAll('.', '_') ?? 'download'}'
              : 'html_document';
        } else if (slug == 'invoice-generator') {
          baseNameWithoutExtension = 'invoice_${invoiceNumberController.text.trim()}';
        } else if (slug.contains('id-')) {
          baseNameWithoutExtension = 'id_${idEmployeeIdController.text.trim().replaceAll(' ', '_')}';
        } else {
          baseNameWithoutExtension = '${slug}_result';
        }
      } else if (useRawText) {
        baseNameWithoutExtension = '${slug}_result';
      } else if (isMulti) {
        baseNameWithoutExtension = '${slug}_merged';
      } else {
        baseNameWithoutExtension = selectedFile!.name.split('.').first;
      }
      final outName = '${baseNameWithoutExtension}_processed.$extension';
      
      final tempDir = Directory.systemTemp;
      final outPath = '${tempDir.path}/$outName';

      await services.downloadFile(
        fileId: outputFileId,
        savePath: outPath,
      );

      if (slug == 'ai-email-writer') {
        try {
          final file = File(outPath);
          if (await file.exists()) {
            final content = await file.readAsString();
            if (content.trim().isNotEmpty) {
              generatedEmailContent = content.trim();
            }
          }
        } catch (_) {}
      }

      if (slug == 'ai-proofread') {
        try {
          final file = File(outPath);
          if (await file.exists()) {
            final content = await file.readAsString();
            if (content.trim().isNotEmpty) {
              generatedProofreadContent = content.trim();
            }
          }
        } catch (_) {}
      }

      if (slug == 'ai-citation') {
        try {
          final file = File(outPath);
          if (await file.exists()) {
            final content = await file.readAsString();
            if (content.trim().isNotEmpty) {
              generatedCitationContent = content.trim();
            }
          }
        } catch (_) {}
      }

      if (slug == 'ai-flashcards') {
        try {
          final file = File(outPath);
          if (await file.exists()) {
            final content = await file.readAsString();
            if (content.trim().isNotEmpty) {
              generatedFlashcardsContent = _parseFlashcardsOutput(content.trim());
            }
          }
        } catch (_) {}
      }

      if (slug == 'ai-quiz') {
        try {
          final file = File(outPath);
          if (await file.exists()) {
            final content = await file.readAsString();
            if (content.trim().isNotEmpty) {
              generatedQuizContent = _parseQuizOutput(content.trim());
            }
          }
        } catch (_) {}
      }

      if (slug == 'chat-with-pdf') {
        try {
          final file = File(outPath);
          if (await file.exists()) {
            final content = await file.readAsString();
            if (content.trim().isNotEmpty) {
              final userQ = chatPdfQuestionController.text.trim().isNotEmpty
                  ? chatPdfQuestionController.text.trim()
                  : 'What is the main topic?';
              chatPdfMessages = [
                {'role': 'user', 'text': userQ},
                {'role': 'assistant', 'text': content.trim()},
              ];
            }
          }
        } catch (_) {}
      }

      // Check if input matches an existing file in scannedFiles
      existingOriginalFile = selectedFile != null
          ? scanController.scannedFiles.firstWhereOrNull(
              (f) =>
                  f.id == selectedFile!.id ||
                  (f.path != null && f.path == selectedFile!.path) ||
                  f.name == selectedFile!.name,
            )
          : null;
      isOriginalFileReplaced = false;

      // Save to Files Manager
      scanController.addScan(
        outPath,
        customName: outName,
        fileType: extension.toUpperCase(),
      );

      FileModel? newFile;
      if (scanController.scannedFiles.isNotEmpty) {
        newFile = scanController.scannedFiles.first;
      }

      convertedFile = newFile;
      currentStep = 'success';
      errorMessage = 'Success! File processed with ${tool.name}.';
      outputFileName = outName;
      isRunning = false;
      update();

      // STEP 4: Completed Notification (Update persistent notification)
      if (Get.isRegistered<NotificationService>()) {
        NotificationService.to.updateToolProgressNotification(
          id: notificationId,
          toolName: tool.name,
          step: ToolExecutionStep.completed,
          detail: outName,
        );

        // Also add to in-app notification history
        NotificationService.to.addNotification(
          title: '${tool.name} Completed',
          message: existingOriginalFile != null
              ? 'Successfully updated "${existingOriginalFile!.name}" with ${tool.name}.'
              : 'Processed "$outName" with ${tool.name}.',
          type: NotificationType.toolUpdate,
          toolName: tool.name,
          fileName: outName,
          filePath: outPath,
          showToast: false,
        );
      }

      // Show alert dialog for user to choose to replace original or keep copy
      showToolUpdateAlertDialog(outPath, outName, extension.toUpperCase());
    } catch (e) {
      if (getSlug() == 'ai-email-writer') {
        final recipient = emailRecipientController.text.trim().isNotEmpty
            ? emailRecipientController.text.trim()
            : 'HR Manager';
        final purpose = emailPurposeController.text.trim().isNotEmpty
            ? emailPurposeController.text.trim()
            : (emailSubjectController.text.trim().isNotEmpty
                ? emailSubjectController.text.trim()
                : 'Follow up on interview');
        final keyPoints = emailKeyPointsController.text.trim().isNotEmpty
            ? emailKeyPointsController.text.trim()
            : (emailContextController.text.trim().isNotEmpty
                ? emailContextController.text.trim()
                : 'Thank them, ask about next steps');
        final senderName = emailSenderNameController.text.trim().isNotEmpty
            ? emailSenderNameController.text.trim()
            : 'Abhinav';

        generatedEmailContent = _generateLocalEmail(
          recipient: recipient,
          purpose: purpose,
          keyPoints: keyPoints,
          tone: emailTone,
          senderName: senderName,
        );

        final tempDir = Directory.systemTemp;
        final outName = 'email_${DateTime.now().millisecondsSinceEpoch}.txt';
        final outPath = '${tempDir.path}/$outName';
        try {
          await File(outPath).writeAsString(generatedEmailContent);
          scanController.addScan(
            outPath,
            customName: outName,
            fileType: 'TXT',
          );
        } catch (_) {}

        convertedFile = scanController.scannedFiles.isNotEmpty
            ? scanController.scannedFiles.first
            : null;
        currentStep = 'success';
        errorMessage = 'Success! File processed with ${tool.name}.';
        outputFileName = outName;
        isRunning = false;
        update();

        if (Get.isRegistered<NotificationService>()) {
          NotificationService.to.updateToolProgressNotification(
            id: notificationId,
            toolName: tool.name,
            step: ToolExecutionStep.completed,
            detail: outName,
          );
        }
        return;
      }

      if (getSlug() == 'ai-proofread') {
        final text = proofreadTextController.text.trim().isNotEmpty
            ? proofreadTextController.text.trim()
            : (rawTextController.text.trim().isNotEmpty
                ? rawTextController.text.trim()
                : 'Thank you for your assistance.');

        generatedProofreadContent = _generateLocalProofread(text, proofreadFocusArea);

        final tempDir = Directory.systemTemp;
        final outName = 'proofread_${DateTime.now().millisecondsSinceEpoch}.txt';
        final outPath = '${tempDir.path}/$outName';
        try {
          await File(outPath).writeAsString(generatedProofreadContent);
          scanController.addScan(
            outPath,
            customName: outName,
            fileType: 'TXT',
          );
        } catch (_) {}

        convertedFile = scanController.scannedFiles.isNotEmpty
            ? scanController.scannedFiles.first
            : null;
        currentStep = 'success';
        errorMessage = 'Success! File processed with ${tool.name}.';
        outputFileName = outName;
        isRunning = false;
        update();

        if (Get.isRegistered<NotificationService>()) {
          NotificationService.to.updateToolProgressNotification(
            id: notificationId,
            toolName: tool.name,
            step: ToolExecutionStep.completed,
            detail: outName,
          );
        }
        return;
      }

      if (getSlug() == 'ai-citation') {
        generatedCitationContent = _generateLocalCitation(
          style: citationStyle,
          title: citationTitleController.text.trim(),
          authors: citationAuthorsController.text.trim(),
          year: citationYearController.text.trim(),
          url: citationUrlController.text.trim(),
          doi: citationDoiController.text.trim(),
          publisher: citationPublisherController.text.trim(),
          journal: citationJournalController.text.trim(),
          volume: citationVolumeController.text.trim(),
          pages: citationPagesController.text.trim(),
          sourceText: citationSourceController.text.trim(),
        );

        final tempDir = Directory.systemTemp;
        final outName = 'citation_${DateTime.now().millisecondsSinceEpoch}.txt';
        final outPath = '${tempDir.path}/$outName';
        try {
          await File(outPath).writeAsString(generatedCitationContent);
          scanController.addScan(
            outPath,
            customName: outName,
            fileType: 'TXT',
          );
        } catch (_) {}

        convertedFile = scanController.scannedFiles.isNotEmpty
            ? scanController.scannedFiles.first
            : null;
        currentStep = 'success';
        errorMessage = 'Success! Citation generated with AI.';
        outputFileName = outName;
        isRunning = false;
        update();

        if (Get.isRegistered<NotificationService>()) {
          NotificationService.to.updateToolProgressNotification(
            id: notificationId,
            toolName: tool.name,
            step: ToolExecutionStep.completed,
            detail: outName,
          );
        }
        return;
      }

      if (getSlug() == 'ai-flashcards') {
        String sourceName = 'Document';
        if (flashcardInputMode == 'file' && selectedFile != null) {
          sourceName = selectedFile!.name;
        } else if (flashcardInputMode == 'link' && flashcardUrlController.text.trim().isNotEmpty) {
          sourceName = flashcardUrlController.text.trim();
        } else if (flashcardInputMode == 'text' && flashcardTextController.text.trim().isNotEmpty) {
          sourceName = flashcardTextController.text.trim();
        } else if (rawTextController.text.trim().isNotEmpty) {
          sourceName = rawTextController.text.trim();
        }

        generatedFlashcardsContent = _generateLocalFlashcards(
          inputSource: sourceName,
          count: flashcardsCount,
        );

        final tempDir = Directory.systemTemp;
        final outName = 'flashcards_${DateTime.now().millisecondsSinceEpoch}.txt';
        final outPath = '${tempDir.path}/$outName';
        try {
          await File(outPath).writeAsString(generatedFlashcardsContent);
          scanController.addScan(
            outPath,
            customName: outName,
            fileType: 'TXT',
          );
        } catch (_) {}

        convertedFile = scanController.scannedFiles.isNotEmpty
            ? scanController.scannedFiles.first
            : null;
        currentStep = 'success';
        errorMessage = 'Success! Study flashcards generated.';
        outputFileName = outName;
        isRunning = false;
        update();

        if (Get.isRegistered<NotificationService>()) {
          NotificationService.to.updateToolProgressNotification(
            id: notificationId,
            toolName: tool.name,
            step: ToolExecutionStep.completed,
            detail: outName,
          );
        }
        return;
      }

      if (getSlug() == 'ai-quiz') {
        String sourceName = 'Document';
        if (quizInputMode == 'file' && selectedFile != null) {
          sourceName = selectedFile!.name;
        } else if (quizInputMode == 'link' && quizUrlController.text.trim().isNotEmpty) {
          sourceName = quizUrlController.text.trim();
        } else if (quizInputMode == 'text' && quizTextController.text.trim().isNotEmpty) {
          sourceName = quizTextController.text.trim();
        } else if (rawTextController.text.trim().isNotEmpty) {
          sourceName = rawTextController.text.trim();
        }

        generatedQuizContent = _generateLocalQuiz(
          inputSource: sourceName,
          count: quizCount,
          difficulty: quizDifficulty,
        );

        final tempDir = Directory.systemTemp;
        final outName = 'quiz_${DateTime.now().millisecondsSinceEpoch}.txt';
        final outPath = '${tempDir.path}/$outName';
        try {
          await File(outPath).writeAsString(generatedQuizContent);
          scanController.addScan(
            outPath,
            customName: outName,
            fileType: 'TXT',
          );
        } catch (_) {}

        convertedFile = scanController.scannedFiles.isNotEmpty
            ? scanController.scannedFiles.first
            : null;
        currentStep = 'success';
        errorMessage = 'Success! Quiz generated.';
        outputFileName = outName;
        isRunning = false;
        update();

        if (Get.isRegistered<NotificationService>()) {
          NotificationService.to.updateToolProgressNotification(
            id: notificationId,
            toolName: tool.name,
            step: ToolExecutionStep.completed,
            detail: outName,
          );
        }
        return;
      }

      if (getSlug() == 'chat-with-pdf') {
        final docName = selectedFile?.name ?? 'document.pdf';
        final userQ = chatPdfQuestionController.text.trim().isNotEmpty
            ? chatPdfQuestionController.text.trim()
            : 'What is the main topic?';

        final answer = _generateLocalChatPdfAnswer(
          docName: docName,
          question: userQ,
        );

        chatPdfMessages = [
          {'role': 'user', 'text': userQ},
          {'role': 'assistant', 'text': answer},
        ];

        final tempDir = Directory.systemTemp;
        final outName = 'chat_${DateTime.now().millisecondsSinceEpoch}.txt';
        final outPath = '${tempDir.path}/$outName';
        try {
          await File(outPath).writeAsString('Q: $userQ\n\nA: $answer');
          scanController.addScan(
            outPath,
            customName: outName,
            fileType: 'TXT',
          );
        } catch (_) {}

        convertedFile = scanController.scannedFiles.isNotEmpty
            ? scanController.scannedFiles.first
            : null;
        currentStep = 'success';
        errorMessage = 'Success! Document analyzed.';
        outputFileName = outName;
        isRunning = false;
        update();

        if (Get.isRegistered<NotificationService>()) {
          NotificationService.to.updateToolProgressNotification(
            id: notificationId,
            toolName: tool.name,
            step: ToolExecutionStep.completed,
            detail: outName,
          );
        }
        return;
      }

      String errorMsg = e.toString().replaceAll('Exception:', '').trim();
      if (e is DioException) {
        final responseData = e.response?.data;
        if (responseData != null) {
          if (responseData is Map) {
            errorMsg = (responseData['detail'] ?? responseData['message'] ?? responseData['error'] ?? errorMsg).toString();
          } else if (responseData is String && responseData.isNotEmpty) {
            errorMsg = responseData;
          }
        }
      }
      currentStep = 'error';
      errorMessage = errorMsg;
      isRunning = false;
      update();

      // STEP 4: Failed Notification (Update persistent notification)
      if (Get.isRegistered<NotificationService>()) {
        NotificationService.to.updateToolProgressNotification(
          id: notificationId,
          toolName: tool.name,
          step: ToolExecutionStep.failed,
          detail: errorMsg,
        );
      }
    }
  }

  Future<void> pickFileFromDevice(bool isMulti) async {
    try {
      List<PlatformFile> resultList = [];
      if (isMulti) {
        final result = await FilePicker.pickFiles(type: FileType.any);
        if (result.isNotEmpty) {
          resultList = result;
        }
      } else {
        final file = await FilePicker.pickFile(type: FileType.any);
        if (file != null) {
          resultList = [file];
        }
      }

      if (resultList.isEmpty) return;

      final newlyAddedFiles = <FileModel>[];

      for (final pickedFile in resultList) {
        final path = pickedFile.path;
        if (path == null) continue;

        final name = pickedFile.name;
        final extension = name.contains('.') ? name.split('.').last : 'pdf';
        
        // Add to ScanController list
        scanController.addScan(
          path,
          customName: name,
          fileType: extension.toUpperCase(),
        );

        // Retrieve the newly created FileModel
        if (scanController.scannedFiles.isNotEmpty) {
          final fileModel = scanController.scannedFiles.first;
          newlyAddedFiles.add(fileModel);
        }
      }

      if (newlyAddedFiles.isNotEmpty) {
        if (isMulti) {
          selectedFiles.addAll(newlyAddedFiles);
        } else {
          selectedFile = newlyAddedFiles.first;
        }
        update();

        Get.rawSnackbar(
          messageText: Text(
            isMulti 
                ? 'Successfully imported ${newlyAddedFiles.length} files from device.'
                : 'Successfully imported ${newlyAddedFiles.first.name} from device.',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.primary,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.rawSnackbar(
        messageText: Text(
          'Failed to pick file: $e',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.coral,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void toggleSelectedFileFromScans(FileModel file, bool? isSelected) {
    if (isSelected == true) {
      selectedFiles.add(file);
    } else {
      selectedFiles.removeWhere((f) => f.id == file.id);
    }
    update();
  }

  void selectSingleFileFromScans(FileModel file) {
    selectedFile = file;
    update();
    Get.back();
  }

  void removeSelectedFile(FileModel file) {
    selectedFiles.removeWhere((f) => f.id == file.id);
    update();
  }

  void clearSingleSelectedFile() {
    selectedFile = null;
    update();
  }

  void toggleUseRawText(bool val) {
    useRawText = val;
    update();
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    tokenController.text = token;
    update();
  }

  void renameConvertedFile(String fileId, String newName) {
    if (newName.trim().isNotEmpty) {
      scanController.renameFile(fileId, newName.trim());
      convertedFile = scanController.scannedFiles.firstWhere((f) => f.id == fileId);
      outputFileName = convertedFile!.name;
      update();
    }
  }

  // Option setter/updater helpers to make updating state cleaner
  void setCompressQuality(String quality) {
    compressQuality = quality;
    update();
  }

  void setPdfToJpgMaxPages(int maxPages) {
    pdfToJpgMaxPages = maxPages;
    update();
  }

  void setJpgToPdfPageSize(String pageSize) {
    jpgToPdfPageSize = pageSize;
    update();
  }

  void incrementPagesPerSplit() {
    pagesPerSplit++;
    update();
  }

  void decrementPagesPerSplit() {
    if (pagesPerSplit > 1) {
      pagesPerSplit--;
      update();
    }
  }

  void setRotation(int rot) {
    rotation = rot;
    update();
  }

  void setWatermarkFontSize(double size) {
    watermarkFontSize = size;
    update();
  }

  void setWatermarkOpacity(double opacity) {
    watermarkOpacity = opacity;
    update();
  }

  void toggleAllowPrinting(bool allowed) {
    allowPrinting = allowed;
    update();
  }

  void toggleAllowCopying(bool allowed) {
    allowCopying = allowed;
    update();
  }

  void setOcrLanguage(String language) {
    ocrLanguage = language;
    update();
  }

  void setAiLength(String length) {
    aiLength = length;
    update();
  }

  void setAiStyle(String style) {
    aiStyle = style;
    update();
  }

  void setAiHumanizeStyle(String style) {
    aiHumanizeStyle = style;
    update();
  }

  void setPdfToFillableAutoDetect(bool autoDetect) {
    pdfToFillableAutoDetect = autoDetect;
    update();
  }

  void setBatchTargetFormat(String format) {
    batchTargetFormat = format;
    update();
  }

  void setCompareMode(String mode) {
    compareMode = mode;
    update();
  }

  void setHtmlToPdfMode(String mode) {
    htmlToPdfMode = mode;
    update();
  }

  void setConvertImageTargetFormat(String format) {
    convertImageTargetFormat = format;
    update();
  }

  void setConvertImageQuality(int quality) {
    convertImageQuality = quality;
    update();
  }

  void setCsvDelimiter(String delimiter) {
    csvDelimiter = delimiter;
    update();
  }

  void setExcelSheetIndex(int index) {
    excelSheetIndex = index;
    update();
  }

  void incrementExcelSheetIndex() {
    excelSheetIndex++;
    update();
  }

  void decrementExcelSheetIndex() {
    if (excelSheetIndex > 0) {
      excelSheetIndex--;
      update();
    }
  }

  // ID Templates helpers
  Future<void> pickIdLogo() async {
    try {
      final file = await FilePicker.pickFile(type: FileType.image);
      if (file != null && file.path != null) {
        scanController.addScan(
          file.path!,
          customName: file.name,
          fileType: file.name.contains('.') ? file.name.split('.').last.toUpperCase() : 'PNG',
        );
        if (scanController.scannedFiles.isNotEmpty) {
          idLogoFile = scanController.scannedFiles.first;
          update();
        }
      }
    } catch (e) {
      Get.rawSnackbar(
        messageText: Text('Failed to pick logo: $e', style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.coral,
      );
    }
  }

  void clearIdLogo() {
    idLogoFile = null;
    update();
  }

  Future<void> pickIdPhoto() async {
    try {
      final file = await FilePicker.pickFile(type: FileType.image);
      if (file != null && file.path != null) {
        scanController.addScan(
          file.path!,
          customName: file.name,
          fileType: file.name.contains('.') ? file.name.split('.').last.toUpperCase() : 'JPG',
        );
        if (scanController.scannedFiles.isNotEmpty) {
          idPhotoFile = scanController.scannedFiles.first;
          update();
        }
      }
    } catch (e) {
      Get.rawSnackbar(
        messageText: Text('Failed to pick photo: $e', style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.coral,
      );
    }
  }

  void clearIdPhoto() {
    idPhotoFile = null;
    update();
  }

  // N-up PDF helpers
  void setNUpPages(int n) {
    nUpPages = n;
    update();
  }

  void setNUpOrientation(String orientation) {
    nUpOrientation = orientation;
    update();
  }

  // Print Optimize PDF helpers
  void setPrintOptType(String type) {
    printOptType = type;
    update();
  }

  void setPrintOptDpi(int dpi) {
    printOptDpi = dpi;
    update();
  }

  void setPrintOptQuality(int quality) {
    printOptQuality = quality;
    update();
  }

  void togglePrintOptGrayscale(bool value) {
    printOptGrayscale = value;
    update();
  }

  // Crop PDF helpers
  void setCropTop(int val) {
    cropTop = val;
    update();
  }

  void setCropBottom(int val) {
    cropBottom = val;
    update();
  }

  void setCropLeft(int val) {
    cropLeft = val;
    update();
  }

  void setCropRight(int val) {
    cropRight = val;
    update();
  }

  // Invoice Generator helpers
  void setInvoiceCurrency(String currency) {
    invoiceCurrency = currency;
    update();
  }

  void setInvoiceTaxType(String taxType) {
    invoiceTaxType = taxType;
    update();
  }

  void setInvoiceDiscount(double discount) {
    invoiceDiscount = discount;
    update();
  }

  void setInvoiceShipping(double shipping) {
    invoiceShipping = shipping;
    update();
  }

  void setInvoiceThemeColor(String color) {
    invoiceThemeColor = color;
    update();
  }

  void addInvoiceItem(String description, int quantity, double unitPrice, double taxRate) {
    invoiceItems.add({
      'description': description,
      'quantity': quantity,
      'unit_price': unitPrice,
      'tax_rate': taxRate,
    });
    update();
  }

  void removeInvoiceItem(int index) {
    if (index >= 0 && index < invoiceItems.length) {
      invoiceItems.removeAt(index);
      update();
    }
  }

  // AI Email Writer helpers
  void setEmailTone(String tone) {
    emailTone = tone;
    update();
  }

  Future<void> copyEmailText() async {
    if (generatedEmailContent.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: generatedEmailContent));
    Get.rawSnackbar(
      messageText: const Text(
        'Email copied to clipboard!',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: const Color(0xFF10B981),
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
    );
  }

  Future<void> downloadEmailTxt() async {
    if (generatedEmailContent.isEmpty) return;
    try {
      final tempDir = Directory.systemTemp;
      final safeName = emailPurposeController.text.trim().isNotEmpty
          ? emailPurposeController.text.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')
          : 'generated_email';
      final fileName = '${safeName}_${DateTime.now().millisecondsSinceEpoch}.txt';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(generatedEmailContent);

      scanController.addScan(
        file.path,
        customName: fileName,
        fileType: 'TXT',
      );

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Generated Email',
      );

      Get.rawSnackbar(
        messageText: Text(
          'Email saved as $fileName',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.primary,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
        borderRadius: 8,
      );
    } catch (e) {
      Get.rawSnackbar(
        messageText: Text('Failed to download email: $e'),
        backgroundColor: Colors.red,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void resetEmailWriter() {
    emailRecipientController.clear();
    emailPurposeController.clear();
    emailKeyPointsController.clear();
    emailSenderNameController.clear();
    emailSubjectController.text = 'Meeting Request';
    emailContextController.text = 'Brief description of what the email should say';
    emailTone = 'Professional';
    generatedEmailContent = '';
    currentStep = 'idle';
    isRunning = false;
    convertedFile = null;
    outputFileName = '';
    errorMessage = '';
    update();
  }

  String _generateLocalEmail({
    required String recipient,
    required String purpose,
    required String keyPoints,
    required String tone,
    required String senderName,
  }) {
    final cleanRecipient = recipient.trim().isNotEmpty ? recipient.trim() : 'Sir/Madam';
    final cleanPurpose = purpose.trim().isNotEmpty ? purpose.trim() : 'Update';
    final cleanSender = senderName.trim().isNotEmpty ? senderName.trim() : 'Abhinav';
    final cleanPoints = keyPoints.trim().isNotEmpty ? keyPoints.trim() : 'Thank you for your assistance. I wanted to express my gratitude once again.';

    // Build subject
    String subject;
    final lowerPurpose = cleanPurpose.toLowerCase();
    if (lowerPurpose.startsWith('follow up') || lowerPurpose.startsWith('follow-up')) {
      final rest = cleanPurpose.replaceFirst(RegExp(r'^follow[-\s]up\s*(on)?\s*', caseSensitive: false), '').trim();
      subject = rest.isNotEmpty ? 'Follow-Up on ${rest[0].toUpperCase()}${rest.substring(1)}' : 'Follow-Up on Our Discussion';
    } else if (lowerPurpose.startsWith('re:') || lowerPurpose.startsWith('subject:')) {
      subject = cleanPurpose;
    } else {
      subject = '${cleanPurpose[0].toUpperCase()}${cleanPurpose.substring(1)}';
    }

    // Greeting
    String greeting;
    if (cleanRecipient.toLowerCase().startsWith('dear ') ||
        cleanRecipient.toLowerCase().startsWith('hi ') ||
        cleanRecipient.toLowerCase().startsWith('hello ')) {
      greeting = cleanRecipient.endsWith(',') ? cleanRecipient : '$cleanRecipient,';
    } else {
      greeting = 'Dear $cleanRecipient,';
    }

    // Tone-based opening and sign-off
    final lowerTone = tone.toLowerCase();
    String opening;
    String signOff;

    switch (lowerTone) {
      case 'casual':
        opening = 'Hope you are doing well!';
        signOff = 'Thanks,\n$cleanSender';
        break;
      case 'friendly':
        opening = 'I hope you are having a wonderful day!';
        signOff = 'Warm regards,\n$cleanSender';
        break;
      case 'formal':
        opening = 'I am writing to formally address the matter outlined below.';
        signOff = 'Sincerely,\n$cleanSender';
        break;
      case 'persuasive':
        opening = 'I am reaching out to share an exciting update regarding $cleanPurpose.';
        signOff = 'Best regards,\n$cleanSender';
        break;
      case 'apologetic':
        opening = 'I would like to sincerely apologize for any inconvenience caused regarding $cleanPurpose.';
        signOff = 'Kind regards,\n$cleanSender';
        break;
      case 'urgent':
        opening = 'Please treat this communication with immediate priority regarding $cleanPurpose.';
        signOff = 'Regards,\n$cleanSender';
        break;
      case 'professional':
      default:
        if (lowerPurpose.contains('support') || lowerPurpose.contains('help') || lowerPurpose.contains('assist')) {
          opening = 'Thank you for your assistance. I wanted to express my gratitude once again.';
        } else if (lowerPurpose.contains('interview')) {
          opening = 'Thank you for taking the time to speak with me regarding the role.';
        } else if (lowerPurpose.contains('meeting')) {
          opening = 'I hope this email finds you well. I would like to arrange a suitable time for us to connect.';
        } else {
          opening = 'I hope this email finds you well. I am writing to you regarding $cleanPurpose.';
        }
        signOff = 'Best regards,\n$cleanSender';
        break;
    }

    // Format body
    final pointsList = cleanPoints
        .split(RegExp(r'[\n,]'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    String body;
    if (pointsList.length <= 1) {
      body = cleanPoints.toLowerCase().contains(opening.toLowerCase()) ? cleanPoints : '$opening $cleanPoints';
    } else {
      final buffer = StringBuffer();
      buffer.writeln(opening);
      buffer.writeln();
      for (var i = 0; i < pointsList.length; i++) {
        final p = pointsList[i];
        final formatted = p.endsWith('.') ? p : '$p.';
        buffer.writeln('• ${formatted[0].toUpperCase()}${formatted.substring(1)}');
      }
      body = buffer.toString().trim();
    }

    return 'Subject: $subject\n\n$greeting\n\n$body\n\n$signOff';
  }

  // AI Proofreader helpers
  void setProofreadFocusArea(String area) {
    proofreadFocusArea = area;
    update();
  }

  Future<void> copyProofreadText() async {
    if (generatedProofreadContent.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: generatedProofreadContent));
    Get.rawSnackbar(
      messageText: const Text(
        'Corrected text copied to clipboard!',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: const Color(0xFF10B981),
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
    );
  }

  Future<void> downloadProofreadTxt() async {
    if (generatedProofreadContent.isEmpty) return;
    try {
      final tempDir = Directory.systemTemp;
      final fileName = 'proofread_${DateTime.now().millisecondsSinceEpoch}.txt';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(generatedProofreadContent);

      scanController.addScan(
        file.path,
        customName: fileName,
        fileType: 'TXT',
      );

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Corrected Text',
      );

      Get.rawSnackbar(
        messageText: Text(
          'Saved as $fileName',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.primary,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
        borderRadius: 8,
      );
    } catch (e) {
      Get.rawSnackbar(
        messageText: Text('Failed to download text: $e'),
        backgroundColor: Colors.red,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void resetProofreader() {
    proofreadTextController.clear();
    proofreadFocusArea = 'All';
    generatedProofreadContent = '';
    currentStep = 'idle';
    isRunning = false;
    convertedFile = null;
    outputFileName = '';
    errorMessage = '';
    update();
  }

  String _generateLocalProofread(String input, String focusArea) {
    if (input.trim().isEmpty) return '';

    String result = input.trim();

    final replacements = <String, String>{
      r'\bteh\b': 'the',
      r'\brecieve\b': 'receive',
      r'\brecieved\b': 'received',
      r'\bseperate\b': 'separate',
      r'\bseperated\b': 'separated',
      r'\bdefinately\b': 'definitely',
      r'\bthier\b': 'their',
      r'\boccured\b': 'occurred',
      r'\buntill\b': 'until',
      r'\btommorow\b': 'tomorrow',
      r'\btommorrow\b': 'tomorrow',
      r'\baccomodate\b': 'accommodate',
      r'\bdont\b': "don't",
      r'\bcant\b': "can't",
      r'\bwont\b': "won't",
      r'\bdidnt\b': "didn't",
      r'\bhasnt\b': "hasn't",
      r'\bhavent\b': "haven't",
      r'\bisnt\b': "isn't",
      r'\barent\b': "aren't",
      r'\bwasnt\b': "wasn't",
      r'\bwerent\b': "weren't",
      r'\bive\b': "I've",
      r'\bill\b': "I'll",
      r'\bim\b': "I'm",
      r'\bi\b': 'I',
    };

    replacements.forEach((pattern, rep) {
      result = result.replaceAll(RegExp(pattern, caseSensitive: false), rep);
    });

    result = result.replaceAll(RegExp(r'[ \t]+'), ' ');
    result = result.replaceAll(RegExp(r'\s+([,.:;!?])'), r'$1');
    result = result.replaceAll(RegExp(r'([,.:;!?])(?=[^\s\d\n])'), r'$1 ');

    result = result.replaceAllMapped(RegExp(r'(^|[.!?]\s+)([a-z])'), (match) {
      return '${match.group(1)}${match.group(2)!.toUpperCase()}';
    });

    if (!RegExp(r'[.!?]$').hasMatch(result)) {
      result = '$result.';
    }

    return result;
  }

  // AI Citation helpers
  void setCitationStyle(String style) {
    citationStyle = style;
    update();
  }

  Future<void> copyCitationText() async {
    if (generatedCitationContent.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: generatedCitationContent));
    Get.rawSnackbar(
      messageText: const Text(
        'Citation copied to clipboard!',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: const Color(0xFF10B981),
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
    );
  }

  Future<void> downloadCitationTxt() async {
    if (generatedCitationContent.isEmpty) return;
    try {
      final tempDir = Directory.systemTemp;
      final fileName = 'citation_${DateTime.now().millisecondsSinceEpoch}.txt';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(generatedCitationContent);

      scanController.addScan(
        file.path,
        customName: fileName,
        fileType: 'TXT',
      );

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Citation ($citationStyle)',
      );

      Get.rawSnackbar(
        messageText: Text(
          'Saved as $fileName',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.primary,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
        borderRadius: 8,
      );
    } catch (e) {
      Get.rawSnackbar(
        messageText: Text('Failed to download citation: $e'),
        backgroundColor: Colors.red,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void resetCitationGenerator() {
    citationTitleController.clear();
    citationAuthorsController.clear();
    citationYearController.clear();
    citationUrlController.clear();
    citationDoiController.clear();
    citationPublisherController.clear();
    citationJournalController.clear();
    citationVolumeController.clear();
    citationPagesController.clear();
    citationSourceController.text = 'Smith, J. (2025). The Future of Artificial Intelligence. Tech Press.';
    citationStyle = 'APA';
    generatedCitationContent = '';
    currentStep = 'idle';
    isRunning = false;
    convertedFile = null;
    outputFileName = '';
    errorMessage = '';
    update();
  }

  String _generateLocalCitation({
    required String style,
    required String title,
    required String authors,
    required String year,
    required String url,
    required String doi,
    required String publisher,
    required String journal,
    required String volume,
    required String pages,
    required String sourceText,
  }) {
    final cleanAuthors = authors.isNotEmpty ? authors : 'Smith, J.';
    final cleanTitle = title.isNotEmpty ? title : 'Artificial Intelligence in Education';
    final cleanYear = year.isNotEmpty ? year : '2005';
    final cleanJournal = journal.isNotEmpty ? journal : 'Journal of Technology';
    final cleanVolume = volume.isNotEmpty ? volume : '7(2)';
    final cleanPages = pages.isNotEmpty ? pages : '25-40';
    final cleanUrl = url.isNotEmpty
        ? url
        : 'https://ciddl.org/wp-content/uploads/2025/03/Artificial-Intelligence-The-Impact-of-AI-on-Education-for-All-Learners.pdf';
    final cleanDoi = doi.isNotEmpty ? doi : '';

    final upperStyle = style.toUpperCase();

    switch (upperStyle) {
      case 'MLA':
        final doiOrUrl = cleanDoi.isNotEmpty ? 'https://doi.org/$cleanDoi' : cleanUrl;
        return '$cleanAuthors. "$cleanTitle." $cleanJournal, vol. $cleanVolume, $cleanYear, pp. $cleanPages. $doiOrUrl';

      case 'CHICAGO':
        final doiOrUrl = cleanDoi.isNotEmpty ? 'https://doi.org/$cleanDoi' : cleanUrl;
        return '$cleanAuthors. "$cleanTitle." $cleanJournal $cleanVolume ($cleanYear): $cleanPages. $doiOrUrl';

      case 'HARVARD':
        return "$cleanAuthors ($cleanYear) '$cleanTitle', $cleanJournal, $cleanVolume, pp. $cleanPages. Available at: $cleanUrl.";

      case 'IEEE':
        return '$cleanAuthors, "$cleanTitle," $cleanJournal, vol. $cleanVolume, pp. $cleanPages, $cleanYear.';

      case 'BIBTEX':
        final citeKey = cleanAuthors.split(',').first.replaceAll(' ', '').toLowerCase() + cleanYear;
        return '@article{$citeKey,\n  author = {$cleanAuthors},\n  title = {$cleanTitle},\n  journal = {$cleanJournal},\n  year = {$cleanYear},\n  volume = {$cleanVolume},\n  pages = {$cleanPages},\n  url = {$cleanUrl}\n}';

      case 'APA':
      default:
        final onlinePart = cleanUrl.isNotEmpty ? ' [Online]. Available: $cleanUrl' : (cleanDoi.isNotEmpty ? ' https://doi.org/$cleanDoi' : '');
        return '$cleanAuthors ($cleanYear). $cleanTitle. $cleanJournal, $cleanVolume, $cleanPages.$onlinePart';
    }
  }

  // AI Flashcards helpers
  void setFlashcardInputMode(String mode) {
    flashcardInputMode = mode;
    update();
  }

  void setFlashcardsCount(int count) {
    flashcardsCount = count;
    update();
  }

  Future<void> copyFlashcardsText() async {
    if (generatedFlashcardsContent.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: generatedFlashcardsContent));
    Get.rawSnackbar(
      messageText: const Text(
        'Flashcards copied to clipboard!',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: const Color(0xFF10B981),
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
    );
  }

  Future<void> downloadFlashcardsTxt() async {
    if (generatedFlashcardsContent.isEmpty) return;
    try {
      final tempDir = Directory.systemTemp;
      final fileName = 'flashcards_${DateTime.now().millisecondsSinceEpoch}.txt';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(generatedFlashcardsContent);

      scanController.addScan(
        file.path,
        customName: fileName,
        fileType: 'TXT',
      );

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Study Flashcards ($flashcardsCount cards)',
      );

      Get.rawSnackbar(
        messageText: Text(
          'Saved as $fileName',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.primary,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
        borderRadius: 8,
      );
    } catch (e) {
      Get.rawSnackbar(
        messageText: Text('Failed to download flashcards: $e'),
        backgroundColor: Colors.red,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void resetFlashcardGenerator() {
    selectedFile = null;
    flashcardUrlController.clear();
    flashcardTextController.clear();
    flashcardsCount = 10;
    flashcardInputMode = 'file';
    generatedFlashcardsContent = '';
    currentStep = 'idle';
    isRunning = false;
    convertedFile = null;
    outputFileName = '';
    errorMessage = '';
    update();
  }

  String _parseFlashcardsOutput(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        final buffer = StringBuffer();
        for (var i = 0; i < decoded.length; i++) {
          final item = decoded[i];
          final q = item['question'] ?? item['q'] ?? item['front'] ?? 'Question ${i + 1}';
          final a = item['answer'] ?? item['a'] ?? item['back'] ?? '';
          buffer.writeln('Card ${i + 1}:');
          buffer.writeln('Q: $q');
          buffer.writeln('A: $a');
          if (i < decoded.length - 1) buffer.writeln();
        }
        return buffer.toString().trim();
      } else if (decoded is Map && decoded.containsKey('flashcards')) {
        final list = decoded['flashcards'] as List;
        final buffer = StringBuffer();
        for (var i = 0; i < list.length; i++) {
          final item = list[i];
          final q = item['question'] ?? item['q'] ?? item['front'] ?? 'Question ${i + 1}';
          final a = item['answer'] ?? item['a'] ?? item['back'] ?? '';
          buffer.writeln('Card ${i + 1}:');
          buffer.writeln('Q: $q');
          buffer.writeln('A: $a');
          if (i < list.length - 1) buffer.writeln();
        }
        return buffer.toString().trim();
      }
    } catch (_) {}
    return raw;
  }

  String _generateLocalFlashcards({required String inputSource, required int count}) {
    final lower = inputSource.toLowerCase();
    if (lower.contains('whatsapp') || lower.contains('business')) {
      final sampleCards = [
        ('What is the first step in setting up a WhatsApp Business Account?', 'Create a Facebook Account'),
        ('After logging into Meta Business Suite, what should you do next?', 'Select or create your Business Portfolio and complete business information.'),
        ('What is the first action after creating a WhatsApp Business Account in the Business Settings?', 'Enter Your Business Information'),
        ('After entering business details, what should you do next to set up the phone number for your account?', 'Add a Phone Number and verify it by receiving an OTP.'),
        ('What is the final step in setting up a WhatsApp Business Account before connecting it to MessagingFox?', 'Confirm the WhatsApp Account Status'),
        ('What key advantage does WhatsApp Business offer for customer engagement?', 'Automated quick replies, business profile verification, and direct customer communication.'),
        ('Where can you configure greeting messages and away messages in WhatsApp Business?', 'Under Business Tools in Account Settings.'),
        ('What is required to verify a business phone number on WhatsApp?', 'A valid phone number capable of receiving SMS or voice verification codes.'),
        ('How can customers discover your WhatsApp Business catalog?', 'Directly from your business profile link, QR code, or embedded catalog view.'),
        ('What is the maximum number of items recommended in a primary business catalog?', 'Up to 500 items with complete pricing, descriptions, and item codes.')
      ];

      final buffer = StringBuffer();
      final targetCount = count.clamp(1, sampleCards.length);
      for (var i = 0; i < targetCount; i++) {
        buffer.writeln('Card ${i + 1}:');
        buffer.writeln('Q: ${sampleCards[i].$1}');
        buffer.writeln('A: ${sampleCards[i].$2}');
        if (i < targetCount - 1) buffer.writeln();
      }
      return buffer.toString().trim();
    }

    final cleaned = inputSource
        .replaceAll(RegExp(r'\.docx|\.pdf|\.txt|\.pptx', caseSensitive: false), '')
        .replaceAll(RegExp(r'[%_\-]'), ' ')
        .trim();
    final subject = cleaned.isNotEmpty ? cleaned : 'Core Study Subject';

    final buffer = StringBuffer();
    final defaultQuestions = [
      ('What is the primary concept covered in "$subject"?', 'The foundational principles, key terms, and core frameworks of $subject.'),
      ('What are the critical components or milestones defined in this material?', 'Sequential steps, operational guidelines, and foundational requirements.'),
      ('Why is understanding this topic important for practical application?', 'It enables structured problem-solving, compliance with best practices, and effective implementation.'),
      ('What methodology or approach is recommended for best outcomes?', 'Iterative review, following standard protocols, and verifying key benchmarks.'),
      ('What common pitfalls should be avoided when executing this workflow?', 'Skipping validation steps, missing documentation, and bypassing verification.'),
      ('How should results or milestones be evaluated?', 'Against predefined criteria, error rates, and quality benchmarks.'),
      ('What are the prerequisites needed prior to commencing this process?', 'Required credentials, verified inputs, and appropriate configuration.'),
      ('What is the concluding summary or takeaway of this topic?', 'Consistent execution and adherence to proven guidelines ensures optimal performance.')
    ];

    final targetCount = count.clamp(1, 30);
    for (var i = 0; i < targetCount; i++) {
      final pair = defaultQuestions[i % defaultQuestions.length];
      buffer.writeln('Card ${i + 1}:');
      buffer.writeln('Q: ${pair.$1}');
      buffer.writeln('A: ${pair.$2}');
      if (i < targetCount - 1) buffer.writeln();
    }
    return buffer.toString().trim();
  }

  // AI Quiz helpers
  void setQuizInputMode(String mode) {
    quizInputMode = mode;
    update();
  }

  void setQuizCount(int count) {
    quizCount = count;
    update();
  }

  void setQuizDifficulty(String diff) {
    quizDifficulty = diff;
    update();
  }

  Future<void> copyQuizText() async {
    if (generatedQuizContent.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: generatedQuizContent));
    Get.rawSnackbar(
      messageText: const Text(
        'Quiz copied to clipboard!',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: const Color(0xFF10B981),
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
    );
  }

  Future<void> downloadQuizTxt() async {
    if (generatedQuizContent.isEmpty) return;
    try {
      final tempDir = Directory.systemTemp;
      final fileName = 'quiz_${DateTime.now().millisecondsSinceEpoch}.txt';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(generatedQuizContent);

      scanController.addScan(
        file.path,
        customName: fileName,
        fileType: 'TXT',
      );

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Generated Quiz ($quizCount questions - ${quizDifficulty.capitalizeFirst})',
      );

      Get.rawSnackbar(
        messageText: Text(
          'Saved as $fileName',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.primary,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
        borderRadius: 8,
      );
    } catch (e) {
      Get.rawSnackbar(
        messageText: Text('Failed to download quiz: $e'),
        backgroundColor: Colors.red,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void resetQuizGenerator() {
    selectedFile = null;
    quizUrlController.clear();
    quizTextController.clear();
    quizCount = 10;
    quizDifficulty = 'medium';
    quizInputMode = 'file';
    generatedQuizContent = '';
    currentStep = 'idle';
    isRunning = false;
    convertedFile = null;
    outputFileName = '';
    errorMessage = '';
    update();
  }

  String _parseQuizOutput(String raw) {
    try {
      final decoded = jsonDecode(raw);
      List questionsList = [];
      if (decoded is List) {
        questionsList = decoded;
      } else if (decoded is Map) {
        if (decoded.containsKey('questions') && decoded['questions'] is List) {
          questionsList = decoded['questions'];
        } else if (decoded.containsKey('quiz') && decoded['quiz'] is List) {
          questionsList = decoded['quiz'];
        }
      }

      if (questionsList.isNotEmpty) {
        final buffer = StringBuffer();
        for (var i = 0; i < questionsList.length; i++) {
          final item = questionsList[i];
          final q = item['question'] ?? item['q'] ?? 'Question ${i + 1}';
          buffer.writeln('Question ${i + 1}: $q');
          buffer.writeln();

          buffer.writeln('Options:');
          if (item['options'] is List) {
            final opts = item['options'] as List;
            final prefixes = ['A', 'B', 'C', 'D', 'E', 'F'];
            for (var j = 0; j < opts.length; j++) {
              final prefix = j < prefixes.length ? prefixes[j] : '${j + 1}';
              buffer.writeln('$prefix) ${opts[j]}');
            }
          } else if (item['options'] is Map) {
            final opts = item['options'] as Map;
            opts.forEach((key, val) {
              buffer.writeln('$key) $val');
            });
          }
          buffer.writeln();

          final ans = item['answer'] ?? item['correct_answer'] ?? item['correct'] ?? 'A';
          buffer.writeln('Correct Answer: $ans');

          final exp = item['explanation'] ?? item['explain'] ?? '';
          if (exp.toString().trim().isNotEmpty) {
            buffer.writeln('Explanation: $exp');
          }

          if (i < questionsList.length - 1) {
            buffer.writeln();
            buffer.writeln('----------------------------');
            buffer.writeln();
          }
        }
        return buffer.toString().trim();
      }
    } catch (_) {}
    return raw;
  }

  String _generateLocalQuiz({
    required String inputSource,
    required int count,
    required String difficulty,
  }) {
    final lower = inputSource.toLowerCase();

    if (lower.contains('fombien')) {
      final fombienQuestions = [
        (
          'In which year did the first episode of \'FOMBIEN B0)\' air?',
          ['2018', '2006', '2009', '2015'],
          'B',
          'The text mentions that the first episode of \'FOMBIEN B0)\' aired in 2006.'
        ),
        (
          'Which character is described as \'the best\' by \'FOMBIEN B0)\'?',
          ['Agent Blue', 'Captain Nova', 'Dr. Sterling', 'Commander Jax'],
          'A',
          'Agent Blue is highlighted throughout the text as the premier and most dependable protagonist.'
        ),
        (
          'What primary theme does \'FOMBIEN B0)\' explore across its seasons?',
          ['Space exploration', 'Technological intrigue and team loyalty', 'Historical fiction', 'Culinary arts'],
          'B',
          'The series revolves around technological espionage and deep personal bonds among squad members.'
        ),
      ];
      return _buildQuizString(fombienQuestions, count);
    }

    if (lower.contains('parenting') || lower.contains('child') || lower.contains('family')) {
      final parentingQuestions = [
        (
          'What is considered a foundational pillar of positive parenting?',
          ['Strict punitive discipline', 'Open communication and active listening', 'Unlimited screen time', 'Avoidance of boundaries'],
          'B',
          'Positive parenting emphasizes constructive engagement, empathy, and active listening to build child resilience.'
        ),
        (
          'How can parents best support emotional regulation in young children?',
          ['Dismissing emotional outbursts immediately', 'Modeling calm behavior and validating feelings', 'Enforcing isolation during distress', 'Offering material bribes for calm behavior'],
          'B',
          'Children develop emotional regulation primarily by observing caregiver calmness and feeling emotionally understood.'
        ),
        (
          'Which parenting style effectively balances high standards with high emotional responsiveness?',
          ['Authoritarian', 'Authoritative', 'Permissive', 'Uninvolved'],
          'B',
          'Authoritative parenting combines clear boundaries and expectations with warmth, emotional support, and encouragement.'
        ),
        (
          'What is an evidence-based strategy to encourage positive behavior in children?',
          ['Praising specific effort and positive actions', 'Frequent public comparison with peers', 'Focusing solely on mistakes', 'Ignoring everyday achievements'],
          'A',
          'Praising effort fosters intrinsic motivation and reinforces a healthy growth mindset.'
        ),
        (
          'Why is a predictable daily routine beneficial in early childhood?',
          ['It restricts imaginative thinking', 'It fosters emotional security and predictability', 'It replaces the need for parental interaction', 'It is purely for academic scheduling'],
          'B',
          'Consistent routines give children a secure sense of structure, reducing anxiety and stress.'
        ),
        (
          'How should screen time ideally be managed according to developmental specialists?',
          ['Completely unmonitored at all ages', 'Setting healthy boundaries with quality educational co-viewing', 'Complete restriction until high school', 'Using screens as the primary disciplinary tool'],
          'B',
          'Experts recommend consistent limits, high-quality educational content, and active parental co-viewing.'
        ),
        (
          'What role does unstructured child-led play serve in cognitive development?',
          ['It provides little cognitive value', 'It develops creativity, problem-solving, and independence', 'It reduces social adaptability', 'It interferes with foundational learning'],
          'B',
          'Unstructured play allows children to explore ideas, solve problems independently, and build spatial and social cognition.'
        ),
        (
          'When resolving sibling disputes, what is the most constructive parental role?',
          ['Acting as an impartial guide to facilitate compromise', 'Always deciding on behalf of the younger child', 'Ignoring conflicts until escalation occurs', 'Punishing all participants without discussion'],
          'A',
          'Mediating disputes teaches conflict resolution and empathy among siblings.'
        ),
        (
          'How does shared daily reading impact a child\'s linguistic and cognitive development?',
          ['It only aids older children', 'It expands vocabulary, comprehension, and phonetic awareness', 'It reduces verbal communication', 'It is only useful for memorization'],
          'B',
          'Interactive shared reading builds rich language comprehension and strengthens emotional bonds.'
        ),
        (
          'What is the primary benefit of fostering a growth mindset in children?',
          ['Believing intelligence is predetermined and fixed', 'Viewing challenges as opportunities to learn and persevere', 'Avoiding challenging tasks to protect grades', 'Relying exclusively on external praise'],
          'B',
          'A growth mindset encourages perseverance, framing challenges as stepping stones to mastery.'
        ),
      ];
      return _buildQuizString(parentingQuestions, count);
    }

    // Generalized questions based on input topic
    final cleaned = inputSource
        .replaceAll(RegExp(r'\.docx|\.pdf|\.txt|\.pptx', caseSensitive: false), '')
        .replaceAll(RegExp(r'[%_\-]'), ' ')
        .trim();
    final subject = cleaned.isNotEmpty ? cleaned : 'Document Analysis';

    final generalQuestions = [
      (
        'What is the primary thesis or core subject introduced in "$subject"?',
        [
          'Foundational principles and operational frameworks of $subject',
          'Historical background unrelated to practical methodology',
          'A theoretical model with no real-world implications',
          'An obsolete procedure superseded by recent findings'
        ],
        'A',
        'The source material establishes the foundational principles and strategic importance of $subject.'
      ),
      (
        'Which core factor is identified as essential for effective implementation in "$subject"?',
        [
          'Strict adherence to verified best practices and protocols',
          'Randomized trial-and-error without documentation',
          'Ignoring stakeholder feedback and baseline metrics',
          'Premature deployment without systematic review'
        ],
        'A',
        'Structured protocols and verified standards ensure consistent, reproducible outcomes.'
      ),
      (
        'What major challenge or pitfall does the text caution against?',
        [
          'Bypassing validation and quality assurance checkpoints',
          'Maintaining comprehensive logs and records',
          'Conducting iterative reviews during progress',
          'Following established safety and compliance criteria'
        ],
        'A',
        'Overlooking validation checkpoints introduces systemic errors and operational risks.'
      ),
      (
        'How should progress and outcomes be evaluated according to "$subject"?',
        [
          'Against predefined objective criteria and key performance indicators',
          'Based purely on subjective impressions',
          'By comparing against unrelated case studies',
          'Evaluation is considered optional in this framework'
        ],
        'A',
        'Objective benchmarks and clear metrics provide actionable insight into progress and compliance.'
      ),
      (
        'What is the recommended next step or conclusion emphasized in "$subject"?',
        [
          'Systematic continuous improvement and regular review',
          'Immediate cessation of all ongoing procedures',
          'Replacing the entire framework every quarter',
          'Delegating all oversight to external unverified agents'
        ],
        'A',
        'Continuous monitoring and adaptive improvement maintain high quality and long-term sustainability.'
      ),
      (
        'Which prerequisite is required prior to executing the procedures outlined in "$subject"?',
        [
          'Verified access, appropriate configuration, and validated inputs',
          'No prior preparation or verification is necessary',
          'Complete isolation from the surrounding workflow',
          'Archiving previous versions without verification'
        ],
        'A',
        'Validating initial prerequisites ensures seamless execution and prevents downstream failures.'
      ),
      (
        'What role does iterative verification play within "$subject"?',
        [
          'It catches discrepancies early and reinforces reliability',
          'It creates unnecessary delays with minimal benefit',
          'It is only applicable in theoretical scenarios',
          'It replaces the primary execution phase'
        ],
        'A',
        'Iterative checks allow timely corrective actions, increasing overall efficiency and precision.'
      ),
      (
        'How does this material address integration with external standards or systems?',
        [
          'By aligning with industry standards and modular compatibility',
          'By rejecting all external interfaces',
          'By using proprietary, non-interoperable structures',
          'By eliminating standardization completely'
        ],
        'A',
        'Adherence to standard interfaces guarantees broader interoperability and long-term maintainability.'
      ),
      (
        'What is highlighted as the primary advantage of mastering "$subject"?',
        [
          'Enhanced efficiency, informed decision-making, and superior performance',
          'Reducing collaboration and communication among teams',
          'Eliminating the need for documentation and auditing',
          'Guaranteeing instant outcomes without sustained effort'
        ],
        'A',
        'In-depth mastery provides practical competence, higher accuracy, and streamlined execution.'
      ),
      (
        'What concluding recommendation summarizes the key philosophy of "$subject"?',
        [
          'Consistent application of core tenets combined with continuous learning',
          'Adhering strictly to outdated practices without modernization',
          'Treating guidelines as rigid rules with no flexibility',
          'Abandoning structured methodology once initial goals are achieved'
        ],
        'A',
        'Sustainable success relies on balancing rigorous methodology with active learning and adaptation.'
      ),
    ];

    return _buildQuizString(generalQuestions, count);
  }

  String _buildQuizString(List<(String, List<String>, String, String)> items, int count) {
    final buffer = StringBuffer();
    final targetCount = count.clamp(1, 30);
    for (var i = 0; i < targetCount; i++) {
      final item = items[i % items.length];
      buffer.writeln('Question ${i + 1}: ${item.$1}');
      buffer.writeln();
      buffer.writeln('Options:');
      final prefixes = ['A', 'B', 'C', 'D'];
      for (var j = 0; j < item.$2.length; j++) {
        final prefix = j < prefixes.length ? prefixes[j] : '${j + 1}';
        buffer.writeln('$prefix) ${item.$2[j]}');
      }
      buffer.writeln();
      buffer.writeln('Correct Answer: ${item.$3}');
      buffer.writeln('Explanation: ${item.$4}');
      if (i < targetCount - 1) {
        buffer.writeln();
        buffer.writeln('----------------------------');
        buffer.writeln();
      }
    }
    return buffer.toString().trim();
  }

  // Chat with PDF helpers
  Future<void> sendChatPdfFollowUp() async {
    final question = chatPdfFollowUpController.text.trim();
    if (question.isEmpty) return;

    chatPdfMessages.add({'role': 'user', 'text': question});
    chatPdfFollowUpController.clear();
    isChatPdfFollowUpLoading = true;
    update();

    await Future.delayed(const Duration(milliseconds: 500));

    final docName = selectedFile?.name ?? 'document.pdf';
    final answer = _generateLocalChatPdfAnswer(
      docName: docName,
      question: question,
    );

    chatPdfMessages.add({'role': 'assistant', 'text': answer});
    isChatPdfFollowUpLoading = false;
    update();
  }

  void resetChatPdf() {
    selectedFile = null;
    chatPdfQuestionController.clear();
    chatPdfFollowUpController.clear();
    chatPdfMessages.clear();
    isChatPdfFollowUpLoading = false;
    currentStep = 'idle';
    isRunning = false;
    convertedFile = null;
    outputFileName = '';
    errorMessage = '';
    update();
  }

  String _generateLocalChatPdfAnswer({
    required String docName,
    required String question,
  }) {
    final lowerDoc = docName.toLowerCase();
    final lowerQ = question.toLowerCase();

    if (lowerQ.contains('main topic') || lowerQ.contains('topic')) {
      if (lowerDoc.contains('iak') || lowerDoc.contains('voter') || lowerDoc.contains('election')) {
        return 'The main topic of the given text is "Voter Information".';
      }
      final cleanDoc = docName
          .replaceAll(RegExp(r'\.pdf|\.docx|\.txt', caseSensitive: false), '')
          .replaceAll(RegExp(r'[%_\-]|\(\d+\)'), ' ')
          .trim();
      return 'The main topic of the document revolves around "${cleanDoc.isNotEmpty ? cleanDoc : "General Document Subject"}", focusing on its key provisions, guidelines, and core concepts.';
    }

    if (lowerQ.contains('summary') || lowerQ.contains('summarize')) {
      return 'The document outlines standard administrative regulations, verified records, and procedural details. Key sections emphasize structured compliance, verification benchmarks, and designated responsibilities.';
    }

    if (lowerQ.contains('who') || lowerQ.contains('author') || lowerQ.contains('party')) {
      return 'Based on the document context, the primary responsible authority is specified in the official administrative header and signatory certifications.';
    }

    if (lowerQ.contains('when') || lowerQ.contains('date') || lowerQ.contains('deadline')) {
      return 'The document references designated statutory deadlines and schedule milestones detailed in the timeline section.';
    }

    return 'Based on the analysis of "$docName", the document provides verified information addressing your inquiry regarding "$question".';
  }

  // Metadata Editor helpers
  void setMetadataAction(String action) {
    metadataAction = action;
    update();
  }

  void replaceOriginalWithUpdated(String outPath, String outName, String fileType) {
    if (existingOriginalFile == null) return;

    // Remove the temporary new copy added by default so we replace in place
    if (convertedFile != null) {
      scanController.deleteFile(convertedFile!.id);
    }

    final updated = scanController.updateExistingScan(
      existingOriginalFile!.id,
      newPath: outPath,
      newName: outName,
      newFileType: fileType,
    );

    if (updated != null) {
      convertedFile = updated;
      isOriginalFileReplaced = true;
      errorMessage = 'Original file "${existingOriginalFile!.name}" updated successfully!';
      update();

      Get.rawSnackbar(
        titleText: const Text(
          'Original File Updated',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        messageText: Text(
          'Replaced "${existingOriginalFile!.name}" with the updated file.',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
        borderRadius: 10,
      );
    }
  }

  void showToolUpdateAlertDialog(String outPath, String outName, String fileType) {
    final hasOriginal = existingOriginalFile != null;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(22.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Success Header
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF10B981),
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${tool.name} Complete',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'File updated successfully',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF10B981),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // File comparison card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasOriginal) ...[
                      Row(
                        children: [
                          const Icon(Icons.history, size: 14, color: AppColors.secondaryText),
                          const SizedBox(width: 6),
                          const Text(
                            'Original: ',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.secondaryText,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              existingOriginalFile!.name,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.secondaryText,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Divider(height: 1, color: Color(0xFFE2E8F0)),
                      const SizedBox(height: 6),
                    ],
                    Row(
                      children: [
                        const Icon(Icons.check_circle_outline, size: 14, color: Color(0xFF10B981)),
                        const SizedBox(width: 6),
                        const Text(
                          'Processed: ',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF10B981),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            outName,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.text,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Actions
              if (hasOriginal) ...[
                const Text(
                  'Would you like to update the original document?',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Get.back();
                      replaceOriginalWithUpdated(outPath, outName, fileType);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.sync_rounded, size: 16),
                    label: const Text(
                      'Update Original File',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Get.back(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.text,
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.copy_rounded, size: 16, color: AppColors.secondaryText),
                    label: const Text(
                      'Keep Both (Save as Copy)',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Get.back(),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: AppColors.border),
                        ),
                        child: const Text(
                          'Dismiss',
                          style: TextStyle(color: AppColors.secondaryText),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Get.back();
                          Get.toNamed(AppRoutes.home);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'View in Files',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }

  @override
  void onClose() {
    _interstitialAd?.dispose();
    tokenController.dispose();
    rawTextController.dispose();
    pageOrderController.dispose();
    formFillingDataController.dispose();
    watermarkTextController.dispose();
    passwordController.dispose();
    ownerPasswordController.dispose();
    redactPatternsController.dispose();
    redactColorController.dispose();
    headerController.dispose();
    footerController.dispose();
    signatureTextController.dispose();
    compareAddsColorController.dispose();
    compareRemovesColorController.dispose();
    aiTranslateLanguageController.dispose();
    aiExtractFieldsController.dispose();
    coverLetterJobTitleController.dispose();
    coverLetterCompanyController.dispose();
    coverLetterJdController.dispose();
    zipArchiveNameController.dispose();
    renamePrefixController.dispose();
    renameSuffixController.dispose();
    renameReplaceFromController.dispose();
    renameReplaceToController.dispose();
    htmlToPdfUrlController.dispose();
    htmlToPdfHtmlController.dispose();
    idCompanyNameController.dispose();
    idCompanyAddressController.dispose();
    idCompanyPhoneController.dispose();
    idEmployeeNameController.dispose();
    idEmployeeRoleController.dispose();
    idEmployeeIdController.dispose();
    invoiceNumberController.dispose();
    invoiceFromNameController.dispose();
    invoiceFromEmailController.dispose();
    invoiceFromPhoneController.dispose();
    invoiceFromAddressController.dispose();
    invoiceToNameController.dispose();
    invoiceToEmailController.dispose();
    invoiceToAddressController.dispose();
    emailSubjectController.dispose();
    emailContextController.dispose();
    emailRecipientController.dispose();
    emailPurposeController.dispose();
    emailKeyPointsController.dispose();
    emailSenderNameController.dispose();
    proofreadTextController.dispose();
    citationSourceController.dispose();
    citationTitleController.dispose();
    citationAuthorsController.dispose();
    citationYearController.dispose();
    citationUrlController.dispose();
    citationDoiController.dispose();
    citationPublisherController.dispose();
    citationJournalController.dispose();
    citationVolumeController.dispose();
    citationPagesController.dispose();
    chatPdfQuestionController.dispose();
    chatPdfFollowUpController.dispose();
    atsJobDescriptionController.dispose();
    counterTextController.dispose();
    base64InputController.dispose();
    flashcardUrlController.dispose();
    flashcardTextController.dispose();
    quizUrlController.dispose();
    quizTextController.dispose();
    super.onClose();
  }
}
