import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:plainscan/app/routes.dart';
import 'package:plainscan/core/controllers/alltool_controller.dart';
import 'package:plainscan/core/controllers/dashboard_controller.dart';
import 'package:plainscan/core/controllers/profile_controller.dart';
import 'package:plainscan/core/controllers/scan_controller.dart';
import 'package:plainscan/features/home/widgets/dashboard_search_bar.dart';
import 'package:plainscan/features/search/screens/search_screen.dart';
import 'package:plainscan/models/tool_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Get.reset();
  });

  testWidgets('Dashboard search bar renders with search icon, no filter icon, and navigates to SearchScreen on tap',
      (WidgetTester tester) async {
    Get.put(ScanController());
    Get.put(ProfileController());
    Get.put(AllToolsController());
    Get.put(DashboardController());

    await tester.pumpWidget(
      GetMaterialApp(
        initialRoute: AppRoutes.home,
        getPages: AppRoutes.pages,
        home: Scaffold(
          body: buildDashboardSearchBar(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify search icon exists
    expect(find.byIcon(Icons.search), findsOneWidget);

    // Verify tune / filter icon does NOT exist
    expect(find.byIcon(Icons.tune), findsNothing);

    // Verify hint text
    expect(find.text('Search ${allPlainscanTools.length}+ PDF tools, AI actions...'), findsOneWidget);

    // Tap on search bar
    await tester.tap(find.text('Search ${allPlainscanTools.length}+ PDF tools, AI actions...'));
    await tester.pumpAndSettle();

    // Verify SearchScreen is open
    expect(find.byType(SearchScreen), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('SearchScreen live filtering and category selection works', (WidgetTester tester) async {
    Get.put(ScanController());
    Get.put(ProfileController());
    Get.put(AllToolsController());

    await tester.pumpWidget(
      const GetMaterialApp(
        home: SearchScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Filter chips exist
    expect(find.text('▦ All'), findsOneWidget);
    expect(find.text('📄 PDF Conversion'), findsOneWidget);
    expect(find.text('🤖 AI Tools'), findsOneWidget);

    // Type query in search field
    await tester.enterText(find.byType(TextField), 'merge');
    await tester.pumpAndSettle();

    // Verify search result contains PDF Merge
    expect(find.text('PDF Merge'), findsWidgets);

    // Clear search using clear button
    expect(find.byIcon(Icons.close), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    // Verify search field is cleared
    expect(find.text('Popular PDF & AI Tools'), findsOneWidget);
  });
}
