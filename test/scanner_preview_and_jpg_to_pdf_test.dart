import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:plainscan/core/controllers/scan_controller.dart';
import 'package:plainscan/core/controllers/tool_executor_controller.dart';
import 'package:plainscan/features/scanner/pages/scan_preview_page.dart';
import 'package:plainscan/models/file_model.dart';
import 'package:plainscan/models/tool_model.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Get.reset();
    Get.put(ScanController());
  });

  tearDown(() {
    Get.reset();
  });

  group('Scanner Preview & JPG to PDF Integration Tests', () {
    test('JPG to PDF tool model has isMultiFile enabled', () {
      final tool = allPlainscanTools.firstWhere((t) => t.id == 'jpg-to-pdf');
      expect(tool.isMultiFile, isTrue);
      expect(tool.name, 'JPG to PDF');
      expect(tool.slug, 'jpg-to-pdf');
    });

    test('ToolExecutorController correctly pre-populates multi-image input files', () {
      final tool = allPlainscanTools.firstWhere((t) => t.id == 'jpg-to-pdf');
      final testFiles = [
        FileModel(
          id: 'scan_1',
          name: 'Scan_Page_1.jpg',
          createdDate: DateTime.now(),
          sizeKb: 500,
          fileType: 'JPG',
          path: '/mock/path/page1.jpg',
        ),
        FileModel(
          id: 'scan_2',
          name: 'Scan_Page_2.jpg',
          createdDate: DateTime.now(),
          sizeKb: 600,
          fileType: 'JPG',
          path: '/mock/path/page2.jpg',
        ),
      ];

      final controller = Get.put(ToolExecutorController(
        tool: tool,
        initialFiles: testFiles,
      ));

      expect(controller.isMultiFileTool(), isTrue);
      expect(controller.selectedFiles.length, 2);
      expect(controller.selectedFiles[0].name, 'Scan_Page_1.jpg');
      expect(controller.selectedFiles[1].name, 'Scan_Page_2.jpg');
    });

    testWidgets('ScanPreviewPage displays captured photos count and layout selector', (WidgetTester tester) async {
      final samplePaths = [
        'test_photo_1.jpg',
        'test_photo_2.jpg',
      ];

      await tester.pumpWidget(
        GetMaterialApp(
          home: ScanPreviewPage(imagePaths: samplePaths),
        ),
      );

      // Verify page count header and title
      expect(find.text('Scan Preview'), findsOneWidget);
      expect(find.text('2 pages captured'), findsOneWidget);
      expect(find.text('Page 1 of 2'), findsOneWidget);
      expect(find.text('PDF Page Layout'), findsOneWidget);
      expect(find.text('Convert to PDF (2 pages)'), findsOneWidget);
      expect(find.text('JPG to PDF'), findsOneWidget);
    });
  });
}
