import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:plainscan/app/routes.dart';
import 'package:plainscan/core/constants/app_colors.dart';
import 'package:plainscan/core/services/auth_service.dart';
import 'package:plainscan/core/services/storage_service.dart';

class ProfileController extends GetxController {
  final RxString userName = 'User'.obs;
  final RxString userEmail = ''.obs;
  final RxString userPlan = 'free'.obs;
  final RxBool isPro = false.obs;

  final RxBool autoSave = true.obs;
  final RxBool cloudBackup = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadUserProfile();
  }

  Future<void> loadUserProfile() async {
    try {
      final name = await StorageService.getName();
      final email = await StorageService.getEmail();
      final localPlan = await StorageService.getPlan();
      final pro = await StorageService.isProUser();

      userName.value =
          name != null && name.trim().isNotEmpty
              ? name.trim()
              : 'User';

      userEmail.value =
          email != null && email.trim().isNotEmpty
              ? email.trim()
              : 'No email associated';

      userPlan.value = localPlan;
      isPro.value = pro;

      // Sync latest profile/plan from backend
      AuthService.getProfile().then((profile) {
        if (profile != null) {
          final serverPlan = profile['plan_id']?.toString() ?? profile['plan']?.toString() ?? 'free';
          userPlan.value = serverPlan;
          isPro.value = serverPlan.toLowerCase() == 'pro' || serverPlan.toLowerCase().contains('pro');
        }
      });
    } catch (e) {
      debugPrint('Error loading user profile: $e');

      userName.value = 'User';
      userEmail.value = 'No email associated';
    }
  }

  Future<void> upgradeToPro() async {
    isPro.value = true;
    userPlan.value = 'pro';
    await StorageService.savePlan('pro');
  }

  static void showUpgradeSnackbar(String toolName) {
    Get.rawSnackbar(
      messageText: Text(
        '$toolName is a Pro tool. Please upgrade your plan to access it.',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
      mainButton: TextButton(
        onPressed: () {
          if (Get.isSnackbarOpen) {
            Get.closeCurrentSnackbar();
          }
          if (Get.isRegistered<ProfileController>()) {
            Get.find<ProfileController>().showUpgradeBottomSheet();
          } else {
            Get.put(ProfileController()).showUpgradeBottomSheet();
          }
        },
        child: const Text(
          'UPGRADE',
          style: TextStyle(
            color: AppColors.amber,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      backgroundColor: const Color(0xFF1E224F),
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(12),
      borderRadius: 10,
      duration: const Duration(seconds: 4),
    );
  }

  void toggleAutoSave(bool value) {
    autoSave.value = value;
  }

  void toggleCloudBackup(bool value) {
    cloudBackup.value = value;
  }

  void showQualityMessage() {
    Get.snackbar(
      'Scan Quality',
      'Quality defaults to High Definition (HD)',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void showUpgradeBottomSheet() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Unlock PlainScan Premium',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Supercharge your scanning workflow with professional AI capabilities.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.secondaryText,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 24),

            _buildBenefitRow(
              Icons.auto_awesome,
              'Unlimited AI Cleanup & Rescaling',
            ),
            _buildBenefitRow(
              Icons.text_fields,
              'Unlimited OCR Text Extractions',
            ),
            _buildBenefitRow(
              Icons.cloud_upload_outlined,
              '10 GB Secured Cloud Backup',
            ),
            _buildBenefitRow(
              Icons.block_outlined,
              'Ad-Free Premium Interface',
            ),

            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: _buildSubOptionCard(
                    'Monthly',
                    '\$4.99/mo',
                    false,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSubOptionCard(
                    'Yearly (Save 40%)',
                    '\$35.99/yr',
                    true,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: () async {
                await upgradeToPro();
                Get.back();

                Get.rawSnackbar(
                  messageText: const Text(
                    'Congratulations! You have upgraded to PlainScan Pro.',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  backgroundColor: AppColors.primary,
                  snackPosition: SnackPosition.BOTTOM,
                  margin: const EdgeInsets.all(12),
                  borderRadius: 10,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Subscribe Now',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildBenefitRow(
    IconData icon,
    String text,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.primary,
            size: 22,
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.text,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubOptionCard(
    String title,
    String price,
    bool isPopular,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPopular
            ? AppColors.primary.withOpacity(0.04)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPopular
              ? AppColors.primary
              : AppColors.border,
          width: isPopular ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          if (isPopular)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'POPULAR',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

          const SizedBox(height: 4),

          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.secondaryText,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            price,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> logout() async {
    await StorageService.logout();
    Get.offAllNamed(AppRoutes.auth);
  }
}