import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:plainscan/core/controllers/scan_controller.dart';
import 'package:plainscan/core/controllers/tool_executor_controller.dart';
import 'package:plainscan/core/services/background_job_service.dart';
import 'package:plainscan/core/utils/local_document_generators.dart';
import 'package:plainscan/features/alltools/tool_executor_page.dart';
import 'package:plainscan/models/tool_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

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

  test('LocalDocumentPdfGenerator creates valid ID Card PDF file', () async {
    final tempDir = Directory.systemTemp;
    final outPath = '${tempDir.path}/test_id_card.pdf';

    final file = await LocalDocumentPdfGenerator.generateIdCardPdf(
      outputFilePath: outPath,
      companyName: 'PlainScan Corp',
      companyAddress: '123 Tech Park, NY',
      companyPhone: '+1 555-1234',
      employeeName: 'Neymar Jr',
      employeeRole: 'Software Engineer',
      employeeId: 'EMP-001',
    );

    expect(await file.exists(), isTrue);
    final bytes = await file.readAsBytes();
    expect(bytes.length, greaterThan(100));
    final text = String.fromCharCodes(bytes);
    expect(text.startsWith('%PDF-1.4'), isTrue);
    expect(text.contains('ID NUMBER:'), isTrue);
    expect(text.contains('EMP-001'), isTrue);
    expect(text.contains('LOCATION:'), isTrue);
    expect(text.contains('123 Tech Park, NY'), isTrue);
    expect(text.contains('PHONE:'), isTrue);
    expect(text.contains('+1 555-1234'), isTrue);
    expect(text.contains('Neymar Jr'), isTrue);
    expect(text.contains('Software Engineer'), isTrue);
    expect(text.contains('PLAINSCAN CORP'), isTrue);
    expect(text.contains('OFFICIAL IDENTIFICATION PASS'), isTrue);
  });

  test('LocalDocumentPdfGenerator creates valid Invoice PDF file', () async {
    final tempDir = Directory.systemTemp;
    final outPath = '${tempDir.path}/test_invoice.pdf';

    final file = await LocalDocumentPdfGenerator.generateInvoicePdf(
      outputFilePath: outPath,
      invoiceNumber: 'INV-2026-001',
      fromName: 'PlainScan Ltd',
      fromEmail: 'billing@plainscan.com',
      fromPhone: '+1 800 555 0199',
      fromAddress: '100 Innovation Way, CA',
      toName: 'Acme Corp',
      toEmail: 'accounts@acme.com',
      toAddress: '200 Market Street, SF',
      currency: 'USD',
      discount: 10.0,
      items: [
        {'description': 'Software Subscription', 'quantity': 2, 'price': 100.0, 'tax': 5.0},
        {'description': 'Technical Consulting', 'quantity': 5, 'price': 80.0, 'tax': 0.0},
      ],
    );

    expect(await file.exists(), isTrue);
    final bytes = await file.readAsBytes();
    expect(bytes.length, greaterThan(100));
    final text = String.fromCharCodes(bytes.take(10));
    expect(text.startsWith('%PDF-1.4'), isTrue);
  });

  test('ToolExecutorController generates ID card successfully without Tool Not Found error', () async {
    const tool = ToolModel(
      id: 'id-templates',
      slug: 'id-templates',
      name: 'ID Templates',
      icon: Icons.badge_outlined,
      color: Colors.blue,
      categoryId: 'utility',
    );

    final controller = Get.put(ToolExecutorController(tool: tool));
    controller.idCompanyNameController.text = 'PlainScan Corp';
    controller.idEmployeeNameController.text = 'Neymar Jr';
    controller.idEmployeeRoleController.text = 'Software Engineer';
    controller.idEmployeeIdController.text = 'EMP-001';

    await controller.executeJobFlow();

    expect(controller.currentStep, equals('success'));
    expect(controller.errorMessage.contains('Success'), isTrue);
    expect(controller.convertedFile, isNotNull);
    expect(controller.convertedFile!.name.endsWith('.pdf'), isTrue);
    expect(Get.find<ScanController>().scannedFiles.isNotEmpty, isTrue);
  });

  testWidgets('ToolExecutorPage displays ID Templates input form correctly', (tester) async {
    const tool = ToolModel(
      id: 'id-templates',
      slug: 'id-templates',
      name: 'ID Templates',
      icon: Icons.badge_outlined,
      color: Colors.blue,
      categoryId: 'utility',
    );

    await tester.pumpWidget(
      const GetMaterialApp(
        home: ToolExecutorPage(tool: tool),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Run ID Templates'), findsOneWidget);
    expect(find.text('Company / Organization Name *'), findsOneWidget);
    expect(find.text('Employee Full Name *'), findsOneWidget);
    expect(find.text('Role / Job Title'), findsOneWidget);
    expect(find.text('Employee ID'), findsOneWidget);
  });
}
