import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:plainscan/core/controllers/scan_controller.dart';
import 'package:plainscan/core/controllers/tool_executor_controller.dart';
import 'package:plainscan/core/services/background_job_service.dart';
import 'package:plainscan/core/utils/local_document_generators.dart';
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

  test('Metadata Editor accepts PDF input and outputs PDF for strip and TXT for view', () async {
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
    expect(controller.getOptionsJson(), {'action': 'strip', 'strip_all': true});

    // Switch operation to view -> should output txt
    controller.setMetadataAction('view');
    expect(controller.getExpectedExtension(), 'txt');
    expect(controller.getOptionsJson(), {'action': 'view'});

    // Test executeJobFlow with view mode
    await controller.executeJobFlow();
    expect(controller.currentStep, 'success');
    expect(controller.convertedFile, isNotNull);
    expect(controller.outputFileName.endsWith('.txt'), isTrue);

    // Verify generated TXT content
    final txtFile = File(controller.convertedFile!.path!);
    final txtContent = await txtFile.readAsString();
    expect(txtContent.contains('DOCUMENT METADATA REPORT'), isTrue);
    expect(txtContent.contains('File Name: annual_report.pdf'), isTrue);
    expect(txtContent.contains('Format: PDF Document'), isTrue);

    // Test executeJobFlow with strip mode
    controller.setMetadataAction('strip');
    await controller.executeJobFlow();
    expect(controller.currentStep, 'success');
    expect(controller.convertedFile, isNotNull);
    expect(controller.outputFileName.endsWith('.pdf'), isTrue);
  });

  test('Metadata Editor accepts Image input and outputs JPG for strip and TXT for view', () async {
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
    expect(controller.getExpectedExtension(), 'txt');

    await controller.executeJobFlow();
    expect(controller.currentStep, 'success');
    expect(controller.outputFileName.endsWith('.txt'), isTrue);

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

  test('Read Metadata tool inspects PDF and extracts structured TXT metadata', () async {
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

    expect(controller.getExpectedExtension(), 'txt');
    await controller.executeJobFlow();

    expect(controller.currentStep, 'success');
    expect(controller.convertedFile, isNotNull);
    expect(controller.outputFileName.endsWith('.txt'), isTrue);
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
    final readTool = allPlainscanTools.firstWhere((t) => t.slug == 'read-metadata');

    await tester.pumpWidget(
      GetMaterialApp(
        home: ToolExecutorPage(
          tool: readTool,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Read Metadata'), findsWidgets);
    expect(find.text('Run Read Metadata'), findsOneWidget);

    final controller = Get.find<ToolExecutorController>();
    controller.extractedMetadataMap = {
      'file_name': 'test.pdf',
      'format': 'PDF Document',
      'metadata': {
        'Title': 'Confidential Proposal',
        'Author': 'Jane Lead',
        'Subject': 'Sales Pitch',
      }
    };
    controller.generatedMetadataText = LocalDocumentPdfGenerator.formatMetadataAsText(controller.extractedMetadataMap!);
    controller.currentStep = 'success';
    controller.update();
    await tester.pump();

    expect(find.text('Document Metadata Extracted'), findsOneWidget);
    expect(find.text('Confidential Proposal'), findsOneWidget);
    expect(find.text('Jane Lead'), findsOneWidget);
    expect(find.text('Sales Pitch'), findsOneWidget);
    expect(find.text('Copy Text'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('ToolExecutorPage displays all metadata editor fields and privacy mode switch', (tester) async {
    final metaTool = allPlainscanTools.firstWhere((t) => t.slug == 'metadata-editor');

    await tester.pumpWidget(
      GetMaterialApp(
        home: ToolExecutorPage(
          tool: metaTool,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Strip All Metadata (Privacy Mode)'), findsOneWidget);
    expect(find.text('Remove all EXIF tags including GPS and camera info.'), findsOneWidget);
    expect(find.text('Or Edit Specific Fields:'), findsOneWidget);
    expect(find.text('Title'), findsOneWidget);
    expect(find.text('Author'), findsOneWidget);
    expect(find.text('Description'), findsOneWidget);
    expect(find.text('Copyright'), findsOneWidget);
    expect(find.text('Software'), findsOneWidget);
    expect(find.text('Comment'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  test('Metadata Editor updates PDF fields accurately', () async {
    const rawPdfString = '%PDF-1.4\n'
        '1 0 obj\n'
        '<< /Title (Old Title) /Author (Old Author) >>\n'
        'endobj\n'
        'xref\n0 2\n0000000000 65535 f \n'
        'trailer\n<< /Root 1 0 R >>\nstartxref\n100\n%%EOF';

    final tempDir = Directory.systemTemp;
    final testPdfFile = File('${tempDir.path}/test_edit_meta_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await testPdfFile.writeAsBytes(latin1.encode(rawPdfString));

    final metaTool = allPlainscanTools.firstWhere((t) => t.slug == 'metadata-editor');
    final pdfModel = FileModel(
      id: 'pdf_test_edit',
      name: testPdfFile.uri.pathSegments.last,
      createdDate: DateTime.now(),
      sizeKb: (await testPdfFile.length()) / 1024.0,
      fileType: 'PDF',
      path: testPdfFile.path,
    );

    final controller = Get.put(ToolExecutorController(
      tool: metaTool,
      initialFiles: [pdfModel],
    ));

    controller.metadataTitleController.text = 'Vacation Photo';
    controller.metadataAuthorController.text = 'John Doe';
    controller.metadataDescriptionController.text = 'A detailed description of the trip';
    controller.metadataCopyrightController.text = '© 2025 John Doe';
    controller.metadataSoftwareController.text = 'Plainscan';
    controller.metadataCommentController.text = 'Custom vacation comments';

    await controller.executeJobFlow();
    expect(controller.currentStep, 'success');
    expect(controller.convertedFile, isNotNull);

    final editedFile = File(controller.convertedFile!.path!);
    final editedBytes = await editedFile.readAsBytes();
    final editedString = latin1.decode(editedBytes);

    expect(editedString.contains('Vacation Photo'), isTrue);
    expect(editedString.contains('John Doe'), isTrue);
    expect(editedString.contains('A detailed description of the trip'), isTrue);
    expect(editedString.contains('Plainscan'), isTrue);

    // Cleanup
    if (await testPdfFile.exists()) await testPdfFile.delete();
    if (await editedFile.exists()) await editedFile.delete();
  });

  test('LocalDocumentPdfGenerator.formatMetadataAsText formats all fields into clean readable text report', () {
    final metaMap = {
      'file_name': 'document.pdf',
      'file_size_kb': 150.5,
      'format': 'PDF Document',
      'pdf_version': 'PDF 1.7',
      'page_count': 5,
      'is_encrypted': false,
      'created_at': '2026-02-10T12:00:00.000',
      'metadata': {
        'Title': 'Quarterly Report',
        'Author': 'Alice Engineer',
        'Subject': 'Q1 Metrics',
        'Creator': 'Plainscan PDF Engine',
      },
    };

    final formatted = LocalDocumentPdfGenerator.formatMetadataAsText(metaMap);
    expect(formatted.contains('DOCUMENT METADATA REPORT'), isTrue);
    expect(formatted.contains('File Name: document.pdf'), isTrue);
    expect(formatted.contains('File Size: 150.5 KB'), isTrue);
    expect(formatted.contains('Format: PDF Document'), isTrue);
    expect(formatted.contains('PDF Version: PDF 1.7'), isTrue);
    expect(formatted.contains('Page Count: 5'), isTrue);
    expect(formatted.contains('Encrypted: No'), isTrue);
    expect(formatted.contains('Title: Quarterly Report'), isTrue);
    expect(formatted.contains('Author: Alice Engineer'), isTrue);
    expect(formatted.contains('Subject: Q1 Metrics'), isTrue);
    expect(formatted.contains('Creator: Plainscan PDF Engine'), isTrue);
  });

  test('Metadata Editor updates JPEG metadata and Read Metadata extracts edited fields', () {
    final originalBytes = Uint8List.fromList(LocalDocumentPdfGenerator.minimalJpegBytes);
    final editedBytes = LocalDocumentPdfGenerator.updateJpegMetadata(
      originalBytes,
      title: 'laptop',
      author: 'Abhinav S',
      description: 'laptop on table',
      copyright: 'Abhinav S',
      software: 'Plainscan',
      comment: 'Sample comment',
    );

    expect(editedBytes, isNotNull);
    expect(editedBytes.length, greaterThan(originalBytes.length));

    final extractedMap = LocalDocumentPdfGenerator.extractMetadata(
      editedBytes,
      'photo_edited.jpg',
    );

    expect(extractedMap, isNotNull);
    final meta = extractedMap['metadata'] as Map<String, dynamic>;
    expect(meta['Title'], 'laptop');
    expect(meta['Author'], 'Abhinav S');
    expect(meta['Description'], 'laptop');
    expect(meta['Copyright'], 'Abhinav S');
    expect(meta['Software'], 'Plainscan');
    expect(meta['Comment'], 'Sample comment');
  });

  test('Metadata Editor updates PNG metadata and Read Metadata extracts edited fields', () {
    // Minimal PNG byte structure
    final pngHeader = Uint8List.fromList([
      137, 80, 78, 71, 13, 10, 26, 10, // Signature
      0, 0, 0, 13, 73, 72, 68, 82, // IHDR
      0, 0, 0, 1, 0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137,
      0, 0, 0, 0, 73, 69, 78, 68, 174, 66, 96, 130 // IEND
    ]);

    final editedBytes = LocalDocumentPdfGenerator.updatePngMetadata(
      pngHeader,
      title: 'laptop',
      author: 'Abhinav S',
      description: 'laptop on table',
      copyright: 'Abhinav S',
      software: 'Plainscan',
      comment: 'Sample comment',
    );

    expect(editedBytes, isNotNull);

    final extractedMap = LocalDocumentPdfGenerator.extractMetadata(
      editedBytes,
      'image_edited.png',
    );

    expect(extractedMap, isNotNull);
    final meta = extractedMap['metadata'] as Map<String, dynamic>;
    expect(meta['Title'], 'laptop');
    expect(meta['Author'], 'Abhinav S');
    expect(meta['Description'], 'laptop on table');
    expect(meta['Copyright'], 'Abhinav S');
    expect(meta['Software'], 'Plainscan');
    expect(meta['Comment'], 'Sample comment');
  });
}

