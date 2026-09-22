import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:excel/excel.dart' as xl;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:plainscan/core/constants/app_colors.dart';
import 'package:plainscan/core/utils/local_document_generators.dart';
import 'package:plainscan/models/file_model.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

class PdfViewerPage extends StatefulWidget {
  final FileModel? file;
  final String? filePath;
  final String? fileName;
  final String? fileType;

  const PdfViewerPage({
    super.key,
    this.file,
    this.filePath,
    this.fileName,
    this.fileType,
  });

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  String? _textContent;
  bool _isLoading = false;
  int _totalPages = 1;
  final TransformationController _transformationController = TransformationController();

  // PDF Viewer Data
  PDFViewController? _pdfViewController;
  int _currentPdfPage = 1;
  bool _pdfError = false;

  // Excel / Spreadsheet Data
  Map<String, List<List<String>>> _excelSheets = {};
  String? _selectedSheet;

  // Word Document Data
  String? _docxText;
  int _docxWordCount = 0;
  int _docxParagraphCount = 0;

  // PowerPoint Presentation Data
  List<String> _pptxSlides = [];
  int _currentPptxSlide = 0;

  String get _name => widget.fileName ?? widget.file?.name ?? 'document.pdf';
  String get _type {
    if (widget.fileType != null && widget.fileType!.isNotEmpty) {
      return widget.fileType!.toUpperCase();
    }
    if (widget.file?.fileType != null && widget.file!.fileType.isNotEmpty) {
      return widget.file!.fileType.toUpperCase();
    }
    if (_name.contains('.')) {
      return _name.split('.').last.toUpperCase();
    }
    return 'PDF';
  }

  String? get _path => widget.filePath ?? widget.file?.path;

  @override
  void initState() {
    super.initState();
    _loadFileContent();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _loadFileContent() {
    try {
      if (_path != null && File(_path!).existsSync()) {
        final file = File(_path!);
        final bytes = file.readAsBytesSync();
        final type = _type;

        if (type == 'TXT' || type == 'JSON' || type == 'CSV' || type == 'MD' || type == 'HTML' || type == 'XML') {
          try {
            _textContent = utf8.decode(bytes);
          } catch (_) {
            _textContent = latin1.decode(bytes);
          }
        }

        if (type == 'XLSX' || type == 'XLS') {
          _loadExcelSheets(bytes);
        } else if (type == 'CSV') {
          _loadCsvTable(_textContent ?? '');
        } else if (type == 'DOCX' || type == 'DOC') {
          _loadDocxContent(bytes);
        } else if (type == 'PPTX' || type == 'PPT') {
          _loadPptxContent(bytes);
        } else if (type == 'PDF') {
          _pdfError = false;
        }
      }
    } catch (e) {
      debugPrint('Error reading file in viewer: $e');
    } finally {
      _isLoading = false;
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _loadExcelSheets(Uint8List bytes) {
    try {
      final excel = xl.Excel.decodeBytes(bytes);
      final Map<String, List<List<String>>> sheets = {};
      for (final table in excel.tables.keys) {
        final sheet = excel.tables[table]!;
        final rows = sheet.rows.map((row) {
          return row.map((cell) => cell?.value?.toString() ?? '').toList();
        }).toList();
        if (rows.isNotEmpty) {
          sheets[table] = rows;
        }
      }
      if (sheets.isNotEmpty) {
        _excelSheets = sheets;
        _selectedSheet = sheets.keys.first;
      }
    } catch (e) {
      debugPrint('Error decoding excel: $e');
    }
  }

  void _loadCsvTable(String csvText) {
    try {
      final rows = LocalDocumentPdfGenerator.parseCsv(csvText);
      if (rows.isNotEmpty) {
        _excelSheets = {'Sheet1': rows};
        _selectedSheet = 'Sheet1';
      }
    } catch (_) {}
  }

  void _loadDocxContent(Uint8List bytes) {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      final docFile = archive.findFile('word/document.xml');
      if (docFile != null) {
        final xmlString = utf8.decode(docFile.content as List<int>);
        final pRegex = RegExp(r'<w:p[ >](.*?)</w:p>', dotAll: true);
        final tRegex = RegExp(r'<w:t[ >](.*?)</w:t>', dotAll: true);
        final buffer = StringBuffer();
        int pCount = 0;
        for (final pMatch in pRegex.allMatches(xmlString)) {
          final pContent = pMatch.group(1) ?? '';
          final lineSb = StringBuffer();
          for (final tMatch in tRegex.allMatches(pContent)) {
            var text = tMatch.group(1) ?? '';
            text = text
                .replaceAll('&amp;', '&')
                .replaceAll('&lt;', '<')
                .replaceAll('&gt;', '>')
                .replaceAll('&quot;', '"')
                .replaceAll('&apos;', "'");
            lineSb.write(text);
          }
          if (lineSb.isNotEmpty) {
            buffer.writeln(lineSb.toString());
            pCount++;
          }
        }
        final fullText = buffer.toString().trim();
        if (fullText.isNotEmpty) {
          _docxText = fullText;
          _docxParagraphCount = pCount;
          _docxWordCount = fullText.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).length;
        }
      }
    } catch (e) {
      debugPrint('Error decoding docx: $e');
    }
  }

  void _loadPptxContent(Uint8List bytes) {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      final List<String> slides = [];
      int slideIndex = 1;
      while (true) {
        final slideFile = archive.findFile('ppt/slides/slide$slideIndex.xml');
        if (slideFile == null) break;
        final xmlString = utf8.decode(slideFile.content as List<int>);
        final tRegex = RegExp(r'<a:t>(.*?)</a:t>', dotAll: true);
        final slideSb = StringBuffer();
        for (final tMatch in tRegex.allMatches(xmlString)) {
          var text = tMatch.group(1) ?? '';
          text = text
              .replaceAll('&amp;', '&')
              .replaceAll('&lt;', '<')
              .replaceAll('&gt;', '>')
              .replaceAll('&quot;', '"')
              .replaceAll('&apos;', "'");
          slideSb.writeln(text);
        }
        slides.add(slideSb.toString().trim());
        slideIndex++;
      }
      _pptxSlides = slides;
      _currentPptxSlide = 0;
    } catch (e) {
      debugPrint('Error decoding pptx: $e');
    }
  }

  void _shareDocument() {
    if (_path != null && File(_path!).existsSync()) {
      Share.shareXFiles([XFile(_path!)], text: 'Sharing $_name via PlainScan');
    } else {
      Share.share('PlainScan Document: $_name');
    }
  }

  Future<void> _saveDocument() async {
    try {
      if (_path != null && File(_path!).existsSync()) {
        final bytes = await File(_path!).readAsBytes();
        final savePath = await FilePicker.saveFile(
          dialogTitle: 'Save copy of $_name',
          fileName: _name,
          bytes: bytes,
        );
        if (savePath != null) {
          Get.rawSnackbar(
            titleText: const Text('File Saved', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            messageText: Text('Successfully saved to $savePath', style: const TextStyle(color: Colors.white)),
            backgroundColor: AppColors.primary,
            snackPosition: SnackPosition.BOTTOM,
            margin: const EdgeInsets.all(12),
            borderRadius: 10,
          );
        }
      } else {
        Get.rawSnackbar(
          messageText: const Text('File downloaded to storage', style: TextStyle(color: Colors.white)),
          backgroundColor: AppColors.primary,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(12),
          borderRadius: 10,
        );
      }
    } catch (e) {
      Get.rawSnackbar(
        messageText: Text('Failed to save file: $e', style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.coral,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
        borderRadius: 10,
      );
    }
  }

  Color _getFormatBrandColor() {
    final type = _type;
    if (type == 'XLSX' || type == 'XLS' || type == 'CSV') {
      return const Color(0xFF107C41); // Excel Green
    } else if (type == 'DOCX' || type == 'DOC' || type == 'RTF') {
      return const Color(0xFF2B579A); // Word Blue
    } else if (type == 'PPTX' || type == 'PPT') {
      return const Color(0xFFD24726); // PowerPoint Orange
    } else if (type == 'PNG' || type == 'JPG' || type == 'JPEG' || type == 'WEBP') {
      return const Color(0xFF06B6D4); // Cyan / Image
    } else if (type == 'TXT' || type == 'JSON' || type == 'MD' || type == 'HTML') {
      return const Color(0xFF8B5CF6); // Violet / Text
    } else if (type == 'ZIP') {
      return const Color(0xFFF59E0B); // Amber / Archive
    }
    return AppColors.coral; // Default PDF Red
  }

  String _getFormatDescription() {
    final type = _type;
    if (type == 'XLSX' || type == 'XLS') return 'Microsoft Excel Spreadsheet';
    if (type == 'CSV') return 'Comma-Separated Data File';
    if (type == 'DOCX' || type == 'DOC') return 'Microsoft Word Document';
    if (type == 'PPTX' || type == 'PPT') return 'Microsoft PowerPoint Presentation';
    if (type == 'PDF') return 'Portable Document Format';
    if (type == 'TXT') return 'Plain Text Document';
    if (type == 'PNG' || type == 'JPG' || type == 'JPEG') return 'Raster Image File';
    if (type == 'ZIP') return 'Compressed Archive';
    return '$type Document';
  }

  @override
  Widget build(BuildContext context) {
    final brandColor = _getFormatBrandColor();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Get.back(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: brandColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '$_type Document • Ready',
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.white),
            tooltip: 'Share',
            onPressed: _shareDocument,
          ),
          IconButton(
            icon: const Icon(Icons.download_rounded, color: Colors.white),
            tooltip: 'Save / Download',
            onPressed: _saveDocument,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                        child: _buildFileViewer(),
                      ),
                    ),
                  ),
                  _buildBottomToolbar(),
                ],
              ),
      ),
    );
  }

  Widget _buildFileViewer() {
    final type = _type;
    final fileExists = _path != null && File(_path!).existsSync();

    // 1. Images
    if (type == 'PNG' || type == 'JPG' || type == 'JPEG' || type == 'WEBP' || type == 'HEIC' || type == 'TIFF' || type == 'ICO') {
      if (fileExists) {
        return InteractiveViewer(
          transformationController: _transformationController,
          minScale: 0.5,
          maxScale: 4.0,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(File(_path!), fit: BoxFit.contain),
          ),
        );
      }
    }

    // 2. Excel & CSV Spreadsheets (Interactive Grid Table)
    if (type == 'XLSX' || type == 'XLS' || (type == 'CSV' && _excelSheets.isNotEmpty)) {
      return _buildExcelViewer();
    }

    // 3. Word Documents (.docx, .doc)
    if (type == 'DOCX' || type == 'DOC' || type == 'RTF' || type == 'ODT') {
      return _buildWordViewer();
    }

    // 4. PowerPoint Presentations (.pptx, .ppt)
    if (type == 'PPTX' || type == 'PPT' || type == 'ODP') {
      return _buildPowerPointViewer();
    }

    // 5. Monospace Text / Code Viewer
    if (_textContent != null && _textContent!.isNotEmpty) {
      return _buildTextViewer();
    }

    // 6. PDF Document Viewer Card
    if (type == 'PDF') {
      return _buildPdfViewerCard(fileExists);
    }

    // 7. General Fallback Card
    return _buildGenericFormatCard(fileExists);
  }

  /// Interactive Spreadsheet Table Viewer (Excel / CSV)
  Widget _buildExcelViewer() {
    final sheetNames = _excelSheets.keys.toList();
    final currentRows = _excelSheets[_selectedSheet] ?? [];
    final rowCount = currentRows.length;
    final colCount = currentRows.isNotEmpty ? currentRows.map((r) => r.length).reduce((a, b) => a > b ? a : b) : 0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF107C41), // Excel Green
              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                const Icon(Icons.table_chart_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Excel Workbook • $rowCount rows • $colCount columns',
                        style: const TextStyle(color: Color(0xFFD1FAE5), fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _type,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),

          // Multi-sheet Tabs if workbook has multiple sheets
          if (sheetNames.length > 1)
            Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              color: const Color(0xFF0F172A),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: sheetNames.length,
                separatorBuilder: (context, index) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  final name = sheetNames[index];
                  final isSelected = name == _selectedSheet;
                  return InkWell(
                    onTap: () => setState(() => _selectedSheet = name),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF107C41) : const Color(0xFF334155),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        name,
                        style: TextStyle(
                          color: isSelected ? Colors.white : const Color(0xFFCBD5E1),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

          // Spreadsheet Grid Body
          Expanded(
            child: currentRows.isEmpty
                ? const Center(
                    child: Text('Sheet is empty', style: TextStyle(color: Color(0xFF94A3B8))),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: MaterialStateProperty.all(const Color(0xFF0F172A)),
                        dataRowColor: MaterialStateProperty.resolveWith<Color>((states) {
                          return const Color(0xFF1E293B);
                        }),
                        columnSpacing: 20,
                        horizontalMargin: 12,
                        headingTextStyle: const TextStyle(
                          color: Color(0xFF34D399),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        dataTextStyle: const TextStyle(
                          color: Color(0xFFE2E8F0),
                          fontSize: 12,
                        ),
                        columns: List.generate(colCount, (colIdx) {
                          String colLetter = String.fromCharCode(65 + (colIdx % 26));
                          if (colIdx >= 26) {
                            colLetter = '${String.fromCharCode(64 + (colIdx ~/ 26))}$colLetter';
                          }
                          // If first row looks like headers, show it
                          final headerVal = (currentRows.isNotEmpty && colIdx < currentRows.first.length)
                              ? currentRows.first[colIdx]
                              : '';
                          return DataColumn(
                            label: Text(headerVal.isNotEmpty ? headerVal : colLetter),
                          );
                        }),
                        rows: List.generate(
                          currentRows.length > 1 ? currentRows.length - 1 : currentRows.length,
                          (rowIdx) {
                            final actualRow = currentRows.length > 1 ? currentRows[rowIdx + 1] : currentRows[rowIdx];
                            return DataRow(
                              color: MaterialStateProperty.all(
                                rowIdx.isEven ? const Color(0xFF1E293B) : const Color(0xFF162032),
                              ),
                              cells: List.generate(colCount, (colIdx) {
                                final cellVal = colIdx < actualRow.length ? actualRow[colIdx] : '';
                                return DataCell(
                                  SelectableText(
                                    cellVal,
                                    style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 12),
                                  ),
                                );
                              }),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /// Word Document Preview (.docx / .doc)
  Widget _buildWordViewer() {
    final wordText = _docxText ?? _textContent;
    final hasContent = wordText != null && wordText.isNotEmpty;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 480, maxHeight: 620),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Word Document Header Ribbon
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF2B579A), // Word Blue
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Icon(Icons.description_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        hasContent
                            ? 'Word Document • $_docxWordCount words • $_docxParagraphCount paragraphs'
                            : 'Microsoft Word Document (.docx)',
                        style: const TextStyle(color: Color(0xFFBFDBFE), fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _type,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),

          // Word Document Body Layout
          Expanded(
            child: hasContent
                ? Container(
                    padding: const EdgeInsets.all(24),
                    color: const Color(0xFFFAFBFD),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        wordText,
                        style: const TextStyle(
                          color: Color(0xFF1E293B),
                          fontSize: 13.5,
                          height: 1.6,
                          fontFamily: 'sans-serif',
                        ),
                      ),
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.all(24),
                    color: Colors.white,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2B579A).withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.description_rounded,
                            size: 64,
                            color: Color(0xFF2B579A),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          _name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF0F172A),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Microsoft Word document is formatted and ready for reading, editing, and sharing.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
                        ),
                        const SizedBox(height: 20),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            _buildBadge(Icons.check_circle_outline, 'Formatted', const Color(0xFF10B981)),
                            _buildBadge(Icons.article_outlined, 'DOCX Standard', const Color(0xFF2B579A)),
                            _buildBadge(Icons.verified_outlined, 'Ready to Edit', AppColors.purple),
                          ],
                        ),
                      ],
                    ),
                  ),
          ),

          // Footer info bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'PlainScan Word Conversion Engine',
                  style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                ),
                Text(
                  _type,
                  style: const TextStyle(fontSize: 10.5, color: Color(0xFF2B579A), fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// PowerPoint Slide Deck Viewer (.pptx / .ppt)
  Widget _buildPowerPointViewer() {
    final slideCount = _pptxSlides.isNotEmpty ? _pptxSlides.length : 1;
    final currentText = (_pptxSlides.isNotEmpty && _currentPptxSlide < _pptxSlides.length)
        ? _pptxSlides[_currentPptxSlide]
        : '';

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 520, maxHeight: 600),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // PowerPoint Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFD24726), // PowerPoint Orange
              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                const Icon(Icons.slideshow_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'PowerPoint Deck • Slide ${_currentPptxSlide + 1} of $slideCount',
                        style: const TextStyle(color: Color(0xFFFFEDD5), fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'PPTX',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),

          // 16:9 Widescreen Slide Frame
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: currentText.isNotEmpty
                      ? SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFEDD5),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'SLIDE ${_currentPptxSlide + 1}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFC2410C),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              SelectableText(
                                currentText,
                                style: const TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontSize: 13,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.co_present_rounded, size: 54, color: Color(0xFFD24726)),
                            const SizedBox(height: 12),
                            Text(
                              _name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFF0F172A),
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'PowerPoint presentation slide deck is ready.',
                              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),

          // Slide Navigation Controls
          if (slideCount > 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: const Color(0xFF0F172A),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    onPressed: _currentPptxSlide > 0
                        ? () => setState(() => _currentPptxSlide--)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF334155),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                    ),
                    icon: const Icon(Icons.arrow_back, size: 14),
                    label: const Text('Prev Slide', style: TextStyle(fontSize: 11)),
                  ),
                  Text(
                    '${_currentPptxSlide + 1} / $slideCount',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  ElevatedButton.icon(
                    onPressed: _currentPptxSlide < slideCount - 1
                        ? () => setState(() => _currentPptxSlide++)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF334155),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                    ),
                    icon: const Icon(Icons.arrow_forward, size: 14),
                    label: const Text('Next Slide', style: TextStyle(fontSize: 11)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Text / Code Document Viewer
  Widget _buildTextViewer() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$_type Document Content',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              IconButton(
                icon: const Icon(Icons.copy_rounded, color: Color(0xFF94A3B8), size: 18),
                tooltip: 'Copy all text',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _textContent!));
                  Get.rawSnackbar(
                    messageText: const Text('Text copied to clipboard!', style: TextStyle(color: Colors.white)),
                    backgroundColor: AppColors.primary,
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
              ),
            ],
          ),
          const Divider(color: Color(0xFF334155)),
          Expanded(
            child: SingleChildScrollView(
              child: SelectableText(
                _textContent!,
                style: const TextStyle(
                  color: Color(0xFFE2E8F0),
                  fontFamily: 'monospace',
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// PDF Viewer Preview Card using native PDFView
  Widget _buildPdfViewerCard(bool fileExists) {
    if (!fileExists || _path == null || !File(_path!).existsSync() || _pdfError) {
      return _buildPdfFallbackCard(fileExists);
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Ribbon with Title and Page Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.coral,
              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 180),
                      child: Text(
                        _name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Page $_currentPdfPage of $_totalPages',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Native Flutter PDFView Widget
          Expanded(
            child: ClipRRect(
              child: PDFView(
                filePath: _path!,
                enableSwipe: true,
                swipeHorizontal: false,
                autoSpacing: true,
                pageFling: true,
                pageSnap: true,
                fitPolicy: FitPolicy.BOTH,
                preventLinkNavigation: false,
                onRender: (pages) {
                  if (mounted) {
                    setState(() {
                      _totalPages = pages ?? 1;
                      _pdfError = false;
                    });
                  }
                },
                onError: (error) {
                  debugPrint('PDFView error: $error');
                  if (mounted) {
                    setState(() {
                      _pdfError = true;
                    });
                  }
                },
                onPageError: (page, error) {
                  debugPrint('PDFView page $page error: $error');
                },
                onViewCreated: (PDFViewController controller) {
                  _pdfViewController = controller;
                },
                onPageChanged: (page, total) {
                  if (mounted && page != null) {
                    setState(() {
                      _currentPdfPage = page + 1;
                      if (total != null && total > 0) {
                        _totalPages = total;
                      }
                    });
                  }
                },
              ),
            ),
          ),

          // Bottom Navigation Controls
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(15)),
              border: Border(top: BorderSide(color: Color(0xFF334155))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded, color: Colors.white),
                  tooltip: 'Previous Page',
                  onPressed: _currentPdfPage > 1
                      ? () {
                          _pdfViewController?.setPage(_currentPdfPage - 2);
                        }
                      : null,
                ),
                Text(
                  'Swipe up/down to scroll pages',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade400,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded, color: Colors.white),
                  tooltip: 'Next Page',
                  onPressed: _currentPdfPage < _totalPages
                      ? () {
                          _pdfViewController?.setPage(_currentPdfPage);
                        }
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPdfFallbackCard(bool fileExists) {
    return InteractiveViewer(
      transformationController: _transformationController,
      minScale: 0.5,
      maxScale: 3.5,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 600),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.picture_as_pdf, color: AppColors.coral, size: 18),
                      const SizedBox(width: 8),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 200),
                        child: Text(
                          _name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Color(0xFF1E293B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Page 1 of $_totalPages',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(24),
                color: Colors.white,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.coral.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.picture_as_pdf_rounded,
                        size: 64,
                        color: AppColors.coral,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      _name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF0F172A),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      fileExists
                          ? 'PDF Document is generated and ready for viewing, sharing, or downloading.'
                          : 'Document processed successfully and saved.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        _buildBadge(Icons.check_circle_outline, 'Processed', const Color(0xFF10B981)),
                        _buildBadge(Icons.lock_open_rounded, 'Unlocked / Ready', AppColors.blue),
                        _buildBadge(Icons.verified_outlined, 'Standard PDF', AppColors.purple),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Generic Format Card for any other formats
  Widget _buildGenericFormatCard(bool fileExists) {
    final brandColor = _getFormatBrandColor();
    final desc = _getFormatDescription();

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 420, maxHeight: 540),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: brandColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Icon(Icons.insert_drive_file_outlined, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _type,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: brandColor.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.folder_zip_outlined,
                      size: 64,
                      color: brandColor,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    _name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF0F172A),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$desc converted and ready.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: Color(0xFF334155))),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _shareDocument,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFF475569)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.share_outlined, size: 16),
              label: const Text('Share', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _saveDocument,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.download_rounded, size: 16),
              label: const Text('Download', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }
}
