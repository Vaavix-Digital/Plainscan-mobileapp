import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:plainscan/app/routes.dart';
import 'package:plainscan/core/constants/app_colors.dart';
import 'package:plainscan/core/controllers/profile_controller.dart';
import 'package:plainscan/core/services/permission_service.dart';
import 'package:plainscan/features/home/widgets/notifications_sheet.dart';
import 'package:plainscan/models/tool_model.dart';


class ProfilePage extends StatelessWidget {
  ProfilePage({super.key});

  final ProfileController controller =
      Get.put(ProfileController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: Text(
          'Profile Settings'.tr,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ─────────────────────────────
              // Profile Header
              // ─────────────────────────────

              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                    child: Obx(
                      () => CircleAvatar(
                        radius: 36,
                        backgroundColor: Colors.white,
                        backgroundImage: controller.userPicture.value.isNotEmpty
                            ? NetworkImage(controller.userPicture.value)
                            : null,
                        onBackgroundImageError: controller.userPicture.value.isNotEmpty
                            ? (_, stackTrace) {}
                            : null,
                        child: controller.userPicture.value.isEmpty
                            ? const Icon(
                                Icons.person,
                                color: AppColors.primary,
                                size: 40,
                              )
                            : null,
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  Expanded(
                    child: Obx(
                      () => Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            controller.userName.value,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.text,
                            ),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            controller.userEmail.value,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  Obx(
                    () => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: controller.isPro.value
                            ? const Color(0xFFFEF3C7)
                            : AppColors.amber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: controller.isPro.value
                              ? const Color(0xFFD97706)
                              : AppColors.amber,
                        ),
                      ),
                      child: Text(
                        controller.isPro.value ? 'PRO Account'.tr : 'Free Account'.tr,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: controller.isPro.value
                              ? const Color(0xFFD97706)
                              : AppColors.amber,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ─────────────────────────────
              // Upgrade Promo
              // ─────────────────────────────

              Obx(() => controller.isPro.value ? const SizedBox.shrink() : Column(
                children: [
                  GestureDetector(
                    onTap: controller.showUpgradeBottomSheet,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.purple,
                            AppColors.coral,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color:
                                AppColors.purple.withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: Colors.white,
                            size: 32,
                          ),

                          const SizedBox(width: 16),

                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Upgrade to Premium'.tr,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height: 4),

                                Text(
                                  'Access AI translation, batch editing, and auto-crop accuracy.'.tr,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const Icon(
                            Icons.chevron_right,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              )),

              // Share & Earn 1 Month Free Promo Card
              Obx(() => controller.isPro.value ? const SizedBox.shrink() : GestureDetector(
                onTap: () => Get.toNamed(AppRoutes.referral),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFEF3C7),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.card_giftcard_rounded, color: Color(0xFFD97706), size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Refer & Earn — 50 Credits + 1 Mo Free'.tr,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppColors.text,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Earn 50 credits & 1 month of unlimited PRO when a friend installs PlainScan.'.tr,
                              style: const TextStyle(fontSize: 11, color: AppColors.secondaryText),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.secondaryText),
                    ],
                  ),
                ),
              )),

              const SizedBox(height: 28),

              // ─────────────────────────────
              // Settings
              // ─────────────────────────────

              Text(
                'Settings & Preferences'.tr,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),

              const SizedBox(height: 12),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.border,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: Column(
                    children: [
                    ListTile(
                      leading: const Icon(
                        Icons.notifications_active_outlined,
                        color: AppColors.primary,
                      ),
                      title: Text('Notifications & Alerts'.tr),
                      subtitle: Text('View recent tool activity and update notices'.tr),
                      trailing: const Icon(Icons.chevron_right, color: AppColors.secondaryText),
                      onTap: () => showNotificationsBottomSheet(context),
                    ),

                    const Divider(
                      height: 1,
                      color: AppColors.border,
                    ),

                    Obx(() => controller.isPro.value ? const SizedBox.shrink() : Column(
                      children: [
                        ListTile(
                          leading: const Icon(
                            Icons.workspace_premium_outlined,
                            color: AppColors.primary,
                          ),
                          title: Text('Plans & Pricing'.tr),
                          subtitle: Text('Upgrade to Pro for unlimited AI & OCR'.tr),
                          trailing: const Icon(Icons.chevron_right, color: AppColors.secondaryText),
                          onTap: () => Get.toNamed(AppRoutes.plans),
                        ),
                        const Divider(
                          height: 1,
                          color: AppColors.border,
                        ),
                      ],
                    )),

                    Obx(() => controller.isPro.value ? const SizedBox.shrink() : Column(
                      children: [
                        ListTile(
                          leading: const Icon(
                            Icons.card_giftcard_rounded,
                            color: Color(0xFFD97706),
                          ),
                          title: Text('Share & Get 1 Month Free'.tr),
                          subtitle: Text('Invite friends to get unlimited PRO access'.tr),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFF59E0B)),
                            ),
                            child: Text(
                              'FREE PRO'.tr,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFD97706),
                              ),
                            ),
                          ),
                          onTap: () => Get.toNamed(AppRoutes.referral),
                        ),
                        const Divider(
                          height: 1,
                          color: AppColors.border,
                        ),
                      ],
                    )),


                    ListTile(
                      leading: const Icon(
                        Icons.translate_rounded,
                        color: AppColors.blue,
                      ),
                      title: Text('App Language'.tr),
                      subtitle: Text('Change display and tool language'.tr),
                      trailing: const Icon(Icons.chevron_right, color: AppColors.secondaryText),
                      onTap: () => Get.toNamed(AppRoutes.language, arguments: {'isStandalone': true}),
                    ),

                    const Divider(
                      height: 1,
                      color: AppColors.border,
                    ),

                    ListTile(
                      leading: const Icon(
                        Icons.verified_user_outlined,
                        color: AppColors.primary,
                      ),
                      title: Text('Camera & App Permissions'.tr),
                      subtitle: Text('Manage Camera and Notification access'.tr),
                      trailing: const Icon(Icons.chevron_right, color: AppColors.secondaryText),
                      onTap: () => AppPermissionService.openSettings(),
                    ),

                    const Divider(
                      height: 1,
                      color: AppColors.border,
                    ),

                    ListTile(
                      leading: const Icon(
                        Icons.explore_outlined,
                        color: AppColors.purple,
                      ),
                      title: Text('Welcome Tour & Overview'.tr),
                      subtitle: Text('Explore all ${allPlainscanTools.length}+ tools and features'.tr),
                      trailing: const Icon(Icons.chevron_right, color: AppColors.secondaryText),
                      onTap: () => Get.toNamed(AppRoutes.onboarding, arguments: {'isReplay': true}),
                    ),

                    const Divider(
                      height: 1,
                      color: AppColors.border,
                    ),

                    ListTile(
                      leading: const Icon(
                        Icons.privacy_tip_outlined,
                        color: AppColors.text,
                      ),
                      title: Text('Privacy Policy'.tr),
                      trailing: const Icon(Icons.chevron_right, color: AppColors.secondaryText),
                      onTap: () => Get.toNamed(AppRoutes.privacyPolicy),
                    ),

                    const Divider(
                      height: 1,
                      color: AppColors.border,
                    ),

                    ListTile(
                      leading: const Icon(
                        Icons.description_outlined,
                        color: AppColors.text,
                      ),
                      title: Text('Terms of Service'.tr),
                      trailing: const Icon(Icons.chevron_right, color: AppColors.secondaryText),
                      onTap: () => Get.toNamed(AppRoutes.termsOfService),
                    ),
                  ],
                ),
              ),
              ),

              const SizedBox(height: 24),

              // ─────────────────────────────
              // Logout & Delete Account
              // ─────────────────────────────

              Center(
                child: Column(
                  children: [
                    TextButton.icon(
                      onPressed: controller.logout,
                      icon: const Icon(
                        Icons.logout,
                        color: AppColors.coral,
                      ),
                      label: Text(
                        'Log Out'.tr,
                        style: const TextStyle(
                          color: AppColors.coral,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: controller.deleteAccount,
                      icon: const Icon(
                        Icons.delete_forever,
                        color: Colors.red,
                      ),
                      label: Text(
                        'Delete Account'.tr,
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}