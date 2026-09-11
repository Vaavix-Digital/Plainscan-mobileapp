import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:plainscan/core/constants/app_colors.dart';
import 'package:plainscan/core/controllers/scan_controller.dart';
import 'package:plainscan/features/ai/pages/ai_page.dart';
import 'package:plainscan/features/alltools/all_tools.dart';
import 'package:plainscan/features/home/pages/dashboard_page.dart';
import 'package:plainscan/features/profile/pages/profile_page.dart';

class HomeScreenController extends GetxController {
  final RxInt currentIndex = 0.obs;

  void changeTab(int index) {
    currentIndex.value = index;
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Widget _navItem(HomeScreenController controller, IconData icon, String label, int index) {
    return Obx(() {
      final isSelected = controller.currentIndex.value == index;
      return GestureDetector(
        onTap: () {
          controller.changeTab(index);
        },
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? AppColors.primary : AppColors.secondaryText,
                size: 24,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? AppColors.primary : AppColors.secondaryText,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<HomeScreenController>()
        ? Get.find<HomeScreenController>()
        : Get.put(HomeScreenController());

    final List<Widget> pages = [
      const DashboardPage(),
      AllTools(showBackButton: false),
      const AiPage(),
      ProfilePage(),
    ];

    return Scaffold(
      body: Obx(
        () => IndexedStack(
          index: controller.currentIndex.value,
          children: pages,
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: AppColors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 12,
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        height: 70,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(child: _navItem(controller, Icons.home_outlined, 'Home', 0)),
            Expanded(child: _navItem(controller, Icons.grid_view_outlined, 'Tools', 1)),
            
            // Central scan button
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              child: FloatingActionButton(
                onPressed: () {
                  Get.find<ScanController>().openScanner();
                },
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                shape: const CircleBorder(),
                elevation: 4,
                child: const Icon(Icons.document_scanner_outlined, size: 28),
              ),
            ),
            
            Expanded(child: _navItem(controller, Icons.auto_awesome_outlined, 'AI', 2)),
            Expanded(child: _navItem(controller, Icons.person_outline, 'Profile', 3)),
          ],
        ),
      ),
    );
  }
}
