import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:plainscan/app/app.dart';
import 'package:plainscan/core/controllers/scan_controller.dart';
import 'package:plainscan/core/services/background_job_service.dart';
import 'package:plainscan/core/services/notification_service.dart';
import 'package:plainscan/core/services/storage_service.dart';
import 'package:plainscan/core/services/iap_service.dart';
import 'package:plainscan/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
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
