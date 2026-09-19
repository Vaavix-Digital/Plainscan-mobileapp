import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:plainscan/core/constants/app_colors.dart';
import 'package:plainscan/core/controllers/scan_controller.dart';
import 'package:plainscan/features/files/pages/pdf_viewer_page.dart';
import 'package:plainscan/models/file_model.dart';
import 'package:share_plus/share_plus.dart';

class FilesPage extends StatefulWidget {
  final String? highlightFileId;

  const FilesPage({
    super.key,
    this.highlightFileId,
  });

  @override
  State<FilesPage> createState() => _FilesPageState();
}

class _FilesPageState extends State<FilesPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  final List<String> _folders = ['Work', 'Personal', 'Receipts', 'Legal'];

  @override
  void initState() {
    super.initState();
    int initialIndex = 0;
    if (widget.highlightFileId != null && Get.isRegistered<ScanController>()) {
      final file = Get.find<ScanController>().scannedFiles.firstWhereOrNull((f) => f.id == widget.highlightFileId);
      if (file != null && file.fileType == 'PDF') {
        initialIndex = 1; // PDF Tab
      } else if (file != null && (file.fileType == 'PNG' || file.fileType == 'JPG')) {
        initialIndex = 2; // Images Tab
      }
    }
    _tabController = TabController(length: 4, vsync: this, initialIndex: initialIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _createNewFolder() {
    showDialog(
      context: context,
      builder: (context) {
        String folderName = '';
        return AlertDialog(
          title: Text('New Folder'.tr),
          content: TextField(
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Folder name'.tr,
              focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
            ),
            onChanged: (value) {
              folderName = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'.tr, style: const TextStyle(color: AppColors.secondaryText)),
            ),
            ElevatedButton(
              onPressed: () {
                if (folderName.trim().isNotEmpty) {
                  setState(() {
                    _folders.add(folderName.trim());
                  });
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: Text('Create'.tr, style: const TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showRenameDialog(String id, String currentName) {
    showDialog(
      context: context,
      builder: (context) {
        String newName = currentName;
        return AlertDialog(
          title: Text('Rename File'.tr),
          content: TextField(
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'New file name'.tr,
              focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
            ),
            controller: TextEditingController(text: currentName),
            onChanged: (value) {
              newName = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'.tr, style: const TextStyle(color: AppColors.secondaryText)),
            ),
            ElevatedButton(
              onPressed: () {
                if (newName.trim().isNotEmpty) {
                  Get.find<ScanController>().renameFile(id, newName.trim());
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: Text('Rename'.tr, style: const TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  List<FileModel> _getFilteredFiles(List<FileModel> allFiles, int tabIndex) {
    switch (tabIndex) {
      case 1: // PDF
        return allFiles.where((file) => file.fileType == 'PDF').toList();
      case 2: // Images
        return allFiles.where((file) => file.fileType == 'PNG' || file.fileType == 'JPG').toList();
      case 3: // Starred
        return allFiles.where((file) => file.isFavorite).toList();
      case 0: // All
      default:
        return allFiles;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Files Manager'.tr, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.create_new_folder_outlined, color: AppColors.primary),
            onPressed: _createNewFolder,
          ),
          IconButton(
            icon: const Icon(Icons.sort_outlined, color: AppColors.primary),
            onPressed: () {
              Get.rawSnackbar(
                messageText: Text(
                  'Sorting list...'.tr,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                backgroundColor: AppColors.primary,
                snackPosition: SnackPosition.BOTTOM,
                margin: const EdgeInsets.all(12),
                borderRadius: 8,
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search inside Files
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search files...'.tr,
                    prefixIcon: const Icon(Icons.search, color: AppColors.secondaryText),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),

            // Tab Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: AppColors.primary.withOpacity(0.1),
                  ),
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.secondaryText,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  tabs: [
                    Tab(text: 'All'.tr),
                    Tab(text: 'PDF'.tr),
                    Tab(text: 'Images'.tr),
                    Tab(text: 'Starred'.tr),
                  ],
                ),
              ),
            ),

            Expanded(
              child: Obx(() {
                final controller = Get.find<ScanController>();
                final files = controller.scannedFiles;
                return TabBarView(
                  controller: _tabController,
                  children: List.generate(4, (tabIndex) {
                    final filteredFiles = _getFilteredFiles(files, tabIndex);

                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Folders section (Only visible on the 'All' tab)
                        if (tabIndex == 0 && _folders.isNotEmpty) ...[
                          Text(
                            'Folders'.tr,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text),
                          ),
                          const SizedBox(height: 12),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 2.2,
                            ),
                            itemCount: _folders.length,
                            itemBuilder: (context, index) {
                              final folder = _folders[index];
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.folder, color: AppColors.primary, size: 28),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            folder,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            '@count files'.trParams({'count': '0'}),
                                            style: const TextStyle(color: AppColors.secondaryText, fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Files section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Documents'.tr,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text),
                            ),
                            Text(
                              '@count items'.trParams({'count': '${filteredFiles.length}'}),
                              style: const TextStyle(fontSize: 12, color: AppColors.secondaryText),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        if (filteredFiles.isEmpty)
                          Container(
                            height: 150,
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.insert_drive_file_outlined, size: 48, color: AppColors.secondaryText),
                                const SizedBox(height: 12),
                                Text(
                                  'No documents found'.tr,
                                  style: const TextStyle(color: AppColors.secondaryText),
                                ),
                              ],
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filteredFiles.length,
                            itemBuilder: (context, index) {
                              final file = filteredFiles[index];
                              final isHighlighted = widget.highlightFileId != null && file.id == widget.highlightFileId;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: isHighlighted ? const Color(0xFFF0FDF4) : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isHighlighted ? const Color(0xFF10B981) : AppColors.border,
                                    width: isHighlighted ? 1.5 : 1.0,
                                  ),
                                ),
                                child: ListTile(
                                  onTap: () => _showFileDetailsBottomSheet(file),
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: (file.fileType == 'PDF' ? AppColors.coral : AppColors.blue).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      file.fileType == 'PDF' ? Icons.picture_as_pdf : Icons.image,
                                      color: file.fileType == 'PDF' ? AppColors.coral : AppColors.blue,
                                    ),
                                  ),
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          file.name,
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.text),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (isHighlighted) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF10B981),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Text(
                                            'NEW',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  subtitle: Text(
                                    '${file.createdDate.day}/${file.createdDate.month}/${file.createdDate.year} • ${(file.sizeKb / 1024).toStringAsFixed(1)} MB',
                                    style: const TextStyle(fontSize: 12, color: AppColors.secondaryText),
                                  ),
                                  trailing: PopupMenuButton<String>(
                                    onSelected: (action) {
                                      final controller = Get.find<ScanController>();
                                      if (action == 'favorite') {
                                        controller.toggleFavorite(file.id);
                                      } else if (action == 'delete') {
                                        controller.deleteFile(file.id);
                                        Get.rawSnackbar(
                                          messageText: Text(
                                            'File deleted'.tr,
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                          ),
                                          backgroundColor: AppColors.coral,
                                          snackPosition: SnackPosition.BOTTOM,
                                          margin: const EdgeInsets.all(12),
                                          borderRadius: 8,
                                        );
                                      } else if (action == 'rename') {
                                        _showRenameDialog(file.id, file.name);
                                      } else if (action == 'share') {
                                        _shareFile(file);
                                      } else {
                                        Get.rawSnackbar(
                                          messageText: Text(
                                            'Action: $action',
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                          ),
                                          backgroundColor: AppColors.primary,
                                          snackPosition: SnackPosition.BOTTOM,
                                          margin: const EdgeInsets.all(12),
                                          borderRadius: 8,
                                        );
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      PopupMenuItem(
                                        value: 'favorite',
                                        child: Row(
                                          children: [
                                            Icon(
                                              file.isFavorite ? Icons.star : Icons.star_border,
                                              color: AppColors.amber,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(file.isFavorite ? 'Unstar'.tr : 'Star'.tr),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'share',
                                        child: Row(
                                          children: [
                                            const Icon(Icons.share_outlined, color: AppColors.blue),
                                            const SizedBox(width: 8),
                                            Text('Share'.tr),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'rename',
                                        child: Row(
                                          children: [
                                            const Icon(Icons.edit_outlined, color: AppColors.primary),
                                            const SizedBox(width: 8),
                                            Text('Rename'.tr),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuDivider(),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            const Icon(Icons.delete_outline, color: AppColors.coral),
                                            const SizedBox(width: 8),
                                            Text('Delete'.tr),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  );
                }),
              );
            }),
          ),
          ],
        ),
      ),
    );
  }

  void _shareFile(FileModel file) {
    if (file.path != null && File(file.path!).existsSync()) {
      Share.shareXFiles([XFile(file.path!)], text: 'Sharing ${file.name} via PlainScan');
    } else {
      Share.share('PlainScan Document: ${file.name}');
    }
  }

  void _showFileDetailsBottomSheet(FileModel file) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // File Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (file.fileType == 'PDF' ? AppColors.coral : AppColors.blue).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      file.fileType == 'PDF' ? Icons.picture_as_pdf : Icons.image,
                      color: file.fileType == 'PDF' ? AppColors.coral : AppColors.blue,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          file.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${file.fileType} • ${(file.sizeKb / 1024).toStringAsFixed(2)} MB',
                          style: const TextStyle(fontSize: 12, color: AppColors.secondaryText),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: AppColors.border),
              const SizedBox(height: 12),

              // Metadata rows
              _buildMetaRow(Icons.calendar_today_outlined, 'Date Created',
                  '${file.createdDate.day}/${file.createdDate.month}/${file.createdDate.year} ${file.createdDate.hour.toString().padLeft(2, '0')}:${file.createdDate.minute.toString().padLeft(2, '0')}'),
              const SizedBox(height: 10),
              if (file.path != null && file.path!.isNotEmpty) ...[
                _buildMetaRow(Icons.folder_outlined, 'Location', file.path!),
                const SizedBox(height: 10),
              ],
              _buildMetaRow(Icons.star_outline, 'Status', file.isFavorite ? 'Starred' : 'Standard'),

              const SizedBox(height: 20),

              // Action Buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Get.back();
                    Get.to(() => PdfViewerPage(
                      file: file,
                      filePath: file.path,
                      fileName: file.name,
                      fileType: file.fileType,
                    ));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  icon: const Icon(Icons.visibility_outlined, size: 20),
                  label: const Text(
                    'Open Document',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Get.back();
                        _shareFile(file);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.share_outlined, size: 18),
                      label: const Text('Share', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Get.back();
                        try {
                          if (file.path != null && File(file.path!).existsSync()) {
                            final bytes = await File(file.path!).readAsBytes();
                            final savePath = await FilePicker.saveFile(
                              dialogTitle: 'Save copy of file...',
                              fileName: file.name,
                              bytes: bytes,
                            );
                            if (savePath != null) {
                              Get.rawSnackbar(
                                messageText: const Text('File saved successfully!', style: TextStyle(color: Colors.white)),
                                backgroundColor: AppColors.primary,
                                snackPosition: SnackPosition.BOTTOM,
                              );
                            }
                          } else {
                            Get.rawSnackbar(
                              messageText: const Text('File downloaded to storage', style: TextStyle(color: Colors.white)),
                              backgroundColor: AppColors.primary,
                              snackPosition: SnackPosition.BOTTOM,
                            );
                          }
                        } catch (e) {
                          Get.rawSnackbar(
                            messageText: Text('Download failed: $e', style: const TextStyle(color: Colors.white)),
                            backgroundColor: AppColors.coral,
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.download_outlined, size: 18),
                      label: const Text('Save / Export', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () {
                        Get.back();
                        _showRenameDialog(file.id, file.name);
                      },
                      icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.secondaryText),
                      label: const Text('Rename', style: TextStyle(color: AppColors.secondaryText, fontSize: 13)),
                    ),
                  ),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () {
                        Get.back();
                        Get.find<ScanController>().toggleFavorite(file.id);
                      },
                      icon: Icon(file.isFavorite ? Icons.star : Icons.star_border, size: 16, color: AppColors.amber),
                      label: Text(file.isFavorite ? 'Unstar' : 'Star', style: const TextStyle(color: AppColors.secondaryText, fontSize: 13)),
                    ),
                  ),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () {
                        Get.back();
                        Get.find<ScanController>().deleteFile(file.id);
                        Get.rawSnackbar(
                          messageText: Text('File deleted'.tr, style: const TextStyle(color: Colors.white)),
                          backgroundColor: AppColors.coral,
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      },
                      icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.coral),
                      label: const Text('Delete', style: TextStyle(color: AppColors.coral, fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildMetaRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.secondaryText),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.secondaryText,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.text,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
