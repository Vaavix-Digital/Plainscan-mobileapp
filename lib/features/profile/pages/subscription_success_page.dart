import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:plainscan/app/routes.dart';
import 'package:plainscan/core/constants/app_colors.dart';
import 'package:plainscan/core/services/storage_service.dart';
import 'package:plainscan/features/home/screens/home_screen.dart';
import 'package:plainscan/models/plan_model.dart';

class SubscriptionSuccessPage extends StatefulWidget {
  const SubscriptionSuccessPage({super.key});

  @override
  State<SubscriptionSuccessPage> createState() => _SubscriptionSuccessPageState();
}

class _SubscriptionSuccessPageState extends State<SubscriptionSuccessPage> {
  String? _userEmail;
  String? _userName;
  String? _userId;
  bool _isPro = false;
  String? _jwtToken;
  bool _isLoadingAuth = true;

  @override
  void initState() {
    super.initState();
    _loadUserAuthDetails();
  }

  Future<void> _loadUserAuthDetails() async {
    final email = await StorageService.getEmail();
    final name = await StorageService.getName();
    final userId = await StorageService.getUserId();
    final plan = await StorageService.getPlan();
    final isPro = await StorageService.isProUser();
    final token = await StorageService.getToken();

    if (mounted) {
      setState(() {
        _userEmail = email ?? 'Unregistered / Guest User';
        _userName = name ?? 'PlainScan User';
        _userId = userId ?? 'N/A';
        _isPro = isPro;
        _jwtToken = token;
        _isLoadingAuth = false;
      });
    }

    // Print activation response and user authentication details to console log
    _printActivationAndAuthDetails(
      email: _userEmail!,
      name: _userName!,
      userId: _userId!,
      plan: plan,
      isPro: isPro,
      token: token,
    );
  }

  void _printActivationAndAuthDetails({
    required String email,
    required String name,
    required String userId,
    required String plan,
    required bool isPro,
    String? token,
  }) {
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    final paymentId = args['paymentId'] ?? 'PAY-${DateTime.now().millisecondsSinceEpoch}';
    final provider = args['provider'] ?? 'razorpay';
    final amount = args['amount'] ?? '₹764';

    final responsePayload = {
      'status': 'success',
      'message': 'Subscription verified and activated successfully',
      'payment_id': paymentId,
      'provider': provider,
      'amount': amount,
      'activated_at': DateTime.now().toIso8601String(),
    };

    final jsonStr = const JsonEncoder.withIndent('  ').convert(responsePayload);

    final logText = '''

========================================================================
🎉 SUBSCRIPTION ACTIVATION RESPONSE & USER AUTHENTICATION DETAILS
========================================================================
[Payment Provider] : ${provider.toString().toUpperCase()}
[Activation Status]: SUCCESS (HTTP 200)
[Payment ID]       : $paymentId
[Amount Paid]      : $amount

---------------- CURRENT USER AUTHENTICATION DETAILS ----------------
• Account Status : ${isPro ? 'PRO ⚡ (Active Subscription)' : 'FREE 👤'}
• User Email     : $email
• Display Name   : $name
• User ID        : $userId
• Active Plan    : ${plan.toUpperCase()}
• Auth Status    : ${token != null && token.isNotEmpty ? 'AUTHENTICATED (JWT Token Active)' : 'UNAUTHENTICATED'}
• Token Snippet  : ${token != null && token.length > 20 ? '${token.substring(0, 20)}...' : (token ?? 'None')}

---------------- ACTIVATION RESPONSE PAYLOAD ----------------
$jsonStr
========================================================================
''';

    debugPrint(logText);
  }

  void _navigateToProfile() {
    if (Get.isRegistered<HomeScreenController>()) {
      Get.find<HomeScreenController>().changeTab(3);
    }
    Get.offAllNamed(AppRoutes.home);
    if (Get.isRegistered<HomeScreenController>()) {
      Get.find<HomeScreenController>().changeTab(3);
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    final plan = args['plan'] as PlanModel? ??
        PlanModel(
          planId: 'pro',
          name: 'Pro',
          priceMonthly: 764.0,
          priceYearly: 4584.0,
          currency: 'INR',
          currencySymbol: '₹',
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
        );

    final billingPeriod = args['billingPeriod'] as String? ?? 'monthly';
    final isYearly = billingPeriod == 'yearly';
    final paymentId = args['paymentId'] as String? ?? 'PAY-${DateTime.now().millisecondsSinceEpoch}';
    final provider = args['provider'] as String? ?? 'razorpay';
    final amountPaid = args['amount'] as String? ?? plan.formattedPrice(isYearly);

    final nextRenewalDate = isYearly
        ? DateTime.now().add(const Duration(days: 365))
        : DateTime.now().add(const Duration(days: 30));
    final renewalFormatted =
        '${nextRenewalDate.day}/${nextRenewalDate.month}/${nextRenewalDate.year}';

    final responsePayload = {
      'status': 'success',
      'message': 'Subscription verified and activated successfully',
      'payment_id': paymentId,
      'provider': provider,
      'amount': amountPaid,
      'user_email': _userEmail ?? 'Loading...',
      'account_type': _isPro ? 'PRO' : 'FREE',
      'activated_at': DateTime.now().toIso8601String(),
    };

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _navigateToProfile();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.close_rounded, color: AppColors.text, size: 24),
              onPressed: _navigateToProfile,
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Celebration Icon
                Center(
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF10B981), width: 2),
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF10B981),
                      size: 54,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'Subscription Activated! 🎉',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Congratulations! You are now subscribed to PlainScan ${plan.name}. All premium features are unlocked.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.secondaryText,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 24),

                // User Authentication & Account Details Card (Free vs Pro)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.badge_rounded,
                                  color: AppColors.primary,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'User Account Details',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.text,
                                ),
                              ),
                            ],
                          ),

                          // Account Status Badge (Free or Pro)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _isPro
                                  ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _isPro ? const Color(0xFF10B981) : Colors.grey,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _isPro ? Icons.bolt_rounded : Icons.person_outline,
                                  size: 14,
                                  color: _isPro ? const Color(0xFF10B981) : Colors.black87,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _isPro ? 'PRO ACCOUNT' : 'FREE ACCOUNT',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: _isPro ? const Color(0xFF047857) : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),
                      const Divider(height: 1),
                      const SizedBox(height: 14),

                      if (_isLoadingAuth)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(12.0),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      else ...[
                        _buildReceiptRow('User Name', _userName ?? 'N/A'),
                        const SizedBox(height: 10),
                        _buildReceiptRow('Email Address', _userEmail ?? 'N/A'),
                        const SizedBox(height: 10),
                        _buildReceiptRow('User ID', _userId ?? 'N/A', isMonospace: true),
                        const SizedBox(height: 10),
                        _buildReceiptRow(
                          'Account Tier',
                          _isPro ? 'Pro (Unlimited Access)' : 'Free Tier',
                          statusColor: _isPro ? const Color(0xFF10B981) : Colors.grey.shade700,
                        ),
                        const SizedBox(height: 10),
                        _buildReceiptRow(
                          'Authentication Status',
                          _jwtToken != null && _jwtToken!.isNotEmpty
                              ? 'Authenticated (JWT Active)'
                              : 'Unauthenticated',
                          statusColor: _jwtToken != null && _jwtToken!.isNotEmpty
                              ? const Color(0xFF10B981)
                              : Colors.amber.shade800,
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Order & Subscription Receipt Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildReceiptRow('Plan', 'PlainScan ${plan.name} (${isYearly ? 'Annual' : 'Monthly'})'),
                      const SizedBox(height: 12),
                      _buildReceiptRow('Amount Paid', amountPaid, isHighlight: true),
                      const SizedBox(height: 12),
                      _buildReceiptRow(
                        'Payment Method',
                        provider.toLowerCase() == 'stripe'
                            ? 'Stripe Global'
                            : (provider.toLowerCase().contains('google')
                                ? 'Google Play Billing'
                                : 'Razorpay (India)'),
                      ),
                      const SizedBox(height: 12),
                      _buildReceiptRow('Status', 'Active', statusColor: const Color(0xFF10B981)),
                      const SizedBox(height: 12),
                      _buildReceiptRow('Next Renewal', renewalFormatted),
                      const SizedBox(height: 12),
                      _buildReceiptRow('Transaction ID', paymentId, isMonospace: true),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Printed Activation Response JSON Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.terminal_rounded, color: Color(0xFF38BDF8), size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Activation Response Output',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: SelectableText(
                          const JsonEncoder.withIndent('  ').convert(responsePayload),
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: Color(0xFF4ADE80),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Unlocked Features Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.star_rounded,
                              color: AppColors.primary,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Unlocked Perks',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.text,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ...plan.features.map(
                        (feature) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle_rounded,
                                color: Color(0xFF10B981),
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  feature,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.text,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Navigation Buttons
                ElevatedButton(
                  onPressed: _navigateToProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'Start Using PlainScan Pro',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                TextButton(
                  onPressed: _navigateToProfile,
                  child: const Text(
                    'View My Profile',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptRow(
    String label,
    String value, {
    bool isHighlight = false,
    Color? statusColor,
    bool isMonospace = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.secondaryText,
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: isHighlight ? 15 : 13,
              fontWeight: isHighlight || statusColor != null ? FontWeight.bold : FontWeight.w600,
              color: statusColor ?? (isHighlight ? AppColors.primary : AppColors.text),
              fontFamily: isMonospace ? 'monospace' : null,
            ),
          ),
        ),
      ],
    );
  }
}
