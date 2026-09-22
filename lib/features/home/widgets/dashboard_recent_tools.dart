import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:plainscan/core/constants/app_colors.dart';
import 'package:plainscan/core/controllers/dashboard_controller.dart';
import 'package:plainscan/core/controllers/profile_controller.dart';
import 'package:plainscan/features/alltools/all_tools.dart';

import 'package:plainscan/features/home/screens/home_screen.dart';

Widget buildDashboardRecentTools() {
  final controller = Get.find<DashboardController>();
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Recent Tools'.tr,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          TextButton(
            onPressed: () {
              if (Get.isRegistered<HomeScreenController>()) {
                Get.find<HomeScreenController>().changeTab(1);
              } else {
                Get.to(() => AllTools());
              }
            },
            child: Text(
              'View All'.tr,
              style: const TextStyle(
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
          final profileCtrl = Get.isRegistered<ProfileController>()
              ? Get.find<ProfileController>()
              : Get.put(ProfileController());
          final isProUser = profileCtrl.isPro.value;

          final recentTools = controller.allToolsController.filteredRecentTools;
          if (recentTools.isEmpty) {
            return const _AnimatedEmptyRecentTools();
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
                                tool.name.tr,
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
                                (tool.category ?? '').tr,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF4C5CE8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!isProUser)
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
                              (isFree ? 'FREE' : 'PRO').tr,
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

class _AnimatedEmptyRecentTools extends StatefulWidget {
  const _AnimatedEmptyRecentTools();

  @override
  State<_AnimatedEmptyRecentTools> createState() => _AnimatedEmptyRecentToolsState();
}

class _AnimatedEmptyRecentToolsState extends State<_AnimatedEmptyRecentTools>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.94, end: 1.06).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );

    _pulseAnimation = Tween<double>(begin: 0.15, end: 0.35).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );

    final isTestEnv = !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
    if (isTestEnv) {
      _controller.forward();
    } else {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 32,
        horizontal: 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 64 * _scaleAnimation.value,
                    height: 64 * _scaleAnimation.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withOpacity(_pulseAnimation.value * 0.4),
                    ),
                  ),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFEFF2FE),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.08),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: const Icon(
                        Icons.handyman_outlined,
                        size: 24,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          Text(
            'There is no tool selected'.tr,
            style: const TextStyle(
              color: Color(0xFF20243D),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Select a tool from above to get started'.tr,
            style: const TextStyle(
              color: Color(0xFF8C95A6),
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
