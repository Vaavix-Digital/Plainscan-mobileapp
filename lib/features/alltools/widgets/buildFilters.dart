import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:plainscan/core/controllers/alltool_controller.dart';

Widget buildFilters() {
  final AllToolsController controller = Get.find<AllToolsController>();
  return SizedBox(
    height: 52,
    child: ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 8,
      ),
      scrollDirection: Axis.horizontal,
      itemCount: controller.filters.length,
      separatorBuilder: (context, index) => const SizedBox(width: 8),
      itemBuilder: (context, index) {
        final filter = controller.filters[index];

        return Obx(
          () {
            final selected = controller.selectedFilter.value == filter;

            return GestureDetector(
              onTap: () => controller.selectFilter(filter),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF1E1B4B)
                      : const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: Text(
                  filter,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : const Color(0xFF4338CA),
                  ),
                ),
              ),
            );
          },
        );
      },
    ),
  );
}