import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:plainscan/core/controllers/alltool_controller.dart';
import 'package:plainscan/models/tool_model.dart';

Widget buildToolList() {
  final AllToolsController controller =
  Get.put(AllToolsController());
    return Expanded(
      child: Obx(
        () {
          final tools = controller.filteredTools;

          if (tools.isEmpty) {
            return const Center(
              child: Text(
                'No tools found',
                style: TextStyle(
                  color: Color(0xFF747A91),
                  fontSize: 14,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(
              20,
              4,
              20,
              30,
            ),
            itemCount: tools.length,
            itemBuilder: (context, index) {
              final tool = tools[index];

              final currentCategory =
                  tool.category ?? 'Other';

              final previousCategory = index > 0
                  ? tools[index - 1].category
                  : null;

              final showCategoryHeader =
                  index == 0 ||
                  previousCategory != currentCategory;

              return Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  if (showCategoryHeader)
                    _buildCategoryHeader(
                      currentCategory,
                    ),
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

  if (category == 'Core daily drivers') {
    icon = 'ϟ';
    title = 'CORE  DAILY DRIVERS';
  } else if (category == 'High intent conversions') {
    icon = '☷';
    title = 'HIGH-INTENT CONVERSIONS';
  } else if (category == 'PDF editing') {
    icon = '✎';
    title = 'PDF EDITING';
  } else if (category == 'OCR') {
    icon = '⌕';
    title = 'OCR';
  } else if (category == 'AI tools') {
    icon = '✦';
    title = 'AI TOOLS';
  } else if (category == 'Image tools') {
    icon = '▧';
    title = 'IMAGE TOOLS';
  }

  return Padding(
    padding: const EdgeInsets.only(
      top: 12,
      bottom: 8,
    ),
    child: Row(
      children: [
        Text(
          icon,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4D5EEA),
          ),
        ),
        const SizedBox(width: 7),
        Text(
          title,
          style: const TextStyle(
            fontSize: 10,
            letterSpacing: 1.1,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4658E5),
          ),
        ),
      ],
    ),
  );
}

  Widget _buildToolItem(ToolModel tool) {
    final isFree = tool.isFree ?? true;

    return Container(
      height: 55,
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFDCE0EB),
            width: .8,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFE8EBFA),
              borderRadius:
                  BorderRadius.circular(10),
            ),
            child: Icon(
              tool.icon,
              size: 18,
              color: tool.color,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  tool.name,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF20243D),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  tool.category ?? '',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF4C5CE8),
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFE2E5F5),
              borderRadius:
                  BorderRadius.circular(10),
            ),
            child: Text(
              isFree ? 'FREE' : 'PRO',
              style: const TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: Color(0xFF39416D),
              ),
            ),
          ),
        ],
      ),
    );
  }
