import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service responsible for managing app permissions on initial install/launch
/// and from system settings.
class AppPermissionService {
  /// Asks system permissions upfront when the user installs and opens the app,
  /// triggering native OS dialogs (e.g. Android 13+ Notification prompt, Camera, Photos).
  static Future<void> requestAppOpenPermissions() async {
    if (kIsWeb) return;
    try {
      // 1. Notification permission (system notification prompt)
      await Permission.notification.request();

      // 2. Camera and media/storage permissions for scanning and importing files
      if (Platform.isAndroid || Platform.isIOS) {
        await [
          Permission.camera,
          Permission.photos,
          Permission.storage,
        ].request();
      }
    } catch (e) {
      debugPrint('Error requesting initial app open permissions: $e');
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
