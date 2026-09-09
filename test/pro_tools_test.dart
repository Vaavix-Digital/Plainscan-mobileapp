import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:plainscan/core/services/storage_service.dart';
import 'package:plainscan/models/tool_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Pro Tools Configuration', () {
    final expectedProToolIds = [
      'pdf-to-epub',
      'ocr-to-pdf',
      'ocr-to-word',
      'ocr-to-excel',
      'ai-summarize',
      'ai-rewrite',
      'ai-translate',
      'ai-extract-data',
      'ai-extract-key-points',
      'ai-expand',
      'ai-condense',
      'ai-keywords',
      'grammar-checker',
      'humanize-ai-content',
      'ai-detector',
      'plagiarism-check',
      'summarize-long-pdfs',
      'batch-pdf-converter',
      'form-filling',
      'pdf-to-fillable-form',
      'pdf-compare',
    ];

    test('exactly 21 specified tools are marked as Pro (isFree == false)', () {
      final proToolsInList = allPlainscanTools.where((t) => (t.isFree ?? true) == false).toList();
      expect(proToolsInList.length, 21);

      for (final id in expectedProToolIds) {
        final tool = allPlainscanTools.firstWhere(
          (t) => t.id == id || t.slug == id,
          orElse: () => throw Exception('Tool $id not found in allPlainscanTools'),
        );
        expect(tool.isFree, isFalse, reason: 'Tool $id must have isFree == false');
      }
    });

    test('standard free tools remain isFree == true', () {
      final freeToolIds = ['pdf-to-word', 'word-to-pdf', 'pdf-merge', 'pdf-compress', 'pdf-split'];
      for (final id in freeToolIds) {
        final tool = allPlainscanTools.firstWhere((t) => t.id == id);
        expect(tool.isFree ?? true, isTrue, reason: 'Tool $id must be free');
      }
    });

    test('StorageService pro plan detection', () async {
      await StorageService.savePlan('free');
      expect(await StorageService.isProUser(), isFalse);

      await StorageService.savePlan('pro');
      expect(await StorageService.isProUser(), isTrue);

      await StorageService.savePlan('PRO');
      expect(await StorageService.isProUser(), isTrue);
    });
  });
}
