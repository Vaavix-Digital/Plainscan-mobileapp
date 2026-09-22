import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:plainscan/core/utils/local_document_generators.dart';
import 'package:excel/excel.dart' as xl;

void main() {
  group('CSV to Excel and Excel to CSV Conversion Tests', () {
    test('parseCsv correctly parses comma-delimited strings with quotes', () {
      const csv = '''Name,Age,"City, State",Active
Alice,30,"New York, NY",true
Bob,25,"San Francisco, CA",false
"Charlie ""The Boss""",40,"Chicago, IL",true''';

      final rows = LocalDocumentPdfGenerator.parseCsv(csv, delimiter: ',');
      expect(rows.length, 4);
      expect(rows[0], ['Name', 'Age', 'City, State', 'Active']);
      expect(rows[1], ['Alice', '30', 'New York, NY', 'true']);
      expect(rows[2], ['Bob', '25', 'San Francisco, CA', 'false']);
      expect(rows[3], ['Charlie "The Boss"', '40', 'Chicago, IL', 'true']);
    });

    test('convertCsvToExcel creates valid XLSX bytes that can be decoded', () {
      const csv = '''Product,Price,Quantity
Apple,1.5,10
Banana,0.75,20
Orange,2.0,15''';

      final csvBytes = Uint8List.fromList(utf8.encode(csv));
      final excelBytes = LocalDocumentPdfGenerator.convertCsvToExcel(csvBytes);

      expect(excelBytes.isNotEmpty, true);

      final decoded = xl.Excel.decodeBytes(excelBytes);
      expect(decoded.tables.isNotEmpty, true);

      final sheet = decoded.tables[decoded.getDefaultSheet() ?? decoded.tables.keys.first]!;
      expect(sheet.rows.length, 4);
      expect(sheet.rows[0][0]?.value.toString(), 'Product');
      expect(sheet.rows[0][1]?.value.toString(), 'Price');
      expect(sheet.rows[1][0]?.value.toString(), 'Apple');
    });

    test('convertExcelToCsv converts Excel workbook back to CSV text', () {
      const csv = '''Item,Count\nBook,5\nPen,12''';
      final csvBytes = Uint8List.fromList(utf8.encode(csv));
      final excelBytes = LocalDocumentPdfGenerator.convertCsvToExcel(csvBytes);

      final backToCsv = LocalDocumentPdfGenerator.convertExcelToCsv(excelBytes);
      expect(backToCsv.contains('Item,Count'), true);
      expect(backToCsv.contains('Book,5'), true);
      expect(backToCsv.contains('Pen,12'), true);
    });

    test('convertCsvToExcel auto-detects semicolon delimiter', () {
      const semicolonCsv = '''ID;Name;Department\n101;Alice;Engineering\n102;Bob;Marketing''';
      final csvBytes = Uint8List.fromList(utf8.encode(semicolonCsv));
      final excelBytes = LocalDocumentPdfGenerator.convertCsvToExcel(csvBytes, delimiter: ',');

      expect(excelBytes.isNotEmpty, true);
      final decoded = xl.Excel.decodeBytes(excelBytes);
      final sheet = decoded.tables[decoded.getDefaultSheet() ?? decoded.tables.keys.first]!;
      expect(sheet.rows[0].length, 3);
      expect(sheet.rows[0][0]?.value.toString(), 'ID');
      expect(sheet.rows[0][1]?.value.toString(), 'Name');
      expect(sheet.rows[0][2]?.value.toString(), 'Department');
    });
  });
}
