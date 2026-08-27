import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:plainscan/app/app.dart';
import 'package:plainscan/core/controllers/scan_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Get.put(ScanController(), permanent: true);
  runApp(const PlainScanApp());
}
