import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:plainscan/core/controllers/alltool_controller.dart';
import 'package:plainscan/core/controllers/scan_controller.dart';
import 'package:plainscan/features/home/widgets/dashboard_carousel_slider.dart';

void main() {
  setUp(() {
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

    // Verify first slide items render
    expect(find.text('52+ TOOLS · 1 WORKSPACE'), findsOneWidget);
    expect(find.text('Scan, Convert, Redact\n& Ask AI'), findsOneWidget);
    expect(find.text('Explore Tools'), findsOneWidget);

    // Verify PageView exists
    expect(find.byType(PageView), findsOneWidget);
  });
}
