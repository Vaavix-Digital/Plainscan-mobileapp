 import 'package:flutter/material.dart';
import 'package:get/get.dart';

Widget buildHeader({bool showBack = true}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
      child: Row(
        children: [
          if (showBack) ...[
            GestureDetector(
              onTap: () => Get.back(),
              child: const Icon(
                Icons.arrow_back_ios_new,
                size: 18,
                color: Color(0xFF11152F),
              ),
            ),
            const SizedBox(width: 14),
          ],
          const Text(
            'All Tools',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF11152F),
            ),
          ),
        ],
      ),
    );
  }
