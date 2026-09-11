import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service responsible for managing app permissions on initial install/launch
/// and from system settings.
class AppPermissionService {
  /// Asks for notification permission first when user installs and opens the app.
  static Future<PermissionStatus> requestNotificationPermission() async {
    if (kIsWeb) return PermissionStatus.granted;
    try {
      return await Permission.notification.request();
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
      return PermissionStatus.denied;
    }
  }

  /// Asks for Camera permission AFTER notification permission.
  /// (Photos/storage broad permissions removed to comply with Google Play policy;
  /// document scanning and file picking use system pickers which require no permissions).
  static Future<void> requestCameraAndGalleryPermissions() async {
    if (kIsWeb) return;
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        // Camera permission
        await Permission.camera.request();
      }
    } catch (e) {
      debugPrint('Error requesting camera permission: $e');
    }
  }

  /// Sequentially requests permissions on app open:
  /// 1. Notification permission first.
  /// 2. Camera and Gallery permissions after notification permission.
  static Future<void> requestAppOpenPermissions() async {
    if (kIsWeb) return;
    try {
      // 1. Notification permission first
      await requestNotificationPermission();

      // Brief pause so the OS dialog closes cleanly
      await Future.delayed(const Duration(milliseconds: 350));

      // 2. Camera and Gallery permissions AFTER notification permission
      await requestCameraAndGalleryPermissions();
    } catch (e) {
      debugPrint('Error requesting sequential app open permissions: $e');
    }
  }

  /// Opens the device system settings page for PlainScan so the user
  /// can inspect or manage permissions anytime.
  static Future<void> openSettings() async {
    try {
      await openAppSettings();
    } catch (e) {
      debugPrint('Error opening app settings: $e');
    }
  }
}
