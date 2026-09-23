import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:plainscan/app/routes.dart';
import 'package:plainscan/core/constants/app_colors.dart';
import 'package:plainscan/models/tool_model.dart';

Widget buildDashboardSearchBar() {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: () => Get.toNamed(AppRoutes.search),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(
          children: [
            const Icon(
              Icons.search,
              color: AppColors.secondaryText,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Search ${allPlainscanTools.length}+ PDF tools, AI actions...'.tr,
                style: const TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
