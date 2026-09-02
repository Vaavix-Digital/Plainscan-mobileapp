import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:plainscan/core/constants/app_colors.dart';
import 'package:plainscan/core/controllers/scan_controller.dart';
import 'package:plainscan/core/services/jobflow_services.dart';
import 'package:plainscan/core/services/storage_service.dart';
import 'package:plainscan/helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:plainscan/models/file_model.dart';
import 'package:plainscan/models/tool_model.dart';

class ToolExecutorController extends GetxController {
  final ToolModel tool;
  final ScanController scanController = Get.find<ScanController>();

  ToolExecutorController({required this.tool});

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

  @override
  void onInit() {
    super.onInit();
    _loadInterstitialAd();
    loadSavedToken();
    initializeDefaults();
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

  bool isMultiFileTool() {
    final slug = getSlug();
    return slug == 'pdf-merge' ||
        slug == 'pdf-compare' ||
        slug == 'file-to-zip' ||
        slug == 'batch-pdf-converter' ||
        slug == 'batch-converter' ||
        slug == 'batch-rename';
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
        slug == 'plagiarism-check';
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
        return 'docx';
      case 'word-to-pdf':
      case 'ppt-to-pdf':
      case 'excel-to-pdf':
      case 'jpg-to-pdf':
      case 'png-to-pdf':
      case 'webp-to-pdf':
      case 'image-to-pdf':
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
        return 'pdf';
      case 'pdf-to-excel':
      case 'ocr-to-excel':
      case 'pdf-extract-table':
        return 'xlsx';
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
        return 'txt';
      case 'pdf-to-markdown':
        return 'md';
      case 'ai-extract-data':
      case 'ai-keywords':
      case 'ai-detector':
        return 'json';
      default:
        return 'pdf';
    }
  }

  Future<void> executeJobFlow() async {
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
    update();

    try {
      final slug = getSlug();
      final isMulti = isMultiFileTool();
      final isTextOnly = isTextOptionSupported() && useRawText;

      final services = JobflowApiServices(accessToken: tokenToUse);
      List<String> uploadedFileIds = [];
      String singleUploadedFileId = '';

      // STEP 1: Upload File(s) (unless it is a text-only call)
      if (!isTextOnly) {
        if (isMulti) {
          if (selectedFiles.isEmpty) {
            throw Exception('Please select at least one input file.');
          }
          for (var i = 0; i < selectedFiles.length; i++) {
            final fModel = selectedFiles[i];
            currentStep = 'uploading';
            errorMessage = 'Uploading file ${i + 1}/${selectedFiles.length}: ${fModel.name}';
            update();
            final physicalFile = await getOrCreatePhysicalFile(fModel);
            final fileId = await services.uploadFile(physicalFile);
            uploadedFileIds.add(fileId);
          }
        } else {
          if (selectedFile == null) {
            throw Exception('Please select an input file.');
          }
          currentStep = 'uploading';
          errorMessage = 'Uploading ${selectedFile!.name}...';
          update();
          final physicalFile = await getOrCreatePhysicalFile(selectedFile!);
          singleUploadedFileId = await services.uploadFile(physicalFile);
        }
      }

      // STEP 2: Create Job
      currentStep = 'creating';
      errorMessage = 'Submitting job details...';
      update();

      final options = getOptionsJson();
      String jobIdLocal = '';

      final requestBody = <String, dynamic>{};
      if (isTextOnly) {
        // Text-only tool doesn't send file IDs
      } else if (isMulti) {
        requestBody['file_ids'] = uploadedFileIds;
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

      // STEP 3: Poll Status
      Map<String, dynamic> jobResult = {};
      while (true) {
        pollingCount++;
        errorMessage = 'Waiting for job completion (Attempt $pollingCount)...';
        update();

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

      // STEP 4: Download Output File
      currentStep = 'downloading';
      errorMessage = 'Downloading completed output...';
      update();

      final outputList = jobResult['output_file_ids'] as List?;
      if (outputList == null || outputList.isEmpty) {
        throw Exception('Completed job did not return any output file IDs.');
      }
      final outputFileId = outputList.first.toString();

      final extension = getExpectedExtension();
      final baseNameWithoutExtension = useRawText 
          ? '${slug}_result' 
          : (isMulti ? '${slug}_merged' : selectedFile!.name.split('.').first);
      final outName = '${baseNameWithoutExtension}_processed.$extension';
      
      final tempDir = Directory.systemTemp;
      final outPath = '${tempDir.path}/$outName';

      await services.downloadFile(
        fileId: outputFileId,
        savePath: outPath,
      );

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
      errorMessage = 'Success! File added to Files Manager.';
      outputFileName = outName;
      isRunning = false;
      update();

      Get.rawSnackbar(
        messageText: Text(
          'Tool execution complete! Saved: $outName',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primary,
        snackPosition: SnackPosition.BOTTOM,
      );
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
    super.onClose();
  }
}
