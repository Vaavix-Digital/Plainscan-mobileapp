import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:plainscan/core/constants/app_colors.dart';
import 'package:plainscan/core/controllers/profile_controller.dart';
import 'package:plainscan/core/controllers/scan_controller.dart';
import 'package:plainscan/features/alltools/all_tools.dart';
import 'package:plainscan/models/tool_model.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final TextEditingController _searchController = TextEditingController();
  final ProfileController controller = Get.find<ProfileController>();

  final List<ToolModel> _quickTools = [
    const ToolModel(
      id: 'doc_scan',
      name: 'Doc Scan',
      icon: Icons.document_scanner_outlined,
      color: AppColors.primary,
      categoryId: 'scanner',
    ),
    const ToolModel(
      id: 'doc_convert',
      name: 'Convert',
      icon: Icons.swap_horiz,
      color: AppColors.amber,
      categoryId: 'scanner',
    ),
    const ToolModel(
      id: 'sign',
      name: 'Sign',
      icon: Icons.text_fields_outlined,
      color: AppColors.purple,
      categoryId: 'ai',
    ),
  ];

 void _triggerToolAction(ToolModel tool) {
  if (tool.id == 'doc_scan' || tool.id == 'id_scan') {
    Get.find<ScanController>().openScanner();
  } else {
    Get.rawSnackbar(
      messageText: Text(
        '${tool.name} module is loading...',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: AppColors.primary,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(12),
      borderRadius: 8,
    );
  }
}

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Obx(
                        () => Text(
                          'Hi, ${controller.userName.value}!',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Ready to organize your documents?',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border, width: 2),
                    ),
                    child: const CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Search Bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search scans, folders, tools...',
                    hintStyle: const TextStyle(color: AppColors.secondaryText),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.secondaryText,
                    ),
                    suffixIcon: const Icon(
                      Icons.tune,
                      color: AppColors.primary,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Stats / Premium Banner
              Container(
                width: double.infinity,
                height: 126,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF171A3D),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '49+ TOOLS · 1 WORKSPACE',
                      style: TextStyle(
                        color: Colors.blue.shade200,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      'Scan, convert, redact &\nask AI – no other app\ninstalled',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Quick Tools Grid
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Quick Tools',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // Navigate/switch tab logic is handled in the shell,
                      // but we can prompt user.
                      Get.snackbar(
                        'Files',
                        'Switching to All tools tab...',
                        duration: const Duration(milliseconds: 900),
                      );
                      Get.to(() => AllTools());
                    },
                    child: const Text(
                      'See All',
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                itemCount: _quickTools.length,
                itemBuilder: (context, index) {
                  final tool = _quickTools[index];
                  return GestureDetector(
                    onTap: () => _triggerToolAction(tool),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: tool.color.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(tool.icon, color: tool.color, size: 24),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            tool.name,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.text,
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 28),

              // Recent Scans
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Scans',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // Navigate/switch tab logic is handled in the shell,
                      // but we can prompt user.
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Switching to Files tab...'),
                          duration: Duration(milliseconds: 500),
                        ),
                      );
                    },
                    child: const Text(
                      'See All',
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Obx(() {
                final controller = Get.find<ScanController>();
                final recentFiles = controller.scannedFiles.take(3).toList();
                if (recentFiles.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.0),
                    child: Center(
                      child: Text(
                        'No recent scans',
                        style: TextStyle(color: AppColors.secondaryText),
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recentFiles.length,
                  itemBuilder: (context, index) {
                    final file = recentFiles[index];
                    return Card(
                      color: Colors.white,
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppColors.border),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color:
                                (file.fileType == 'PDF'
                                        ? AppColors.coral
                                        : AppColors.blue)
                                    .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            file.fileType == 'PDF'
                                ? Icons.picture_as_pdf
                                : Icons.image,
                            color: file.fileType == 'PDF'
                                ? AppColors.coral
                                : AppColors.blue,
                          ),
                        ),
                        title: Text(
                          file.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.text,
                          ),
                        ),
                        subtitle: Text(
                          '${file.createdDate.day}/${file.createdDate.month}/${file.createdDate.year} • ${(file.sizeKb / 1024).toStringAsFixed(1)} MB',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.secondaryText,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                file.isFavorite
                                    ? Icons.star
                                    : Icons.star_border,
                                color: file.isFavorite
                                    ? AppColors.amber
                                    : AppColors.secondaryText,
                              ),
                              onPressed: () {
                                controller.toggleFavorite(file.id);
                                Get.rawSnackbar(
                                  messageText: Text(
                                    file.isFavorite
                                        ? 'Removed from Starred'
                                        : 'Added to Starred',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  backgroundColor: AppColors.primary,
                                  snackPosition: SnackPosition.BOTTOM,
                                  margin: const EdgeInsets.all(12),
                                  borderRadius: 8,
                                );
                              },
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: AppColors.secondaryText,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
