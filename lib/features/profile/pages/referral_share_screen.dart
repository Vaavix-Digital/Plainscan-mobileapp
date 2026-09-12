import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:plainscan/core/constants/api_constants.dart';
import 'package:plainscan/core/constants/app_colors.dart';
import 'package:plainscan/core/controllers/profile_controller.dart';
import 'package:plainscan/core/services/referral_service.dart';
import 'package:plainscan/core/services/storage_service.dart';

class ReferralShareScreen extends StatefulWidget {
  const ReferralShareScreen({super.key});

  @override
  State<ReferralShareScreen> createState() => _ReferralShareScreenState();
}

class _ReferralShareScreenState extends State<ReferralShareScreen> {
  String _myCode = 'PLAIN2026';
  String _shareLink = 'https://plainscan.com/invite/PLAIN2026';
  int _totalReferred = 5;
  int _creditsEarned = 250;
  int _userCredits = 250;
  DateTime? _proExpiryDate;
  bool _isPro = false;
  bool _isLoading = true;
  final TextEditingController _redeemController = TextEditingController();
  bool _isRedeeming = false;

  @override
  void initState() {
    super.initState();
    _loadReferralData();
  }

  Future<void> _loadReferralData() async {
    try {
      final referralInfo = await ReferralService.getMyReferralCode();
      final expiry = await StorageService.getProExpiryDate();
      final isPro = await StorageService.isProUser();
      final credits = await StorageService.getUserCredits();

      if (mounted) {
        setState(() {
          _myCode = referralInfo.referralCode;
          _shareLink = referralInfo.shareLink;
          _totalReferred = referralInfo.totalReferred;
          _creditsEarned = referralInfo.creditsEarned;
          _userCredits = credits;
          _proExpiryDate = expiry;
          _isPro = isPro;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading referral data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _shareApp() async {
    await ReferralService.shareReferral(
      referralCode: _myCode,
      shareLink: _shareLink,
    );
  }

  Future<void> _openPlayStore() async {
    final uri = Uri.parse(ApiConstants.playStoreUrl);
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        Get.snackbar(
          'Notice',
          'Could not open Google Play Store.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      debugPrint('Error opening Play Store: $e');
    }
  }

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: _myCode));
    Get.snackbar(
      'Code Copied! 📋',
      'Referral code $_myCode copied to clipboard.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.white,
      colorText: AppColors.text,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    );
  }

  void _copyShareLink() {
    final link = _shareLink.isNotEmpty ? _shareLink : 'https://plainscan.com/invite/$_myCode';
    Clipboard.setData(ClipboardData(text: link));
    Get.snackbar(
      'Link Copied! 🔗',
      'Invite link copied to clipboard.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.white,
      colorText: AppColors.text,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> _redeemCode() async {
    final code = _redeemController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _isRedeeming = true;
    });

    final res = await ReferralService.applyReferralCode(code);

    setState(() {
      _isRedeeming = false;
    });

    if (res.success) {
      _redeemController.clear();
      await _loadReferralData();

      if (Get.isRegistered<ProfileController>()) {
        final profileCtrl = Get.find<ProfileController>();
        profileCtrl.loadUserProfile();
        profileCtrl.refreshCredits();
      }

      Get.snackbar(
        'Success! 🎉',
        res.message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.emerald,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      );
    } else {
      Get.snackbar(
        'Redemption Notice',
        res.message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.white,
        colorText: AppColors.text,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      );
    }
  }

  @override
  void dispose() {
    _redeemController.dispose();
    super.dispose();
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
        title: const Text(
          'Share & Refer PlainScan',
          style: TextStyle(
            color: AppColors.text,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Hero Banner Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.purple],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.card_giftcard_rounded, size: 48, color: Colors.white),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Refer Friends & Earn Credits',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Give 50 credits, get 50 credits! When your friend joins PlainScan using your invite, you both receive 50 AI credits and 1 month of Unlimited PRO access.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Referral Stats Grid
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.people_alt_rounded,
                          color: AppColors.primary,
                          label: 'Friends Referred',
                          value: '$_totalReferred',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.stars_rounded,
                          color: AppColors.amber,
                          label: 'Credits Earned',
                          value: '$_creditsEarned',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.account_balance_wallet_outlined,
                          color: AppColors.emerald,
                          label: 'Available Credits',
                          value: '$_userCredits',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Your Referral Code Card
                  Container(
                    padding: const EdgeInsets.all(20),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your Unique Referral Code',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondaryText,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _myCode,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                  color: AppColors.primary,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: _copyCode,
                                icon: const Icon(Icons.copy_rounded, size: 16, color: AppColors.primary),
                                label: const Text(
                                  'Copy',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Share Link Box
                        const Text(
                          'Your Share Link',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondaryText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.link_rounded, size: 18, color: AppColors.secondaryText),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _shareLink,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.text,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: _copyShareLink,
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  'Copy Link',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Primary Share Button
                        ElevatedButton.icon(
                          onPressed: _shareApp,
                          icon: const Icon(Icons.share_rounded, size: 18),
                          label: const Text(
                            'Share PlainScan via Google Play',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Play Store Link Button
                        OutlinedButton.icon(
                          onPressed: _openPlayStore,
                          icon: const Icon(Icons.shop_two_rounded, size: 18, color: AppColors.primary),
                          label: const Text(
                            'View on Google Play Store',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary),
                          ),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 46),
                            side: const BorderSide(color: AppColors.primary, width: 1.2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Active PRO Status
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: _isPro ? const Color(0xFFF0FDF4) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _isPro ? const Color(0xFFBBF7D0) : AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _isPro
                                ? AppColors.emerald.withValues(alpha: 0.15)
                                : AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isPro ? Icons.verified_rounded : Icons.card_giftcard_rounded,
                            color: _isPro ? AppColors.emerald : AppColors.primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isPro ? 'PRO Access: Active ⚡' : 'Referral Reward Program',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: _isPro ? const Color(0xFF166534) : AppColors.text,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _proExpiryDate != null && _isPro
                                    ? 'PRO active until ${_proExpiryDate!.month}/${_proExpiryDate!.day}/${_proExpiryDate!.year} • $_creditsEarned bonus credits earned'
                                    : 'Invite friends to earn 50 credits per referral and unlock unlimited PRO access!',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _isPro ? const Color(0xFF15803D) : AppColors.secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Apply Friend's Referral Code Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Have a Friend\'s Referral Code?',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Enter their code below to receive 50 bonus credits and unlock 1 month of unlimited PRO access.',
                          style: TextStyle(fontSize: 12, color: AppColors.secondaryText),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _redeemController,
                                textCapitalization: TextCapitalization.characters,
                                decoration: InputDecoration(
                                  hintText: 'e.g. PLAIN2026',
                                  hintStyle: const TextStyle(fontSize: 13, color: AppColors.secondaryText),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  filled: true,
                                  fillColor: AppColors.background,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: AppColors.border),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: AppColors.border),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: _isRedeeming ? null : _redeemCode,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                elevation: 0,
                              ),
                              child: _isRedeeming
                                  ? const SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Text('Apply Code', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // How It Works
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'How Referrals Work',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildStepRow(
                          step: '1',
                          title: 'Share your personal invite link',
                          desc: 'Share your referral code or Google Play Store download link with colleagues & friends.',
                        ),
                        const SizedBox(height: 14),
                        _buildStepRow(
                          step: '2',
                          title: 'Friend installs & enters your code',
                          desc: 'When they join PlainScan and apply your referral code, they receive 50 bonus credits.',
                        ),
                        const SizedBox(height: 14),
                        _buildStepRow(
                          step: '3',
                          title: 'Both receive 50 credits & Pro access',
                          desc: '50 AI credits are added to your balance, and both accounts get 1 month of unlimited PRO features!',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.secondaryText,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepRow({
    required String step,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 26,
          width: 26,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              step,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.text),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: const TextStyle(fontSize: 12, color: AppColors.secondaryText, height: 1.3),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
