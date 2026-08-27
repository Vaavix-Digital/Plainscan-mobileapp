import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:plainscan/app/routes.dart';
import 'package:plainscan/app/theme.dart';

class PlainScanApp extends StatelessWidget {
  const PlainScanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'PlainScan',
      theme: appTheme,
      initialRoute: AppRoutes.splash,
      getPages: AppRoutes.pages,
      debugShowCheckedModeBanner: false,
    );
  }
}
