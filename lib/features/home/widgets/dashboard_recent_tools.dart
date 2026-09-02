import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:plainscan/core/constants/app_colors.dart';
import 'package:plainscan/core/controllers/dashboard_controller.dart';
import 'package:plainscan/features/alltools/all_tools.dart';

Widget buildDashboardRecentTools() {
  final controller = Get.find<DashboardController>();
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Recent Tools',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          TextButton(
            onPressed: () {
              Get.to(() => AllTools());
            },
            child: const Text(
              'View All Tools',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      Obx(
        () {
          final recentTools = controller.allToolsController.filteredRecentTools;
          if (recentTools.isEmpty) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                vertical: 36,
                horizontal: 20,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.history_outlined,
                    size: 38,
                    color: Color(0xFF94A3B8),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'No recent tools found',
                    style: TextStyle(
                      color: Color(0xFF20243D),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Use any tool to see it appear here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF747A91),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          }

          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recentTools.length,
              separatorBuilder: (context, index) => const Divider(
                height: 1,
                thickness: 0.8,
                color: Color(0xFFF1F3F9),
                indent: 62,
                endIndent: 16,
              ),
              itemBuilder: (context, index) {
                final tool = recentTools[index];
                final isFree = tool.isFree ?? true;

                return InkWell(
                  onTap: () => controller.triggerToolAction(tool),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(index == 0 ? 16 : 0),
                    bottom: Radius.circular(
                      index == recentTools.length - 1 ? 16 : 0,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8EBFA),
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tool.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF20243D),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                tool.category ?? '',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF4C5CE8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E5F5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isFree ? 'FREE' : 'PRO',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF39416D),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.chevron_right,
                          size: 18,
                          color: Color(0xFF94A3B8),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    ],
  );
}
