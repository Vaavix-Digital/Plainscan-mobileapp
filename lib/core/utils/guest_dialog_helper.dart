import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:plainscan/app/routes.dart';
import 'package:plainscan/core/constants/app_colors.dart';

Future<void> showGuestLoginRequiredDialog({
  BuildContext? context,
  String? toolName,
  bool isScanLimit = false,
}) async {
  final dialogContext = context ?? Get.overlayContext ?? Get.context;
  if (dialogContext == null) return;

  final title = isScanLimit
      ? 'Free Guest Scan Used'.tr
      : (toolName != null
          ? 'Sign In Required for @tool'.trParams({'tool': toolName})
          : 'Sign In Required'.tr);

  final message = isScanLimit
      ? 'You have already used your 1 free guest scan. Please sign in or create an account to unlock unlimited scanning and access all tools.'.tr
      : (toolName != null
          ? '@tool is available for registered accounts. Please sign in or create an account to continue.'.trParams({'tool': toolName})
          : 'Signing in is required to access this tool. Please sign in or create an account to continue.'.tr);

  await showDialog<void>(
    context: dialogContext,
    barrierDismissible: true,
    builder: (ctx) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24),
        actionsPadding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isScanLimit
                    ? AppColors.coral.withValues(alpha: 0.1)
                    : AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isScanLimit ? Icons.lock_clock_rounded : Icons.lock_rounded,
                color: isScanLimit ? AppColors.coral : AppColors.primary,
                size: 26,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
            ),
          ],
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
          child: Text(
            message,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.secondaryText,
              height: 1.45,
            ),
          ),
        ),
        actions: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Get.toNamed(AppRoutes.auth, arguments: {'tab': 0});
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(
                  'Sign In'.tr,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Get.toNamed(AppRoutes.auth, arguments: {'tab': 1});
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'Sign Up'.tr,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  if (Get.currentRoute != AppRoutes.home) {
                    Get.until((route) => route.settings.name == AppRoutes.home || Get.routing.current == AppRoutes.home);
                  }
                },
                child: Text(
                  'Return to Dashboard'.tr,
                  style: const TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    },
  );
}
