import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:plainscan/core/controllers/alltool_controller.dart';
import 'package:plainscan/core/controllers/profile_controller.dart';
import 'package:plainscan/features/alltools/tool_executor_page.dart';
import 'package:plainscan/models/tool_model.dart';

Widget buildToolList() {
  final AllToolsController controller = Get.find<AllToolsController>();
  return Expanded(
    child: Obx(
      () {
        final tools = controller.filteredTools;

        if (tools.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 48, color: Color(0xFF94A3B8)),
                  SizedBox(height: 12),
                  Text(
                    'No tools found matching your search',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Group tools by category
        final Map<String, List<ToolModel>> groupedTools = {};
        for (final tool in tools) {
          final cat = tool.category ?? 'Other';
          groupedTools.putIfAbsent(cat, () => []).add(tool);
        }

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            for (final entry in groupedTools.entries) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                  child: _buildCategoryHeader(entry.key, entry.value.length),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.78,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildToolGridCard(entry.value[index]),
                    childCount: entry.value.length,
                  ),
                ),
              ),
            ],
            const SliverToBoxAdapter(
              child: SizedBox(height: 32),
            ),
          ],
        );
      },
    ),
  );
}

Widget _buildCategoryHeader(String category, [int? count]) {
  String icon = '≡';
  String title = category.toUpperCase();

  if (category.contains('Conversion')) {
    icon = '📄';
    title = 'PDF CONVERSION';
  } else if (category.contains('Manipulation') || category.contains('editing')) {
    icon = '🛠️';
    title = 'PDF MANIPULATION';
  } else if (category.contains('OCR') || category.contains('Scan')) {
    icon = '🔍';
    title = 'OCR & SCAN TOOLS';
  } else if (category.contains('AI')) {
    icon = '🤖';
    title = 'AI TOOLS';
  } else if (category.contains('Utility')) {
    icon = '📦';
    title = 'UTILITY TOOLS';
  }

  return Row(
    children: [
      Text(
        icon,
        style: const TextStyle(fontSize: 14),
      ),
      const SizedBox(width: 8),
      Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          letterSpacing: 1.1,
          fontWeight: FontWeight.w700,
          color: Color(0xFF4338CA),
        ),
      ),
      if (count != null) ...[
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0xFF4338CA),
            ),
          ),
        ),
      ],
    ],
  );
}

Widget _buildToolGridCard(ToolModel tool) {
  final isFree = tool.isFree ?? true;
  final formatBadge = (tool.inputFormat != null && tool.outputFormat != null)
      ? '${tool.inputFormat} → ${tool.outputFormat}'
      : tool.outputFormat ?? tool.inputFormat;

  return Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(14),
    elevation: 0,
    child: InkWell(
      onTap: () {
        Get.find<AllToolsController>().recordToolUsage(tool.id);

        if (!isFree) {
          final profileCtrl = Get.isRegistered<ProfileController>()
              ? Get.find<ProfileController>()
              : Get.put(ProfileController());
          if (!profileCtrl.isPro.value) {
            ProfileController.showUpgradeSnackbar(tool.name);
            return;
          }
        }

        Get.to(() => ToolExecutorPage(tool: tool));
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
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
        child: Stack(
          children: [
            // Center content: Icon, Title, Subtitle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: tool.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      tool.icon,
                      size: 20,
                      color: tool.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tool.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    formatBadge ?? tool.category ?? '',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w500,
                      color: formatBadge != null
                          ? const Color(0xFF6366F1)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            // Top Right: FREE / PRO badge
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isFree ? const Color(0xFFEFF6FF) : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isFree ? const Color(0xFFDBEAFE) : const Color(0xFFFDE68A),
                    width: 0.6,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isFree) ...[
                      const Icon(
                        Icons.workspace_premium_rounded,
                        size: 8,
                        color: Color(0xFFD97706),
                      ),
                      const SizedBox(width: 1.5),
                    ],
                    Text(
                      isFree ? 'FREE' : 'PRO',
                      style: TextStyle(
                        fontSize: 7.5,
                        fontWeight: FontWeight.w800,
                        color: isFree ? const Color(0xFF2563EB) : const Color(0xFFD97706),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
