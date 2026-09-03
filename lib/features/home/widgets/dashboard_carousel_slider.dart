import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:plainscan/core/constants/app_colors.dart';
import 'package:plainscan/core/controllers/alltool_controller.dart';
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
  final String imagePath;
  final String semanticLabel;
  final VoidCallback onTap;

  const _CarouselSlideItem({
    required this.imagePath,
    required this.semanticLabel,
    required this.onTap,
  });
}

class _DashboardCarouselSliderState extends State<DashboardCarouselSlider> {
  late final PageController _pageController;
  int _currentPage = 0;
  Timer? _autoScrollTimer;
  bool _isUserInteracting = false;

  void _navigateToTool(String toolId, Widget fallback) {
    try {
      final allToolsCtrl = Get.isRegistered<AllToolsController>()
          ? Get.find<AllToolsController>()
          : Get.put(AllToolsController());
      final tool = allToolsCtrl.findToolByIdOrSlug(toolId);
      if (tool != null) {
        Get.to(() => ToolExecutorPage(tool: tool));
      } else {
        Get.to(() => fallback);
      }
    } catch (_) {
      Get.to(() => fallback);
    }
  }

  List<_CarouselSlideItem> _getSlides() {
    return [
      _CarouselSlideItem(
        imagePath: 'assets/image/Slider 1.jpg.jpeg',
        semanticLabel: 'Meet the smarter way to handle documents',
        onTap: () => Get.to(() => AllTools()),
      ),
      _CarouselSlideItem(
        imagePath: 'assets/image/Slider 2.jpg.jpeg',
        semanticLabel: 'Summarize documents with PlainScan AI',
        onTap: () => _navigateToTool('ai-summarize', const AiPage()),
      ),
      _CarouselSlideItem(
        imagePath: 'assets/image/Slider 3.jpg.jpeg',
        semanticLabel: 'Compress large PDF files',
        onTap: () => _navigateToTool('pdf-compress', AllTools()),
      ),
      _CarouselSlideItem(
        imagePath: 'assets/image/Slider 4.jpg.jpeg',
        semanticLabel: '100+ tools in 1 smart workspace',
        onTap: () => Get.to(() => AllTools()),
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
        LayoutBuilder(
          builder: (context, constraints) {
            // Responsive height matching the 1024x500 image aspect ratio
            final double height =
                (constraints.maxWidth * (500 / 1024)).clamp(140.0, 260.0);
            return SizedBox(
              height: height,
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
            );
          },
        ),
        const SizedBox(height: 12),
        _buildIndicators(slides.length),
      ],
    );
  }

  Widget _buildSlideCard(_CarouselSlideItem slide) {
    return Semantics(
      label: slide.semanticLabel,
      button: true,
      child: GestureDetector(
        onTap: slide.onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              slide.imagePath,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: const Color(0xFFF1F5F9),
                  child: const Center(
                    child: Icon(
                      Icons.image_outlined,
                      color: Color(0xFF94A3B8),
                      size: 32,
                    ),
                  ),
                );
              },
            ),
          ),
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
