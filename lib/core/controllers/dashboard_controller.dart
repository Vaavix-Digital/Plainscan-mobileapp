import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:plainscan/core/constants/app_colors.dart';
import 'package:plainscan/core/controllers/alltool_controller.dart';
import 'package:plainscan/core/controllers/profile_controller.dart';
import 'package:plainscan/core/controllers/scan_controller.dart';
import 'package:plainscan/core/services/referral_service.dart';
import 'package:plainscan/features/alltools/tool_executor_page.dart';
import 'package:plainscan/models/tool_model.dart';

class DashboardController extends GetxController {
  final searchController = TextEditingController();
  final ProfileController profileController = Get.find<ProfileController>();
  final AllToolsController allToolsController = Get.put(AllToolsController());

  // Referral state for Dashboard "Refer a Friend" box
  final Rx<ReferralInfo?> referralInfo = Rx<ReferralInfo?>(null);
  final RxBool isLoadingReferral = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadReferralData();
  }

  Future<void> loadReferralData() async {
    isLoadingReferral.value = true;
    try {
      final info = await ReferralService.getMyReferralCode();
      referralInfo.value = info;
    } catch (e) {
      debugPrint('Error loading dashboard referral data: $e');
      referralInfo.value ??= ReferralInfo.mockDefault;
    } finally {
      isLoadingReferral.value = false;
    }
  }

  void copyInviteLink() {
    final link = referralInfo.value?.inviteLink ?? 'https://plainscan.com/login?ref=${referralInfo.value?.referralCode ?? 'XYZ987'}';
    Clipboard.setData(ClipboardData(text: link));
    Get.rawSnackbar(
      messageText: Row(
        children: [
          const Icon(Icons.link, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Invite link copied to clipboard: $link',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      backgroundColor: AppColors.primary,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(12),
      borderRadius: 8,
      duration: const Duration(seconds: 3),
    );
  }

  void copyReferralCode() {
    final code = referralInfo.value?.referralCode ?? 'XYZ987';
    Clipboard.setData(ClipboardData(text: code));
    Get.rawSnackbar(
      messageText: Text(
        'Referral code "$code" copied to clipboard!',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
      backgroundColor: AppColors.primary,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(12),
      borderRadius: 8,
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> shareInviteLink() async {
    final code = referralInfo.value?.referralCode ?? 'XYZ987';
    final link = referralInfo.value?.inviteLink ?? 'https://plainscan.com/login?ref=$code';
    await ReferralService.shareReferral(
      referralCode: code,
      shareLink: link,
    );
  }

  final List<ToolModel> quickTools = const [
    ToolModel(
      id: 'scan-ocr',
      slug: 'scan-ocr',
      name: 'Scan & OCR',
      icon: Icons.document_scanner_outlined,
      color: AppColors.primary,
      categoryId: 'ocr',
      category: 'OCR / Scan Tools',
      inputFormat: '.pdf / image',
      outputFormat: '.txt',
      isFree: true,
    ),
    ToolModel(
      id: 'pdf-to-word',
      slug: 'pdf-to-word',
      name: 'PDF to Word',
      icon: Icons.description_outlined,
      color: AppColors.amber,
      categoryId: 'conversion',
      category: 'PDF Conversion',
      inputFormat: '.pdf',
      outputFormat: '.docx',
      isFree: true,
    ),
    ToolModel(
      id: 'pdf-merge',
      slug: 'pdf-merge',
      name: 'Merge PDF',
      icon: Icons.merge_type_outlined,
      color: AppColors.purple,
      categoryId: 'manipulation',
      category: 'PDF Manipulation',
      inputFormat: 'Multiple .pdf',
      outputFormat: '.pdf',
      isMultiFile: true,
      isFree: true,
    ),
    ToolModel(
      id: 'pdf-compress',
      slug: 'pdf-compress',
      name: 'Compress PDF',
      icon: Icons.compress_outlined,
      color: Color(0xFF10B981),
      categoryId: 'manipulation',
      category: 'PDF Manipulation',
      inputFormat: '.pdf',
      outputFormat: '.pdf',
      isFree: true,
    ),
    ToolModel(
      id: 'pdf-sign',
      slug: 'pdf-sign',
      name: 'Sign PDF',
      icon: Icons.draw_outlined,
      color: Color(0xFFEC4899),
      categoryId: 'manipulation',
      category: 'PDF Manipulation',
      inputFormat: '.pdf',
      outputFormat: '.pdf',
      isFree: true,
    ),
    ToolModel(
      id: 'ai-summarize',
      slug: 'ai-summarize',
      name: 'AI Summarize',
      icon: Icons.summarize_outlined,
      color: Color(0xFF6366F1),
      categoryId: 'ai',
      category: 'AI Tools',
      inputFormat: '.pdf / text',
      outputFormat: '.txt',
      isTextAllowed: true,
      isFree: false,
    ),
  ];

  void triggerToolAction(ToolModel tool) {
    allToolsController.recordToolUsage(tool.id);

    final isFree = tool.isFree ?? true;
    if (!isFree && !profileController.isPro.value) {
      ProfileController.showUpgradeSnackbar(tool.name);
      return;
    }

    if (tool.id == 'doc_scan' || tool.id == 'id_scan') {
      Get.find<ScanController>().openScanner();
    } else {
      Get.to(() => ToolExecutorPage(tool: tool));
    }
  }

  void onSearchChanged(String value) {
    allToolsController.updateSearch(value);
  }

  void clearSearch() {
    searchController.clear();
    allToolsController.clearSearch();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}
