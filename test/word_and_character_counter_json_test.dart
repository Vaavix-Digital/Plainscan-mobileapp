import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:plainscan/core/controllers/scan_controller.dart';
import 'package:plainscan/core/controllers/tool_executor_controller.dart';
import 'package:plainscan/core/services/background_job_service.dart';
import 'package:plainscan/features/alltools/tool_executor_page.dart';
import 'package:plainscan/models/tool_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Get.reset();
    Get.testMode = true;
    Get.put(ScanController());
    Get.put(BackgroundJobService());
  });

  tearDown(() {
    Get.reset();
  });

  group('Word and Character Counter JSON Output Tests', () {
    test('calculateCounterJson produces valid formatted JSON with all required statistics', () {
      const tool = ToolModel(
        id: 'word-counter',
        slug: 'word-counter',
        name: 'Word Counter',
        description: 'Count words and characters',
        icon: Icons.numbers,
        color: Colors.blue,
        categoryId: 'utility',
      );

      final controller = ToolExecutorController(tool: tool);
      const sampleText = 'PlainScan is a fast and powerful document scanner. It works seamlessly on mobile devices!';
      final jsonOutput = controller.calculateCounterJson(sampleText);

      final decoded = jsonDecode(jsonOutput) as Map<String, dynamic>;
      expect(decoded.containsKey('word_count'), isTrue);
      expect(decoded.containsKey('char_with_spaces'), isTrue);
      expect(decoded.containsKey('char_no_spaces'), isTrue);
      expect(decoded.containsKey('sentence_count'), isTrue);
      expect(decoded.containsKey('paragraph_count'), isTrue);
      expect(decoded.containsKey('reading_time_min'), isTrue);

      expect(decoded['word_count'], equals(14));
      expect(decoded['sentence_count'], equals(2));
      expect(decoded['paragraph_count'], equals(1));
      expect(decoded['char_with_spaces'], equals(sampleText.length));
      expect(decoded['char_no_spaces'], equals(sampleText.replaceAll(RegExp(r'\s+'), '').length));
      expect(decoded['reading_time_min'], equals(0.1));
    });

    testWidgets('Word Counter UI displays formatted JSON card with Process another item, Download TXT, Copy Text', (WidgetTester tester) async {
      const wordCounterTool = ToolModel(
        id: 'word-counter',
        slug: 'word-counter',
        name: 'Word Counter',
        description: 'Count words and characters in text',
        icon: Icons.numbers,
        color: Colors.indigo,
        categoryId: 'utility',
      );

      await tester.pumpWidget(
        const GetMaterialApp(
          home: ToolExecutorPage(
            tool: wordCounterTool,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final controller = Get.find<ToolExecutorController>();
      controller.counterTextController.text = 'The citation you shared appears to be a general reference.';
      controller.generatedCounterContent = controller.calculateCounterJson(controller.counterTextController.text);
      controller.currentStep = 'success';
      controller.update();
      await tester.pumpAndSettle();

      // Verify JSON output is displayed in the result card
      expect(find.text('Corrected Text'), findsOneWidget);
      expect(find.textContaining('"word_count":'), findsOneWidget);
      expect(find.textContaining('"char_with_spaces":'), findsOneWidget);
      expect(find.textContaining('"char_no_spaces":'), findsOneWidget);
      expect(find.textContaining('"sentence_count":'), findsOneWidget);
      expect(find.textContaining('"paragraph_count":'), findsOneWidget);
      expect(find.textContaining('"reading_time_min":'), findsOneWidget);

      // Verify Action Buttons
      expect(find.text('Process another item'), findsOneWidget);
      expect(find.text('Download TXT'), findsOneWidget);
      expect(find.text('Copy Text'), findsOneWidget);

      // Verify reset functionality
      await tester.tap(find.text('Process another item'));
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Process'), findsOneWidget);
    });

    testWidgets('Character Counter UI displays formatted JSON output', (WidgetTester tester) async {
      const charCounterTool = ToolModel(
        id: 'character-counter',
        slug: 'character-counter',
        name: 'Character Counter',
        description: 'Count characters and words in text',
        icon: Icons.pin_outlined,
        color: Colors.indigo,
        categoryId: 'utility',
      );

      await tester.pumpWidget(
        const GetMaterialApp(
          home: ToolExecutorPage(
            tool: charCounterTool,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final controller = Get.find<ToolExecutorController>();
      controller.counterTextController.text = 'Flutter makes cross platform development easy.';
      controller.generatedCounterContent = controller.calculateCounterJson(controller.counterTextController.text);
      controller.currentStep = 'success';
      controller.update();
      await tester.pumpAndSettle();

      expect(find.text('Corrected Text'), findsOneWidget);
      expect(find.textContaining('"word_count": 6'), findsOneWidget);
      expect(find.textContaining('"sentence_count": 1'), findsOneWidget);
      expect(find.textContaining('"paragraph_count": 1'), findsOneWidget);
    });

    testWidgets('downloadCounterTxt saves correctly for Word Counter', (WidgetTester tester) async {
      const wordCounterTool = ToolModel(
        id: 'word-counter',
        slug: 'word-counter',
        name: 'Word Counter',
        description: 'Count words and characters in text',
        icon: Icons.numbers,
        color: Colors.indigo,
        categoryId: 'utility',
      );

      final mockPlatform = MockFilePickerPlatform();
      FilePickerPlatform.instance = mockPlatform;

      await tester.pumpWidget(
        const GetMaterialApp(
          home: ToolExecutorPage(
            tool: wordCounterTool,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final controller = Get.find<ToolExecutorController>();
      controller.counterTextController.text = 'The quick brown fox jumps over the lazy dog.';
      controller.generatedCounterContent = controller.calculateCounterJson(controller.counterTextController.text);
      controller.currentStep = 'success';
      controller.update();
      await tester.pumpAndSettle();

      await controller.downloadCounterTxt();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(seconds: 3));

      expect(mockPlatform.lastSavedFileName, equals('word_counter_result.txt'));
      expect(mockPlatform.lastSavedBytes, isNotNull);
      expect(utf8.decode(mockPlatform.lastSavedBytes!), contains('"word_count": 9'));
      expect(controller.scanController.scannedFiles.first.name, equals('word_counter_result.txt'));
      expect(controller.scanController.scannedFiles.first.fileType, equals('TXT'));
    });

    testWidgets('downloadCounterTxt saves correctly for Character Counter', (WidgetTester tester) async {
      const charCounterTool = ToolModel(
        id: 'character-counter',
        slug: 'character-counter',
        name: 'Character Counter',
        description: 'Count characters and words in text',
        icon: Icons.pin_outlined,
        color: Colors.indigo,
        categoryId: 'utility',
      );

      final mockPlatform = MockFilePickerPlatform();
      FilePickerPlatform.instance = mockPlatform;

      await tester.pumpWidget(
        const GetMaterialApp(
          home: ToolExecutorPage(
            tool: charCounterTool,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final controller = Get.find<ToolExecutorController>();
      controller.counterTextController.text = 'Hello World';
      controller.generatedCounterContent = controller.calculateCounterJson(controller.counterTextController.text);
      controller.currentStep = 'success';
      controller.update();
      await tester.pumpAndSettle();

      await controller.downloadCounterTxt();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(seconds: 3));

      expect(mockPlatform.lastSavedFileName, equals('character_counter_result.txt'));
      expect(mockPlatform.lastSavedBytes, isNotNull);
      expect(utf8.decode(mockPlatform.lastSavedBytes!), contains('"char_with_spaces": 11'));
      expect(controller.scanController.scannedFiles.first.name, equals('character_counter_result.txt'));
      expect(controller.scanController.scannedFiles.first.fileType, equals('TXT'));
    });
  });
}

class MockFilePickerPlatform extends FilePickerPlatform {
  String? lastSavedFileName;
  Uint8List? lastSavedBytes;
  Uri? mockReturnUri;

  @override
  Future<Uri?> saveFile({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
    String? dialogTitle,
    String? initialDirectory,
    Function(FilePickerStatus)? onFileSaving,
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    lastSavedFileName = fileName;
    lastSavedBytes = bytes;
    return mockReturnUri ?? Uri.file('/mock/path/$fileName');
  }
}

