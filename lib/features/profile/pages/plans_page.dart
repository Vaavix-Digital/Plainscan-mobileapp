import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:plainscan/app/routes.dart';
import 'package:plainscan/core/constants/app_colors.dart';
import 'package:plainscan/core/controllers/plan_controller.dart';
import 'package:plainscan/models/plan_model.dart';

class PlansPage extends StatelessWidget {
  const PlansPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<PlanController>()
        ? Get.find<PlanController>()
        : Get.put(PlanController());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Subscription Plans',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.text, size: 20),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.plans.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (controller.errorMessage.isNotEmpty && controller.plans.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_off_rounded, size: 64, color: AppColors.secondaryText),
                  const SizedBox(height: 16),
                  Text(
                    controller.errorMessage.value,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.secondaryText),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => controller.loadPlansData(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => controller.loadPlansData(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Title & Subtitle
                const Text(
                  'Unlock Full Power with Pro',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Access high-definition scanning, batch AI enhancements, full OCR extractions, and cloud storage.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.secondaryText,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 24),

                // Billing Interval Selector (Monthly / Yearly)
                _buildBillingToggle(controller),

                const SizedBox(height: 24),

                // Plan Cards List
                ...controller.plans.map((plan) {
                  return _buildPlanCard(context, controller, plan);
                }),

                const SizedBox(height: 16),

                // Free Referral Option Card
                _buildReferralCard(),

                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildBillingToggle(PlanController controller) {
    return Obx(() {
      final isYearly = controller.isYearly.value;
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => controller.toggleBilling(false),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: !isYearly ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: !isYearly
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : [],
                  ),
                  child: Center(
                    child: Text(
                      'Monthly Billing',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: !isYearly ? FontWeight.bold : FontWeight.w500,
                        color: !isYearly ? AppColors.text : AppColors.secondaryText,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => controller.toggleBilling(true),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isYearly ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: isYearly
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : [],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Annual',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isYearly ? FontWeight.bold : FontWeight.w500,
                          color: isYearly ? AppColors.text : AppColors.secondaryText,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'SAVE 40%',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildPlanCard(
    BuildContext context,
    PlanController controller,
    PlanModel plan,
  ) {
    return Obx(() {
      final isYearly = controller.isYearly.value;
      final isCurrent = controller.isCurrentPlan(plan.planId);
      final isPopular = plan.isPopular;

      return Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isPopular
                ? AppColors.primary
                : (isCurrent ? const Color(0xFF10B981) : AppColors.border),
            width: (isPopular || isCurrent) ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isPopular
                  ? AppColors.primary.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Badge if Popular or Current
            if (isPopular || isCurrent)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                decoration: BoxDecoration(
                  color: isCurrent ? const Color(0xFF10B981) : AppColors.primary,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isCurrent ? Icons.check_circle : Icons.star,
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isCurrent ? 'YOUR ACTIVE PLAN' : 'MOST POPULAR',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        plan.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text,
                        ),
                      ),
                      if (plan.savingsPercentage > 0 && isYearly)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFF59E0B)),
                          ),
                          child: Text(
                            'Save ${plan.savingsPercentage}%',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFD97706),
                            ),
                          ),
                        ),
                    ],
                  ),

                  if (plan.description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      plan.description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Price Display
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        plan.isFree
                            ? 'Free'
                            : '${plan.currencySymbol}${plan.priceMonthly == 0 ? 0 : (isYearly ? (plan.priceYearly % 1 == 0 ? plan.priceYearly.toInt() : plan.priceYearly) : (plan.priceMonthly % 1 == 0 ? plan.priceMonthly.toInt() : plan.priceMonthly))}',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text,
                        ),
                      ),
                      if (!plan.isFree) ...[
                        const SizedBox(width: 4),
                        Text(
                          isYearly ? '/year' : '/month',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ],
                  ),

                  if (!plan.isFree && isYearly) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Billed annually at ${plan.formattedPrice(true)} (${plan.formattedMonthlyEquivalent()})',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF10B981),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),
                  const Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: 16),

                  // Features list
                  ...plan.features.map((feature) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.primary,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              feature,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.text,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  // Limitations list
                  ...plan.limitations.map((limit) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.remove_circle_outline_rounded,
                            color: Color(0xFF94A3B8),
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              limit,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF94A3B8),
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 20),

                  // CTA Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isCurrent
                          ? null
                          : () => controller.subscribeToPlan(plan),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isPopular ? AppColors.primary : const Color(0xFF1E224F),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFFF1F5F9),
                        disabledForegroundColor: const Color(0xFF64748B),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: isCurrent ? 0 : 2,
                      ),
                      child: Text(
                        isCurrent
                            ? 'Current Plan'
                            : (plan.ctaLabel ?? (plan.isFree ? 'Get Started' : 'Upgrade to ${plan.name}')),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildReferralCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.card_giftcard_rounded,
                  color: Color(0xFFD97706),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Get 50 Credits + 1 Month Pro Free',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.text,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Invite friends to PlainScan to get 50 bonus credits and 30 days of unlimited Pro access.',
                      style: TextStyle(fontSize: 12, color: AppColors.secondaryText),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Get.toNamed(AppRoutes.referral),
              icon: const Icon(Icons.share_rounded, color: Color(0xFFD97706), size: 18),
              label: const Text(
                'Invite Friends Now',
                style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFF59E0B), width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
