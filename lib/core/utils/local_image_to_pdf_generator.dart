import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

class LocalImageToPdfGenerator {
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

  static Future<File> convertImagesToPdf({
    required List<File> imageFiles,
    required String outputFilePath,
    String pageSize = 'A4',
  }) async {
    final double pageWidth = pageSize.toUpperCase() == 'LETTER' ? 612.0 : 595.28;
    final double pageHeight = pageSize.toUpperCase() == 'LETTER' ? 792.0 : 841.89;

    final buffer = BytesBuilder();

    void writeString(String s) {
      buffer.add(latin1.encode(s));
    }

    final List<int> xrefOffsets = [];
    xrefOffsets.add(0);

    writeString('%PDF-1.4\n%\xFF\xFF\xFF\xFF\n');

    final int numPages = imageFiles.isEmpty ? 1 : imageFiles.length;
    final int catalogObj = 1;
    final int pagesObj = 2;

    xrefOffsets.add(buffer.length);
    writeString('$catalogObj 0 obj\n<< /Type /Catalog /Pages $pagesObj 0 R >>\nendobj\n');

    final List<String> pageRefs = [];
    for (int i = 0; i < numPages; i++) {
      final pageObjId = 3 + i * 3;
      pageRefs.add('$pageObjId 0 R');
    }
    xrefOffsets.add(buffer.length);
    writeString('$pagesObj 0 obj\n<< /Type /Pages /Kids [${pageRefs.join(' ')}] /Count $numPages >>\nendobj\n');

    final filesToProcess = imageFiles.isEmpty ? [File('')] : imageFiles;

    for (int i = 0; i < filesToProcess.length; i++) {
      final pageObjId = 3 + i * 3;
      final contentObjId = 3 + i * 3 + 1;
      final imageObjId = 3 + i * 3 + 2;

      final file = filesToProcess[i];
      Uint8List imageBytes;
      if (file.path.isNotEmpty && await file.exists()) {
        imageBytes = await file.readAsBytes();
      } else {
        imageBytes = Uint8List.fromList(minimalJpegBytes);
      }

      int imgWidth = 800;
      int imgHeight = 1100;
      final dims = _getJpegDimensions(imageBytes);
      if (dims != null && dims.width > 0 && dims.height > 0) {
        imgWidth = dims.width;
        imgHeight = dims.height;
      }

      const double margin = 20.0;
      final double maxWidth = pageWidth - (margin * 2);
      final double maxHeight = pageHeight - (margin * 2);

      final double scale = (maxWidth / imgWidth < maxHeight / imgHeight)
          ? (maxWidth / imgWidth)
          : (maxHeight / imgHeight);

      final double drawWidth = imgWidth * scale;
      final double drawHeight = imgHeight * scale;
      final double drawX = (pageWidth - drawWidth) / 2;
      final double drawY = (pageHeight - drawHeight) / 2;

      // Page Object
      xrefOffsets.add(buffer.length);
      writeString('$pageObjId 0 obj\n'
          '<< /Type /Page\n'
          '   /Parent $pagesObj 0 R\n'
          '   /MediaBox [0 0 $pageWidth $pageHeight]\n'
          '   /Contents $contentObjId 0 R\n'
          '   /Resources << /XObject << /Im$i $imageObjId 0 R >> >>\n'
          '>>\nendobj\n');

      // Content Stream Object
      final contentStream = 'q\n'
          '${drawWidth.toStringAsFixed(2)} 0 0 ${drawHeight.toStringAsFixed(2)} ${drawX.toStringAsFixed(2)} ${drawY.toStringAsFixed(2)} cm\n'
          '/Im$i Do\n'
          'Q\n';
      final contentBytes = latin1.encode(contentStream);

      xrefOffsets.add(buffer.length);
      writeString('$contentObjId 0 obj\n'
          '<< /Length ${contentBytes.length} >>\n'
          'stream\n');
      buffer.add(contentBytes);
      writeString('endstream\nendobj\n');

      // Image XObject
      xrefOffsets.add(buffer.length);
      writeString('$imageObjId 0 obj\n'
          '<< /Type /XObject\n'
          '   /Subtype /Image\n'
          '   /Width $imgWidth\n'
          '   /Height $imgHeight\n'
          '   /ColorSpace /DeviceRGB\n'
          '   /BitsPerComponent 8\n'
          '   /Filter /DCTDecode\n'
          '   /Length ${imageBytes.length}\n'
          '>>\nstream\n');
      buffer.add(imageBytes);
      writeString('\nendstream\nendobj\n');
    }

    // XRef table
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
      // JPEG SOF markers (SOF0 to SOF15 except DHT 0xC4, JPG 0xC8, DAC 0xCC)
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
}
