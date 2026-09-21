import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:plainscan/core/controllers/scan_controller.dart';
import 'package:plainscan/core/controllers/tool_executor_controller.dart';
import 'package:plainscan/core/services/background_job_service.dart';
import 'package:plainscan/core/services/storage_service.dart';
import 'package:plainscan/features/alltools/tool_executor_page.dart';
import 'package:plainscan/models/file_model.dart';
import 'package:plainscan/models/tool_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Get.reset();
    Get.put(ScanController());
    Get.put(BackgroundJobService());
  });

  tearDown(() {
    Get.reset();
  });

  test('StorageService persists and retrieves active background jobs', () async {
    final jobMap = {
      'jobId': 'job_test_123',
      'toolSlug': 'pdf-compress',
      'toolName': 'Compress PDF',
      'step': 'polling',
      'stepMessage': 'Processing...',
      'pollingCount': 3,
      'startTime': DateTime.now().toIso8601String(),
    };

    await StorageService.saveActiveJob(jobMap);
    final jobs = await StorageService.getActiveJobs();
    expect(jobs.any((j) => j['jobId'] == 'job_test_123'), isTrue);
    expect(jobs.firstWhere((j) => j['jobId'] == 'job_test_123')['toolSlug'], equals('pdf-compress'));

    await StorageService.removeActiveJob('job_test_123');
    final updatedJobs = await StorageService.getActiveJobs();
    expect(updatedJobs.any((j) => j['jobId'] == 'job_test_123'), isFalse);
  });

  test('ToolExecutorController guards option modifications while isRunning', () {
    const tool = ToolModel(
      id: 'pdf-compress',
      name: 'Compress PDF',
      description: 'Compress PDF documents',
      icon: Icons.compress,
      color: Colors.blue,
      categoryId: 'pdf',
    );

    final controller = Get.put(ToolExecutorController(tool: tool));
    expect(controller.compressQuality, equals('balanced'));

    // Change while not running
    controller.setCompressQuality('low');
    expect(controller.compressQuality, equals('low'));

    // Set isRunning manually (simulate running state)
    controller.isRunning = true;

    // Attempt to modify quality while running
    controller.setCompressQuality('high');
    expect(controller.compressQuality, equals('low'), reason: 'Option should not change when isRunning is true');

    // Attempt to change rotation while running
    final initialRotation = controller.rotation;
    controller.setRotation(180);
    expect(controller.rotation, equals(initialRotation));
  });

  testWidgets('ToolExecutorPage displays locked state and disables options while running', (tester) async {
    const tool = ToolModel(
      id: 'pdf-compress',
      name: 'Compress PDF',
      description: 'Compress PDF documents',
      icon: Icons.compress,
      color: Colors.blue,
      categoryId: 'pdf',
    );

    final testFile = FileModel(
      id: 'f1',
      name: 'sample.pdf',
      path: '/tmp/sample.pdf',
      fileType: 'PDF',
      sizeKb: 1024,
      createdDate: DateTime.now(),
    );

    await tester.pumpWidget(
      GetMaterialApp(
        home: ToolExecutorPage(
          tool: tool,
          initialFiles: [testFile],
        ),
      ),
    );
    await tester.pumpAndSettle();

    final controller = Get.find<ToolExecutorController>();
    expect(find.text('Run Compress PDF'), findsOneWidget);
    expect(find.text('Options locked during processing'), findsNothing);

    // Simulate running
    controller.isRunning = true;
    controller.update();
    await tester.pumpAndSettle();

    expect(find.text('Options locked during processing'), findsOneWidget);
    expect(find.text('Executing Job Flow'), findsOneWidget);

    // Verify AbsorbPointer is absorbing touch events for both cards
    final absorbPointers = tester.widgetList<AbsorbPointer>(find.byType(AbsorbPointer)).where((w) => w.absorbing).toList();
    expect(absorbPointers.length, greaterThanOrEqualTo(2));

    // Verify opacity is applied to indicate disabled state
    final opacities = tester.widgetList<Opacity>(find.byType(Opacity)).where((o) => o.opacity == 0.65).toList();
    expect(opacities.length, greaterThanOrEqualTo(2));
  });

  test('ToolExecutorController automatically synchronizes state when app is resumed from background', () async {
    const tool = ToolModel(
      id: 'print-optimize-pdf',
      name: 'Print Optimize PDF',
      description: 'Optimize PDF for printing',
      icon: Icons.print,
      color: Colors.indigo,
      categoryId: 'pdf',
    );

    final controller = Get.put(ToolExecutorController(tool: tool));
    expect(controller.isRunning, isFalse);
    expect(controller.currentStep, isEmpty);

    // Simulate background service receiving completion while user was in another app
    final bgService = BackgroundJobService.to;
    bgService.registerJob(BackgroundJobState(
      jobId: 'job_bg_print_999',
      toolSlug: 'print-optimize-pdf',
      toolName: 'Print Optimize PDF',
      step: 'completed',
      stepMessage: 'Success! File processed with Print Optimize PDF.',
      outputFileName: 'Print_Optimized_Document.pdf',
      outputFilePath: '/mock/path/Print_Optimized_Document.pdf',
      startTime: DateTime.now(),
      notificationId: 1001,
    ));

    // Simulate AppLifecycleState.resumed when user switches back to PlainScan
    controller.didChangeAppLifecycleState(AppLifecycleState.resumed);

    expect(controller.currentStep, equals('success'));
    expect(controller.isRunning, isFalse);
    expect(controller.outputFileName, equals('Print_Optimized_Document.pdf'));
    expect(controller.convertedFile, isNotNull);
    expect(controller.convertedFile!.name, equals('Print_Optimized_Document.pdf'));
  });
}
