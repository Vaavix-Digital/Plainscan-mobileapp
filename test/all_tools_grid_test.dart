import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:plainscan/core/controllers/alltool_controller.dart';
import 'package:plainscan/features/alltools/all_tools.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Get.reset();
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('AllTools screen renders CustomScrollView with SliverGrid', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      GetMaterialApp(
        home: AllTools(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify CustomScrollView and SliverGrid exist with 3 items per row
    expect(find.byType(CustomScrollView), findsOneWidget);
    expect(find.byType(SliverGrid), findsWidgets);
    final sliverGrid = tester.widget<SliverGrid>(find.byType(SliverGrid).first);
    final delegate = sliverGrid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, 3);

    // Verify category header exists
    expect(find.text('PDF CONVERSION'), findsOneWidget);

    // Verify some tool names appear
    expect(find.text('PDF to Word'), findsOneWidget);
    expect(find.text('Word to PDF'), findsOneWidget);

    // Verify Free and Pro badges appear
    expect(find.text('FREE'), findsWidgets);
  });

  testWidgets('AllTools filters tools by category', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      GetMaterialApp(
        home: AllTools(),
      ),
    );
    await tester.pumpAndSettle();

    final controller = Get.find<AllToolsController>();
    controller.selectFilter('🤖 AI Tools');
    await tester.pumpAndSettle();

    // Now category header should be AI TOOLS
    expect(find.text('AI TOOLS'), findsOneWidget);
    expect(find.text('PDF CONVERSION'), findsNothing);
    expect(find.text('PRO'), findsWidgets);
  });
}
