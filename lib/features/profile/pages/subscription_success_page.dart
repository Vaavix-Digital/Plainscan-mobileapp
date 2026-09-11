import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:plainscan/app/routes.dart';
import 'package:plainscan/core/constants/app_colors.dart';
import 'package:plainscan/models/plan_model.dart';

class SubscriptionSuccessPage extends StatelessWidget {
  const SubscriptionSuccessPage({super.key});

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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Get.offAllNamed(AppRoutes.home);
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
              onPressed: () => Get.offAllNamed(AppRoutes.home),
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
                        provider.toLowerCase() == 'stripe' ? 'Stripe Global' : 'Razorpay (India)',
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
                  onPressed: () => Get.offAllNamed(AppRoutes.home),
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
                  onPressed: () => Get.offNamed(AppRoutes.plans),
                  child: const Text(
                    'View My Plan Details',
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
