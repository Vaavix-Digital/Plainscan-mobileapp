 import 'package:flutter/material.dart';
import 'package:get/get.dart';

Widget buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: const Icon(
              Icons.arrow_back_ios_new,
              size: 18,
              color: Color(0xFF11152F),
            ),
          ),
          const SizedBox(width: 14),
          const Text(
            'All tools',
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
