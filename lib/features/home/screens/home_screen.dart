import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:plainscan/core/constants/app_colors.dart';
import 'package:plainscan/core/controllers/scan_controller.dart';
import 'package:plainscan/features/ai/pages/ai_page.dart';
import 'package:plainscan/features/files/pages/files_page.dart';
import 'package:plainscan/features/home/pages/dashboard_page.dart';
import 'package:plainscan/features/profile/pages/profile_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const DashboardPage(),
    const FilesPage(),
    const AiPage(),
     ProfilePage(),
  ];

  bool get _isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  

  Widget _navItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
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
            Expanded(child: _navItem(Icons.home_outlined, 'Home', 0)),
            Expanded(child: _navItem(Icons.folder_outlined, 'Files', 1)),
            
            // Central scan button
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              child: FloatingActionButton(
                onPressed: (){
                  Get.find<ScanController>().openScanner();
                },
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                shape: const CircleBorder(),
                elevation: 4,
                child: const Icon(Icons.document_scanner_outlined, size: 28),
              ),
            ),
            
            Expanded(child: _navItem(Icons.auto_awesome_outlined, 'AI', 2)),
            Expanded(child: _navItem(Icons.person_outline, 'Profile', 3)),
          ],
        ),
      ),
    );
  }
}
