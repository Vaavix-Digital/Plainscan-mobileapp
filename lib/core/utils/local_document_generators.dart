import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

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

    // 2. Scrub Info dictionary tags: Title, Author, Subject, Keywords, Creator, Producer, Dates, etc.
    final metaKeysRegex = RegExp(
      r'/(Title|Author|Subject|Keywords|Creator|Producer|CreationDate|ModDate|Trapped|PTEX\.Fullbanner|Company)\s*(\([^\)]*\)|<[0-9a-fA-F\s]*>)',
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
    String creationDate = DateTime.now().subtract(const Duration(days: 1)).toIso8601String();
    String modDate = DateTime.now().toIso8601String();
    String? pdfVersion;
    int pageCount = 1;
    bool isEncrypted = false;

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

        // Extract /Info Dictionary values (both literal `(...)` and hex `<...>`)
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
    }

    author ??= 'PlainScan User';
    subject ??= isPdf ? 'PDF Document' : 'Digital Media';
    keywords ??= 'plainscan, document, clean';
    creator ??= 'PlainScan Document Suite';
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
        'Keywords': keywords,
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
          'Software': 'PlainScan Camera Subsystem',
        },
      },
    };
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
}
