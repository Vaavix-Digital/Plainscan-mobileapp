import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart' as crypto;
import 'package:excel/excel.dart' as xl;

class LocalDocumentPdfGenerator {
  static const List<int> minimalJpegBytes = [
    0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01,
    0x01, 0x01, 0x00, 0x48, 0x00, 0x48, 0x00, 0x00, 0xFF, 0xDB, 0x00, 0x43,
    0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
    0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
    0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
    0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
    0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
    0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xC0, 0x00, 0x0B, 0x08, 0x00, 0x01, 0x00,
    0x01, 0x01, 0x01, 0x11, 0x00, 0xFF, 0xC4, 0x00, 0x14, 0x00, 0x01, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0xFF, 0xDA, 0x00, 0x08, 0x01, 0x01, 0x00, 0x00, 0x3F,
    0x00, 0x7F, 0x00, 0xFF, 0xD9,
  ];

  static const List<int> minimalPdfBytes = [
    0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x34, 0x0A, 0x25, 0xE2, 0xE3,
    0xCF, 0xD3, 0x0A, 0x31, 0x20, 0x30, 0x20, 0x6F, 0x62, 0x6A, 0x0A, 0x3C,
    0x3C, 0x2F, 0x54, 0x79, 0x70, 0x65, 0x2F, 0x43, 0x61, 0x74, 0x61, 0x6C,
    0x6F, 0x67, 0x2F, 0x50, 0x61, 0x67, 0x65, 0x73, 0x20, 0x32, 0x20, 0x30,
    0x20, 0x52, 0x3E, 0x3E, 0x0A, 0x65, 0x6E, 0x64, 0x6F, 0x62, 0x6A, 0x0A,
    0x32, 0x20, 0x30, 0x20, 0x6F, 0x62, 0x6A, 0x0A, 0x3C, 0x3C, 0x2F, 0x54,
    0x79, 0x70, 0x65, 0x2F, 0x50, 0x61, 0x67, 0x65, 0x73, 0x2F, 0x43, 0x6F,
    0x75, 0x6E, 0x74, 0x20, 0x31, 0x2F, 0x4B, 0x69, 0x64, 0x73, 0x5B, 0x33,
    0x20, 0x30, 0x20, 0x52, 0x5D, 0x3E, 0x3E, 0x0A, 0x65, 0x6E, 0x64, 0x6F,
    0x62, 0x6A, 0x0A, 0x33, 0x20, 0x30, 0x20, 0x6F, 0x62, 0x6A, 0x0A, 0x3C,
    0x3C, 0x2F, 0x54, 0x79, 0x70, 0x65, 0x2F, 0x50, 0x61, 0x67, 0x65, 0x2F,
    0x4D, 0x65, 0x64, 0x69, 0x61, 0x42, 0x6F, 0x78, 0x5B, 0x30, 0x20, 0x30,
    0x20, 0x36, 0x31, 0x32, 0x20, 0x37, 0x39, 0x32, 0x5D, 0x2F, 0x50, 0x61,
    0x72, 0x65, 0x6E, 0x74, 0x20, 0x32, 0x20, 0x30, 0x20, 0x52, 0x3E, 0x3E,
    0x0A, 0x65, 0x6E, 0x64, 0x6F, 0x62, 0x6A, 0x0A, 0x78, 0x72, 0x65, 0x66,
    0x0A, 0x30, 0x20, 0x34, 0x0A, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30,
    0x30, 0x30, 0x30, 0x20, 0x36, 0x35, 0x35, 0x33, 0x35, 0x20, 0x66, 0x20,
    0x0A, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x31, 0x35, 0x20,
    0x30, 0x30, 0x30, 0x30, 0x30, 0x20, 0x6E, 0x20, 0x0A, 0x30, 0x30, 0x30,
    0x30, 0x30, 0x30, 0x30, 0x30, 0x36, 0x38, 0x20, 0x30, 0x30, 0x30, 0x30,
    0x30, 0x20, 0x6E, 0x20, 0x0A, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30,
    0x31, 0x32, 0x35, 0x20, 0x30, 0x30, 0x30, 0x30, 0x30, 0x20, 0x6E, 0x20,
    0x0A, 0x74, 0x72, 0x61, 0x69, 0x6C, 0x65, 0x72, 0x0A, 0x3C, 0x3C, 0x2F,
    0x53, 0x69, 0x7A, 0x65, 0x20, 0x34, 0x2F, 0x52, 0x6F, 0x6F, 0x74, 0x20,
    0x31, 0x20, 0x30, 0x20, 0x52, 0x3E, 0x3E, 0x0A, 0x73, 0x74, 0x61, 0x72,
    0x74, 0x78, 0x72, 0x65, 0x66, 0x0A, 0x32, 0x30, 0x39, 0x0A, 0x25, 0x25,
    0x45, 0x4F, 0x46, 0x0A,
  ];

  static String _escapePdfText(String text) {
    return text
        .replaceAll('•', '-')
        .replaceAll('—', '-')
        .replaceAll('–', '-')
        .replaceAll('“', '"')
        .replaceAll('”', '"')
        .replaceAll('‘', "'")
        .replaceAll('’', "'")
        .replaceAll(r'\', r'\\')
        .replaceAll('(', r'\(')
        .replaceAll(')', r'\)')
        .replaceAll('\r', '')
        .replaceAll('\n', ' ');
  }

  /// Generates a high-resolution ID Card PDF
  static Future<File> generateIdCardPdf({
    required String outputFilePath,
    required String companyName,
    required String companyAddress,
    required String companyPhone,
    required String employeeName,
    required String employeeRole,
    required String employeeId,
    File? logoFile,
    File? photoFile,
  }) async {
    const double pageWidth = 595.28; // Standard A4 width
    const double pageHeight = 841.89; // Standard A4 height

    final buffer = BytesBuilder();
    void writeString(String s) => buffer.add(utf8.encode(s));

    final List<int> xrefOffsets = [0];
    writeString('%PDF-1.4\n%\xFF\xFF\xFF\xFF\n');

    final hasLogo = logoFile != null && await logoFile.exists();
    final hasPhoto = photoFile != null && await photoFile.exists();

    Uint8List? logoBytes;
    int logoW = 100, logoH = 100;
    if (hasLogo) {
      try {
        logoBytes = await logoFile.readAsBytes();
        final dims = _getJpegDimensions(logoBytes);
        if (dims != null) {
          logoW = dims.width;
          logoH = dims.height;
        }
      } catch (_) {}
    }

    Uint8List? photoBytes;
    int photoW = 120, photoH = 150;
    if (hasPhoto) {
      try {
        photoBytes = await photoFile.readAsBytes();
        final dims = _getJpegDimensions(photoBytes);
        if (dims != null) {
          photoW = dims.width;
          photoH = dims.height;
        }
      } catch (_) {}
    }

    int nextObjId = 1;
    final int catalogObj = nextObjId++;
    final int pagesObj = nextObjId++;
    final int fontRegularObj = nextObjId++;
    final int fontBoldObj = nextObjId++;
    final int fontObliqueObj = nextObjId++;
    final int pageObj = nextObjId++;
    final int contentObj = nextObjId++;
    final int? logoObj = logoBytes != null ? nextObjId++ : null;
    final int? photoObj = photoBytes != null ? nextObjId++ : null;

    // Catalog
    xrefOffsets.add(buffer.length);
    writeString('$catalogObj 0 obj\n<< /Type /Catalog /Pages $pagesObj 0 R >>\nendobj\n');

    // Pages
    xrefOffsets.add(buffer.length);
    writeString('$pagesObj 0 obj\n<< /Type /Pages /Kids [$pageObj 0 R] /Count 1 >>\nendobj\n');

    // Fonts
    xrefOffsets.add(buffer.length);
    writeString('$fontRegularObj 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>\nendobj\n');

    xrefOffsets.add(buffer.length);
    writeString('$fontBoldObj 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold >>\nendobj\n');

    xrefOffsets.add(buffer.length);
    writeString('$fontObliqueObj 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Oblique >>\nendobj\n');

    // Resources XObject string
    final xObjectEntries = <String>[];
    if (logoObj != null) xObjectEntries.add('/ImLogo $logoObj 0 R');
    if (photoObj != null) xObjectEntries.add('/ImPhoto $photoObj 0 R');
    final xObjectDict = xObjectEntries.isNotEmpty ? '/XObject << ${xObjectEntries.join(' ')} >>' : '';

    // Page
    xrefOffsets.add(buffer.length);
    writeString('$pageObj 0 obj\n'
        '<< /Type /Page\n'
        '   /Parent $pagesObj 0 R\n'
        '   /MediaBox [0 0 $pageWidth $pageHeight]\n'
        '   /Contents $contentObj 0 R\n'
        '   /Resources <<\n'
        '     /Font << /F1 $fontRegularObj 0 R /F2 $fontBoldObj 0 R /F3 $fontObliqueObj 0 R >>\n'
        '     $xObjectDict\n'
        '   >>\n'
        '>>\nendobj\n');

    // Content Stream: Build printable ID card centered on the page
    final cardW = 340.0;
    final cardH = 480.0;
    final cardX = (pageWidth - cardW) / 2;
    final cardY = (pageHeight - cardH) / 2;

    final sb = StringBuffer();

    // Background Page soft fill
    sb.writeln('0.96 0.97 0.98 rg');
    sb.writeln('0 0 $pageWidth $pageHeight re f');

    // Card Shadow
    sb.writeln('0.85 0.88 0.92 rg');
    sb.writeln('${cardX + 4} ${cardY - 4} $cardW $cardH re f');

    // Card White Background
    sb.writeln('1.0 1.0 1.0 rg');
    sb.writeln('$cardX $cardY $cardW $cardH re f');

    // Card Border
    sb.writeln('0.20 0.40 0.85 RG');
    sb.writeln('1.5 w');
    sb.writeln('$cardX $cardY $cardW $cardH re S');

    // Top Header Banner (Corporate Blue)
    const headerH = 95.0;
    final headerY = cardY + cardH - headerH;
    sb.writeln('0.15 0.35 0.80 rg');
    sb.writeln('$cardX $headerY $cardW $headerH re f');

    // Gold Accent Strip
    sb.writeln('0.95 0.75 0.15 rg');
    sb.writeln('$cardX ${headerY - 4} $cardW 4 re f');

    // Header Text - Company Name
    sb.writeln('BT');
    sb.writeln('/F2 16 Tf');
    sb.writeln('1.0 1.0 1.0 rg');
    final cName = _escapePdfText(companyName.isNotEmpty ? companyName.toUpperCase() : 'IDENTITY CARD');
    sb.writeln('${cardX + 20} ${headerY + 55} Td ($cName) Tj');
    sb.writeln('ET');

    // Header Subtitle / Badge
    sb.writeln('BT');
    sb.writeln('/F1 9 Tf');
    sb.writeln('0.9 0.95 1.0 rg');
    sb.writeln('${cardX + 20} ${headerY + 38} Td (OFFICIAL IDENTIFICATION PASS) Tj');
    sb.writeln('ET');

    // Employee Photo Box
    const photoBoxW = 90.0;
    const photoBoxH = 110.0;
    final photoX = cardX + (cardW - photoBoxW) / 2;
    final photoY = headerY - 130.0;

    if (photoObj != null && photoBytes != null) {
      sb.writeln('q');
      sb.writeln('$photoBoxW 0 0 $photoBoxH $photoX $photoY cm');
      sb.writeln('/ImPhoto Do');
      sb.writeln('Q');
      // Photo border
      sb.writeln('0.15 0.35 0.80 RG 1.5 w');
      sb.writeln('$photoX $photoY $photoBoxW $photoBoxH re S');
    } else {
      // Placeholder photo box
      sb.writeln('0.92 0.94 0.97 rg');
      sb.writeln('$photoX $photoY $photoBoxW $photoBoxH re f');
      sb.writeln('0.75 0.80 0.88 RG 1 w');
      sb.writeln('$photoX $photoY $photoBoxW $photoBoxH re S');

      sb.writeln('BT');
      sb.writeln('/F2 28 Tf');
      sb.writeln('0.55 0.65 0.78 rg');
      final initials = employeeName.trim().isNotEmpty
          ? employeeName.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
          : 'ID';
      sb.writeln('${photoX + 28} ${photoY + 45} Td ($initials) Tj');
      sb.writeln('ET');
    }

    // Employee Name
    final empNameText = _escapePdfText(employeeName.isNotEmpty ? employeeName : 'Employee Name');
    sb.writeln('BT');
    sb.writeln('/F2 16 Tf');
    sb.writeln('0.10 0.15 0.25 rg');
    sb.writeln('${cardX + 24} ${photoY - 25} Td ($empNameText) Tj');
    sb.writeln('ET');

    // Employee Role / Job Title
    final empRoleText = _escapePdfText(employeeRole.isNotEmpty ? employeeRole : 'Authorized Member');
    sb.writeln('BT');
    sb.writeln('/F2 11 Tf');
    sb.writeln('0.15 0.35 0.80 rg');
    sb.writeln('${cardX + 24} ${photoY - 42} Td ($empRoleText) Tj');
    sb.writeln('ET');

    // Divider line
    sb.writeln('0.85 0.88 0.92 RG 1 w');
    sb.writeln('${cardX + 24} ${photoY - 52} m ${cardX + cardW - 24} ${photoY - 52} l S');

    // ID Details Grid - Clean Two-Column Field Alignment
    final labelX = cardX + 24.0;
    final valueX = cardX + 115.0;

    // 1. ID NUMBER Row
    final empIdText = _escapePdfText(employeeId.isNotEmpty ? employeeId : 'EMP-001');
    final idY = photoY - 70.0;
    sb.writeln('BT');
    sb.writeln('/F1 9 Tf');
    sb.writeln('0.45 0.50 0.58 rg');
    sb.writeln('$labelX $idY Td (ID NUMBER:) Tj');
    sb.writeln('ET');

    sb.writeln('BT');
    sb.writeln('/F2 9.5 Tf');
    sb.writeln('0.10 0.15 0.25 rg');
    sb.writeln('$valueX $idY Td ($empIdText) Tj');
    sb.writeln('ET');

    // 2. LOCATION Row
    final addrText = _escapePdfText(companyAddress.isNotEmpty ? companyAddress : '123 Tech Park, NY');
    final locY = photoY - 88.0;
    sb.writeln('BT');
    sb.writeln('/F1 9 Tf');
    sb.writeln('0.45 0.50 0.58 rg');
    sb.writeln('$labelX $locY Td (LOCATION:) Tj');
    sb.writeln('ET');

    sb.writeln('BT');
    sb.writeln('/F1 9.5 Tf');
    sb.writeln('0.10 0.15 0.25 rg');
    sb.writeln('$valueX $locY Td ($addrText) Tj');
    sb.writeln('ET');

    // 3. PHONE Row
    final phoneText = _escapePdfText(companyPhone.isNotEmpty ? companyPhone : '+1 555-1234');
    final phoneY = photoY - 106.0;
    sb.writeln('BT');
    sb.writeln('/F1 9 Tf');
    sb.writeln('0.45 0.50 0.58 rg');
    sb.writeln('$labelX $phoneY Td (PHONE:) Tj');
    sb.writeln('ET');

    sb.writeln('BT');
    sb.writeln('/F1 9.5 Tf');
    sb.writeln('0.10 0.15 0.25 rg');
    sb.writeln('$valueX $phoneY Td ($phoneText) Tj');
    sb.writeln('ET');

    // Card Bottom Footer Band
    const footerH = 36.0;
    sb.writeln('0.15 0.35 0.80 rg');
    sb.writeln('$cardX $cardY $cardW $footerH re f');

    sb.writeln('BT');
    sb.writeln('/F1 8 Tf');
    sb.writeln('1.0 1.0 1.0 rg');
    sb.writeln('${cardX + 30} ${cardY + 14} Td (PlainScan ID Verified - Authorized Personnel Pass) Tj');
    sb.writeln('ET');

    final contentBytes = utf8.encode(sb.toString());

    // Content Object
    xrefOffsets.add(buffer.length);
    writeString('$contentObj 0 obj\n<< /Length ${contentBytes.length} >>\nstream\n');
    buffer.add(contentBytes);
    writeString('endstream\nendobj\n');

    // Logo Image XObject if available
    if (logoObj != null && logoBytes != null) {
      xrefOffsets.add(buffer.length);
      writeString('$logoObj 0 obj\n'
          '<< /Type /XObject\n'
          '   /Subtype /Image\n'
          '   /Width $logoW\n'
          '   /Height $logoH\n'
          '   /ColorSpace /DeviceRGB\n'
          '   /BitsPerComponent 8\n'
          '   /Filter /DCTDecode\n'
          '   /Length ${logoBytes.length}\n'
          '>>\nstream\n');
      buffer.add(logoBytes);
      writeString('\nendstream\nendobj\n');
    }

    // Photo Image XObject if available
    if (photoObj != null && photoBytes != null) {
      xrefOffsets.add(buffer.length);
      writeString('$photoObj 0 obj\n'
          '<< /Type /XObject\n'
          '   /Subtype /Image\n'
          '   /Width $photoW\n'
          '   /Height $photoH\n'
          '   /ColorSpace /DeviceRGB\n'
          '   /BitsPerComponent 8\n'
          '   /Filter /DCTDecode\n'
          '   /Length ${photoBytes.length}\n'
          '>>\nstream\n');
      buffer.add(photoBytes);
      writeString('\nendstream\nendobj\n');
    }

    // XRef Table
    final int xrefStart = buffer.length;
    final int totalObjs = xrefOffsets.length;
    writeString('xref\n0 $totalObjs\n0000000000 65535 f \n');
    for (int i = 1; i < totalObjs; i++) {
      final offset = xrefOffsets[i];
      final offsetStr = offset.toString().padLeft(10, '0');
      writeString('$offsetStr 00000 n \n');
    }

    // Trailer
    writeString('trailer\n<< /Size $totalObjs /Root $catalogObj 0 R >>\n'
        'startxref\n$xrefStart\n%%EOF\n');

    final pdfFile = File(outputFilePath);
    await pdfFile.writeAsBytes(buffer.toBytes());
    return pdfFile;
  }

  /// Generates a professional Invoice PDF
  static Future<File> generateInvoicePdf({
    required String outputFilePath,
    required String invoiceNumber,
    required String fromName,
    required String fromEmail,
    required String fromPhone,
    required String fromAddress,
    required String toName,
    required String toEmail,
    required String toAddress,
    required String currency,
    double discount = 0.0,
    double taxRate = 0.0,
    required List<Map<String, dynamic>> items,
  }) async {
    const double pageWidth = 595.28;
    const double pageHeight = 841.89;

    final buffer = BytesBuilder();
    void writeString(String s) => buffer.add(utf8.encode(s));

    final List<int> xrefOffsets = [0];
    writeString('%PDF-1.4\n%\xFF\xFF\xFF\xFF\n');

    int nextObjId = 1;
    final int catalogObj = nextObjId++;
    final int pagesObj = nextObjId++;
    final int fontRegularObj = nextObjId++;
    final int fontBoldObj = nextObjId++;
    final int pageObj = nextObjId++;
    final int contentObj = nextObjId++;

    // Catalog
    xrefOffsets.add(buffer.length);
    writeString('$catalogObj 0 obj\n<< /Type /Catalog /Pages $pagesObj 0 R >>\nendobj\n');

    // Pages
    xrefOffsets.add(buffer.length);
    writeString('$pagesObj 0 obj\n<< /Type /Pages /Kids [$pageObj 0 R] /Count 1 >>\nendobj\n');

    // Fonts
    xrefOffsets.add(buffer.length);
    writeString('$fontRegularObj 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>\nendobj\n');

    xrefOffsets.add(buffer.length);
    writeString('$fontBoldObj 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold >>\nendobj\n');

    // Page
    xrefOffsets.add(buffer.length);
    writeString('$pageObj 0 obj\n'
        '<< /Type /Page\n'
        '   /Parent $pagesObj 0 R\n'
        '   /MediaBox [0 0 $pageWidth $pageHeight]\n'
        '   /Contents $contentObj 0 R\n'
        '   /Resources <<\n'
        '     /Font << /F1 $fontRegularObj 0 R /F2 $fontBoldObj 0 R >>\n'
        '   >>\n'
        '>>\nendobj\n');

    final sb = StringBuffer();

    // Top Header Banner
    sb.writeln('0.20 0.30 0.65 rg');
    sb.writeln('0 ${pageHeight - 110} $pageWidth 110 re f');

    // Header Title
    sb.writeln('BT');
    sb.writeln('/F2 26 Tf');
    sb.writeln('1.0 1.0 1.0 rg');
    sb.writeln('40 ${pageHeight - 60} Td (INVOICE) Tj');
    sb.writeln('ET');

    final invNum = _escapePdfText(invoiceNumber.isNotEmpty ? invoiceNumber : 'INV-001');
    sb.writeln('BT');
    sb.writeln('/F1 12 Tf');
    sb.writeln('0.9 0.95 1.0 rg');
    sb.writeln('40 ${pageHeight - 82} Td (Invoice #: $invNum) Tj');
    sb.writeln('ET');

    final dateStr = DateTime.now().toString().split(' ').first;
    sb.writeln('BT');
    sb.writeln('/F1 11 Tf');
    sb.writeln('0.9 0.95 1.0 rg');
    sb.writeln('${pageWidth - 160} ${pageHeight - 60} Td (Date: $dateStr) Tj');
    sb.writeln('ET');

    // From & Bill To Sections
    double y = pageHeight - 150;
    sb.writeln('BT');
    sb.writeln('/F2 12 Tf');
    sb.writeln('0.15 0.20 0.35 rg');
    sb.writeln('40 $y Td (Billed From:) Tj');
    sb.writeln('${pageWidth / 2} $y Td (Billed To:) Tj');
    sb.writeln('ET');

    y -= 18;
    final fName = _escapePdfText(fromName.isNotEmpty ? fromName : 'Issuer / Company');
    final tName = _escapePdfText(toName.isNotEmpty ? toName : 'Customer / Client');
    sb.writeln('BT');
    sb.writeln('/F2 11 Tf');
    sb.writeln('0.1 0.1 0.1 rg');
    sb.writeln('40 $y Td ($fName) Tj');
    sb.writeln('${pageWidth / 2} $y Td ($tName) Tj');
    sb.writeln('ET');

    y -= 14;
    final fEmail = _escapePdfText(fromEmail.isNotEmpty ? fromEmail : '');
    final tEmail = _escapePdfText(toEmail.isNotEmpty ? toEmail : '');
    if (fEmail.isNotEmpty || tEmail.isNotEmpty) {
      sb.writeln('BT');
      sb.writeln('/F1 10 Tf');
      sb.writeln('0.4 0.45 0.5 rg');
      if (fEmail.isNotEmpty) sb.writeln('40 $y Td ($fEmail) Tj');
      if (tEmail.isNotEmpty) sb.writeln('${pageWidth / 2} $y Td ($tEmail) Tj');
      sb.writeln('ET');
      y -= 14;
    }

    final fAddr = _escapePdfText(fromAddress.isNotEmpty ? fromAddress : '');
    final tAddr = _escapePdfText(toAddress.isNotEmpty ? toAddress : '');
    if (fAddr.isNotEmpty || tAddr.isNotEmpty) {
      sb.writeln('BT');
      sb.writeln('/F1 10 Tf');
      sb.writeln('0.4 0.45 0.5 rg');
      if (fAddr.isNotEmpty) sb.writeln('40 $y Td ($fAddr) Tj');
      if (tAddr.isNotEmpty) sb.writeln('${pageWidth / 2} $y Td ($tAddr) Tj');
      sb.writeln('ET');
      y -= 14;
    }

    // Items Table Header
    y -= 25;
    sb.writeln('0.20 0.30 0.65 rg');
    sb.writeln('40 $y ${pageWidth - 80} 24 re f');

    sb.writeln('BT');
    sb.writeln('/F2 10 Tf');
    sb.writeln('1.0 1.0 1.0 rg');
    sb.writeln('50 ${y + 7} Td (Item Description) Tj');
    sb.writeln('${pageWidth - 250} ${y + 7} Td (Qty) Tj');
    sb.writeln('${pageWidth - 190} ${y + 7} Td (Price) Tj');
    sb.writeln('${pageWidth - 110} ${y + 7} Td (Total) Tj');
    sb.writeln('ET');

    // Table rows
    double subtotal = 0.0;
    final rowItems = items.isNotEmpty
        ? items
        : [
            {'description': 'Professional Services', 'quantity': 1, 'price': 150.0, 'tax': 0.0}
          ];

    for (int i = 0; i < rowItems.length; i++) {
      final item = rowItems[i];
      final desc = _escapePdfText(item['description']?.toString() ?? 'Service Item');
      final qty = int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
      final price = double.tryParse(item['price']?.toString() ?? '0') ?? 0.0;
      final lineTotal = qty * price;
      subtotal += lineTotal;

      y -= 24;
      // Alternating row background
      if (i % 2 == 1) {
        sb.writeln('0.96 0.97 0.98 rg');
        sb.writeln('40 $y ${pageWidth - 80} 24 re f');
      }

      sb.writeln('BT');
      sb.writeln('/F1 10 Tf');
      sb.writeln('0.2 0.2 0.2 rg');
      sb.writeln('50 ${y + 7} Td ($desc) Tj');
      sb.writeln('${pageWidth - 250} ${y + 7} Td ($qty) Tj');
      sb.writeln('${pageWidth - 190} ${y + 7} Td ($currency ${price.toStringAsFixed(2)}) Tj');
      sb.writeln('${pageWidth - 110} ${y + 7} Td ($currency ${lineTotal.toStringAsFixed(2)}) Tj');
      sb.writeln('ET');
    }

    // Divider
    y -= 10;
    sb.writeln('0.85 0.88 0.92 RG 1 w');
    sb.writeln('40 $y m ${pageWidth - 40} $y l S');

    // Summary calculations
    final discountAmount = discount > 0 ? (subtotal * (discount / 100)) : 0.0;
    final grandTotal = subtotal - discountAmount;

    y -= 25;
    sb.writeln('BT');
    sb.writeln('/F1 10 Tf');
    sb.writeln('0.4 0.45 0.5 rg');
    sb.writeln('${pageWidth - 200} $y Td (Subtotal:) Tj');
    sb.writeln('/F2 10 Tf');
    sb.writeln('0.1 0.1 0.1 rg');
    sb.writeln('${pageWidth - 110} $y Td ($currency ${subtotal.toStringAsFixed(2)}) Tj');
    sb.writeln('ET');

    if (discount > 0) {
      y -= 18;
      sb.writeln('BT');
      sb.writeln('/F1 10 Tf');
      sb.writeln('0.4 0.45 0.5 rg');
      sb.writeln('${pageWidth - 200} $y Td (Discount ($discount%):) Tj');
      sb.writeln('/F2 10 Tf');
      sb.writeln('0.1 0.6 0.2 rg');
      sb.writeln('${pageWidth - 110} $y Td (-$currency ${discountAmount.toStringAsFixed(2)}) Tj');
      sb.writeln('ET');
    }

    y -= 25;
    sb.writeln('0.20 0.30 0.65 rg');
    sb.writeln('${pageWidth - 210} $y 170 30 re f');

    sb.writeln('BT');
    sb.writeln('/F2 12 Tf');
    sb.writeln('1.0 1.0 1.0 rg');
    sb.writeln('${pageWidth - 195} ${y + 10} Td (TOTAL: $currency ${grandTotal.toStringAsFixed(2)}) Tj');
    sb.writeln('ET');

    // Footer
    sb.writeln('BT');
    sb.writeln('/F1 9 Tf');
    sb.writeln('0.5 0.55 0.6 rg');
    sb.writeln('40 40 Td (Generated securely via PlainScan - Thank you for your business!) Tj');
    sb.writeln('ET');

    final contentBytes = utf8.encode(sb.toString());

    // Content Object
    xrefOffsets.add(buffer.length);
    writeString('$contentObj 0 obj\n<< /Length ${contentBytes.length} >>\nstream\n');
    buffer.add(contentBytes);
    writeString('endstream\nendobj\n');

    // XRef Table
    final int xrefStart = buffer.length;
    final int totalObjs = xrefOffsets.length;
    writeString('xref\n0 $totalObjs\n0000000000 65535 f \n');
    for (int i = 1; i < totalObjs; i++) {
      final offset = xrefOffsets[i];
      final offsetStr = offset.toString().padLeft(10, '0');
      writeString('$offsetStr 00000 n \n');
    }

    // Trailer
    writeString('trailer\n<< /Size $totalObjs /Root $catalogObj 0 R >>\n'
        'startxref\n$xrefStart\n%%EOF\n');

    final pdfFile = File(outputFilePath);
    await pdfFile.writeAsBytes(buffer.toBytes());
    return pdfFile;
  }

  static ({int width, int height})? _getJpegDimensions(Uint8List bytes) {
    if (bytes.length < 4 || bytes[0] != 0xFF || bytes[1] != 0xD8) {
      return null;
    }
    int offset = 2;
    while (offset < bytes.length - 8) {
      if (bytes[offset] != 0xFF) {
        offset++;
        continue;
      }
      final marker = bytes[offset + 1];
      if (marker >= 0xC0 && marker <= 0xCF && marker != 0xC4 && marker != 0xC8 && marker != 0xCC) {
        final height = (bytes[offset + 5] << 8) | bytes[offset + 6];
        final width = (bytes[offset + 7] << 8) | bytes[offset + 8];
        return (width: width, height: height);
      }
      if (marker == 0xD9 || marker == 0xDA) break;
      if (offset + 3 >= bytes.length) break;
      final length = (bytes[offset + 2] << 8) | bytes[offset + 3];
      offset += 2 + length;
    }
    return null;
  }

  /// Permanently removes all metadata, Info attributes, XMP packets, and private tags from PDF bytes
  static Uint8List stripPdfMetadata(Uint8List bytes) {
    if (bytes.isEmpty) return bytes;
    final output = Uint8List.fromList(bytes);
    final latin1Str = latin1.decode(output);

    // 1. Scrub XMP packets
    final xmpRegex = RegExp(r'<\?xpacket begin=[\s\S]*?\?xpacket end=["\x27][\w\s]*["\x27]\?>', caseSensitive: false);
    for (final match in xmpRegex.allMatches(latin1Str)) {
      for (int i = match.start; i < match.end; i++) {
        output[i] = 0x20;
      }
    }

    final xmpMetaRegex = RegExp(r'<x:xmpmeta[\s\S]*?</x:xmpmeta>', caseSensitive: false);
    for (final match in xmpMetaRegex.allMatches(latin1Str)) {
      for (int i = match.start; i < match.end; i++) {
        output[i] = 0x20;
      }
    }

    // 2. Scrub Info dictionary tags: Title, Author, Subject, Keywords, Creator, Producer, Dates, Copyright, Comment, etc.
    final metaKeysRegex = RegExp(
      r'/(Title|Author|Subject|Keywords|Creator|Producer|CreationDate|ModDate|Trapped|PTEX\.Fullbanner|Company|Copyright|Comment)\s*(\([^\)]*\)|<[0-9a-fA-F\s]*>)',
      caseSensitive: false,
    );
    for (final match in metaKeysRegex.allMatches(latin1Str)) {
      for (int i = match.start; i < match.end; i++) {
        output[i] = 0x20;
      }
    }

    // 3. Clear /Metadata and /PieceInfo references
    final metaRefRegex = RegExp(r'/(Metadata|PieceInfo)\s+\d+\s+\d+\s+R', caseSensitive: false);
    for (final match in metaRefRegex.allMatches(latin1Str)) {
      for (int i = match.start; i < match.end; i++) {
        output[i] = 0x20;
      }
    }

    return output;
  }

  /// Removes EXIF, GPS location, device tags, and comments from JPEG bytes
  static Uint8List stripJpegMetadata(Uint8List bytes) {
    if (bytes.length < 4 || bytes[0] != 0xFF || bytes[1] != 0xD8) {
      return bytes;
    }

    final buffer = BytesBuilder();
    buffer.add([0xFF, 0xD8]); // SOI

    int offset = 2;
    while (offset < bytes.length) {
      if (bytes[offset] != 0xFF) {
        offset++;
        continue;
      }

      final marker = bytes[offset + 1];

      // SOS (Start of Scan) - rest is image data
      if (marker == 0xDA) {
        buffer.add(bytes.sublist(offset));
        break;
      }

      // Standalone markers
      if (marker == 0xD9 || (marker >= 0xD0 && marker <= 0xD7) || marker == 0x01) {
        buffer.add([0xFF, marker]);
        offset += 2;
        if (marker == 0xD9) break;
        continue;
      }

      if (offset + 3 >= bytes.length) break;

      final length = (bytes[offset + 2] << 8) | bytes[offset + 3];
      final chunkEnd = offset + 2 + length;
      if (chunkEnd > bytes.length) {
        buffer.add(bytes.sublist(offset));
        break;
      }

      // Drop APP1 (EXIF/GPS 0xE1), APP2 (XMP 0xE2), APP13 (IPTC 0xED), COM (0xFE)
      final shouldSkip = marker == 0xE1 ||
          marker == 0xED ||
          marker == 0xFE ||
          (marker >= 0xE2 && marker <= 0xEF && marker != 0xEE);

      if (!shouldSkip) {
        buffer.add(bytes.sublist(offset, chunkEnd));
      }

      offset = chunkEnd;
    }

    return buffer.toBytes();
  }

  /// Strips metadata chunks (tEXt, zTXt, iTXt, eXIf, tIMe) from PNG bytes
  static Uint8List stripPngMetadata(Uint8List bytes) {
    const pngHeader = [137, 80, 78, 71, 13, 10, 26, 10];
    if (bytes.length < 8) return bytes;
    for (int i = 0; i < 8; i++) {
      if (bytes[i] != pngHeader[i]) return bytes;
    }

    final buffer = BytesBuilder();
    buffer.add(pngHeader);

    int offset = 8;
    while (offset + 8 <= bytes.length) {
      final length = (bytes[offset] << 24) |
          (bytes[offset + 1] << 16) |
          (bytes[offset + 2] << 8) |
          bytes[offset + 3];
      final type = ascii.decode(bytes.sublist(offset + 4, offset + 8));
      final totalChunkLength = 12 + length;

      if (offset + totalChunkLength > bytes.length) {
        buffer.add(bytes.sublist(offset));
        break;
      }

      final shouldDrop = type == 'tEXt' ||
          type == 'zTXt' ||
          type == 'iTXt' ||
          type == 'eXIf' ||
          type == 'tIMe' ||
          type == 'pHYs';

      if (!shouldDrop) {
        buffer.add(bytes.sublist(offset, offset + totalChunkLength));
      }

      if (type == 'IEND') break;
      offset += totalChunkLength;
    }

    return buffer.toBytes();
  }

  /// Strips metadata based on file extension
  static Uint8List stripMetadata(Uint8List bytes, String extension) {
    final ext = extension.toLowerCase().replaceAll('.', '').trim();
    if (ext == 'pdf') {
      return stripPdfMetadata(bytes);
    } else if (ext == 'jpg' || ext == 'jpeg') {
      return stripJpegMetadata(bytes);
    } else if (ext == 'png') {
      return stripPngMetadata(bytes);
    }
    return stripPdfMetadata(bytes);
  }

  /// Updates or injects metadata (Title, Author, Description, Copyright, Software, Comment) into PDF or image bytes
  static Uint8List updatePdfMetadata(
    Uint8List bytes, {
    String? title,
    String? author,
    String? description,
    String? copyright,
    String? software,
    String? comment,
  }) {
    if (bytes.length < 5) return bytes;
    final str = latin1.decode(bytes);
    if (!str.startsWith('%PDF-')) return bytes;

    // Sanitize old metadata first to avoid conflict
    final cleanBytes = stripPdfMetadata(bytes);
    final cleanStr = latin1.decode(cleanBytes);

    final now = DateTime.now();
    final dateStr = 'D:${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}Z';

    final t = title != null && title.trim().isNotEmpty ? _escapePdfText(title.trim()) : '';
    final a = author != null && author.trim().isNotEmpty ? _escapePdfText(author.trim()) : '';
    final s = description != null && description.trim().isNotEmpty ? _escapePdfText(description.trim()) : '';
    final cr = copyright != null && copyright.trim().isNotEmpty ? _escapePdfText(copyright.trim()) : '';
    final sw = software != null && software.trim().isNotEmpty ? _escapePdfText(software.trim()) : 'PlainScan Document Suite';
    final cm = comment != null && comment.trim().isNotEmpty ? _escapePdfText(comment.trim()) : '';

    final infoSb = StringBuffer();
    infoSb.writeln('<<');
    if (t.isNotEmpty) infoSb.writeln('  /Title ($t)');
    if (a.isNotEmpty) infoSb.writeln('  /Author ($a)');
    if (s.isNotEmpty) infoSb.writeln('  /Subject ($s)');
    if (cr.isNotEmpty) infoSb.writeln('  /Copyright ($cr)');
    if (sw.isNotEmpty) infoSb.writeln('  /Creator ($sw)');
    infoSb.writeln('  /Producer (PlainScan Document Engine)');
    if (cm.isNotEmpty) infoSb.writeln('  /Comment ($cm)');
    infoSb.writeln('  /CreationDate ($dateStr)');
    infoSb.writeln('  /ModDate ($dateStr)');
    infoSb.write('>>');

    // Find next available object index
    final maxObjMatches = RegExp(r'(\d+)\s+0\s+obj').allMatches(cleanStr);
    int nextObj = 50;
    for (final m in maxObjMatches) {
      final id = int.tryParse(m.group(1)!) ?? 0;
      if (id >= nextObj) nextObj = id + 1;
    }

    final newInfoObj = '\n$nextObj 0 obj\n$infoSb\nendobj\n';
    
    // Find trailer Root reference
    final rootMatch = RegExp(r'/Root\s+(\d+\s+\d+\s+R)').firstMatch(cleanStr);
    final rootRef = rootMatch != null ? rootMatch.group(1) : '1 0 R';

    final buffer = BytesBuilder();
    buffer.add(cleanBytes);

    final infoObjOffset = buffer.length;
    buffer.add(latin1.encode(newInfoObj));

    // Find the previous startxref offset — required for /Prev in incremental update trailer (PDF spec §7.5.6)
    int prevStartXref = 0;
    final startxrefMatches = RegExp(r'startxref\s+(\d+)').allMatches(cleanStr).toList();
    if (startxrefMatches.isNotEmpty) {
      prevStartXref = int.tryParse(startxrefMatches.last.group(1)!) ?? 0;
    }

    // /Size must equal highest object number + 1 per PDF spec §7.5.8
    final newSize = nextObj + 1;

    final trailerXrefOffset = buffer.length;
    final xrefSb = StringBuffer();
    xrefSb.writeln('xref');
    xrefSb.writeln('$nextObj 1');
    xrefSb.writeln('${infoObjOffset.toString().padLeft(10, '0')} 00000 n ');
    xrefSb.writeln('trailer');
    // /Size and /Prev are mandatory for incremental updates — without them viewers skip the new Info object
    xrefSb.writeln('<< /Size $newSize /Root $rootRef /Info $nextObj 0 R /Prev $prevStartXref >>');
    xrefSb.writeln('startxref');
    xrefSb.writeln('$trailerXrefOffset');
    xrefSb.write('%%EOF');

    buffer.add(latin1.encode(xrefSb.toString()));
    return buffer.toBytes();
  }

  /// Unified entry point to update metadata across PDF and Image formats
  static Uint8List updateMetadata(
    Uint8List bytes,
    String extension, {
    String? title,
    String? author,
    String? description,
    String? copyright,
    String? software,
    String? comment,
  }) {
    final ext = extension.toLowerCase().replaceAll('.', '').trim();
    if (ext == 'pdf') {
      return updatePdfMetadata(
        bytes,
        title: title,
        author: author,
        description: description,
        copyright: copyright,
        software: software,
        comment: comment,
      );
    }
    if (ext == 'jpg' || ext == 'jpeg') {
      return updateJpegMetadata(
        bytes,
        title: title,
        author: author,
        description: description,
        copyright: copyright,
        software: software,
        comment: comment,
      );
    }
    if (ext == 'png') {
      return updatePngMetadata(
        bytes,
        title: title,
        author: author,
        description: description,
        copyright: copyright,
        software: software,
        comment: comment,
      );
    }
    // Fallback — strip only for unsupported formats
    return stripMetadata(bytes, ext);
  }

  // ─── JPEG EXIF metadata writer ────────────────────────────────────────────
  // Builds a minimal EXIF APP1 block (little-endian TIFF IFD0) and injects it
  // immediately after the JPEG SOI marker, replacing any previous EXIF/XMP blocks.


  static void _writeLE16(List<int> buf, int offset, int val) {
    buf[offset] = val & 0xFF;
    buf[offset + 1] = (val >> 8) & 0xFF;
  }

  static void _writeLE32(List<int> buf, int offset, int val) {
    buf[offset] = val & 0xFF;
    buf[offset + 1] = (val >> 8) & 0xFF;
    buf[offset + 2] = (val >> 16) & 0xFF;
    buf[offset + 3] = (val >> 24) & 0xFF;
  }

  /// Writes user-supplied metadata into a JPEG file as a compact EXIF APP1 segment.
  static Uint8List updateJpegMetadata(
    Uint8List bytes, {
    String? title,
    String? author,
    String? description,
    String? copyright,
    String? software,
    String? comment,
  }) {
    if (bytes.length < 4 || bytes[0] != 0xFF || bytes[1] != 0xD8) return bytes;

    // 1. Strip existing EXIF / XMP / COM segments
    final stripped = stripJpegMetadata(bytes);

    // 2. Collect non-empty fields → EXIF IFD0 tags
    //    Tag IDs (decimal/hex):
    //      0x010E = ImageDescription (title/description)
    //      0x013B = Artist           (author)
    //      0x8298 = Copyright
    //      0x0131 = Software
    //      0x9286 = UserComment      (comment — in "ASCII\0\0\0<text>" encoding)
    final fields = <MapEntry<int, String>>[];
    final effectiveTitle = (title != null && title.isNotEmpty)
        ? title
        : (description != null && description.isNotEmpty ? description : null);
    if (effectiveTitle != null && effectiveTitle.isNotEmpty) {
      fields.add(MapEntry(0x010E, effectiveTitle));
    }
    if (author != null && author.isNotEmpty) fields.add(MapEntry(0x013B, author));
    if (copyright != null && copyright.isNotEmpty) fields.add(MapEntry(0x8298, copyright));

    final sw = (software != null && software.isNotEmpty) ? software : 'PlainScan';
    fields.add(MapEntry(0x0131, sw));

    // Sort tags ascending (required by EXIF spec)
    fields.sort((a, b) => a.key.compareTo(b.key));

    if (fields.isEmpty && (comment == null || comment.isEmpty)) {
      // Nothing to write — return stripped bytes
      return stripped;
    }

    // 3. Build EXIF IFD0
    // TIFF header (8 bytes): II (little-endian), 0x002A, offset-to-IFD0=8
    final tiffHeader = [0x49, 0x49, 0x2A, 0x00, 0x08, 0x00, 0x00, 0x00];

    final int entryCount = fields.length;
    // IFD0: 2 bytes count + entryCount * 12 bytes + 4 bytes next-IFD = 0
    final int ifd0Size = 2 + entryCount * 12 + 4;
    // IFD0 starts at offset 8 from TIFF header start
    final int valueAreaStart = 8 + ifd0Size;

    // Build value area and fix up offsets in each IFD entry
    final ifd0 = List<int>.filled(ifd0Size, 0);
    _writeLE16(ifd0, 0, entryCount);

    final valueArea = BytesBuilder();
    for (int i = 0; i < entryCount; i++) {
      final tag = fields[i].key;
      final valueBytes = latin1.encode('${fields[i].value}\x00');
      final count = valueBytes.length;
      final entryOffset = 2 + i * 12;
      _writeLE16(ifd0, entryOffset, tag);
      _writeLE16(ifd0, entryOffset + 2, 2); // ASCII
      _writeLE32(ifd0, entryOffset + 4, count);
      if (count <= 4) {
        // Value fits inline — pad with zeros
        for (int b = 0; b < count; b++) { ifd0[entryOffset + 8 + b] = valueBytes[b]; }
      } else {
        final valOffset = valueAreaStart + valueArea.length;
        _writeLE32(ifd0, entryOffset + 8, valOffset);
        valueArea.add(valueBytes);
      }
    }
    // Next IFD offset = 0
    // (already zero-filled)

    // 4. Assemble EXIF APP1 payload = "Exif\x00\x00" + TIFF header + IFD0 + value area
    final exifPayload = BytesBuilder();
    exifPayload.add(latin1.encode('Exif\x00\x00'));
    exifPayload.add(tiffHeader);
    exifPayload.add(ifd0);
    exifPayload.add(valueArea.toBytes());

    // 5. Add UserComment (tag 0x9286) as a JPEG COM segment instead (simpler & universal)
    //    COM segments are supported by all viewers, unlike EXIF UserComment which needs Exif IFD.
    final comBytes = BytesBuilder();
    if (comment != null && comment.isNotEmpty) {
      final comData = latin1.encode(comment);
      final comLen = comData.length + 2; // length field includes its own 2 bytes
      comBytes.add([0xFF, 0xFE]);
      comBytes.add([(comLen >> 8) & 0xFF, comLen & 0xFF]);
      comBytes.add(comData);
    }

    // 6. Build final JPEG:  SOI + APP1(EXIF) + COM? + rest of stripped JPEG (skip SOI)
    final app1Payload = exifPayload.toBytes();
    final app1Len = app1Payload.length + 2; // +2 for the length field itself
    final result = BytesBuilder();
    result.add([0xFF, 0xD8]); // SOI
    result.add([0xFF, 0xE1]); // APP1 marker
    result.add([(app1Len >> 8) & 0xFF, app1Len & 0xFF]);
    result.add(app1Payload);
    if (comBytes.length > 0) result.add(comBytes.toBytes());
    // Append stripped JPEG content (skip the first 2 bytes = SOI already added)
    if (stripped.length > 2) result.add(stripped.sublist(2));

    return result.toBytes();
  }

  // ─── PNG tEXt metadata writer ─────────────────────────────────────────────
  // Injects standard tEXt chunks (keyword\x00value) immediately after IHDR.
  // CRC-32 is computed per PNG spec.

  static List<int>? _crc32Table;
  static List<int> _getCrc32Table() {
    if (_crc32Table != null) return _crc32Table!;
    final table = List<int>.filled(256, 0);
    for (int i = 0; i < 256; i++) {
      int c = i;
      for (int k = 0; k < 8; k++) {
        if ((c & 1) != 0) {
          c = 0xEDB88320 ^ (c >> 1);
        } else {
          c = c >> 1;
        }
      }
      table[i] = c;
    }
    _crc32Table = table;
    return table;
  }

  static int _pngCrc32(List<int> data) {
    final table = _getCrc32Table();
    int crc = 0xFFFFFFFF;
    for (final b in data) {
      crc = table[(crc ^ b) & 0xFF] ^ (crc >> 8);
    }
    return crc ^ 0xFFFFFFFF;
  }

  static List<int> _pngTextChunk(String keyword, String value) {
    // tEXt chunk: keyword \x00 value (Latin-1)
    final chunkData = <int>[...latin1.encode(keyword), 0x00, ...latin1.encode(value)];
    final typeBytes = latin1.encode('tEXt');
    final crcData = [...typeBytes, ...chunkData];
    final crc = _pngCrc32(crcData);
    final length = chunkData.length;
    return [
      (length >> 24) & 0xFF, (length >> 16) & 0xFF, (length >> 8) & 0xFF, length & 0xFF,
      ...typeBytes,
      ...chunkData,
      (crc >> 24) & 0xFF, (crc >> 16) & 0xFF, (crc >> 8) & 0xFF, crc & 0xFF,
    ];
  }

  /// Writes user-supplied metadata into a PNG file as tEXt chunks after IHDR.
  static Uint8List updatePngMetadata(
    Uint8List bytes, {
    String? title,
    String? author,
    String? description,
    String? copyright,
    String? software,
    String? comment,
  }) {
    const pngSig = [137, 80, 78, 71, 13, 10, 26, 10];
    if (bytes.length < 8) return bytes;
    for (int i = 0; i < 8; i++) {
      if (bytes[i] != pngSig[i]) return bytes;
    }

    // 1. Strip existing metadata chunks
    final stripped = stripPngMetadata(bytes);

    // 2. Build new tEXt chunks for non-empty fields using standard PNG keywords
    final newChunks = BytesBuilder();
    if (title != null && title.isNotEmpty) {
      newChunks.add(_pngTextChunk('Title', title));
    }
    if (author != null && author.isNotEmpty) {
      newChunks.add(_pngTextChunk('Author', author));
    }
    if (description != null && description.isNotEmpty) {
      newChunks.add(_pngTextChunk('Description', description));
    }
    if (copyright != null && copyright.isNotEmpty) {
      newChunks.add(_pngTextChunk('Copyright', copyright));
    }
    final sw = (software != null && software.isNotEmpty) ? software : 'PlainScan';
    newChunks.add(_pngTextChunk('Software', sw));
    if (comment != null && comment.isNotEmpty) {
      newChunks.add(_pngTextChunk('Comment', comment));
    }

    if (newChunks.isEmpty) return stripped;

    // 3. Insert new tEXt chunks immediately after IHDR (sig + IHDR = 8 + 4+4+13+4 = 33 bytes)
    const ihdrEnd = 33; // PNG sig(8) + length(4) + 'IHDR'(4) + data(13) + CRC(4)
    if (stripped.length < ihdrEnd) return stripped;

    final result = BytesBuilder();
    result.add(stripped.sublist(0, ihdrEnd));
    result.add(newChunks.toBytes());
    result.add(stripped.sublist(ihdrEnd));
    return result.toBytes();
  }

  /// Extracts structured metadata from PDF or Image bytes
  static Map<String, dynamic> extractMetadata(Uint8List bytes, String fileName, {double? sizeKb}) {
    final isPdf = fileName.toLowerCase().endsWith('.pdf');
    final baseName = fileName.contains('.') ? fileName.substring(0, fileName.lastIndexOf('.')) : fileName;
    final fileKb = sizeKb ?? (bytes.length / 1024.0);

    String title = baseName;
    String? author;
    String? subject;
    String? keywords;
    String? creator;
    String? producer;
    String? copyright;
    String? comment;
    String creationDate = DateTime.now().subtract(const Duration(days: 1)).toIso8601String();
    String modDate = DateTime.now().toIso8601String();
    String? pdfVersion;
    int pageCount = 1;
    bool isEncrypted = false;

    String? description;
    String? software;

    if (isPdf && bytes.isNotEmpty) {
      try {
        final str = latin1.decode(bytes);

        // PDF Version
        final verMatch = RegExp(r'%PDF-(\d+\.\d+)').firstMatch(str);
        if (verMatch != null) {
          pdfVersion = 'PDF ${verMatch.group(1)}';
        }

        // Encryption Check
        if (str.contains('/Encrypt') || str.contains('/Filter/Standard')) {
          isEncrypted = true;
        }

        // Page Count Estimation
        final pageMatches = RegExp(r'/Type\s*/Page\b').allMatches(str).length;
        if (pageMatches > 0) {
          pageCount = pageMatches;
        } else {
          final countMatch = RegExp(r'/Count\s+(\d+)').firstMatch(str);
          if (countMatch != null) {
            pageCount = int.tryParse(countMatch.group(1)!) ?? 1;
          }
        }

        // Extract /Info Dictionary values (both literal `(...)` and hex `<... >`)
        String? extractKey(String key) {
          final literalMatch = RegExp('$key\\s*(\\([^\\)]*\\))').firstMatch(str);
          if (literalMatch != null && literalMatch.group(1) != null) {
            return _decodePdfString(literalMatch.group(1)!);
          }
          final hexMatch = RegExp('$key\\s*(<[0-9A-Fa-f\\s]+>)').firstMatch(str);
          if (hexMatch != null && hexMatch.group(1) != null) {
            return _decodePdfString(hexMatch.group(1)!);
          }
          return null;
        }

        final parsedTitle = extractKey('/Title');
        if (parsedTitle != null && parsedTitle.trim().isNotEmpty) title = parsedTitle.trim();

        final parsedAuthor = extractKey('/Author');
        if (parsedAuthor != null && parsedAuthor.trim().isNotEmpty) author = parsedAuthor.trim();

        final parsedSubject = extractKey('/Subject');
        if (parsedSubject != null && parsedSubject.trim().isNotEmpty) subject = parsedSubject.trim();

        final parsedKeywords = extractKey('/Keywords');
        if (parsedKeywords != null && parsedKeywords.trim().isNotEmpty) keywords = parsedKeywords.trim();

        final parsedCreator = extractKey('/Creator');
        if (parsedCreator != null && parsedCreator.trim().isNotEmpty) creator = parsedCreator.trim();

        final parsedProducer = extractKey('/Producer');
        if (parsedProducer != null && parsedProducer.trim().isNotEmpty) producer = parsedProducer.trim();

        final parsedCreation = extractKey('/CreationDate');
        if (parsedCreation != null && parsedCreation.trim().isNotEmpty) {
          creationDate = _formatPdfDate(parsedCreation.trim());
        }

        final parsedMod = extractKey('/ModDate');
        if (parsedMod != null && parsedMod.trim().isNotEmpty) {
          modDate = _formatPdfDate(parsedMod.trim());
        }

        // Parse Copyright and Comment (PlainScan-defined keys)
        final parsedCopyright = extractKey('/Copyright');
        if (parsedCopyright != null && parsedCopyright.trim().isNotEmpty) {
          copyright = parsedCopyright.trim();
        }

        final parsedComment = extractKey('/Comment');
        if (parsedComment != null && parsedComment.trim().isNotEmpty) {
          comment = parsedComment.trim();
        }

        // Fallback to XMP metadata if available
        if (author == null) {
          final xmpAuthor = RegExp(r'<dc:creator>.*?<rdf:li[^>]*>([^<]+)</rdf:li>', dotAll: true).firstMatch(str);
          if (xmpAuthor != null && xmpAuthor.group(1)!.trim().isNotEmpty) {
            author = xmpAuthor.group(1)!.trim();
          }
        }
        if (title == baseName) {
          final xmpTitle = RegExp(r'<dc:title>.*?<rdf:li[^>]*>([^<]+)</rdf:li>', dotAll: true).firstMatch(str);
          if (xmpTitle != null && xmpTitle.group(1)!.trim().isNotEmpty) {
            title = xmpTitle.group(1)!.trim();
          }
        }
        if (subject == null) {
          final xmpDesc = RegExp(r'<dc:description>.*?<rdf:li[^>]*>([^<]+)</rdf:li>', dotAll: true).firstMatch(str);
          if (xmpDesc != null && xmpDesc.group(1)!.trim().isNotEmpty) {
            subject = xmpDesc.group(1)!.trim();
          }
        }
        if (keywords == null) {
          final xmpKeywords = RegExp(r'<pdf:Keywords>([^<]+)</pdf:Keywords>').firstMatch(str);
          if (xmpKeywords != null && xmpKeywords.group(1)!.trim().isNotEmpty) {
            keywords = xmpKeywords.group(1)!.trim();
          }
        }
      } catch (_) {}
    } else if (!isPdf && bytes.isNotEmpty) {
      try {
        final ext = fileName.toLowerCase().contains('.')
            ? fileName.substring(fileName.lastIndexOf('.') + 1)
            : '';
        final imgMeta = (ext == 'png')
            ? _extractPngMetadata(bytes)
            : _extractJpegMetadata(bytes);

        if (imgMeta.containsKey('title') && imgMeta['title']!.isNotEmpty) {
          title = imgMeta['title']!;
        }
        if (imgMeta.containsKey('author') && imgMeta['author']!.isNotEmpty) {
          author = imgMeta['author'];
        }
        if (imgMeta.containsKey('description') && imgMeta['description']!.isNotEmpty) {
          description = imgMeta['description'];
        }
        if (imgMeta.containsKey('copyright') && imgMeta['copyright']!.isNotEmpty) {
          copyright = imgMeta['copyright'];
        }
        if (imgMeta.containsKey('software') && imgMeta['software']!.isNotEmpty) {
          software = imgMeta['software'];
        }
        if (imgMeta.containsKey('comment') && imgMeta['comment']!.isNotEmpty) {
          comment = imgMeta['comment'];
        }
      } catch (_) {}
    }

    if (description != null && description.isNotEmpty) {
      subject = description;
    }

    author ??= 'PlainScan User';
    subject ??= isPdf ? 'PDF Document' : 'Digital Media';
    keywords ??= 'plainscan, document, clean';
    creator ??= software ?? (isPdf ? 'PlainScan Document Suite' : 'PlainScan Camera Subsystem');
    producer ??= isPdf ? 'PlainScan PDF Engine v1.0' : 'PlainScan Image Processing Subsystem';

    return {
      'file_name': fileName,
      'file_size_kb': double.parse(fileKb.toStringAsFixed(2)),
      'format': isPdf ? 'PDF Document' : 'Image',
      'created_at': DateTime.now().toIso8601String(),
      if (isPdf) ...{
        'pdf_version': pdfVersion ?? 'PDF 1.4',
        'page_count': pageCount,
        'is_encrypted': isEncrypted,
      },
      'metadata': {
        'Title': title,
        'Author': author,
        'Subject': subject,
        'Description': description ?? subject,
        'Copyright': copyright ?? '',
        'Keywords': keywords,
        'Comment': comment ?? '',
        'Creator': creator,
        'Producer': producer,
        'CreationDate': creationDate,
        'ModDate': modDate,
        if (!isPdf) ...{
          'ColorSpace': 'sRGB',
          'ResolutionUnit': 'inches',
          'XResolution': 300,
          'YResolution': 300,
          'ExifVersion': '0232',
          'Software': software ?? creator,
        },
      },
    };
  }

  static Map<String, String> _extractJpegMetadata(Uint8List bytes) {
    final result = <String, String>{};
    if (bytes.length < 4 || bytes[0] != 0xFF || bytes[1] != 0xD8) return result;

    int offset = 2;
    while (offset + 4 <= bytes.length) {
      if (bytes[offset] != 0xFF) break;
      final marker = bytes[offset + 1];
      if (marker == 0xDA || marker == 0xD9) break; // SOS or EOI -> stop

      final len = (bytes[offset + 2] << 8) | bytes[offset + 3];
      if (len < 2 || offset + 2 + len > bytes.length) break;

      final segmentData = bytes.sublist(offset + 4, offset + 2 + len);

      // JPEG COM (0xFF, 0xFE) segment
      if (marker == 0xFE) {
        try {
          final comStr = latin1.decode(segmentData).trim();
          if (comStr.isNotEmpty) {
            result['comment'] = comStr;
          }
        } catch (_) {}
      }

      // JPEG APP1 (0xFF, 0xE1) segment (EXIF)
      if (marker == 0xE1 && segmentData.length >= 14) {
        final header = latin1.decode(segmentData.sublist(0, 6));
        if (header == 'Exif\x00\x00') {
          final tiffBytes = segmentData.sublist(6);
          _parseTiffIfd0(tiffBytes, result);
        }
      }

      offset += 2 + len;
    }
    return result;
  }

  static void _parseTiffIfd0(Uint8List bytes, Map<String, String> result) {
    if (bytes.length < 8) return;
    final isLE = bytes[0] == 0x49 && bytes[1] == 0x49; // "II"
    final isBE = bytes[0] == 0x4D && bytes[1] == 0x4D; // "MM"
    if (!isLE && !isBE) return;

    int read16(int o) {
      if (o + 2 > bytes.length) return 0;
      return isLE ? (bytes[o] | (bytes[o + 1] << 8)) : ((bytes[o] << 8) | bytes[o + 1]);
    }

    int read32(int o) {
      if (o + 4 > bytes.length) return 0;
      return isLE
          ? (bytes[o] | (bytes[o + 1] << 8) | (bytes[o + 2] << 16) | (bytes[o + 3] << 24))
          : ((bytes[o] << 24) | (bytes[o + 1] << 16) | (bytes[o + 2] << 8) | bytes[o + 3]);
    }

    final magic = read16(2);
    if (magic != 0x002A) return;

    final ifd0Offset = read32(4);
    if (ifd0Offset < 8 || ifd0Offset + 2 > bytes.length) return;

    final entryCount = read16(ifd0Offset);
    int entryOffset = ifd0Offset + 2;

    for (int i = 0; i < entryCount; i++) {
      if (entryOffset + 12 > bytes.length) break;
      final tag = read16(entryOffset);
      final type = read16(entryOffset + 2);
      final count = read32(entryOffset + 4);

      if (type == 2) {
        String val = '';
        if (count <= 4) {
          final strBytes = bytes.sublist(entryOffset + 8, entryOffset + 8 + count);
          val = latin1.decode(strBytes);
        } else {
          final valOffset = read32(entryOffset + 8);
          if (valOffset > 0 && valOffset + count <= bytes.length) {
            final strBytes = bytes.sublist(valOffset, valOffset + count);
            val = latin1.decode(strBytes);
          }
        }
        val = val.replaceAll('\x00', '').trim();

        if (val.isNotEmpty) {
          switch (tag) {
            case 0x010E: // ImageDescription
              result['title'] = val;
              result['description'] = val;
              break;
            case 0x013B: // Artist
              result['author'] = val;
              break;
            case 0x8298: // Copyright
              result['copyright'] = val;
              break;
            case 0x0131: // Software
              result['software'] = val;
              break;
            case 0x9286: // UserComment
              result['comment'] = val;
              break;
          }
        }
      }
      entryOffset += 12;
    }
  }

  static Map<String, String> _extractPngMetadata(Uint8List bytes) {
    final result = <String, String>{};
    const pngSig = [137, 80, 78, 71, 13, 10, 26, 10];
    if (bytes.length < 8) return result;
    for (int i = 0; i < 8; i++) {
      if (bytes[i] != pngSig[i]) return result;
    }

    int offset = 8;
    while (offset + 12 <= bytes.length) {
      final len = (bytes[offset] << 24) |
          (bytes[offset + 1] << 16) |
          (bytes[offset + 2] << 8) |
          bytes[offset + 3];
      final type = latin1.decode(bytes.sublist(offset + 4, offset + 8));

      if (offset + 12 + len > bytes.length) break;
      final chunkData = bytes.sublist(offset + 8, offset + 8 + len);

      if (type == 'tEXt') {
        final nullIdx = chunkData.indexOf(0x00);
        if (nullIdx > 0 && nullIdx < chunkData.length - 1) {
          final key = latin1.decode(chunkData.sublist(0, nullIdx)).trim();
          final val = latin1.decode(chunkData.sublist(nullIdx + 1)).trim();
          if (val.isNotEmpty) {
            switch (key.toLowerCase()) {
              case 'title':
                result['title'] = val;
                break;
              case 'author':
              case 'artist':
                result['author'] = val;
                break;
              case 'description':
              case 'subject':
                result['description'] = val;
                break;
              case 'copyright':
                result['copyright'] = val;
                break;
              case 'software':
                result['software'] = val;
                break;
              case 'comment':
                result['comment'] = val;
                break;
            }
          }
        }
      }

      if (type == 'IEND') break;
      offset += 12 + len;
    }
    return result;
  }

  /// Formats extracted metadata map into clean, readable plain text (TXT format)
  static String formatMetadataAsText(Map<String, dynamic> map) {
    final buffer = StringBuffer();
    buffer.writeln('DOCUMENT METADATA REPORT');
    buffer.writeln('========================');
    buffer.writeln('File Name: ${map['file_name'] ?? 'Unknown'}');
    buffer.writeln('File Size: ${map['file_size_kb']} KB');
    buffer.writeln('Format: ${map['format'] ?? 'Unknown'}');
    if (map.containsKey('pdf_version')) {
      buffer.writeln('PDF Version: ${map['pdf_version']}');
    }
    if (map.containsKey('page_count')) {
      buffer.writeln('Page Count: ${map['page_count']}');
    }
    if (map.containsKey('is_encrypted')) {
      buffer.writeln('Encrypted: ${map['is_encrypted'] == true ? 'Yes' : 'No'}');
    }
    if (map.containsKey('created_at')) {
      buffer.writeln('Extracted At: ${map['created_at']}');
    }
    buffer.writeln();
    buffer.writeln('METADATA ATTRIBUTES:');
    buffer.writeln('--------------------');
    final meta = map['metadata'] as Map<String, dynamic>? ?? {};
    for (final entry in meta.entries) {
      buffer.writeln('${entry.key}: ${entry.value}');
    }
    return buffer.toString();
  }

  static String _decodePdfString(String raw) {
    var s = raw.trim();
    if (s.startsWith('(') && s.endsWith(')')) {
      s = s.substring(1, s.length - 1);
      s = s.replaceAll(r'\(', '(').replaceAll(r'\)', ')').replaceAll(r'\\', r'\');
      if (s.length >= 2 && s.codeUnitAt(0) == 0xFE && s.codeUnitAt(1) == 0xFF) {
        final buffer = StringBuffer();
        for (int i = 2; i + 1 < s.length; i += 2) {
          final code = (s.codeUnitAt(i) << 8) | s.codeUnitAt(i + 1);
          buffer.writeCharCode(code);
        }
        return buffer.toString();
      }
      return s;
    } else if (s.startsWith('<') && s.endsWith('>')) {
      final hex = s.substring(1, s.length - 1).replaceAll(RegExp(r'\s+'), '');
      if (hex.length >= 4 && hex.toUpperCase().startsWith('FEFF')) {
        final buffer = StringBuffer();
        for (int i = 4; i + 3 < hex.length; i += 4) {
          final code = int.tryParse(hex.substring(i, i + 4), radix: 16);
          if (code != null) buffer.writeCharCode(code);
        }
        return buffer.toString();
      } else {
        final bytes = <int>[];
        for (int i = 0; i + 1 < hex.length; i += 2) {
          final b = int.tryParse(hex.substring(i, i + 2), radix: 16);
          if (b != null) bytes.add(b);
        }
        return latin1.decode(bytes);
      }
    }
    return s;
  }

  static String _formatPdfDate(String rawDate) {
    var d = rawDate;
    if (d.startsWith('D:')) d = d.substring(2);
    if (d.length >= 8) {
      final year = d.substring(0, 4);
      final month = d.substring(4, 6);
      final day = d.substring(6, 8);
      var hour = '00';
      var min = '00';
      var sec = '00';
      if (d.length >= 10) hour = d.substring(8, 10);
      if (d.length >= 12) min = d.substring(10, 12);
      if (d.length >= 14) sec = d.substring(12, 14);
      return '$year-$month-$day $hour:$min:$sec';
    }
    return rawDate;
  }

  /// Parses standard CSV string with custom delimiter, handling quotes and multiline cells.
  static List<List<String>> parseCsv(String input, {String delimiter = ','}) {
    final List<List<String>> rows = [];
    final StringBuffer currentCell = StringBuffer();
    List<String> currentRow = [];
    bool inQuotes = false;

    final text = input.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final int length = text.length;
    final int delimCode = delimiter.isNotEmpty ? delimiter.codeUnitAt(0) : 44;

    for (int i = 0; i < length; i++) {
      final int char = text.codeUnitAt(i);

      if (char == 34) { // quote '"'
        if (inQuotes && i + 1 < length && text.codeUnitAt(i + 1) == 34) {
          currentCell.write('"');
          i++; // skip next quote
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == delimCode && !inQuotes) {
        currentRow.add(currentCell.toString());
        currentCell.clear();
      } else if (char == 10 && !inQuotes) { // newline '\n'
        currentRow.add(currentCell.toString());
        currentCell.clear();
        if (currentRow.isNotEmpty && (currentRow.length > 1 || currentRow[0].isNotEmpty || i < length - 1)) {
          rows.add(currentRow);
        }
        currentRow = [];
      } else {
        currentCell.writeCharCode(char);
      }
    }

    if (currentCell.isNotEmpty || currentRow.isNotEmpty) {
      currentRow.add(currentCell.toString());
      rows.add(currentRow);
    }

    return rows;
  }

  /// Converts CSV file/bytes into XLSX (Excel) workbook bytes
  static Uint8List convertCsvToExcel(Uint8List csvBytes, {String delimiter = ','}) {
    if (csvBytes.isEmpty) {
      final excel = xl.Excel.createExcel();
      final defaultSheet = excel.getDefaultSheet() ?? 'Sheet1';
      final sheet = excel[defaultSheet];
      sheet.appendRow([xl.TextCellValue('')]);
      final saved = excel.save();
      return saved != null ? Uint8List.fromList(saved) : Uint8List(0);
    }

    String csvString;
    try {
      csvString = utf8.decode(csvBytes);
    } catch (_) {
      csvString = latin1.decode(csvBytes);
    }

    // Auto-detect delimiter if default comma is selected but file clearly uses another
    var effectiveDelimiter = delimiter;
    if (effectiveDelimiter == ',' || effectiveDelimiter.isEmpty) {
      final lines = csvString.split('\n');
      if (lines.isNotEmpty) {
        final firstLine = lines.first;
        if (!firstLine.contains(',') && firstLine.contains(';')) {
          effectiveDelimiter = ';';
        } else if (!firstLine.contains(',') && firstLine.contains('\t')) {
          effectiveDelimiter = '\t';
        } else if (!firstLine.contains(',') && firstLine.contains('|')) {
          effectiveDelimiter = '|';
        }
      }
    }

    final rows = parseCsv(csvString, delimiter: effectiveDelimiter);
    final excel = xl.Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet() ?? 'Sheet1';
    final sheet = excel[defaultSheet];

    for (final row in rows) {
      final List<xl.CellValue?> excelRow = [];
      for (final cell in row) {
        final trimmed = cell.trim();
        // Check for integer
        final intVal = int.tryParse(trimmed);
        if (intVal != null && (trimmed.length == 1 || !trimmed.startsWith('0') || trimmed == '0')) {
          excelRow.add(xl.IntCellValue(intVal));
          continue;
        }
        // Check for double
        final doubleVal = double.tryParse(trimmed);
        if (doubleVal != null && (!trimmed.startsWith('0') || trimmed.startsWith('0.'))) {
          excelRow.add(xl.DoubleCellValue(doubleVal));
          continue;
        }
        // Check for bool
        if (trimmed.toLowerCase() == 'true') {
          excelRow.add(xl.BoolCellValue(true));
          continue;
        } else if (trimmed.toLowerCase() == 'false') {
          excelRow.add(xl.BoolCellValue(false));
          continue;
        }

        excelRow.add(xl.TextCellValue(cell));
      }
      sheet.appendRow(excelRow);
    }

    final saved = excel.save();
    if (saved != null) {
      return Uint8List.fromList(saved);
    }
    return Uint8List(0);
  }

  /// Converts XLSX (Excel) workbook bytes into CSV string
  static String convertExcelToCsv(Uint8List excelBytes, {int sheetIndex = 0, String delimiter = ','}) {
    if (excelBytes.isEmpty) return '';
    try {
      final excel = xl.Excel.decodeBytes(excelBytes);
      if (excel.tables.isEmpty) return '';
      final sheetNames = excel.tables.keys.toList();
      final targetSheetName = (sheetIndex >= 0 && sheetIndex < sheetNames.length)
          ? sheetNames[sheetIndex]
          : sheetNames.first;
      final sheet = excel.tables[targetSheetName];
      if (sheet == null) return '';

      final buffer = StringBuffer();
      for (final row in sheet.rows) {
        final rowStrings = row.map((cell) {
          if (cell == null || cell.value == null) return '';
          final val = cell.value.toString();
          if (val.contains(delimiter) || val.contains('"') || val.contains('\n')) {
            return '"${val.replaceAll('"', '""')}"';
          }
          return val;
        }).toList();
        buffer.writeln(rowStrings.join(delimiter));
      }
      return buffer.toString();
    } catch (_) {
      return '';
    }
  }

  static const List<int> _pdfPadding = [
    0x28, 0xBF, 0x4E, 0x5E, 0x4E, 0x75, 0x8A, 0x41,
    0x64, 0x00, 0x4E, 0x56, 0xFF, 0xFA, 0x01, 0x08,
    0x2E, 0x2E, 0x00, 0xB6, 0xD0, 0x68, 0x3E, 0x80,
    0x2F, 0x0C, 0xA9, 0xFE, 0x64, 0x53, 0x69, 0x7A
  ];

  static List<int> _padPassword(String pwd) {
    final pwdBytes = latin1.encode(pwd);
    final result = <int>[];
    if (pwdBytes.length >= 32) {
      result.addAll(pwdBytes.sublist(0, 32));
    } else {
      result.addAll(pwdBytes);
      result.addAll(_pdfPadding.sublist(0, 32 - pwdBytes.length));
    }
    return result;
  }

  /// Locks / password-protects and encrypts a PDF document
  static Uint8List lockPdf(
    Uint8List bytes, {
    required String userPassword,
    String? ownerPassword,
    bool allowPrinting = true,
    bool allowCopying = true,
    String encryption = 'aes-128',
  }) {
    if (bytes.length < 5) return bytes;
    final str = latin1.decode(bytes);
    if (!str.startsWith('%PDF-')) return bytes;

    final effectiveOwnerPwd = (ownerPassword != null && ownerPassword.trim().isNotEmpty)
        ? ownerPassword.trim()
        : userPassword;

    // Calculate Permissions P (signed 32-bit integer)
    int p = -64;
    if (allowPrinting) p |= 4 | 2048;
    if (allowCopying) p |= 16 | 512;

    // Compute or extract File ID from original trailer if present
    final idMatch = RegExp(r'/ID\s*\[\s*<([0-9a-fA-F]+)>').firstMatch(str);
    final existingId = idMatch != null ? _parsePdfHex(idMatch.group(1)!) : null;
    final fileIdBytes = existingId ??
        crypto.md5.convert(bytes.sublist(0, bytes.length.clamp(0, 1024))).bytes;
    final fileIdHex = fileIdBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

    // 1. Owner Key (O) - Standard ISO 32000-1 Algorithm 3.3
    final paddedOwner = _padPassword(effectiveOwnerPwd);
    var ownerMd5 = crypto.md5.convert(paddedOwner).bytes;
    for (int i = 0; i < 50; i++) {
      ownerMd5 = crypto.md5.convert(ownerMd5).bytes;
    }
    final ownerKey = ownerMd5.sublist(0, 16);
    final paddedUser = _padPassword(userPassword);
    var oBytes = _rc4(ownerKey, paddedUser);
    for (int i = 1; i < 20; i++) {
      final iterKey = ownerKey.map((b) => b ^ i).toList();
      oBytes = _rc4(iterKey, oBytes);
    }
    final oHex = oBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

    // 2. Encryption Key - Standard ISO 32000-1 Algorithm 3.2
    final encKey = _computeStandardEncryptionKey(
      userPassword: userPassword,
      o: oBytes,
      p: p,
      fileId: fileIdBytes,
      revision: 3,
    );

    // 3. User Key (U) - Standard ISO 32000-1 Algorithm 3.5
    final uInput = <int>[];
    uInput.addAll(_pdfPadding);
    uInput.addAll(fileIdBytes);
    var uDigest = crypto.md5.convert(uInput).bytes;
    uDigest = _rc4(encKey, uDigest);
    for (int i = 1; i < 20; i++) {
      final iterKey = encKey.map((b) => b ^ i).toList();
      uDigest = _rc4(iterKey, uDigest);
    }
    final uBytes = List<int>.filled(32, 0);
    for (int i = 0; i < 16; i++) {
      uBytes[i] = uDigest[i];
    }
    final uHex = uBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

    // 4. Encrypt all content streams using ISO 32000-1 Algorithm 3.1
    final encryptedBody = _processAllPdfStreams(bytes, encKey, encrypt: true);

    // Find next available object index
    final maxObjMatches = RegExp(r'(\d+)\s+0\s+obj').allMatches(str);
    int nextObj = 50;
    for (final m in maxObjMatches) {
      final id = int.tryParse(m.group(1)!) ?? 0;
      if (id >= nextObj) nextObj = id + 1;
    }

    final encryptDictSb = StringBuffer();
    encryptDictSb.writeln('<<');
    encryptDictSb.writeln('  /Filter /Standard');
    encryptDictSb.writeln('  /V 2');
    encryptDictSb.writeln('  /R 3');
    encryptDictSb.writeln('  /Length 128');
    encryptDictSb.writeln('  /P $p');
    encryptDictSb.writeln('  /O <$oHex>');
    encryptDictSb.writeln('  /U <$uHex>');
    encryptDictSb.write('>>');

    final newEncryptObj = '\n$nextObj 0 obj\n$encryptDictSb\nendobj\n';

    // Find trailer Root & Info references
    final rootMatch = RegExp(r'/Root\s+(\d+\s+\d+\s+R)').firstMatch(str);
    final rootRef = rootMatch?.group(1) ?? '1 0 R';
    final infoMatch = RegExp(r'/Info\s+(\d+\s+\d+\s+R)').firstMatch(str);
    final infoRef = infoMatch?.group(1);

    final buffer = BytesBuilder();
    buffer.add(encryptedBody);

    final encryptObjOffset = buffer.length;
    buffer.add(latin1.encode(newEncryptObj));

    final trailerXrefOffset = buffer.length;
    final xrefSb = StringBuffer();
    xrefSb.writeln('xref');
    xrefSb.writeln('$nextObj 1');
    xrefSb.writeln('${encryptObjOffset.toString().padLeft(10, '0')} 00000 n ');
    xrefSb.writeln('trailer');
    xrefSb.write('<< /Root $rootRef');
    if (infoRef != null) {
      xrefSb.write(' /Info $infoRef');
    }
    xrefSb.write(' /Encrypt $nextObj 0 R');
    xrefSb.write(' /ID [<$fileIdHex> <$fileIdHex>]');
    xrefSb.writeln(' >>');
    xrefSb.writeln('startxref');
    xrefSb.writeln('$trailerXrefOffset');
    xrefSb.write('%%EOF');

    buffer.add(latin1.encode(xrefSb.toString()));
    return buffer.toBytes();
  }

  /// Parses a hex string from a PDF dictionary value (e.g. "&lt;aabbcc&gt;").
  static List<int>? _parsePdfHex(String hexStr) {
    final cleaned = hexStr.replaceAll(RegExp(r'[^0-9a-fA-F]'), '');
    if (cleaned.isEmpty || cleaned.length % 2 != 0) return null;
    final result = <int>[];
    for (int i = 0; i < cleaned.length; i += 2) {
      result.add(int.parse(cleaned.substring(i, i + 2), radix: 16));
    }
    return result;
  }

  static List<int> _rc4(List<int> key, List<int> data) {
    final s = List<int>.generate(256, (i) => i);
    int j = 0;
    for (int i = 0; i < 256; i++) {
      j = (j + s[i] + key[i % key.length]) & 0xFF;
      final temp = s[i];
      s[i] = s[j];
      s[j] = temp;
    }
    int i = 0;
    j = 0;
    final result = Uint8List(data.length);
    for (int k = 0; k < data.length; k++) {
      i = (i + 1) & 0xFF;
      j = (j + s[i]) & 0xFF;
      final temp = s[i];
      s[i] = s[j];
      s[j] = temp;
      final t = (s[i] + s[j]) & 0xFF;
      result[k] = data[k] ^ s[t];
    }
    return result;
  }

  static bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Verifies a PDF user password using PlainScan's local mock algorithm.
  static bool _verifyPdfMockUserPassword({
    required String password,
    required List<int> storedU,
    required List<int> storedO,
    required int p,
    required List<int> fileId,
  }) {
    final paddedUser = _padPassword(password);
    final keyInput = <int>[];
    keyInput.addAll(paddedUser);
    keyInput.addAll(storedO);
    keyInput.add(p & 0xFF);
    keyInput.add((p >> 8) & 0xFF);
    keyInput.add((p >> 16) & 0xFF);
    keyInput.add((p >> 24) & 0xFF);
    keyInput.addAll(fileId);

    final encKeyDigest = crypto.md5.convert(keyInput).bytes;
    final uDigest = crypto.md5.convert(encKeyDigest).bytes;
    final uBytes = <int>[];
    for (int i = 0; i < 32; i++) {
      uBytes.add(_pdfPadding[i] ^ uDigest[i % uDigest.length]);
    }

    final compareLen = storedU.length >= 16 ? 16 : storedU.length;
    for (int i = 0; i < compareLen; i++) {
      if (uBytes[i] != storedU[i]) return false;
    }
    return true;
  }

  /// Computes standard PDF encryption key (ISO 32000-1 Algorithm 3.2).
  static List<int> _computeStandardEncryptionKey({
    required String userPassword,
    required List<int> o,
    required int p,
    required List<int> fileId,
    int revision = 3,
    int keyLength = 16,
  }) {
    final paddedUser = _padPassword(userPassword);
    final keyInput = <int>[];
    keyInput.addAll(paddedUser);
    keyInput.addAll(o);
    keyInput.add(p & 0xFF);
    keyInput.add((p >> 8) & 0xFF);
    keyInput.add((p >> 16) & 0xFF);
    keyInput.add((p >> 24) & 0xFF);
    keyInput.addAll(fileId);

    var md5Digest = crypto.md5.convert(keyInput).bytes;
    if (revision >= 3) {
      for (int round = 0; round < 50; round++) {
        md5Digest = crypto.md5.convert(md5Digest.sublist(0, keyLength)).bytes;
      }
    }
    return md5Digest.sublist(0, keyLength);
  }

  /// Encrypts or decrypts all content streams in [pdfBytes] with per-object RC4 keys (ISO 32000-1 Algorithm 3.1).
  static Uint8List _processAllPdfStreams(
    Uint8List pdfBytes,
    List<int> encKey, {
    required bool encrypt,
  }) {
    final res = Uint8List.fromList(pdfBytes);
    final str = latin1.decode(pdfBytes);

    final streamRegex = RegExp(r'\bstream(?:\r\n|\n|\r)');
    final endStreamRegex = RegExp(r'(?:\r\n|\n|\r)endstream\b');
    final objRegex = RegExp(r'(\d+)\s+(\d+)\s+obj\b');

    final streamMatches = streamRegex.allMatches(str);
    for (final sm in streamMatches) {
      final streamStart = sm.end;
      final endMatches = endStreamRegex.allMatches(str, streamStart);
      if (endMatches.isEmpty) continue;
      final streamEnd = endMatches.first.start;

      // Find the object definition immediately preceding this stream
      final prefix = str.substring(0, sm.start);
      final objMatches = objRegex.allMatches(prefix);
      if (objMatches.isEmpty) continue;

      final lastObj = objMatches.last;
      final objNum = int.tryParse(lastObj.group(1) ?? '') ?? 0;
      final genNum = int.tryParse(lastObj.group(2) ?? '') ?? 0;

      // Object key derivation (Algorithm 3.1)
      final keyData = <int>[];
      keyData.addAll(encKey);
      keyData.add(objNum & 0xFF);
      keyData.add((objNum >> 8) & 0xFF);
      keyData.add((objNum >> 16) & 0xFF);
      keyData.add(genNum & 0xFF);
      keyData.add((genNum >> 8) & 0xFF);

      final objKey = crypto.md5.convert(keyData).bytes.sublist(0, 16);
      final streamSlice = res.sublist(streamStart, streamEnd);
      final processedStream = _rc4(objKey, streamSlice);

      for (int i = 0; i < processedStream.length; i++) {
        res[streamStart + i] = processedStream[i];
      }
    }

    return res;
  }

  /// Verifies standard PDF user password (ISO 32000-1 Algorithm 3.2 / 3.4 / 3.5).
  static bool _verifyStandardPdfUserPassword({
    required String password,
    required List<int> storedU,
    required List<int> storedO,
    required int p,
    required List<int> fileId,
    int revision = 3,
    int keyLength = 16,
  }) {
    try {
      final encKey = _computeStandardEncryptionKey(
        userPassword: password,
        o: storedO,
        p: p,
        fileId: fileId,
        revision: revision,
        keyLength: keyLength,
      );

      if (revision == 2) {
        final r2U = _rc4(encKey, _pdfPadding);
        final compareLen = storedU.length >= 16 ? 16 : storedU.length;
        return _listEquals(r2U.sublist(0, compareLen), storedU.sublist(0, compareLen));
      } else {
        final hashInput = <int>[];
        hashInput.addAll(_pdfPadding);
        hashInput.addAll(fileId);
        var uDigest3 = crypto.md5.convert(hashInput).bytes;
        for (int i = 0; i <= 19; i++) {
          final iterKey = encKey.map((b) => b ^ i).toList();
          uDigest3 = _rc4(iterKey, uDigest3);
        }
        final compareLen = storedU.length >= 16 ? 16 : storedU.length;
        return _listEquals(uDigest3.sublist(0, compareLen), storedU.sublist(0, compareLen));
      }
    } catch (_) {
      return false;
    }
  }

  /// Verifies modern AES-256 PDF user password (Revision 5 / Revision 6).
  static bool _verifyAes256PdfUserPassword({
    required String password,
    required List<int> storedU,
  }) {
    if (storedU.length < 40) return false;
    try {
      final validationSalt = storedU.sublist(32, 40);
      final utf8Sha = crypto.sha256.convert(utf8.encode(password) + validationSalt).bytes;
      if (_listEquals(utf8Sha.sublist(0, 32), storedU.sublist(0, 32))) return true;

      final latinSha = crypto.sha256.convert(latin1.encode(password) + validationSalt).bytes;
      if (_listEquals(latinSha.sublist(0, 32), storedU.sublist(0, 32))) return true;
    } catch (_) {}
    return false;
  }

  /// Verifies a PDF user password against stored security dictionary entries.
  /// Checks mock Plainscan format, standard PDF (R=2, R=3), and AES-256.
  static bool _verifyPdfUserPassword({
    required String password,
    required List<int> storedU,
    required List<int> storedO,
    required int p,
    required List<int> fileId,
    int revision = 3,
  }) {
    if (_verifyPdfMockUserPassword(
      password: password,
      storedU: storedU,
      storedO: storedO,
      p: p,
      fileId: fileId,
    )) {
      return true;
    }
    if (_verifyStandardPdfUserPassword(
      password: password,
      storedU: storedU,
      storedO: storedO,
      p: p,
      fileId: fileId,
      revision: revision,
    )) {
      return true;
    }
    if (_verifyAes256PdfUserPassword(
      password: password,
      storedU: storedU,
    )) {
      return true;
    }
    return false;
  }

  /// Checks if a PDF was created locally by [lockPdf] and can be safely unlocked
  /// on-device without requiring full server-side stream decryption.
  static bool isLocallyUnlockable(Uint8List bytes, {required String password}) {
    if (bytes.length < 5) return false;
    final str = latin1.decode(bytes);
    if (!str.startsWith('%PDF-') || !str.contains('/Encrypt')) return false;

    final encRefMatch = RegExp(r'/Encrypt\s+(\d+)\s+\d+\s+R').firstMatch(str);
    if (encRefMatch == null) return false;

    final encObjNum = encRefMatch.group(1)!;
    final encObjBodyMatch =
        RegExp('$encObjNum\\s+0\\s+obj(.*?)endobj', dotAll: true).firstMatch(str);
    if (encObjBodyMatch == null) return false;

    final encBody = encObjBodyMatch.group(1)!;
    final oMatch = RegExp(r'/O\s*<([0-9a-fA-F]+)>').firstMatch(encBody);
    final uMatch = RegExp(r'/U\s*<([0-9a-fA-F]+)>').firstMatch(encBody);
    final pMatch = RegExp(r'/P\s*(-?\d+)').firstMatch(encBody);
    final idMatch = RegExp(r'/ID\s*\[\s*<([0-9a-fA-F]+)>').firstMatch(str);

    final storedO = oMatch != null ? _parsePdfHex(oMatch.group(1)!) : null;
    final storedU = uMatch != null ? _parsePdfHex(uMatch.group(1)!) : null;
    final pValue = pMatch != null ? int.tryParse(pMatch.group(1)!) : null;
    final fileId = idMatch != null ? _parsePdfHex(idMatch.group(1)!) : null;

    if (storedO != null && storedU != null && pValue != null && fileId != null) {
      return _verifyPdfMockUserPassword(
            password: password,
            storedU: storedU,
            storedO: storedO,
            p: pValue,
            fileId: fileId,
          ) ||
          _verifyStandardPdfUserPassword(
            password: password,
            storedU: storedU,
            storedO: storedO,
            p: pValue,
            fileId: fileId,
          );
    }
    return false;
  }

  /// Unlocks / removes password protection and encryption from a PDF.
  /// Verifies the [password] before removing encryption — throws an
  /// [Exception] if the password is incorrect or missing.
  static Uint8List unlockPdf(Uint8List bytes, {String? password}) {
    if (bytes.length < 5) return bytes;
    final str = latin1.decode(bytes);
    if (!str.startsWith('%PDF-')) return bytes;

    // Check if the PDF actually has an /Encrypt entry
    if (!str.contains('/Encrypt')) {
      // Not encrypted; nothing to unlock
      return bytes;
    }

    if (password == null || password.trim().isEmpty) {
      throw Exception(
          'Please enter the password to decrypt and unlock this PDF document.');
    }

    // --- Password Verification ---
    final encRefMatch =
        RegExp(r'/Encrypt\s+(\d+)\s+\d+\s+R').firstMatch(str);

    if (encRefMatch != null) {
      final encObjNum = encRefMatch.group(1)!;
      final encObjBodyMatch =
          RegExp('$encObjNum\\s+0\\s+obj(.*?)endobj', dotAll: true)
              .firstMatch(str);

      if (encObjBodyMatch != null) {
        final encBody = encObjBodyMatch.group(1)!;
        final oMatch =
            RegExp(r'/O\s*<([0-9a-fA-F]+)>').firstMatch(encBody);
        final uMatch =
            RegExp(r'/U\s*<([0-9a-fA-F]+)>').firstMatch(encBody);
        final pMatch = RegExp(r'/P\s*(-?\d+)').firstMatch(encBody);
        final rMatch = RegExp(r'/R\s*(\d+)').firstMatch(encBody);
        final idMatch =
            RegExp(r'/ID\s*\[\s*<([0-9a-fA-F]+)>').firstMatch(str);

        final storedO = oMatch != null ? _parsePdfHex(oMatch.group(1)!) : null;
        final storedU = uMatch != null ? _parsePdfHex(uMatch.group(1)!) : null;
        final pValue =
            pMatch != null ? int.tryParse(pMatch.group(1)!) : null;
        final fileId =
            idMatch != null ? _parsePdfHex(idMatch.group(1)!) : null;
        final revision =
            rMatch != null ? (int.tryParse(rMatch.group(1)!) ?? 3) : 3;

        if (storedO != null &&
            storedU != null &&
            pValue != null &&
            fileId != null) {
          final pwd = password;
          if (!_verifyPdfUserPassword(
            password: pwd,
            storedU: storedU,
            storedO: storedO,
            p: pValue,
            fileId: fileId,
            revision: revision,
          )) {
            throw Exception(
                'Incorrect password. Please enter the correct password to unlock this PDF.');
          }

          // If standard or mock encryption key can be derived, decrypt all streams back to plaintext
          final encKey = _computeStandardEncryptionKey(
            userPassword: pwd,
            o: storedO,
            p: pValue,
            fileId: fileId,
            revision: revision,
          );
          bytes = _processAllPdfStreams(bytes, encKey, encrypt: false);
        }
      }
    }

    // Erase the /Encrypt reference
    final output = Uint8List.fromList(bytes);
    final encryptRefRegex =
        RegExp(r'/Encrypt\s+(\d+\s+\d+\s+R|<<[^>]*>>)');
    for (final match in encryptRefRegex.allMatches(str)) {
      for (int i = match.start; i < match.end; i++) {
        output[i] = 0x20;
      }
    }
    return output;
  }
}
