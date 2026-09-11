import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
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
  String _myCode = 'PLAIN-APP';
  String _shareLink = '';
  int _referralsCount = 0;
  int _creditsEarned = 0;
  DateTime? _proExpiryDate;
  bool _isPro = false;
  final TextEditingController _redeemController = TextEditingController();
  bool _isRedeeming = false;

  @override
  void initState() {
    super.initState();
    _loadReferralData();
  }

  Future<void> _loadReferralData() async {
    final referralInfo = await ReferralService.getMyReferralCode();
    final expiry = await StorageService.getProExpiryDate();
    final isPro = await StorageService.isProUser();

    if (mounted) {
      setState(() {
        _myCode = referralInfo.referralCode;
        _shareLink = referralInfo.shareLink;
        _referralsCount = referralInfo.totalReferred;
        _creditsEarned = referralInfo.creditsEarned;
        _proExpiryDate = expiry;
        _isPro = isPro;
      });
    }
  }

  Future<void> _shareApp() async {
    final link = _shareLink.isNotEmpty ? _shareLink : 'https://plainscan.com/invite/$_myCode';
    final shareText =
        'Hey! I use PlainScan to scan HD documents, convert PDFs, and use unlimited AI tools.\n\n'
        'Install PlainScan with my invite link: $link to get 1 Month of Unlimited PRO access for free!\n\n'
        'Download PlainScan: $link';

    try {
      await Share.share(shareText);
    } catch (e) {
      debugPrint('Error sharing: $e');
    }
  }

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: _myCode));
    Get.snackbar(
      'Code Copied!',
      'Referral code $_myCode copied to clipboard.',
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
        Get.find<ProfileController>().loadUserProfile();
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
          'Share & Get Free Month',
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
      body: SingleChildScrollView(
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
                    'Get 1 Month Unlimited Free',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Share PlainScan with a friend. When they install the application using your invite, you both unlock 1 month of Unlimited PRO access!',
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
                    'How It Works',
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
                    desc: 'Send your referral code or download link via WhatsApp, SMS, or Socials.',
                  ),
                  const SizedBox(height: 14),
                  _buildStepRow(
                    step: '2',
                    title: 'Your friend installs PlainScan',
                    desc: 'They install PlainScan and enter your invite code upon initial setup.',
                  ),
                  const SizedBox(height: 14),
                  _buildStepRow(
                    step: '3',
                    title: 'Enjoy 1 Month of Unlimited PRO',
                    desc: 'Unlimited AI OCR, document compression, and batch tools are instantly unlocked!',
                  ),
                ],
              ),
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
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _shareApp,
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: const Text(
                      'Share PlainScan with Friends',
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
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Active PRO Status / Referrals Count
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
                      _isPro ? Icons.verified_rounded : Icons.people_alt_rounded,
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
                          _isPro ? 'PRO Access: Active ⚡' : 'Friends Referred: $_referralsCount',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: _isPro ? const Color(0xFF166534) : AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _proExpiryDate != null && _isPro
                              ? 'Active until ${_proExpiryDate!.month}/${_proExpiryDate!.day}/${_proExpiryDate!.year}${_creditsEarned > 0 ? " • $_creditsEarned credits earned" : ""}'
                              : 'Total successful referrals: $_referralsCount friends${_creditsEarned > 0 ? " • $_creditsEarned credits earned" : ""}',
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

            // Redeem Friend's Referral Code
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
                    'Have a Friend\'s Invite Code?',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Enter their code below to unlock 1 month of unlimited PRO access.',
                    style: TextStyle(fontSize: 12, color: AppColors.secondaryText),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _redeemController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: InputDecoration(
                            hintText: 'e.g. PLAIN-8K3X9',
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
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        child: _isRedeeming
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Redeem', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
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
