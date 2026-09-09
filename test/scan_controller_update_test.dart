import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:plainscan/core/controllers/scan_controller.dart';
import 'package:plainscan/models/file_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ScanController controller;

  setUp(() {
    Get.reset();
    controller = Get.put(ScanController());
  });

  tearDown(() {
    Get.reset();
  });

  group('ScanController Update Tests', () {
    test('updateExistingScan modifies file in place without adding duplicate', () {
      final initialCount = controller.scannedFiles.length;
      final targetFile = controller.scannedFiles.first;
      final targetId = targetFile.id;

      final updatedFile = controller.updateExistingScan(
        targetId,
        newPath: '/tmp/Tax_Return_2026_compressed.pdf',
        newName: 'Tax_Return_2026_compressed.pdf',
        newSizeKb: 512.0,
        newFileType: 'PDF',
      );

      expect(updatedFile, isNotNull);
      expect(controller.scannedFiles.length, initialCount); // No duplicate added
      expect(controller.scannedFiles.first.id, targetId);
      expect(controller.scannedFiles.first.name, 'Tax_Return_2026_compressed.pdf');
      expect(controller.scannedFiles.first.path, '/tmp/Tax_Return_2026_compressed.pdf');
      expect(controller.scannedFiles.first.sizeKb, 512.0);
    });

    test('updateExistingScan returns null if file ID is not found', () {
      final updated = controller.updateExistingScan(
        'non_existent_id',
        newPath: '/tmp/test.pdf',
      );
      expect(updated, isNull);
    });

    test('FileModel copyWith supports all updated properties', () {
      final original = FileModel(
        id: 'file_1',
        name: 'original.pdf',
        createdDate: DateTime(2026, 1, 1),
        sizeKb: 2000.0,
        fileType: 'PDF',
        path: '/original.pdf',
        isFavorite: false,
      );

      final modified = original.copyWith(
        name: 'modified.pdf',
        path: '/new/path.pdf',
        sizeKb: 1000.0,
        fileType: 'DOCX',
        isFavorite: true,
      );

      expect(modified.id, 'file_1');
      expect(modified.name, 'modified.pdf');
      expect(modified.path, '/new/path.pdf');
      expect(modified.sizeKb, 1000.0);
      expect(modified.fileType, 'DOCX');
      expect(modified.isFavorite, isTrue);
    });
  });
}
