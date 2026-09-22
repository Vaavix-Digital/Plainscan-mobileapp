import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:plainscan/app/app.dart';
import 'package:plainscan/core/controllers/scan_controller.dart';
import 'package:plainscan/core/services/background_job_service.dart';
import 'package:plainscan/core/services/notification_service.dart';
import 'package:plainscan/core/services/storage_service.dart';
import 'package:plainscan/core/services/iap_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb && Platform.isIOS) {
    IAPService().init();
  }
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    // MobileAds initialization is now handled in SplashScreen after ATT request
  }
  Get.put(ScanController(), permanent: true);
  Get.put(NotificationService(), permanent: true);
  Get.put(BackgroundJobService(), permanent: true);
  await StorageService.captureReferral();
  final savedLanguage = await StorageService.getLanguage();
  runApp(PlainScanApp(initialLocale: Locale(savedLanguage)));
}
