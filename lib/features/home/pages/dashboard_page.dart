import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:plainscan/core/constants/app_colors.dart';
import 'package:plainscan/core/controllers/dashboard_controller.dart';
import 'package:plainscan/features/home/widgets/dashboard_ad_banner.dart';
import 'package:plainscan/features/home/widgets/dashboard_carousel_slider.dart';
import 'package:plainscan/features/home/widgets/dashboard_header.dart';
import 'package:plainscan/features/home/widgets/dashboard_quick_tools.dart';
import 'package:plainscan/features/home/widgets/dashboard_recent_tools.dart';
import 'package:plainscan/features/home/widgets/dashboard_search_bar.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(DashboardController());

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildDashboardHeader(),
              const SizedBox(height: 24),
              buildDashboardSearchBar(),
              const SizedBox(height: 24),
              buildDashboardCarouselSlider(),
              buildAdBanner(),
              const SizedBox(height: 28),
              buildDashboardQuickTools(),
              const SizedBox(height: 28),
              buildDashboardRecentTools(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
