import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:plainscan/core/controllers/alltool_controller.dart';

Widget buildFilters() {
  final AllToolsController controller =
  Get.put(AllToolsController());
    return SizedBox(
      height: 62,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 10,
        ),
        scrollDirection: Axis.horizontal,
        itemCount: controller.filters.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = controller.filters[index];

          return Obx(
            () {
              final selected =
                  controller.selectedFilter.value == filter;

              return GestureDetector(
                onTap: () =>
                    controller.selectFilter(filter),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFF12152F)
                        : const Color(0xFFE9ECFF),
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    filter,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? Colors.white
                          : const Color(0xFF3E5FEA),
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