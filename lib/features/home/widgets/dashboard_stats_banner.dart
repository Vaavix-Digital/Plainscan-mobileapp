import 'package:flutter/material.dart';

Widget buildDashboardStatsBanner() {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 14,
    ),
    decoration: BoxDecoration(
      color: const Color(0xFF171A3D),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '28 TOOLS · 1 WORKSPACE',
          style: TextStyle(
            color: Colors.blue.shade200,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Scan, convert, redact &\nask AI – no other app\ninstalled',
          style: TextStyle(
            color: Colors.white,
            fontSize: 23,
            height: 1.25,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}
