import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:plainscan/core/controllers/tool_executor_controller.dart';
import 'package:plainscan/core/utils/local_document_generators.dart';
import 'package:plainscan/models/file_model.dart';
import 'package:plainscan/models/tool_model.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PDF Lock and Unlock Tests', () {
    late Directory tempDir;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      Get.reset();
      Get.testMode = true;
      tempDir = Directory.systemTemp.createTempSync('pdf_lock_test_');
    });

    tearDown(() {
      Get.reset();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('LocalDocumentPdfGenerator.lockPdf locks PDF with password and encryption dictionary', () {
      final minimalPdf = Uint8List.fromList(LocalDocumentPdfGenerator.minimalPdfBytes);
      final lockedBytes = LocalDocumentPdfGenerator.lockPdf(
        minimalPdf,
        userPassword: 'secretpassword123',
        allowPrinting: true,
        allowCopying: false,
      );

      expect(lockedBytes.isNotEmpty, true);
      final lockedStr = latin1.decode(lockedBytes);
      expect(lockedStr.contains('/Encrypt'), true);
      expect(lockedStr.contains('/Filter /Standard'), true);
      expect(lockedStr.contains('/V 2'), true);
      expect(lockedStr.contains('/R 3'), true);
      expect(lockedStr.contains('/P'), true);
      expect(lockedStr.contains('/O <'), true);
      expect(lockedStr.contains('/U <'), true);
    });

    test('LocalDocumentPdfGenerator.unlockPdf removes encryption dictionary from PDF', () {
      final minimalPdf = Uint8List.fromList(LocalDocumentPdfGenerator.minimalPdfBytes);
      final lockedBytes = LocalDocumentPdfGenerator.lockPdf(
        minimalPdf,
        userPassword: 'mypassword',
      );

      final unlockedBytes = LocalDocumentPdfGenerator.unlockPdf(
        lockedBytes,
        password: 'mypassword',
      );

      final unlockedStr = latin1.decode(unlockedBytes);
      expect(unlockedStr.contains('/Encrypt'), false);
    });

    test('ToolExecutorController locks PDF without displaying invalid password error', () async {
      final testPdf = File('${tempDir.path}/sample-form.pdf');
      testPdf.writeAsBytesSync(LocalDocumentPdfGenerator.minimalPdfBytes);

      final lockTool = allPlainscanTools.firstWhere((t) => t.slug == 'pdf-lock');
      final fileModel = FileModel(
        id: '1',
        name: 'sample-form.pdf',
        createdDate: DateTime.now(),
        sizeKb: 1200.0,
        fileType: 'PDF',
        path: testPdf.path,
      );

      final controller = Get.put(ToolExecutorController(
        tool: lockTool,
        initialFiles: [fileModel],
      ));

      controller.passwordController.text = '98765432';
      await controller.executeJobFlow();

      expect(controller.currentStep, 'success');
      expect(controller.errorMessage, contains('password-protected and encrypted'));
      expect(controller.convertedFile, isNotNull);
      expect(controller.isPasswordError, false);
    });
  });
}
