 import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:plainscan/core/controllers/alltool_controller.dart';

Widget buildSearchBar() {
  final AllToolsController controller =
      Get.put(AllToolsController());
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFDDE1EF),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: controller.searchController,
          onChanged: controller.updateSearch,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF20243D),
          ),
          decoration: InputDecoration(
            border: InputBorder.none,
            prefixIcon: const Icon(
              Icons.search,
              size: 20,
              color: Color(0xFF71809D),
            ),
            hintText: 'Search tools',
            hintStyle: const TextStyle(
              fontSize: 14,
              color: Color(0xFF71809D),
            ),
            suffixIcon: Obx(
              () => controller.searchText.value.isNotEmpty
                  ? IconButton(
                      onPressed: controller.clearSearch,
                      icon: const Icon(
                        Icons.close,
                        size: 18,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }