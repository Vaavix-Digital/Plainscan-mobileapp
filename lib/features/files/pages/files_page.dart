import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:plainscan/core/constants/app_colors.dart';
import 'package:plainscan/core/controllers/scan_controller.dart';
import 'package:plainscan/models/file_model.dart';

class FilesPage extends StatefulWidget {
  const FilesPage({super.key});

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
    _tabController = TabController(length: 4, vsync: this);
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
          title: const Text('New Folder'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Folder name',
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
            ),
            onChanged: (value) {
              folderName = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppColors.secondaryText)),
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
              child: const Text('Create', style: TextStyle(color: Colors.white)),
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
          title: const Text('Rename File'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'New file name',
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
            ),
            controller: TextEditingController(text: currentName),
            onChanged: (value) {
              newName = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppColors.secondaryText)),
            ),
            ElevatedButton(
              onPressed: () {
                if (newName.trim().isNotEmpty) {
                  Get.find<ScanController>().renameFile(id, newName.trim());
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Rename', style: TextStyle(color: Colors.white)),
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
        title: const Text('Files Manager', style: TextStyle(fontWeight: FontWeight.bold)),
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
                messageText: const Text(
                  'Sorting list...',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
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
                  decoration: const InputDecoration(
                    hintText: 'Search files...',
                    prefixIcon: Icon(Icons.search, color: AppColors.secondaryText),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
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
                  tabs: const [
                    Tab(text: 'All'),
                    Tab(text: 'PDF'),
                    Tab(text: 'Images'),
                    Tab(text: 'Starred'),
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
                          const Text(
                            'Folders',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text),
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
                                          const Text(
                                            '0 files',
                                            style: TextStyle(color: AppColors.secondaryText, fontSize: 11),
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
                            const Text(
                              'Documents',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text),
                            ),
                            Text(
                              '${filteredFiles.length} items',
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
                              children: const [
                                Icon(Icons.insert_drive_file_outlined, size: 48, color: AppColors.secondaryText),
                                SizedBox(height: 12),
                                Text(
                                  'No documents found',
                                  style: TextStyle(color: AppColors.secondaryText),
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
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: ListTile(
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
                                  title: Text(
                                    file.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.text),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
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
                                          messageText: const Text(
                                            'File deleted',
                                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                          ),
                                          backgroundColor: AppColors.coral,
                                          snackPosition: SnackPosition.BOTTOM,
                                          margin: const EdgeInsets.all(12),
                                          borderRadius: 8,
                                        );
                                      } else if (action == 'rename') {
                                        _showRenameDialog(file.id, file.name);
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
                                            Text(file.isFavorite ? 'Unstar' : 'Star'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'share',
                                        child: Row(
                                          children: [
                                            Icon(Icons.share_outlined, color: AppColors.blue),
                                            SizedBox(width: 8),
                                            Text('Share'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'rename',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit_outlined, color: AppColors.primary),
                                            SizedBox(width: 8),
                                            Text('Rename'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuDivider(),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete_outline, color: AppColors.coral),
                                            SizedBox(width: 8),
                                            Text('Delete'),
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
}
