import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plainscan/features/files/pages/pdf_viewer_page.dart';
import 'package:plainscan/models/file_model.dart';
import 'package:excel/excel.dart' as xl;

void main() {
  group('Multi-format Document Viewer Tests', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('viewer_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    testWidgets('PdfViewerPage displays Excel spreadsheet table for .xlsx files', (tester) async {
      final excel = xl.Excel.createExcel();
      final sheet = excel[excel.getDefaultSheet() ?? 'Sheet1'];
      sheet.appendRow([xl.TextCellValue('Name'), xl.TextCellValue('Score')]);
      sheet.appendRow([xl.TextCellValue('Alice'), xl.IntCellValue(95)]);
      sheet.appendRow([xl.TextCellValue('Bob'), xl.IntCellValue(88)]);
      final excelBytes = excel.save()!;

      final testFile = File('${tempDir.path}/report.xlsx');
      testFile.writeAsBytesSync(excelBytes);

      final fileModel = FileModel(
        id: '1',
        name: 'report.xlsx',
        createdDate: DateTime.now(),
        sizeKb: 12.0,
        fileType: 'XLSX',
        path: testFile.path,
      );

      await tester.pumpWidget(MaterialApp(
        home: PdfViewerPage(
          file: fileModel,
          filePath: testFile.path,
          fileName: 'report.xlsx',
          fileType: 'XLSX',
        ),
      ));
      await tester.pump();

      expect(find.textContaining('report.xlsx'), findsWidgets);
      expect(find.textContaining('Excel Workbook'), findsOneWidget);
      expect(find.text('XLSX'), findsWidgets);
      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Score'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('PdfViewerPage displays Word document viewer for .docx files', (tester) async {
      final testFile = File('${tempDir.path}/contract.docx');
      testFile.writeAsStringSync('Mock docx content');

      final fileModel = FileModel(
        id: '2',
        name: 'contract.docx',
        createdDate: DateTime.now(),
        sizeKb: 25.0,
        fileType: 'DOCX',
        path: testFile.path,
      );

      await tester.pumpWidget(MaterialApp(
        home: PdfViewerPage(
          file: fileModel,
          filePath: testFile.path,
          fileName: 'contract.docx',
          fileType: 'DOCX',
        ),
      ));
      await tester.pump();

      expect(find.textContaining('contract.docx'), findsWidgets);
      expect(find.text('DOCX'), findsWidgets);
      expect(find.textContaining('Word'), findsWidgets);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('PdfViewerPage displays PowerPoint slide deck for .pptx files', (tester) async {
      final testFile = File('${tempDir.path}/presentation.pptx');
      testFile.writeAsStringSync('Mock pptx content');

      final fileModel = FileModel(
        id: '3',
        name: 'presentation.pptx',
        createdDate: DateTime.now(),
        sizeKb: 50.0,
        fileType: 'PPTX',
        path: testFile.path,
      );

      await tester.pumpWidget(MaterialApp(
        home: PdfViewerPage(
          file: fileModel,
          filePath: testFile.path,
          fileName: 'presentation.pptx',
          fileType: 'PPTX',
        ),
      ));
      await tester.pump();

      expect(find.textContaining('presentation.pptx'), findsWidgets);
      expect(find.text('PPTX'), findsWidgets);
      expect(find.textContaining('PowerPoint'), findsWidgets);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('PdfViewerPage displays Text/Code viewer for .txt files', (tester) async {
      final testFile = File('${tempDir.path}/notes.txt');
      testFile.writeAsStringSync('PlainScan extracted report text');

      final fileModel = FileModel(
        id: '4',
        name: 'notes.txt',
        createdDate: DateTime.now(),
        sizeKb: 2.0,
        fileType: 'TXT',
        path: testFile.path,
      );

      await tester.pumpWidget(MaterialApp(
        home: PdfViewerPage(
          file: fileModel,
          filePath: testFile.path,
          fileName: 'notes.txt',
          fileType: 'TXT',
        ),
      ));
      await tester.pump();

      expect(find.textContaining('notes.txt'), findsWidgets);
      expect(find.textContaining('TXT'), findsWidgets);
      expect(find.text('PlainScan extracted report text'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });
  });
}
