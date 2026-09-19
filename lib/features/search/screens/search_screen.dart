import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:plainscan/core/constants/app_colors.dart';
import 'package:plainscan/core/controllers/alltool_controller.dart';
import 'package:plainscan/core/controllers/profile_controller.dart';
import 'package:plainscan/core/controllers/scan_controller.dart';
import 'package:plainscan/features/alltools/tool_executor_page.dart';
import 'package:plainscan/models/tool_model.dart';

class SearchScreenController extends GetxController {
  final searchController = TextEditingController();
  final searchText = ''.obs;
  final selectedFilter = '▦ All'.obs;

  final AllToolsController allToolsController = Get.isRegistered<AllToolsController>()
      ? Get.find<AllToolsController>()
      : Get.put(AllToolsController());

  final ProfileController profileController = Get.isRegistered<ProfileController>()
      ? Get.find<ProfileController>()
      : Get.put(ProfileController());

  final List<String> filters = [
    '▦ All',
    '📄 PDF Conversion',
    '🛠️ PDF Manipulation',
    '🔍 OCR & Scan',
    '🤖 AI Tools',
    '📦 Utility',
  ];

  List<ToolModel> get searchResults {
    final query = searchText.value.toLowerCase().trim();
    List<ToolModel> result = allPlainscanTools;

    // Filter by category
    switch (selectedFilter.value) {
      case '📄 PDF Conversion':
        result = result.where((tool) => tool.categoryId == 'conversion').toList();
        break;
      case '🛠️ PDF Manipulation':
        result = result.where((tool) => tool.categoryId == 'manipulation').toList();
        break;
      case '🔍 OCR & Scan':
        result = result.where((tool) => tool.categoryId == 'ocr').toList();
        break;
      case '🤖 AI Tools':
        result = result.where((tool) => tool.categoryId == 'ai').toList();
        break;
      case '📦 Utility':
        result = result.where((tool) => tool.categoryId == 'utility').toList();
        break;
      default:
        break;
    }

    // Filter by search query
    if (query.isNotEmpty) {
      result = result.where((tool) {
        final name = tool.name.toLowerCase();
        final category = tool.category?.toLowerCase() ?? '';
        final desc = tool.description?.toLowerCase() ?? '';
        final inputFmt = tool.inputFormat?.toLowerCase() ?? '';
        final outputFmt = tool.outputFormat?.toLowerCase() ?? '';
        final slug = tool.slug.toLowerCase();

        return name.contains(query) ||
            category.contains(query) ||
            desc.contains(query) ||
            inputFmt.contains(query) ||
            outputFmt.contains(query) ||
            slug.contains(query);
      }).toList();
    }

    return result;
  }

  void onSearchChanged(String value) {
    searchText.value = value;
  }

  void selectFilter(String filter) {
    selectedFilter.value = filter;
  }

  void clearSearch() {
    searchController.clear();
    searchText.value = '';
  }

  void triggerToolAction(ToolModel tool) {
    allToolsController.recordToolUsage(tool.id);

    final isFree = tool.isFree ?? true;
    if (!isFree && !profileController.isPro.value) {
      ProfileController.showUpgradeSnackbar(tool.name);
      return;
    }

    if (tool.id == 'doc_scan' || tool.id == 'id_scan' || tool.id == 'scan-ocr') {
      if (Get.isRegistered<ScanController>()) {
        Get.find<ScanController>().openScanner();
      } else {
        Get.put(ScanController()).openScanner();
      }
    } else {
      Get.to(() => ToolExecutorPage(tool: tool));
    }
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SearchScreenController());

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FD),
      body: SafeArea(
        child: Column(
          children: [
            // Search Header Bar
            _buildSearchHeader(controller),

            // Filter Chips Bar
            _buildFilterChips(controller),

            // Search Content / Results
            Expanded(
              child: Obx(() {
                final query = controller.searchText.value.trim();
                final filter = controller.selectedFilter.value;
                final results = controller.searchResults;

                // When user hasn't typed anything and filter is All -> Show Quick & Recent Tools
                if (query.isEmpty && filter == '▦ All') {
                  return _buildDefaultSearchContent(controller);
                }

                // If results are empty
                if (results.isEmpty) {
                  return _buildEmptyState(controller, query);
                }

                // Show matching tools
                return _buildSearchResultsList(controller, results);
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHeader(SearchScreenController controller) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              size: 20,
              color: Color(0xFF11152F),
            ),
            onPressed: () => Get.back(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFDDE1EF)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: controller.searchController,
                autofocus: true,
                onChanged: controller.onSearchChanged,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF20243D),
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'Search 56+ PDF tools, AI actions...'.tr,
                  hintStyle: const TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF71809D),
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 20,
                    color: Color(0xFF71809D),
                  ),
                  suffixIcon: Obx(
                    () => controller.searchText.value.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.close,
                              size: 18,
                              color: Color(0xFF71809D),
                            ),
                            onPressed: controller.clearSearch,
                          )
                        : const SizedBox.shrink(),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(SearchScreenController controller) {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        scrollDirection: Axis.horizontal,
        itemCount: controller.filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = controller.filters[index];
          return Obx(() {
            final isSelected = controller.selectedFilter.value == filter;
            return GestureDetector(
              onTap: () => controller.selectFilter(filter),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF1E1B4B)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF1E1B4B)
                        : const Color(0xFFDDE1EF),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  filter.tr,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : const Color(0xFF4338CA),
                  ),
                ),
              ),
            );
          });
        },
      ),
    );
  }

  Widget _buildDefaultSearchContent(SearchScreenController controller) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recent Tools section (if any)
          Obx(() {
            final recent = controller.allToolsController.recentTools;
            if (recent.isEmpty) return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Tools'.tr,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF11152F),
                      ),
                    ),
                    TextButton(
                      onPressed: controller.allToolsController.clearRecentTools,
                      child: Text(
                        'Clear'.tr,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: recent.take(6).map((tool) {
                    return ActionChip(
                      avatar: Icon(tool.icon, size: 16, color: tool.color),
                      label: Text(
                        tool.name.tr,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      onPressed: () => controller.triggerToolAction(tool),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
              ],
            );
          }),

          // Popular / Quick Suggestions Header
          Row(
            children: [
              const Icon(Icons.trending_up, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Popular PDF & AI Tools'.tr,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF11152F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Tools Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: allPlainscanTools.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.3,
            ),
            itemBuilder: (context, index) {
              final tool = allPlainscanTools[index];
              return _buildToolCardCompact(controller, tool);
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSearchResultsList(
    SearchScreenController controller,
    List<ToolModel> results,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 6),
          child: Text(
            '${results.length} tools found'.tr,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            physics: const BouncingScrollPhysics(),
            itemCount: results.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final tool = results[index];
              return _buildToolListTile(controller, tool);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildToolListTile(SearchScreenController controller, ToolModel tool) {
    final isFree = tool.isFree ?? true;
    final formatBadge = (tool.inputFormat != null && tool.outputFormat != null)
        ? '${tool.inputFormat} → ${tool.outputFormat}'
        : tool.outputFormat ?? tool.inputFormat;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => controller.triggerToolAction(tool),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFEEF2F6), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E293B).withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: tool.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  tool.icon,
                  size: 22,
                  color: tool.color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            tool.name.tr,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: isFree
                                ? const Color(0xFFEFF6FF)
                                : const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isFree
                                  ? const Color(0xFFDBEAFE)
                                  : const Color(0xFFFDE68A),
                              width: 0.6,
                            ),
                          ),
                          child: Text(
                            isFree ? 'FREE'.tr : 'PRO'.tr,
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              color: isFree
                                  ? const Color(0xFF2563EB)
                                  : const Color(0xFFD97706),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (tool.description != null &&
                        tool.description!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        tool.description!.tr,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (tool.category != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              tool.category!.tr,
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ),
                        if (formatBadge != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF2FF),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              formatBadge,
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF4338CA),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right,
                size: 20,
                color: Color(0xFFCBD5E1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolCardCompact(SearchScreenController controller, ToolModel tool) {
    final isFree = tool.isFree ?? true;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => controller.triggerToolAction(tool),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFEEF2F6), width: 1.2),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: tool.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(tool.icon, size: 18, color: tool.color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      tool.name.tr,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isFree ? 'FREE'.tr : 'PRO'.tr,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: isFree
                            ? const Color(0xFF2563EB)
                            : const Color(0xFFD97706),
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

  Widget _buildEmptyState(SearchScreenController controller, String query) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off,
                size: 40,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No tools found'.tr,
              style: const TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              query.isNotEmpty
                  ? 'No results matching "$query". Try searching for keywords like "pdf", "word", "compress", or "ocr".'.tr
                  : 'No tools found matching the selected filter.'.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: () {
                controller.clearSearch();
                controller.selectFilter('▦ All');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: Text(
                'Reset Search'.tr,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
