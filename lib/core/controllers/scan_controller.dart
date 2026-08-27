import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_doc_scanner/flutter_doc_scanner.dart';
import 'package:get/get.dart';
import 'package:plainscan/core/constants/app_colors.dart';
import 'package:plainscan/features/scanner/pages/scanner_mock_page.dart';
import 'package:plainscan/models/file_model.dart';

class ScanController extends GetxController {
  
  final scannedFiles = <FileModel>[
    FileModel(
      id: '1',
      name: 'Tax_Return_2026.pdf',
      createdDate: DateTime.now().subtract(const Duration(hours: 2)),
      sizeKb: 1024.5,
      fileType: 'PDF',
      isFavorite: true,
    ),
    FileModel(
      id: '2',
      name: 'Receipt_Uber_August.png',
      createdDate: DateTime.now().subtract(const Duration(days: 1)),
      sizeKb: 450.2,
      fileType: 'PNG',
    ),
    FileModel(
      id: '3',
      name: 'Meeting_Notes.pdf',
      createdDate: DateTime.now().subtract(const Duration(days: 3)),
      sizeKb: 2048.0,
      fileType: 'PDF',
    ),
    FileModel(
      id: '4',
      name: 'ID_Card_Front.jpg',
      createdDate: DateTime.now().subtract(const Duration(days: 5)),
      sizeKb: 890.5,
      fileType: 'JPG',
      isFavorite: true,
    ),
    FileModel(
      id: '5',
      name: 'Rent_Agreement.pdf',
      createdDate: DateTime.now().subtract(const Duration(days: 10)),
      sizeKb: 4120.0,
      fileType: 'PDF',
    ),
  ].obs;

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
  }

  void toggleFavorite(String id) {
    final index = scannedFiles.indexWhere((file) => file.id == id);
    if (index != -1) {
      scannedFiles[index] = scannedFiles[index].copyWith(isFavorite: !scannedFiles[index].isFavorite);
    }
  }

  void deleteFile(String id) {
    scannedFiles.removeWhere((file) => file.id == id);
  }

  void renameFile(String id, String newName) {
    final index = scannedFiles.indexWhere((file) => file.id == id);
    if (index != -1) {
      scannedFiles[index] = scannedFiles[index].copyWith(name: newName);
    }
  }




  // Your existing scan variables and methods...

  Future<void> openScanner() async {
    final isMobile =
        !kIsWeb && (Platform.isAndroid || Platform.isIOS);

    if (!isMobile) {
      Get.to(
        () => const ScannerMockPage(),
        fullscreenDialog: true,
      );
      return;
    }

    try {
      dynamic scannedDocuments =
          await FlutterDocScanner().getScanDocuments(
        page: 4,
      );

      if (scannedDocuments == null) {
        return;
      }

      String? path;

      if (scannedDocuments is String) {
        path = scannedDocuments;
      } else if (scannedDocuments is Map &&
          scannedDocuments.containsKey('pdf')) {
        path = scannedDocuments['pdf'];
      } else if (scannedDocuments is Map &&
          scannedDocuments.containsKey('images')) {
        final imagesList = scannedDocuments['images'];

        if (imagesList is List && imagesList.isNotEmpty) {
          path = imagesList.first;
        }
      } else if (scannedDocuments is List &&
          scannedDocuments.isNotEmpty) {
        path = scannedDocuments.first;
      }

      if (path == null) {
        return;
      }

      final fileType =
          path.toLowerCase().endsWith('.pdf') ? 'PDF' : 'JPG';

      addScan(
        path,
        fileType: fileType,
      );

      Get.rawSnackbar(
        messageText: const Text(
          'Document scanned successfully!',
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
    } catch (e) {
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
  

