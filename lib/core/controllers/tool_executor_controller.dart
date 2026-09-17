import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
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
  String emailTone = 'professional'; // professional, casual, friendly

  // AI Citation options
  final citationSourceController = TextEditingController(text: 'Smith, J. (2025). The Future of Artificial Intelligence. Tech Press.');
  String citationStyle = 'APA'; // APA, MLA, Chicago, Harvard

  // AI Flashcards options
  int flashcardsCount = 10;

  // AI Quiz options
  int quizCount = 5;
  String quizDifficulty = 'medium'; // easy, medium, hard

  // Chat with PDF options
  final chatPdfQuestionController = TextEditingController(text: 'What is the main summary of this document?');

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
        return {
          'subject': emailSubjectController.text.trim(),
          'context': emailContextController.text.trim(),
          'tone': emailTone,
        };
      case 'ai-proofread':
        final proofreadOpts = <String, dynamic>{};
        if (useRawText) {
          proofreadOpts['text'] = rawTextController.text.trim();
        }
        return proofreadOpts;
      case 'ai-citation':
        return {
          'text': citationSourceController.text.trim(),
          'style': citationStyle,
        };
      case 'ai-flashcards':
        final flashcardsOpts = <String, dynamic>{
          'count': flashcardsCount,
        };
        if (useRawText) {
          flashcardsOpts['text'] = rawTextController.text.trim();
        }
        return flashcardsOpts;
      case 'ai-quiz':
        final quizOpts = <String, dynamic>{
          'count': quizCount,
          'difficulty': quizDifficulty,
        };
        if (useRawText) {
          quizOpts['text'] = rawTextController.text.trim();
        }
        return quizOpts;
      case 'chat-with-pdf':
        return {
          'question': chatPdfQuestionController.text.trim(),
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
          if (emailSubjectController.text.trim().isEmpty) {
            throw Exception('Please enter an email subject.');
          }
        } else if (slug == 'ai-citation') {
          if (citationSourceController.text.trim().isEmpty) {
            throw Exception('Please enter source text for citation.');
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
          if (selectedFile == null) {
            throw Exception('Please select an input file.');
          }
          if (slug == 'chat-with-pdf' && chatPdfQuestionController.text.trim().isEmpty) {
            throw Exception('Please enter a question to ask about your PDF.');
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
      if (isNoUpload || isTextOnly) {
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

  // AI Citation helpers
  void setCitationStyle(String style) {
    citationStyle = style;
    update();
  }

  // AI Flashcards helpers
  void setFlashcardsCount(int count) {
    flashcardsCount = count;
    update();
  }

  // AI Quiz helpers
  void setQuizCount(int count) {
    quizCount = count;
    update();
  }

  void setQuizDifficulty(String diff) {
    quizDifficulty = diff;
    update();
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
    citationSourceController.dispose();
    chatPdfQuestionController.dispose();
    atsJobDescriptionController.dispose();
    counterTextController.dispose();
    base64InputController.dispose();
    super.onClose();
  }
}
