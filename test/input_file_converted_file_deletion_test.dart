import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:plainscan/core/controllers/scan_controller.dart';
import 'package:plainscan/core/controllers/tool_executor_controller.dart';
import 'package:plainscan/models/tool_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Get.reset();
  });

  group('Input File & Converted File Deletion Tests', () {
    test('Deleting an input file automatically deletes its converted file from ScanController', () async {
      final scanController = Get.put(ScanController());

      // 1. Add input file
      final inputFile = scanController.addScan('/path/input_doc.pdf', customName: 'Input_Doc.pdf', fileType: 'PDF');
      expect(scanController.scannedFiles.length, 1);

      // 2. Add converted file linked to input file
      final convertedFile = scanController.addScan(
        '/path/converted_doc.docx',
        customName: 'Converted_Doc.docx',
        fileType: 'DOCX',
        sourceFileId: inputFile.id,
      );
      expect(scanController.scannedFiles.length, 2);

      // 3. Delete input file
      scanController.deleteFile(inputFile.id);

      // 4. Verify both input file and converted file are deleted
      expect(scanController.scannedFiles.any((f) => f.id == inputFile.id), isFalse);
      expect(scanController.scannedFiles.any((f) => f.id == convertedFile.id), isFalse);
      expect(scanController.scannedFiles, isEmpty);
    });

    test('Deleting an input file with multiple source IDs removes the associated converted file', () async {
      final scanController = Get.put(ScanController());

      final fileA = scanController.addScan('/path/a.pdf', customName: 'A.pdf');
      final fileB = scanController.addScan('/path/b.pdf', customName: 'B.pdf');
      expect(scanController.scannedFiles.length, 2);

      // Converted merged file
      final mergedFile = scanController.addScan(
        '/path/merged.pdf',
        customName: 'Merged.pdf',
        sourceFileIds: [fileA.id, fileB.id],
      );
      expect(scanController.scannedFiles.length, 3);

      // Delete fileA
      scanController.deleteFile(fileA.id);

      // Merged file depends on fileA, so it must be removed
      expect(scanController.scannedFiles.any((f) => f.id == fileA.id), isFalse);
      expect(scanController.scannedFiles.any((f) => f.id == mergedFile.id), isFalse);
      // fileB remains
      expect(scanController.scannedFiles.length, 1);
      expect(scanController.scannedFiles.first.id, fileB.id);
    });

    test('Removing selected file in ToolExecutorController removes input file and its converted file', () async {
      final scanController = Get.put(ScanController());
      final toolExecutor = Get.put(ToolExecutorController(tool: allPlainscanTools.first));

      // 1. Add input file and set as selected
      final inputFile = scanController.addScan('/path/sample.png', customName: 'Sample.png', fileType: 'PNG');
      toolExecutor.selectedFile = inputFile;

      // 2. Add converted file while ToolExecutorController is active (auto-linking sourceFileId)
      final convertedFile = scanController.addScan('/path/sample.pdf', customName: 'Sample.pdf', fileType: 'PDF');
      toolExecutor.convertedFile = convertedFile;

      expect(convertedFile.sourceFileId, inputFile.id);
      expect(scanController.scannedFiles.length, 2);

      // 3. Remove selected file
      toolExecutor.removeSelectedFile(inputFile);

      // 4. Verify input file and converted file are both deleted
      expect(scanController.scannedFiles.any((f) => f.id == inputFile.id), isFalse);
      expect(scanController.scannedFiles.any((f) => f.id == convertedFile.id), isFalse);
      expect(toolExecutor.convertedFile, isNull);
    });
  });
}
