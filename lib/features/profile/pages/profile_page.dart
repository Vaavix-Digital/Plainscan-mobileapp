import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:plainscan/app/routes.dart';
import 'package:plainscan/core/constants/app_colors.dart';
import 'package:plainscan/core/controllers/profile_controller.dart';
import 'package:plainscan/core/services/app_update_service.dart';
import 'package:plainscan/core/services/permission_service.dart';
import 'package:plainscan/features/home/widgets/notifications_sheet.dart';


class ProfilePage extends StatelessWidget {
  ProfilePage({super.key});

  final ProfileController controller =
      Get.put(ProfileController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text(
          'Profile Settings',
          style: TextStyle(
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
                    child: const CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.person,
                        color: AppColors.primary,
                        size: 40,
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
                        controller.isPro.value ? 'PRO Account' : 'Free Account',
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
                            AppColors.purple.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.star,
                        color: Colors.white,
                        size: 32,
                      ),

                      SizedBox(width: 16),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Upgrade to Premium',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            SizedBox(height: 4),

                            Text(
                              'Access AI translation, batch editing, and auto-crop accuracy.',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Icon(
                        Icons.chevron_right,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ─────────────────────────────
              // Progress
              // ─────────────────────────────

              const Text(
                'My Progress',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Scans',
                      '12',
                      Icons.document_scanner,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: _buildStatCard(
                      'OCR Usage',
                      '4/10',
                      Icons.text_fields,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: _buildStatCard(
                      'Shared',
                      '8',
                      Icons.share,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // ─────────────────────────────
              // Settings
              // ─────────────────────────────

              const Text(
                'Settings & Preferences',
                style: TextStyle(
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
                child: Column(
                  children: [

                    // Scan Quality
                    ListTile(
                      leading: const Icon(
                        Icons.image_outlined,
                        color: AppColors.primary,
                      ),
                      title: const Text('Scan Quality'),
                      trailing: const Text(
                        'HD (1080p)',
                        style: TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 13,
                        ),
                      ),
                      onTap: controller.showQualityMessage,
                    ),

                    const Divider(
                      height: 1,
                      color: AppColors.border,
                    ),

                    // Auto Save
                    Obx(
                      () => SwitchListTile(
                        value: controller.autoSave.value,
                        title: const Text(
                          'Auto-Save to Photo Gallery',
                        ),
                        secondary: const Icon(
                          Icons.photo_library_outlined,
                          color: AppColors.blue,
                        ),
                        onChanged:
                            controller.toggleAutoSave,
                      ),
                    ),

                    const Divider(
                      height: 1,
                      color: AppColors.border,
                    ),

                    // Cloud Backup
                    Obx(
                      () => SwitchListTile(
                        value:
                            controller.cloudBackup.value,
                        title: const Text(
                          'Auto Cloud Sync',
                        ),
                        secondary: const Icon(
                          Icons.cloud_sync_outlined,
                          color: AppColors.purple,
                        ),
                        onChanged:
                            controller.toggleCloudBackup,
                      ),
                    ),

                    const Divider(
                      height: 1,
                      color: AppColors.border,
                    ),

                    ListTile(
                      leading: const Icon(
                        Icons.notifications_active_outlined,
                        color: AppColors.primary,
                      ),
                      title: const Text('Notifications & Alerts'),
                      subtitle: const Text('View recent tool activity and update notices'),
                      trailing: const Icon(Icons.chevron_right, color: AppColors.secondaryText),
                      onTap: () => showNotificationsBottomSheet(context),
                    ),

                    const Divider(
                      height: 1,
                      color: AppColors.border,
                    ),

                    ListTile(
                      leading: const Icon(
                        Icons.system_update_rounded,
                        color: Color(0xFF10B981),
                      ),
                      title: const Text('Check for Tool Updates'),
                      subtitle: const Text('Version 1.0.0 (Build 3)'),
                      trailing: const Icon(Icons.chevron_right, color: AppColors.secondaryText),
                      onTap: () => AppUpdateService.showUpdateDialog(isManualCheck: true),
                    ),

                    const Divider(
                      height: 1,
                      color: AppColors.border,
                    ),

                    ListTile(
                      leading: const Icon(
                        Icons.translate_rounded,
                        color: AppColors.blue,
                      ),
                      title: const Text('App Language'),
                      subtitle: const Text('Change display and tool language'),
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
                      title: const Text('Camera & Gallery Permissions'),
                      subtitle: const Text('Manage Camera, Gallery, and Notification access'),
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
                      title: const Text('Welcome Tour & Overview'),
                      subtitle: const Text('Explore all 52+ tools and features'),
                      trailing: const Icon(Icons.chevron_right, color: AppColors.secondaryText),
                      onTap: () => Get.toNamed(AppRoutes.onboarding, arguments: {'isReplay': true}),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ─────────────────────────────
              // Logout
              // ─────────────────────────────

              Center(
                child: TextButton.icon(
                  onPressed: controller.logout,
                  icon: const Icon(
                    Icons.logout,
                    color: AppColors.coral,
                  ),
                  label: const Text(
                    'Log Out',
                    style: TextStyle(
                      color: AppColors.coral,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 16,
        horizontal: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: AppColors.primary,
            size: 20,
          ),

          const SizedBox(height: 8),

          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.text,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}