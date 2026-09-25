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

      // Verify that standard password validation accepts the correct password
      expect(LocalDocumentPdfGenerator.isLocallyUnlockable(lockedBytes, password: 'secretpassword123'), true);
      // Verify that incorrect password is rejected
      expect(LocalDocumentPdfGenerator.isLocallyUnlockable(lockedBytes, password: 'wrongpassword'), false);
      expect(
        () => LocalDocumentPdfGenerator.unlockPdf(lockedBytes, password: 'wrongpassword'),
        throwsA(isA<Exception>()),
      );
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

    test('ToolExecutorController unlocks PDF with valid password without displaying invalid password error', () async {
      final minimalPdf = Uint8List.fromList(LocalDocumentPdfGenerator.minimalPdfBytes);
      final lockedBytes = LocalDocumentPdfGenerator.lockPdf(
        minimalPdf,
        userPassword: 'validPassword123',
      );

      final testPdf = File('${tempDir.path}/locked-doc.pdf');
      testPdf.writeAsBytesSync(lockedBytes);

      final unlockTool = allPlainscanTools.firstWhere((t) => t.slug == 'pdf-unlock');
      final fileModel = FileModel(
        id: '2',
        name: 'locked-doc.pdf',
        createdDate: DateTime.now(),
        sizeKb: 1200.0,
        fileType: 'PDF',
        path: testPdf.path,
      );

      final controller = Get.put(ToolExecutorController(
        tool: unlockTool,
        initialFiles: [fileModel],
      ));

      expect(controller.isExecutionDisabled, false);

      controller.passwordController.text = 'validPassword123';
      await controller.executeJobFlow();

      expect(controller.currentStep, 'success');
      expect(controller.errorMessage, contains('unlocked and decrypted'));
      expect(controller.convertedFile, isNotNull);
      expect(controller.isPasswordError, false);
      expect(controller.isPdfLocked, false);
    });

    test('isExecutionDisabled is false when file is selected for pdf-unlock', () {
      final unlockTool = allPlainscanTools.firstWhere((t) => t.slug == 'pdf-unlock');
      final controller = Get.put(ToolExecutorController(tool: unlockTool));

      // With no file selected, execution is disabled
      expect(controller.isExecutionDisabled, true);

      // Once a file is selected, execution is enabled
      controller.selectedFile = FileModel(
        id: 'file-1',
        name: 'document.pdf',
        createdDate: DateTime.now(),
        sizeKb: 100,
        fileType: 'PDF',
      );
      expect(controller.isExecutionDisabled, false);
    });

    test('LocalDocumentPdfGenerator locks and unlocks content streams cleanly preserving document content', () {
      const streamText = 'Ticket: Tirur to Guruvayoor - PlainScan Confirmed';
      final pdfString =
          '%PDF-1.4\n'
          '%âãÏÓ\n'
          '1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n'
          '2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj\n'
          '3 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Contents 4 0 R >>\nendobj\n'
          '4 0 obj\n<< /Length ${streamText.length} >>\nstream\n'
          '$streamText\n'
          'endstream\nendobj\n'
          'xref\n0 5\n0000000000 65535 f \n'
          'trailer\n<< /Size 5 /Root 1 0 R >>\nstartxref\n250\n%%EOF\n';
      final originalBytes = Uint8List.fromList(latin1.encode(pdfString));

      // Lock the PDF
      final lockedBytes = LocalDocumentPdfGenerator.lockPdf(
        originalBytes,
        userPassword: 'mysecretpassword',
      );

      // Verify stream was encrypted: the plaintext ticket string should NOT appear in locked bytes
      final lockedStr = latin1.decode(lockedBytes);
      expect(lockedStr.contains(streamText), false);
      expect(lockedStr.contains('/Encrypt'), true);

      // Unlock the PDF
      final unlockedBytes = LocalDocumentPdfGenerator.unlockPdf(
        lockedBytes,
        password: 'mysecretpassword',
      );

      // Verify stream was decrypted: the plaintext ticket string MUST be restored!
      final unlockedStr = latin1.decode(unlockedBytes);
      expect(unlockedStr.contains(streamText), true);
      expect(unlockedStr.contains('/Encrypt'), false);
    });
  });
}

