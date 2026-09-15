import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_doc_scanner/flutter_doc_scanner.dart';
import 'package:get/get.dart';
import 'package:plainscan/core/constants/app_colors.dart';
import 'package:plainscan/core/controllers/scan_controller.dart';
import 'package:plainscan/features/alltools/tool_executor_page.dart';
import 'package:plainscan/models/file_model.dart';
import 'package:plainscan/models/tool_model.dart';

class ScanPreviewPage extends StatefulWidget {
  final List<String> imagePaths;

  const ScanPreviewPage({
    super.key,
    required this.imagePaths,
  });

  @override
  State<ScanPreviewPage> createState() => _ScanPreviewPageState();
}

class _ScanPreviewPageState extends State<ScanPreviewPage> {
  late List<String> _photos;
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  final ScrollController _thumbnailScrollController = ScrollController();
  final Map<int, int> _rotations = {}; // page index -> degrees (0, 90, 180, 270)
  String _selectedPageSize = 'A4'; // 'A4' or 'letter'

  @override
  void initState() {
    super.initState();
    _photos = List<String>.from(widget.imagePaths);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _thumbnailScrollController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    _scrollToThumbnail(index);
  }

  void _scrollToThumbnail(int index) {
    if (_thumbnailScrollController.hasClients) {
      final target = (index * 72.0) - 100.0;
      _thumbnailScrollController.animateTo(
        target.clamp(0.0, _thumbnailScrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _rotateCurrent() {
    setState(() {
      final current = _rotations[_currentIndex] ?? 0;
      _rotations[_currentIndex] = (current + 90) % 360;
    });
  }

  void _deleteCurrent() {
    if (_photos.isEmpty) return;

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Page?'.tr),
        content: Text('Delete page @page from your scanned document?'.trParams({'page': '${_currentIndex + 1}'})),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'.tr),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              setState(() {
                _photos.removeAt(_currentIndex);
                _rotations.remove(_currentIndex);
                if (_currentIndex >= _photos.length && _currentIndex > 0) {
                  _currentIndex = _photos.length - 1;
                }
              });

              if (_photos.isEmpty) {
                Get.back(); // return to previous screen
              } else {
                _pageController.jumpToPage(_currentIndex);
              }
            },
            child: Text('Delete'.tr, style: const TextStyle(color: AppColors.coral)),
          ),
        ],
      ),
    );
  }

  Future<void> _addMorePages() async {
    final isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);

    if (!isMobile) {
      // For desktop / mock testing: add sample asset path or mock
      setState(() {
        _photos.add('mock_scanned_photo_${_photos.length + 1}.jpg');
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sample page added.'.tr)),
      );
      return;
    }

    try {
      final result = await FlutterDocScanner().getScannedDocumentAsImages(page: 10);
      if (result != null && result.images.isNotEmpty) {
        setState(() {
          _photos.addAll(result.images);
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('@count page(s) added.'.trParams({'count': '${result.images.length}'}))),
        );
      } else {
        dynamic docs = await FlutterDocScanner().getScanDocuments(page: 10);
        if (docs != null) {
          List<String> newPaths = [];
          if (docs is Map && docs.containsKey('images')) {
            final list = docs['images'] as List?;
            if (list != null) newPaths = list.map((e) => e.toString()).toList();
          } else if (docs is List) {
            newPaths = docs.map((e) => e.toString()).toList();
          } else if (docs is String) {
            newPaths = [docs];
          }

          if (newPaths.isNotEmpty) {
            setState(() {
              _photos.addAll(newPaths);
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error scanning additional pages: $e');
    }
  }

  void _confirmDiscard() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Discard Scans?'.tr),
        content: Text('Are you sure you want to discard your captured photos?'.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Keep'.tr),
          ),
          TextButton(
            onPressed: () {
              Get.back(); // close dialog
              Get.back(); // close preview
            },
            child: Text('Discard'.tr, style: const TextStyle(color: AppColors.coral)),
          ),
        ],
      ),
    );
  }

  void _convertToPdf() {
    if (_photos.isEmpty) return;

    final scanCtrl = Get.isRegistered<ScanController>()
        ? Get.find<ScanController>()
        : Get.put(ScanController());

    // Build FileModel list for all photos
    final List<FileModel> files = [];
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    for (int i = 0; i < _photos.length; i++) {
      final path = _photos[i];
      final fileName = 'Scan_${timestamp}_Page${i + 1}.jpg';

      final fileModel = FileModel(
        id: '${timestamp}_$i',
        name: fileName,
        createdDate: DateTime.now(),
        sizeKb: 850.0,
        fileType: 'JPG',
        path: path,
      );

      // Save raw image to files list as well
      scanCtrl.addScan(path, customName: fileName, fileType: 'JPG');
      files.add(fileModel);
    }

    // Find the JPG to PDF tool
    final jpgToPdfTool = allPlainscanTools.firstWhere(
      (t) => t.id == 'jpg-to-pdf',
      orElse: () => const ToolModel(
        id: 'jpg-to-pdf',
        name: 'JPG to PDF',
        icon: Icons.photo_size_select_actual_outlined,
        color: AppColors.purple,
        categoryId: 'conversion',
        category: 'PDF Conversion',
        inputFormat: 'image (.jpg)',
        outputFormat: '.pdf',
        isMultiFile: true,
        description: 'Convert single or multiple JPG images into a clean PDF document.',
      ),
    );

    // Launch ToolExecutorPage with the captured files and auto-execute enabled
    Get.off(
      () => ToolExecutorPage(
        tool: jpgToPdfTool,
        initialFiles: files,
        autoExecute: true,
      ),
    );
  }

  Widget _buildPhotoView(String path, int index) {
    final rotation = _rotations[index] ?? 0;
    final file = File(path);
    final fileExists = file.existsSync();

    Widget imageWidget;
    if (fileExists) {
      imageWidget = Image.file(
        file,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _buildFallbackWidget(path, index),
      );
    } else {
      imageWidget = _buildFallbackWidget(path, index);
    }

    return Center(
      child: RotatedBox(
        quarterTurns: (rotation ~/ 90),
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 4.0,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: imageWidget,
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackWidget(String path, int index) {
    return Container(
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.document_scanner_outlined,
            size: 80,
            color: AppColors.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Scanned Page ${index + 1}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              path.split('/').last.split('\\').last,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.secondaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = _photos.length;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _confirmDiscard();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF12141A),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: _confirmDiscard,
            tooltip: 'Discard'.tr,
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Scan Preview'.tr,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Text(
                '@count @pages captured'.trParams({
                  'count': '$total',
                  'pages': total == 1 ? 'page'.tr : 'pages'.tr,
                }),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          actions: [
            TextButton.icon(
              onPressed: _addMorePages,
              icon: const Icon(Icons.add_a_photo_outlined, color: Colors.white, size: 18),
              label: Text(
                'Add Page'.tr,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Main Interactive Preview PageView
              Expanded(
                child: Stack(
                  children: [
                    PageView.builder(
                      controller: _pageController,
                      itemCount: _photos.length,
                      onPageChanged: _onPageChanged,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: _buildPhotoView(_photos[index], index),
                        );
                      },
                    ),

                    // Top page counter badge
                    Positioned(
                      top: 12,
                      left: 24,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white24, width: 0.5),
                        ),
                        child: Text(
                          'Page @page of @total'.trParams({
                            'page': '${_currentIndex + 1}',
                            'total': '$total',
                          }),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),

                    // Quick Page action controls (Rotate & Delete)
                    Positioned(
                      top: 12,
                      right: 24,
                      child: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white24, width: 0.5),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.rotate_right_rounded, color: Colors.white, size: 20),
                              tooltip: 'Rotate 90°'.tr,
                              onPressed: _rotateCurrent,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white24, width: 0.5),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.coral, size: 20),
                              tooltip: 'Delete Page'.tr,
                              onPressed: _deleteCurrent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom Control Panel: Thumbnails + Settings + Convert Button
              Container(
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 16,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Thumbnails list
                    if (_photos.length > 1) ...[
                      SizedBox(
                        height: 72,
                        child: ListView.separated(
                          controller: _thumbnailScrollController,
                          scrollDirection: Axis.horizontal,
                          itemCount: _photos.length,
                          separatorBuilder: (context, index) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final isSelected = index == _currentIndex;
                            final path = _photos[index];
                            final file = File(path);
                            final fileExists = file.existsSync();

                            return GestureDetector(
                              onTap: () {
                                _pageController.animateToPage(
                                  index,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              },
                              child: Container(
                                width: 56,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected ? AppColors.primary : Colors.grey.shade300,
                                    width: isSelected ? 2.5 : 1,
                                  ),
                                ),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: fileExists
                                          ? Image.file(file, fit: BoxFit.cover)
                                          : Container(
                                              color: Colors.grey.shade200,
                                              child: const Icon(Icons.description, size: 24, color: Colors.grey),
                                            ),
                                    ),
                                    Positioned(
                                      bottom: 2,
                                      right: 2,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.8),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '${index + 1}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Page layout quick selector
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.layers_outlined, size: 18, color: AppColors.secondaryText),
                            const SizedBox(width: 6),
                            Text(
                              'PDF Page Layout'.tr,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.text,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedPageSize,
                              isDense: true,
                              items: [
                                DropdownMenuItem(
                                  value: 'A4',
                                  child: Text('A4 (Standard)'.tr, style: const TextStyle(fontSize: 12)),
                                ),
                                DropdownMenuItem(
                                  value: 'letter',
                                  child: Text('Letter (US)'.tr, style: const TextStyle(fontSize: 12)),
                                ),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedPageSize = val;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Convert to PDF primary button
                    ElevatedButton(
                      onPressed: _convertToPdf,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 3,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.picture_as_pdf_rounded, size: 22),
                          const SizedBox(width: 10),
                          Text(
                            'Convert to PDF (@count @pages)'.trParams({
                              'count': '$total',
                              'pages': total == 1 ? 'page'.tr : 'pages'.tr,
                            }),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'JPG to PDF'.tr,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
