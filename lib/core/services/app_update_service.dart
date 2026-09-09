import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:plainscan/core/constants/app_colors.dart';
import 'package:plainscan/core/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppUpdateService {
  static const String currentVersion = '1.0.0';
  static const int currentBuildNumber = 3;
  static const String latestVersion = '1.1.0';
  static const String _keyDismissedVersion = 'dismissed_update_version';

  /// Check if a newer version of tools or the app is available.
  static Future<bool> isUpdateAvailable() async {
    // In a production backend, this would fetch from an endpoint such as /app/version
    // Compare semantic versioning:
    return _compareVersions(latestVersion, currentVersion) > 0;
  }

  static int _compareVersions(String v1, String v2) {
    final v1Parts = v1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final v2Parts = v2.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    for (int i = 0; i < 3; i++) {
      final p1 = i < v1Parts.length ? v1Parts[i] : 0;
      final p2 = i < v2Parts.length ? v2Parts[i] : 0;
      if (p1 > p2) return 1;
      if (p1 < p2) return -1;
    }
    return 0;
  }

  /// Automatically check and show update prompt if not dismissed.
  static Future<void> checkOnAppStart() async {
    final hasUpdate = await isUpdateAvailable();
    if (!hasUpdate) return;

    final prefs = await SharedPreferences.getInstance();
    final dismissed = prefs.getString(_keyDismissedVersion);
    if (dismissed == latestVersion) {
      // User dismissed this specific version update
      return;
    }

    // Delay slightly to let the UI mount
    Future.delayed(const Duration(seconds: 2), () {
      showUpdateDialog(isManualCheck: false);
    });
  }

  /// Display an update dialog alerting the user that tools and the app have updates.
  static void showUpdateDialog({bool isManualCheck = false}) {
    // Notify in notification center
    if (Get.isRegistered<NotificationService>()) {
      final notifService = NotificationService.to;
      final alreadyNotified = notifService.notifications.any(
        (n) => n.type == NotificationType.appUpdate && n.title.contains(latestVersion),
      );
      if (!alreadyNotified) {
        notifService.addNotification(
          title: 'PlainScan Tools Update Available (v$latestVersion)',
          message: 'New tools and enhancements are ready. Update to get the latest features.',
          type: NotificationType.appUpdate,
          showToast: false,
        );
      }
    }

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(22.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.system_update_rounded,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Update Available',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFDBEAFE)),
                              ),
                              child: const Text(
                                'v$latestVersion Ready',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              '(Current: v$currentVersion)',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                'What\'s new in PlainScan tools:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 8),
              _buildFeatureBullet('New and improved PDF, OCR, and AI conversion tools'),
              _buildFeatureBullet('Automatic file update alerts & overwrite options'),
              _buildFeatureBullet('In-app Notification Center for tool completions'),
              _buildFeatureBullet('Performance boosts and offline file handling fixes'),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString(_keyDismissedVersion, latestVersion);
                        Get.back();
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        side: const BorderSide(color: AppColors.border),
                      ),
                      child: const Text(
                        'Later',
                        style: TextStyle(
                          color: AppColors.secondaryText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                        Get.rawSnackbar(
                          titleText: const Text(
                            'Updating PlainScan',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          messageText: const Text(
                            'PlainScan tools have been updated to the latest release!',
                            style: TextStyle(color: Colors.white),
                          ),
                          backgroundColor: AppColors.primary,
                          snackPosition: SnackPosition.BOTTOM,
                          margin: const EdgeInsets.all(12),
                          borderRadius: 10,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Update Now',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }

  static Widget _buildFeatureBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4.0, right: 8.0),
            child: Icon(
              Icons.check_circle,
              color: Color(0xFF10B981),
              size: 14,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF475569),
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
