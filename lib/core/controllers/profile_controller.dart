import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:plainscan/app/routes.dart';
import 'package:plainscan/core/constants/app_colors.dart';
import 'package:plainscan/core/controllers/plan_controller.dart';
import 'package:plainscan/core/services/auth_service.dart';
import 'package:plainscan/core/services/plan_service.dart';
import 'package:plainscan/core/services/storage_service.dart';
import 'package:plainscan/models/plan_model.dart';
import 'package:plainscan/core/services/referral_service.dart';

class ProfileController extends GetxController {
  final RxString userName = 'User'.obs;
  final RxString userEmail = ''.obs;
  final RxString userPlan = 'free'.obs;
  final RxBool isPro = false.obs;
  final RxInt userCredits = 250.obs;

  final RxBool autoSave = true.obs;
  final RxBool cloudBackup = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadUserProfile();
  }

  Future<void> refreshCredits() async {
    userCredits.value = await StorageService.getUserCredits();
  }

  Future<void> loadUserProfile() async {
    try {
      final name = await StorageService.getName();
      final email = await StorageService.getEmail();
      final localPlan = await StorageService.getPlan();
      final pro = await StorageService.isProUser();
      final credits = await StorageService.getUserCredits();

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
      userCredits.value = credits;

      // Sync latest profile/plan from backend
      AuthService.getProfile().then((profile) {
        if (profile != null) {
          final serverPlan = profile['plan_id']?.toString() ?? profile['plan']?.toString() ?? 'free';
          userPlan.value = serverPlan;
          isPro.value = serverPlan.toLowerCase() == 'pro' || serverPlan.toLowerCase().contains('pro');
        }
      });

      // Sync active plan directly via GET /plans/current
      PlanService.getCurrentPlan().then((plan) {
        if (plan != null) {
          userPlan.value = plan.planId;
          isPro.value = plan.planId.toLowerCase() == 'pro' || plan.planId.toLowerCase() == 'teams';
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

  Future<void> shareApp() async {
    await ReferralService.shareReferral();
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
    final planCtrl = Get.isRegistered<PlanController>()
        ? Get.find<PlanController>()
        : Get.put(PlanController());

    if (planCtrl.plans.isEmpty) {
      planCtrl.loadPlansData();
    }

    Get.bottomSheet(
      Container(
        constraints: BoxConstraints(
          maxHeight: Get.height * 0.88,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        child: Obx(() {
          final proPlan = planCtrl.plans.firstWhereOrNull(
                (p) => p.planId.toLowerCase() == 'pro',
              ) ??
              PlanModel(
                planId: 'pro',
                name: 'Pro',
                description: 'For power users and professionals',
                priceMonthly: 764.0,
                priceYearly: 4584.0,
                monthlyEquivalentYearly: 382.0,
                currencySymbol: '₹',
                currency: 'INR',
                features: [
                  'Unlimited documents per day',
                  'Unlimited file size',
                  'All PDF & media tools',
                  'Full AI-powered features',
                  '3,000 AI Credits / month',
                  'Priority processing speed',
                  'No ads',
                  'Email notifications',
                ],
                isPopular: true,
                order: 2,
                ctaLabel: 'Upgrade to Pro',
              );

          final symbol = proPlan.currencySymbol;
          final monthlyPriceStr =
              '$symbol${proPlan.priceMonthly % 1 == 0 ? proPlan.priceMonthly.toInt() : proPlan.priceMonthly}/mo';
          final yearlyPriceStr =
              '$symbol${proPlan.priceYearly % 1 == 0 ? proPlan.priceYearly.toInt() : proPlan.priceYearly}/yr';
          final isYearly = planCtrl.isYearly.value;
          final discountStr = proPlan.savingsPercentage > 0
              ? 'Save ${proPlan.savingsPercentage}%'
              : 'Save 40%';

          final featuresToDisplay = proPlan.features.isNotEmpty
              ? proPlan.features
              : [
                  'Unlimited documents per day',
                  'Unlimited file size',
                  'All PDF & media tools',
                  'Full AI-powered features',
                  '3,000 AI Credits / month',
                  'Priority processing speed',
                  'No ads',
                  'Email notifications',
                ];

          return SingleChildScrollView(
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

                const SizedBox(height: 18),

                const Text(
                  'Unlock PlainScan Pro',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  'For power users and professionals. Supercharge your scanning workflow.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 18),

                ...featuresToDisplay.map(
                  (text) => _buildBenefitRow(Icons.check_circle_rounded, text),
                ),

                const SizedBox(height: 18),

              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => planCtrl.toggleBilling(false),
                      child: _buildSubOptionCard(
                        'Monthly',
                        monthlyPriceStr,
                        false,
                        isSelected: !isYearly,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => planCtrl.toggleBilling(true),
                      child: _buildSubOptionCard(
                        'Yearly ($discountStr)',
                        yearlyPriceStr,
                        true,
                        isSelected: isYearly,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () async {
                  Get.back();
                  await planCtrl.subscribeToPlan(proPlan);
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
                child: Text(
                  'Subscribe to Pro (${isYearly ? yearlyPriceStr : monthlyPriceStr})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              Center(
                child: TextButton(
                  onPressed: () {
                    Get.back();
                    Get.toNamed(AppRoutes.plans);
                  },
                  child: const Text(
                    'Compare All Plans & Features',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),

              Row(
                children: [
                  const Expanded(child: Divider(color: AppColors.border)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'OR GET IT FREE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider(color: AppColors.border)),
                ],
              ),

              const SizedBox(height: 12),

              OutlinedButton.icon(
                onPressed: () {
                  Get.back();
                  Get.toNamed(AppRoutes.referral);
                },
                icon: const Icon(Icons.card_giftcard_rounded, color: AppColors.primary),
                label: const Text(
                  'Share App & Get 1 Month Free Pro',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),

              const SizedBox(height: 10),
            ],
          ),
        );
      }),
    ),
      isScrollControlled: true,
    );
  }

  Widget _buildBenefitRow(
    IconData icon,
    String text,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubOptionCard(
    String title,
    String price,
    bool isPopular, {
    bool isSelected = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.06)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? AppColors.primary
              : AppColors.border,
          width: isSelected ? 2 : 1,
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
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? AppColors.primary : AppColors.secondaryText,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            price,
            style: const TextStyle(
              fontSize: 16,
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