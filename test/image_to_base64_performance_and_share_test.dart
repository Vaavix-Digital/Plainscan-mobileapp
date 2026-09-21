import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:plainscan/core/controllers/scan_controller.dart';
import 'package:plainscan/core/controllers/tool_executor_controller.dart';
import 'package:plainscan/core/services/background_job_service.dart';
import 'package:plainscan/features/alltools/tool_executor_page.dart';
import 'package:plainscan/models/file_model.dart';
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

  test('Image to Base64 executes instantly and generates valid Base64 string and usage snippets', () async {
    final tempDir = Directory.systemTemp;
    final testImgFile = File('${tempDir.path}/test_img_${DateTime.now().millisecondsSinceEpoch}.png');
    final dummyBytes = Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82]);
    await testImgFile.writeAsBytes(dummyBytes);

    const tool = ToolModel(
      id: 'image-to-base64',
      slug: 'image-to-base64',
      name: 'Image to Base64',
      description: 'Convert Image to Base64',
      icon: Icons.image,
      color: Colors.teal,
      categoryId: 'utility',
      outputFormat: '.txt',
    );

    final controller = Get.put(ToolExecutorController(tool: tool));
    controller.selectedFile = FileModel(
      id: 'img_1',
      name: 'sample_icon.png',
      path: testImgFile.path,
      fileType: 'PNG',
      sizeKb: 16.0,
      createdDate: DateTime.now(),
    );

    await controller.executeJobFlow();

    expect(controller.currentStep, equals('success'));
    expect(controller.isRunning, isFalse);
    expect(controller.imageBase64String.isNotEmpty, isTrue);
    expect(controller.imageBase64String, equals(base64Encode(dummyBytes)));

    // Verify usage snippet generators
    expect(controller.getHtmlUsageSnippet(), contains('<img\nsrc="data:image/png;base64,'));
    expect(controller.getCssUsageSnippet(), contains('background-image:\nurl("data:image/png;base64,'));
    expect(controller.getMarkdownUsageSnippet(), contains('![Image]\n(data:image/png;base64,'));
    expect(controller.getJsonUsageSnippet(), contains('"data:image/png;base64,'));

    // Verify copy, share, and reset methods
    await controller.copyBase64Snippet('Base64 String', controller.imageBase64String);
    await controller.shareBase64Snippet('Base64 String', controller.imageBase64String);

    controller.resetImageToBase64();
    expect(controller.imageBase64String, isEmpty);
    expect(controller.selectedFile, isNull);
    expect(controller.currentStep, equals('idle'));
  });

  testWidgets('Image to Base64 UI displays snippets, copy, share, download buttons and handles copy clicks', (WidgetTester tester) async {
    const tool = ToolModel(
      id: 'image-to-base64',
      slug: 'image-to-base64',
      name: 'Image to Base64',
      description: 'Convert Image to Base64',
      icon: Icons.image,
      color: Colors.teal,
      categoryId: 'utility',
      outputFormat: '.txt',
    );

    await tester.pumpWidget(
      const GetMaterialApp(
        home: ToolExecutorPage(
          tool: tool,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final controller = Get.find<ToolExecutorController>();
    controller.imageBase64String = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';
    controller.currentStep = 'success';
    controller.update();
    await tester.pumpAndSettle();

    // Verify Snippet Titles
    expect(find.text('Base64 String'), findsWidgets);
    expect(find.text('HTML Usage'), findsOneWidget);
    expect(find.text('CSS Usage'), findsOneWidget);
    expect(find.text('Markdown Usage'), findsOneWidget);
    expect(find.text('JSON Usage'), findsOneWidget);

    // Verify Action Buttons
    expect(find.text('Process another item'), findsOneWidget);
    expect(find.text('Download TXT'), findsOneWidget);
    expect(find.text('Share Base64'), findsOneWidget);
    expect(find.text('Share'), findsWidgets);
    expect(find.text('Copy'), findsWidgets);

    // Tap a Copy button and verify feedback
    await tester.tap(find.text('Copy').first);
    await tester.pump();
    expect(find.text('Copied!'), findsOneWidget);

    // Settle feedback timer
    await tester.pump(const Duration(seconds: 3));
  });
}
