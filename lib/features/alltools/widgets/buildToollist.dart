import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:plainscan/core/controllers/alltool_controller.dart';
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

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
          itemCount: tools.length,
          itemBuilder: (context, index) {
            final tool = tools[index];
            final currentCategory = tool.category ?? 'Other';
            final previousCategory = index > 0 ? tools[index - 1].category : null;
            final showCategoryHeader = index == 0 || previousCategory != currentCategory;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showCategoryHeader) _buildCategoryHeader(currentCategory),
                _buildToolItem(tool),
              ],
            );
          },
        );
      },
    ),
  );
}

Widget _buildCategoryHeader(String category) {
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

  return Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 8),
    child: Row(
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
      ],
    ),
  );
}

Widget _buildToolItem(ToolModel tool) {
  final isFree = tool.isFree ?? true;
  final formatBadge = (tool.inputFormat != null && tool.outputFormat != null)
      ? '${tool.inputFormat} → ${tool.outputFormat}'
      : tool.outputFormat ?? tool.inputFormat;

  return InkWell(
    onTap: () {
      Get.find<AllToolsController>().recordToolUsage(tool.id);
      Get.to(() => ToolExecutorPage(tool: tool));
    },
    borderRadius: BorderRadius.circular(12),
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEF2F6), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: tool.color.withAlpha(25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              tool.icon,
              size: 20,
              color: tool.color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tool.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                if (formatBadge != null)
                  Text(
                    formatBadge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6366F1),
                    ),
                  )
                else
                  Text(
                    tool.category ?? '',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF64748B),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isFree ? const Color(0xFFEFF6FF) : const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              isFree ? 'FREE' : 'PRO',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: isFree ? const Color(0xFF2563EB) : const Color(0xFFD97706),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

