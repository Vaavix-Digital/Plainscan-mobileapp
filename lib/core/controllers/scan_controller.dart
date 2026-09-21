import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_doc_scanner/flutter_doc_scanner.dart';
import 'package:get/get.dart';
import 'package:plainscan/core/constants/app_colors.dart';
import 'package:plainscan/core/services/storage_service.dart';
import 'package:plainscan/features/alltools/tool_executor_page.dart';
import 'package:plainscan/models/file_model.dart';
import 'package:plainscan/models/tool_model.dart';

class ScanController extends GetxController {
  final scannedFiles = <FileModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadUserFiles();
  }

  Future<void> loadUserFiles() async {
    try {
      final files = await StorageService.getUserScannedFiles();
      scannedFiles.value = files;
    } catch (_) {}
  }

  Future<void> _persistFiles() async {
    try {
      await StorageService.saveUserScannedFiles(scannedFiles.toList());
    } catch (_) {}
  }

  void clearFiles() {
    scannedFiles.clear();
  }

  void addScan(String filePath, {String? customName, String fileType = 'PDF'}) {
    final fileName = customName ?? 'Scan_${DateTime.now().millisecondsSinceEpoch}.${fileType.toLowerCase()}';
    final newFile = FileModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: fileName,
      createdDate: DateTime.now(),
      sizeKb: 1204.0, // mock size
      fileType: fileType,
      path: filePath,
    );

    scannedFiles.insert(0, newFile);
    _persistFiles();
  }

  FileModel? updateExistingScan(
    String fileId, {
    required String newPath,
    String? newName,
    double? newSizeKb,
    String? newFileType,
  }) {
    final index = scannedFiles.indexWhere((file) => file.id == fileId);
    if (index != -1) {
      final existing = scannedFiles[index];
      final updated = existing.copyWith(
        path: newPath,
        name: newName ?? existing.name,
        sizeKb: newSizeKb ?? existing.sizeKb,
        fileType: newFileType ?? existing.fileType,
        createdDate: DateTime.now(),
      );
      scannedFiles[index] = updated;
      _persistFiles();
      return updated;
    }
    return null;
  }

  void toggleFavorite(String id) {
    final index = scannedFiles.indexWhere((file) => file.id == id);
    if (index != -1) {
      scannedFiles[index] = scannedFiles[index].copyWith(isFavorite: !scannedFiles[index].isFavorite);
      _persistFiles();
    }
  }

  void deleteFile(String id) {
    scannedFiles.removeWhere((file) => file.id == id);
    _persistFiles();
  }

  void renameFile(String id, String newName) {
    final index = scannedFiles.indexWhere((file) => file.id == id);
    if (index != -1) {
      scannedFiles[index] = scannedFiles[index].copyWith(name: newName);
      _persistFiles();
    }
  }

  /// Uses flutter_doc_scanner to capture document images and passes them directly
  /// to the JPG to PDF tool for immediate conversion without mock preview pages.
  Future<void> openScanner() async {
    final isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);

    try {
      List<String> imagePaths = [];

      if (isMobile) {
        // Retrieve scanned documents as image photos via flutter_doc_scanner
        final result = await FlutterDocScanner().getScannedDocumentAsImages(page: 20, imageFormat: ImageFormat.jpeg,);
        if (result != null && result.images.isNotEmpty) {
          imagePaths = result.images;
        } else {
          dynamic scannedDocuments = await FlutterDocScanner().getScanDocuments(page: 20);
          if (scannedDocuments == null) {
            return;
          }

          if (scannedDocuments is String && scannedDocuments.isNotEmpty) {
            imagePaths = [scannedDocuments];
          } else if (scannedDocuments is Map && scannedDocuments.containsKey('images')) {
            final imagesList = scannedDocuments['images'];
            if (imagesList is List && imagesList.isNotEmpty) {
              imagePaths = imagesList.map((e) => e.toString()).toList();
            }
          } else if (scannedDocuments is List && scannedDocuments.isNotEmpty) {
            imagePaths = scannedDocuments.map((e) => e.toString()).toList();
          } else if (scannedDocuments is Map && scannedDocuments.containsKey('pdf')) {
            final pdfPath = scannedDocuments['pdf']?.toString();
            if (pdfPath != null && pdfPath.isNotEmpty) {
              addScan(pdfPath, fileType: 'PDF');
              if (!Get.testMode && Get.overlayContext != null) {
                Get.rawSnackbar(
                  messageText: const Text(
                    'Document scanned successfully as PDF!',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  backgroundColor: AppColors.primary,
                  snackPosition: SnackPosition.BOTTOM,
                  margin: const EdgeInsets.all(12),
                  borderRadius: 8,
                );
              }
              return;
            }
          }
        }
      } else {
        // Fallback for non-mobile platforms / testing environments
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        imagePaths = ['mock_scan_$timestamp.jpg'];
      }

      if (imagePaths.isEmpty) {
        return;
      }

      // Convert captured images directly into a PDF via the JPG to PDF tool
      final List<FileModel> files = [];
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      for (int i = 0; i < imagePaths.length; i++) {
        final path = imagePaths[i];
        final fileName = 'Scan_${timestamp}_Page${i + 1}.jpg';

        final fileModel = FileModel(
          id: '${timestamp}_$i',
          name: fileName,
          createdDate: DateTime.now(),
          sizeKb: 850.0,
          fileType: 'JPG',
          path: path,
        );

        addScan(path, customName: fileName, fileType: 'JPG');
        files.add(fileModel);
      }

      // Find the JPG to PDF tool
      final jpgToPdfTool = allPlainscanTools.firstWhere(
        (t) => t.id == 'jpg-to-pdf',
        orElse: () => const ToolModel(
          id: 'jpg-to-pdf',
          name: 'JPG to PDF',
          icon: Icons.photo_size_select_actual_outlined,
          color: AppColors.purple,
          categoryId: 'conversion',
          category: 'PDF Conversion',
          inputFormat: 'image (.jpg)',
          outputFormat: '.pdf',
          isMultiFile: true,
          description: 'Convert single or multiple JPG images into a clean PDF document.',
        ),
      );

      // Pass the captured images directly to the JPG to PDF tool for conversion
      Get.to(
        () => ToolExecutorPage(
          tool: jpgToPdfTool,
          initialFiles: files,
          autoExecute: false,
        ),
      );
    } catch (e) {
      if (!Get.testMode && Get.overlayContext != null) {
        Get.rawSnackbar(
          messageText: Text(
            'Scanner error: $e',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: AppColors.coral,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(12),
          borderRadius: 8,
        );
      }
    }
  }
}
  

