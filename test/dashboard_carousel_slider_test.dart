import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:plainscan/core/controllers/alltool_controller.dart';
import 'package:plainscan/core/controllers/scan_controller.dart';
import 'package:plainscan/features/home/widgets/dashboard_carousel_slider.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    Get.testMode = true;
    Get.put(AllToolsController());
    Get.put(ScanController());
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('DashboardCarouselSlider renders slide content and indicators',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const GetMaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: DashboardCarouselSlider(),
          ),
        ),
      ),
    );

    // Verify PageView exists
    expect(find.byType(PageView), findsOneWidget);

    // Verify slide images render
    expect(find.byType(Image), findsWidgets);
  });
}
