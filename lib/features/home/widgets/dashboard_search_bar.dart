import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:plainscan/core/constants/app_colors.dart';
import 'package:plainscan/core/controllers/dashboard_controller.dart';

Widget buildDashboardSearchBar() {
  final controller = Get.find<DashboardController>();
  return Container(
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
    child: TextField(
      controller: controller.searchController,
      onChanged: controller.onSearchChanged,
      decoration: InputDecoration(
        hintText: 'Search scans, folders, tools...',
        hintStyle: const TextStyle(color: AppColors.secondaryText),
        prefixIcon: const Icon(
          Icons.search,
          color: AppColors.secondaryText,
        ),
        suffixIcon: Obx(
          () => controller.allToolsController.searchText.value.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: AppColors.secondaryText,
                    size: 20,
                  ),
                  onPressed: controller.clearSearch,
                )
              : const Icon(
                  Icons.tune,
                  color: AppColors.primary,
                ),
        ),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
      ),
    ),
  );
}
