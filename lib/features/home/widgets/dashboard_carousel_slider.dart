import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:plainscan/core/constants/app_colors.dart';
import 'package:plainscan/core/controllers/alltool_controller.dart';
import 'package:plainscan/core/controllers/scan_controller.dart';
import 'package:plainscan/features/ai/pages/ai_page.dart';
import 'package:plainscan/features/alltools/all_tools.dart';
import 'package:plainscan/features/alltools/tool_executor_page.dart';

Widget buildDashboardCarouselSlider() {
  return const DashboardCarouselSlider();
}

class DashboardCarouselSlider extends StatefulWidget {
  const DashboardCarouselSlider({super.key});

  @override
  State<DashboardCarouselSlider> createState() =>
      _DashboardCarouselSliderState();
}

class _CarouselSlideItem {
  final String badge;
  final IconData badgeIcon;
  final String title;
  final String subtitle;
  final String buttonText;
  final IconData buttonIcon;
  final List<Color> gradient;
  final Color accentColor;
  final Color buttonTextColor;
  final IconData bgIcon;
  final VoidCallback onTap;

  const _CarouselSlideItem({
    required this.badge,
    required this.badgeIcon,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.buttonIcon,
    required this.gradient,
    required this.accentColor,
    required this.buttonTextColor,
    required this.bgIcon,
    required this.onTap,
  });
}

class _DashboardCarouselSliderState extends State<DashboardCarouselSlider> {
  late final PageController _pageController;
  int _currentPage = 0;
  Timer? _autoScrollTimer;
  bool _isUserInteracting = false;

  List<_CarouselSlideItem> _getSlides() {
    return [
      _CarouselSlideItem(
        badge: '52+ TOOLS · 1 WORKSPACE',
        badgeIcon: Icons.layers_outlined,
        title: 'Scan, Convert, Redact\n& Ask AI',
        subtitle: 'All document tools in one unified workspace',
        buttonText: 'Explore Tools',
        buttonIcon: Icons.arrow_forward_rounded,
        gradient: const [Color(0xFF131738), Color(0xFF1E2555)],
        accentColor: const Color(0xFF93C5FD),
        buttonTextColor: const Color(0xFF131738),
        bgIcon: Icons.grid_view_rounded,
        onTap: () => Get.to(() => AllTools()),
      ),
      _CarouselSlideItem(
        badge: 'AI-POWERED ASSISTANT',
        badgeIcon: Icons.auto_awesome,
        title: 'Summarize & Chat\nwith Documents',
        subtitle: 'Extract insights, key points & translate fast',
        buttonText: 'Try AI Summarizer',
        buttonIcon: Icons.bolt_rounded,
        gradient: const [Color(0xFF381564), Color(0xFF5B21B6)],
        accentColor: const Color(0xFFDDD6FE),
        buttonTextColor: const Color(0xFF381564),
        bgIcon: Icons.psychology_outlined,
        onTap: () {
          final allToolsCtrl = Get.find<AllToolsController>();
          final tool = allToolsCtrl.findToolByIdOrSlug('ai-summarize');
          if (tool != null) {
            Get.to(() => ToolExecutorPage(tool: tool));
          } else {
            Get.to(() => const AiPage());
          }
        },
      ),
      _CarouselSlideItem(
        badge: 'SMART SCANNER & OCR',
        badgeIcon: Icons.document_scanner_outlined,
        title: 'High-Resolution\nDoc & ID Scanner',
        subtitle: 'Auto-detect borders, crop & extract text',
        buttonText: 'Scan Document',
        buttonIcon: Icons.camera_alt_outlined,
        gradient: const [Color(0xFF064E3B), Color(0xFF0F766E)],
        accentColor: const Color(0xFFA7F3D0),
        buttonTextColor: const Color(0xFF064E3B),
        bgIcon: Icons.document_scanner,
        onTap: () => Get.find<ScanController>().openScanner(),
      ),
      _CarouselSlideItem(
        badge: 'FAST & LOSSLESS',
        badgeIcon: Icons.swap_horiz_rounded,
        title: 'Convert PDF to Word,\nExcel & PPT',
        subtitle: 'Preserve formatting, typography & tables',
        buttonText: 'Convert Files',
        buttonIcon: Icons.transform_rounded,
        gradient: const [Color(0xFF1E3A8A), Color(0xFF2563EB)],
        accentColor: const Color(0xFFBFDBFE),
        buttonTextColor: const Color(0xFF1E3A8A),
        bgIcon: Icons.picture_as_pdf_outlined,
        onTap: () {
          final allToolsCtrl = Get.find<AllToolsController>();
          final tool = allToolsCtrl.findToolByIdOrSlug('pdf-to-word');
          if (tool != null) {
            Get.to(() => ToolExecutorPage(tool: tool));
          } else {
            Get.to(() => AllTools());
          }
        },
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!_isUserInteracting && mounted && _pageController.hasClients) {
        final slidesCount = _getSlides().length;
        final nextPage = (_currentPage + 1) % slidesCount;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slides = _getSlides();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 190,
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollStartNotification) {
                _isUserInteracting = true;
              } else if (notification is ScrollEndNotification) {
                _isUserInteracting = false;
              }
              return false;
            },
            child: PageView.builder(
              controller: _pageController,
              itemCount: slides.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemBuilder: (context, index) {
                final slide = slides[index];
                return _buildSlideCard(slide);
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildIndicators(slides.length),
      ],
    );
  }

  Widget _buildSlideCard(_CarouselSlideItem slide) {
    return GestureDetector(
      onTap: slide.onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2.0),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: slide.gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: slide.gradient.first.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative background icon
            Positioned(
              right: -10,
              bottom: -15,
              child: Opacity(
                opacity: 0.12,
                child: Icon(
                  slide.bgIcon,
                  size: 130,
                  color: Colors.white,
                ),
              ),
            ),

            // Main Content
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Tag / Badge
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            slide.badgeIcon,
                            size: 12,
                            color: slide.accentColor,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            slide.badge,
                            style: TextStyle(
                              color: slide.accentColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Title and Subtitle
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      slide.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      slide.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),

                // Action Button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: slide.onTap,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            slide.buttonText,
                            style: TextStyle(
                              color: slide.buttonTextColor,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Icon(
                            slide.buttonIcon,
                            size: 14,
                            color: slide.buttonTextColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicators(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 20 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : const Color(0xFFCBD5E1),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}
