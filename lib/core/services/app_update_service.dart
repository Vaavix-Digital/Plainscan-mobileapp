import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:plainscan/core/constants/app_colors.dart';
import 'package:plainscan/core/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:upgrader/upgrader.dart';
import 'package:url_launcher/url_launcher.dart';

class AppUpdateService {
  static String? _cachedLatestVersion;
  static const String _keyDismissedVersion = 'dismissed_update_version';
  static const String defaultPackageName = 'com.plainscan.app';

  /// Dynamically reads the app's actual installed version from PackageInfo (including build number e.g. 1.0.0+22)
  static Future<String>    getCurrentVersion({bool includeBuildNumber = true}) async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (info.version.isNotEmpty) {
        if (includeBuildNumber && info.buildNumber.isNotEmpty) {
          return '${info.version}+${info.buildNumber}';
        }
        return info.version;
      }
    } catch (e) {
      debugPrint('Error reading installed app version from PackageInfo: $e');
    }
    return includeBuildNumber ? '1.0.0+22' : '1.0.0';
  }

  /// Dynamically fetches the latest version from Play Store (Android) or App Store (iOS)
  static Future<String?> getLatestVersionFromStore() async {
    if (_cachedLatestVersion != null) return _cachedLatestVersion;

    try {
      final info = await PackageInfo.fromPlatform();
      final packageName = info.packageName.isNotEmpty ? info.packageName : defaultPackageName;

      // 1. Try upgrader store lookup
      final upgrader = Upgrader();
      await upgrader.initialize();
      final storeVersion = upgrader.currentAppStoreVersion;

      if (storeVersion != null && storeVersion.isNotEmpty) {
        _cachedLatestVersion = storeVersion;
        return storeVersion;
      }

      // 2. Fallback Play Store scraping lookup on Android
      if (!kIsWeb && Platform.isAndroid) {
        final scrapedVer = await _fetchPlayStoreVersionScrape(packageName);
        if (scrapedVer != null && scrapedVer.isNotEmpty) {
          _cachedLatestVersion = scrapedVer;
          return scrapedVer;
        }
      }
    } catch (e) {
      debugPrint('Error fetching latest version from Play Store: $e');
    }

    return _cachedLatestVersion;
  }

  static Future<String?> _fetchPlayStoreVersionScrape(String packageName) async {
    try {
      final url = Uri.parse('https://play.google.com/store/apps/details?id=$packageName&hl=en');
      final response = await http.get(url, headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
      }).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final regExp = RegExp(r'\[\[\["([0-9]+\.[0-9]+\.[0-9]+)"\]\]');
        final match = regExp.firstMatch(response.body);
        if (match != null && match.groupCount >= 1) {
          return match.group(1);
        }

        final metaRegExp = RegExp(r'itemprop="softwareVersion">([0-9]+\.[0-9]+\.[0-9]+)');
        final metaMatch = metaRegExp.firstMatch(response.body);
        if (metaMatch != null && metaMatch.groupCount >= 1) {
          return metaMatch.group(1);
        }
      }
    } catch (e) {
      debugPrint('Error scraping Play Store version: $e');
    }
    return null;
  }

  /// Check if a newer version of tools or the app is available.
  static Future<bool> isUpdateAvailable() async {
    final current = await getCurrentVersion();
    final latest = await getLatestVersionFromStore() ?? '1.1.0';
    return _compareVersions(latest, current) > 0;
  }

  static int _compareVersions(String v1, String v2) {
    final cleanV1 = v1.split('+').first.trim();
    final cleanV2 = v2.split('+').first.trim();
    final v1Parts = cleanV1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final v2Parts = cleanV2.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    for (int i = 0; i < 3; i++) {
      final p1 = i < v1Parts.length ? v1Parts[i] : 0;
      final p2 = i < v2Parts.length ? v2Parts[i] : 0;
      if (p1 > p2) return 1;
      if (p1 < p2) return -1;
    }
    return 0;
  }

  /// Automatically check and show update prompt immediately on app startup.
  static Future<void> checkOnAppStart({bool ignoreDismissed = false}) async {
    final current = await getCurrentVersion();
    final latest = await getLatestVersionFromStore() ?? '1.1.0';
    
    // ignore: avoid_print
    print(
      '\n=================== PLAINSCAN VERSION INFO ===================\n'
      'Current App Version : $current\n'
      'Latest Store Version: $latest\n'
      '==============================================================\n',
    );

    final hasUpdate = _compareVersions(latest, current) > 0;
    if (!hasUpdate) return;

    if (!ignoreDismissed) {
      final prefs = await SharedPreferences.getInstance();
      final dismissed = prefs.getString(_keyDismissedVersion);
      if (dismissed == latest) {
        return;
      }
    }

    // Small delay to ensure the widget tree and navigator are ready
    Future.delayed(const Duration(milliseconds: 300), () {
      if (Get.context != null && !(Get.isDialogOpen ?? false)) {
        showUpdateDialog(
          isManualCheck: false,
          currentVersion: current,
          latestVersion: latest,
        );
      }
    });
  }

  /// Display an update dialog matching the exact design spec.
  static Future<void> showUpdateDialog({
    bool isManualCheck = false,
    String? currentVersion,
    String? latestVersion,
  }) async {
    final currentVer = currentVersion ?? await getCurrentVersion();
    final latestVer = latestVersion ?? (await getLatestVersionFromStore()) ?? '1.1.0';

    if (Get.isRegistered<NotificationService>()) {
      final notifService = NotificationService.to;
      final alreadyNotified = notifService.notifications.any(
        (n) => n.type == NotificationType.appUpdate && n.title.contains(latestVer),
      );
      if (!alreadyNotified) {
        notifService.addNotification(
          title: 'PlainScan Tools Update Available (v$latestVer)',
          message: 'New tools and enhancements are ready. Update to get the latest features.',
          type: NotificationType.appUpdate,
          showToast: false,
        );
      }
    }

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFECE6F0),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.phonelink_setup_rounded,
                        color: AppColors.primary,
                        size: 26,
                      ),
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
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFDBEAFE)),
                              ),
                              child: Text(
                                'v$latestVer Ready',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '(Current: v$currentVer)',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'What\'s new in PlainScan tools:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 12),
              _buildFeatureBullet('New and improved PDF, OCR, and AI conversion tools'),
              _buildFeatureBullet('Automatic file update alerts & overwrite options'),
              _buildFeatureBullet('In-app Notification Center for tool completions'),
              _buildFeatureBullet('Performance boosts and offline file handling fixes'),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString(_keyDismissedVersion, latestVer);
                        Get.back();
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Later',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Get.back();
                        String pkg = defaultPackageName;
                        try {
                          final info = await PackageInfo.fromPlatform();
                          if (info.packageName.isNotEmpty) {
                            pkg = info.packageName;
                          }
                        } catch (_) {}
                        final playStoreUrl = 'market://details?id=$pkg';
                        final webPlayStoreUrl =
                            'https://play.google.com/store/apps/details?id=$pkg';
                        final uri = Uri.parse(playStoreUrl);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        } else {
                          await launchUrl(
                            Uri.parse(webPlayStoreUrl),
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Update Now',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
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
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2.0, right: 10.0),
            child: Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF10B981),
              size: 18,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF475569),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
