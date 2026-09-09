import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:plainscan/app/routes.dart';
import 'package:plainscan/core/constants/app_colors.dart';
import 'package:plainscan/core/services/storage_service.dart';

class ConsentPermissionsScreen extends StatefulWidget {
  final bool isStandalone;
  const ConsentPermissionsScreen({super.key, this.isStandalone = false});

  @override
  State<ConsentPermissionsScreen> createState() => _ConsentPermissionsScreenState();
}

class _ConsentPermissionsScreenState extends State<ConsentPermissionsScreen> {
  late bool _isStandalone;
  bool _isCameraGranted = false;
  bool _isPhotosGranted = false;
  bool _isNotificationsGranted = false;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    if (args is Map && args.containsKey('isStandalone')) {
      _isStandalone = args['isStandalone'] as bool? ?? widget.isStandalone;
    } else {
      _isStandalone = widget.isStandalone;
    }
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final cameraStatus = await Permission.camera.status;
    final photosStatus = await Permission.photos.status;
    final storageStatus = await Permission.storage.status;
    final notifStatus = await Permission.notification.status;

    if (mounted) {
      setState(() {
        _isCameraGranted = cameraStatus.isGranted;
        _isPhotosGranted = photosStatus.isGranted || storageStatus.isGranted;
        _isNotificationsGranted = notifStatus.isGranted;
      });
    }
  }

  Future<void> _requestCameraPermission() async {
    final result = await Permission.camera.request();
    if (mounted) {
      setState(() {
        _isCameraGranted = result.isGranted;
      });
    }
  }

  Future<void> _requestPhotosPermission() async {
    final result = await Permission.photos.request();
    final storageResult = await Permission.storage.request();
    if (mounted) {
      setState(() {
        _isPhotosGranted = result.isGranted || storageResult.isGranted;
      });
    }
  }

  Future<void> _requestNotificationsPermission() async {
    final result = await Permission.notification.request();
    if (mounted) {
      setState(() {
        _isNotificationsGranted = result.isGranted;
      });
    }
  }

  void _onFinish() async {
    await StorageService.setOnboarded(true);
    if (!mounted) return;

    if (_isStandalone) {
      Get.back();
    } else {
      final hasSession = await StorageService.hasSession();
      if (hasSession) {
        Get.offAllNamed(AppRoutes.home);
      } else {
        Get.offAllNamed(AppRoutes.auth);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.text),
          onPressed: () => Get.back(),
        ),
        title: Text(
          _isStandalone ? 'Camera & Gallery Permissions' : 'Step 2 of 2: Permissions',
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (!_isStandalone)
            TextButton(
              onPressed: _onFinish,
              child: const Text(
                'Skip',
                style: TextStyle(
                  color: AppColors.secondaryText,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Description
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.verified_user_rounded, color: AppColors.primary, size: 28),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Permissions & Consent',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'PlainScan needs access to scan and import your documents securely.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.secondaryText,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Card 1: Camera
            _buildPermissionCard(
              title: 'Camera Access',
              tag: 'Essential for Document Scanning',
              description:
                  'PlainScan uses your camera to capture physical documents, receipts, invoices, IDs, and multi-page books with instant border detection and automatic perspective warp.',
              icon: Icons.camera_alt_rounded,
              iconColor: AppColors.primary,
              isGranted: _isCameraGranted,
              onRequest: _requestCameraPermission,
            ),
            const SizedBox(height: 14),

            // Card 2: Photos & Files Gallery
            _buildPermissionCard(
              title: 'Photos & Files Gallery',
              tag: 'Essential for Importing Documents',
              description:
                  'Needed to import existing PDF files, images, and gallery scans into PlainScan so you can compress, convert, merge, sign, and organize them seamlessly.',
              icon: Icons.photo_library_rounded,
              iconColor: AppColors.blue,
              isGranted: _isPhotosGranted,
              onRequest: _requestPhotosPermission,
            ),
            const SizedBox(height: 14),

            // Card 3: Live Status Notifications
            _buildPermissionCard(
              title: 'Live Tool Notifications',
              tag: 'Recommended for Background Jobs',
              description:
                  'Displays live job progress (Upload → Create job → Polling → Completed) directly in your notification panel without requiring the app to stay open.',
              icon: Icons.notifications_active_rounded,
              iconColor: AppColors.coral,
              isGranted: _isNotificationsGranted,
              onRequest: _requestNotificationsPermission,
            ),
            const SizedBox(height: 20),

            // Privacy Guarantee Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4), // Light Emerald
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.shield_rounded, color: AppColors.emerald, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Our Privacy Guarantee',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF166534),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Camera and gallery are ONLY accessed when you actively trigger a scan or select a file.\n'
                    '• PlainScan NEVER reads your private photos or documents in the background.\n'
                    '• All document conversions are strictly encrypted and under your personal control.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF15803D),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: _onFinish,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _isStandalone ? 'Done' : 'I Consent & Get Started',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Icon(
                  _isStandalone ? Icons.check_circle_rounded : Icons.arrow_forward_rounded,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionCard({
    required String title,
    required String tag,
    required String description,
    required IconData icon,
    required Color iconColor,
    required bool isGranted,
    required VoidCallback onRequest,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGranted ? AppColors.emerald.withValues(alpha: 0.5) : AppColors.border,
          width: isGranted ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isGranted
                      ? AppColors.emerald.withValues(alpha: 0.1)
                      : iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isGranted ? Icons.check_circle_rounded : icon,
                  color: isGranted ? AppColors.emerald : iconColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tag,
                      style: TextStyle(
                        fontSize: 11,
                        color: isGranted ? AppColors.emerald : iconColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: onRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isGranted ? AppColors.emerald : iconColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                child: Text(
                  isGranted ? 'Granted ✓' : 'Grant Access',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, size: 16, color: AppColors.secondaryText),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.secondaryText,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
