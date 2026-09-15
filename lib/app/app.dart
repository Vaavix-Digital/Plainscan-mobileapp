import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:plainscan/app/routes.dart';
import 'package:plainscan/app/theme.dart';
import 'package:plainscan/core/localization/app_translations.dart';

class PlainScanApp extends StatelessWidget {
  final Locale? initialLocale;
  const PlainScanApp({super.key, this.initialLocale});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'PlainScan',
      theme: appTheme,
      initialRoute: AppRoutes.splash,
      getPages: AppRoutes.pages,
      translations: AppTranslations(),
      locale: initialLocale ?? const Locale('en'),
      fallbackLocale: const Locale('en'),
      debugShowCheckedModeBanner: false,
    );
  }
}

