import 'dart:convert';
import 'dart:io';
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

  test('Metadata Editor accepts PDF input and outputs PDF for strip and JSON for view', () async {
    final metaTool = allPlainscanTools.firstWhere((t) => t.slug == 'metadata-editor');

    expect(metaTool.inputFormat, contains('.pdf'));

    final pdfFile = FileModel(
      id: 'pdf_123',
      name: 'annual_report.pdf',
      createdDate: DateTime.now(),
      sizeKb: 256.0,
      fileType: 'PDF',
      path: 'c:/mock/annual_report.pdf',
    );

    final controller = Get.put(ToolExecutorController(
      tool: metaTool,
      initialFiles: [pdfFile],
    ));

    expect(controller.selectedFile, isNotNull);
    expect(controller.selectedFile!.name, 'annual_report.pdf');

    // Default operation is strip -> should output pdf for a PDF input
    controller.setMetadataAction('strip');
    expect(controller.getExpectedExtension(), 'pdf');
    expect(controller.getOptionsJson(), {'action': 'strip'});

    // Switch operation to view -> should output json
    controller.setMetadataAction('view');
    expect(controller.getExpectedExtension(), 'json');
    expect(controller.getOptionsJson(), {'action': 'view'});

    // Test executeJobFlow with view mode
    await controller.executeJobFlow();
    expect(controller.currentStep, 'success');
    expect(controller.convertedFile, isNotNull);
    expect(controller.outputFileName.endsWith('.json'), isTrue);

    // Verify generated JSON content
    final jsonFile = File(controller.convertedFile!.path!);
    final jsonContent = jsonDecode(await jsonFile.readAsString());
    expect(jsonContent['file_name'], 'annual_report.pdf');
    expect(jsonContent['format'], 'PDF Document');
    expect(jsonContent['metadata'], isNotNull);

    // Test executeJobFlow with strip mode
    controller.setMetadataAction('strip');
    await controller.executeJobFlow();
    expect(controller.currentStep, 'success');
    expect(controller.convertedFile, isNotNull);
    expect(controller.outputFileName.endsWith('.pdf'), isTrue);
  });

  test('Metadata Editor accepts Image input and outputs JPG for strip and JSON for view', () async {
    final metaTool = allPlainscanTools.firstWhere((t) => t.slug == 'metadata-editor');

    final imgFile = FileModel(
      id: 'img_123',
      name: 'photo_camera.jpg',
      createdDate: DateTime.now(),
      sizeKb: 1024.0,
      fileType: 'JPG',
      path: 'c:/mock/photo_camera.jpg',
    );

    final controller = Get.put(ToolExecutorController(
      tool: metaTool,
      initialFiles: [imgFile],
    ));

    controller.setMetadataAction('strip');
    expect(controller.getExpectedExtension(), 'jpg');

    controller.setMetadataAction('view');
    expect(controller.getExpectedExtension(), 'json');

    await controller.executeJobFlow();
    expect(controller.currentStep, 'success');
    expect(controller.outputFileName.endsWith('.json'), isTrue);

    controller.setMetadataAction('strip');
    await controller.executeJobFlow();
    expect(controller.currentStep, 'success');
    expect(controller.outputFileName.endsWith('.jpg'), isTrue);
  });

  test('Remove Metadata tool strips PDF metadata and outputs clean PDF', () async {
    final removeTool = allPlainscanTools.firstWhere((t) => t.slug == 'remove-metadata');

    final pdfFile = FileModel(
      id: 'pdf_456',
      name: 'confidential_contract.pdf',
      createdDate: DateTime.now(),
      sizeKb: 512.0,
      fileType: 'PDF',
      path: 'c:/mock/confidential_contract.pdf',
    );

    final controller = Get.put(ToolExecutorController(
      tool: removeTool,
      initialFiles: [pdfFile],
    ));

    expect(controller.getExpectedExtension(), 'pdf');
    await controller.executeJobFlow();

    expect(controller.currentStep, 'success');
    expect(controller.convertedFile, isNotNull);
    expect(controller.outputFileName.endsWith('.pdf'), isTrue);
  });

  test('Read Metadata tool inspects PDF and extracts structured JSON metadata', () async {
    final readTool = allPlainscanTools.firstWhere((t) => t.slug == 'read-metadata');

    final pdfFile = FileModel(
      id: 'pdf_789',
      name: 'specs_doc.pdf',
      createdDate: DateTime.now(),
      sizeKb: 128.0,
      fileType: 'PDF',
      path: 'c:/mock/specs_doc.pdf',
    );

    final controller = Get.put(ToolExecutorController(
      tool: readTool,
      initialFiles: [pdfFile],
    ));

    expect(controller.getExpectedExtension(), 'json');
    await controller.executeJobFlow();

    expect(controller.currentStep, 'success');
    expect(controller.convertedFile, isNotNull);
    expect(controller.outputFileName.endsWith('.json'), isTrue);
  });

  test('stripPdfMetadata completely sanitizes PDF metadata dictionaries and XMP packets', () async {
    const rawPdfString = '%PDF-1.4\n'
        '1 0 obj\n'
        '<< /Title (Top Secret Document) /Author (John Confidential Doe) /Subject (Classified) /Creator (Secret Software) /Producer (Secret Producer) >>\n'
        'endobj\n'
        '2 0 obj\n'
        '<< /Type /Metadata /Subtype /XML >>\n'
        'stream\n'
        '<?xpacket begin="" id="W5M0MpCehiHzreSzNTczkc9d"?>\n'
        '<x:xmpmeta xmlns:x="adobe:ns:meta/"><rdf:RDF><dc:title>Embedded Secret</dc:title></rdf:RDF></x:xmpmeta>\n'
        '<?xpacket end="w"?>\n'
        'endstream\n'
        'endobj\n'
        'xref\n0 3\n0000000000 65535 f \n'
        'trailer\n<< /Root 1 0 R >>\nstartxref\n300\n%%EOF';

    final tempDir = Directory.systemTemp;
    final testPdfFile = File('${tempDir.path}/test_secret_metadata_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await testPdfFile.writeAsBytes(latin1.encode(rawPdfString));

    final removeTool = allPlainscanTools.firstWhere((t) => t.slug == 'remove-metadata');
    final pdfModel = FileModel(
      id: 'pdf_test_strip',
      name: testPdfFile.uri.pathSegments.last,
      createdDate: DateTime.now(),
      sizeKb: (await testPdfFile.length()) / 1024.0,
      fileType: 'PDF',
      path: testPdfFile.path,
    );

    final controller = Get.put(ToolExecutorController(
      tool: removeTool,
      initialFiles: [pdfModel],
    ));

    await controller.executeJobFlow();
    expect(controller.currentStep, 'success');
    expect(controller.convertedFile, isNotNull);

    final cleanFile = File(controller.convertedFile!.path!);
    final cleanBytes = await cleanFile.readAsBytes();
    final cleanString = latin1.decode(cleanBytes);

    // Verify sensitive contents are completely sanitized and removed
    expect(cleanString.contains('Top Secret Document'), isFalse);
    expect(cleanString.contains('John Confidential Doe'), isFalse);
    expect(cleanString.contains('Classified'), isFalse);
    expect(cleanString.contains('Secret Software'), isFalse);
    expect(cleanString.contains('Secret Producer'), isFalse);
    expect(cleanString.contains('Embedded Secret'), isFalse);
    expect(cleanString.contains('<x:xmpmeta'), isFalse);

    // Verify PDF remains intact structurally
    expect(cleanString.startsWith('%PDF-'), isTrue);
    expect(cleanString.contains('%%EOF'), isTrue);

    // Cleanup
    if (await testPdfFile.exists()) await testPdfFile.delete();
    if (await cleanFile.exists()) await cleanFile.delete();
  });

  test('Read Metadata accurately extracts metadata from PDF with Info dict and XMP tags', () async {
    const samplePdf = '%PDF-1.7\n'
        '1 0 obj\n'
        '<< /Title (Annual Financial Statement 2026) /Author (Accounting Lead) /Subject (Quarterly Audit) /Keywords (finance, audit, 2026) /Creator (Adobe InDesign 2025) /Producer (Quartz PDF) /CreationDate (D:20260210143000) >>\n'
        'endobj\n'
        'xref\n0 2\n0000000000 65535 f \n'
        'trailer\n<< /Root 1 0 R >>\nstartxref\n250\n%%EOF';

    final tempDir = Directory.systemTemp;
    final testPdfFile = File('${tempDir.path}/test_read_meta_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await testPdfFile.writeAsBytes(latin1.encode(samplePdf));

    final readTool = allPlainscanTools.firstWhere((t) => t.slug == 'read-metadata');
    final pdfModel = FileModel(
      id: 'pdf_test_read',
      name: testPdfFile.uri.pathSegments.last,
      createdDate: DateTime.now(),
      sizeKb: (await testPdfFile.length()) / 1024.0,
      fileType: 'PDF',
      path: testPdfFile.path,
    );

    final controller = Get.put(ToolExecutorController(
      tool: readTool,
      initialFiles: [pdfModel],
    ));

    await controller.executeJobFlow();
    expect(controller.currentStep, 'success');
    expect(controller.extractedMetadataMap, isNotNull);

    final meta = controller.extractedMetadataMap!['metadata'] as Map<String, dynamic>;
    expect(meta['Title'], 'Annual Financial Statement 2026');
    expect(meta['Author'], 'Accounting Lead');
    expect(meta['Subject'], 'Quarterly Audit');
    expect(meta['Keywords'], 'finance, audit, 2026');
    expect(meta['Creator'], 'Adobe InDesign 2025');
    expect(meta['Producer'], 'Quartz PDF');
    expect(meta['CreationDate'], contains('2026-02-10'));
    expect(controller.extractedMetadataMap!['pdf_version'], 'PDF 1.7');

    // Cleanup
    if (await testPdfFile.exists()) await testPdfFile.delete();
  });

  testWidgets('ToolExecutorPage displays Document Metadata Extracted card upon execution', (tester) async {
    const samplePdf = '%PDF-1.4\n'
        '1 0 obj\n'
        '<< /Title (Confidential Proposal) /Author (Jane Lead) /Subject (Sales Pitch) >>\n'
        'endobj\n'
        'xref\n0 2\n0000000000 65535 f \n'
        'trailer\n<< /Root 1 0 R >>\nstartxref\n180\n%%EOF';

    final tempDir = Directory.systemTemp;
    final testPdfFile = File('${tempDir.path}/test_widget_read_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await testPdfFile.writeAsBytes(latin1.encode(samplePdf));

    final readTool = allPlainscanTools.firstWhere((t) => t.slug == 'read-metadata');
    final pdfModel = FileModel(
      id: 'pdf_test_widget',
      name: testPdfFile.uri.pathSegments.last,
      createdDate: DateTime.now(),
      sizeKb: 34.0,
      fileType: 'PDF',
      path: testPdfFile.path,
    );

    await tester.pumpWidget(
      GetMaterialApp(
        home: ToolExecutorPage(
          tool: readTool,
          initialFiles: [pdfModel],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Read Metadata'), findsWidgets);
    expect(find.text('Run Read Metadata'), findsOneWidget);

    // Tap Run Read Metadata
    await tester.tap(find.text('Run Read Metadata'));
    await tester.pumpAndSettle();

    // Verify metadata results card is rendered
    expect(find.text('Document Metadata Extracted'), findsOneWidget);
    expect(find.text('Confidential Proposal'), findsOneWidget);
    expect(find.text('Jane Lead'), findsOneWidget);
    expect(find.text('Sales Pitch'), findsOneWidget);
    expect(find.text('Copy JSON'), findsOneWidget);

    if (await testPdfFile.exists()) await testPdfFile.delete();
  });
}
