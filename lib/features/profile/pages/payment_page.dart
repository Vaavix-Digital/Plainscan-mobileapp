import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:plainscan/app/routes.dart';
import 'package:plainscan/core/constants/app_colors.dart';
import 'package:plainscan/core/controllers/plan_controller.dart';
import 'package:plainscan/core/services/payment_service.dart';
import 'package:plainscan/models/plan_model.dart';

class PaymentPage extends StatefulWidget {
  final PlanModel? plan;
  final String? billingPeriod;

  const PaymentPage({
    super.key,
    this.plan,
    this.billingPeriod,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  late final PlanModel _plan;
  late final String _billingPeriod;
  final PlanController _planController = Get.isRegistered<PlanController>()
      ? Get.find<PlanController>()
      : Get.put(PlanController());

  PaymentOrderResult? _order;
  bool _isLoadingOrder = true;
  String _orderError = '';

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    _plan = widget.plan ??
        args['plan'] as PlanModel? ??
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
    _billingPeriod = widget.billingPeriod ?? args['billingPeriod'] as String? ?? 'monthly';

    _prepareOrder();
  }

  Future<void> _prepareOrder() async {
    setState(() {
      _isLoadingOrder = true;
      _orderError = '';
    });

    final isYearly = _billingPeriod == 'yearly';
    final planAmount = isYearly ? _plan.priceYearly : _plan.priceMonthly;

    final orderResult = await PaymentService.createOrder(
      planId: _plan.planId,
      billingPeriod: _billingPeriod,
      amount: planAmount,
      currency: _plan.currency,
    );

    if (mounted) {
      setState(() {
        _order = orderResult;
        _isLoadingOrder = false;
        if (!orderResult.success && (orderResult.errorMessage?.isNotEmpty ?? false)) {
          _orderError = orderResult.errorMessage!;
        }
      });
    }
  }

  String _getDisplayAmount() {
    return _plan.formattedAmount(_billingPeriod == 'yearly');
  }

  @override
  Widget build(BuildContext context) {
    final isYearly = _billingPeriod == 'yearly';
    final isRazorpay = _order == null || _order!.isRazorpay;
    final displayAmount = _getDisplayAmount();

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
          'Checkout & Payment',
          style: TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.lock_rounded, size: 12, color: Color(0xFF10B981)),
                SizedBox(width: 4),
                Text(
                  'SSL Encrypted',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          ),
        ],
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
            // Plan Summary Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    blurRadius: 14,
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PlainScan ${_plan.name}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.text,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isYearly ? 'Billed Annually' : 'Billed Monthly',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          displayAmount,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: 14),

                  const Text(
                    'What\'s included:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondaryText,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 10),

                  ..._plan.features.map(
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

            const SizedBox(height: 20),

            // Payment Gateway Details Card
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (isRazorpay ? const Color(0xFF0C2340) : const Color(0xFF635BFF))
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isRazorpay ? Icons.account_balance_wallet_rounded : Icons.credit_card_rounded,
                          color: isRazorpay ? const Color(0xFF0C2340) : const Color(0xFF635BFF),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isRazorpay ? 'Razorpay Secure Gateway' : 'Stripe Global Checkout',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppColors.text,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isRazorpay
                                  ? 'Supports UPI (GPay, PhonePe, Paytm), Cards & NetBanking'
                                  : 'Supports International Credit & Debit Cards (USD)',
                              style: const TextStyle(fontSize: 11, color: AppColors.secondaryText),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_order?.orderId != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Order Reference:',
                            style: TextStyle(fontSize: 11, color: AppColors.secondaryText),
                          ),
                          Text(
                            _order!.orderId!,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                              color: AppColors.text,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Price Breakdown Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _buildPriceRow('Subscription Plan', 'PlainScan ${_plan.name}'),
                  const SizedBox(height: 10),
                  _buildPriceRow('Billing Cycle', isYearly ? 'Annual' : 'Monthly'),
                  if (isYearly && _plan.savingsPercentage > 0) ...[
                    const SizedBox(height: 10),
                    _buildPriceRow(
                      'Annual Savings',
                      'Save ${_plan.savingsPercentage}%',
                      valueColor: const Color(0xFF10B981),
                    ),
                  ],
                  const SizedBox(height: 10),
                  _buildPriceRow('Taxes & Fees', 'Included', valueColor: const Color(0xFF10B981)),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1, color: AppColors.border),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Payable Amount',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text,
                        ),
                      ),
                      Text(
                        displayAmount,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (_orderError.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFF87171)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xFFDC2626), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _orderError,
                        style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 12),
                      ),
                    ),
                    if (_orderError.toLowerCase().contains('auth') ||
                        _orderError.toLowerCase().contains('login'))
                      TextButton(
                        onPressed: () => Get.toNamed(AppRoutes.auth),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                        ),
                        child: const Text(
                          'Log In',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFDC2626),
                            fontSize: 12,
                          ),
                        ),
                      )
                    else
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded, color: Color(0xFFDC2626), size: 18),
                        onPressed: _prepareOrder,
                        tooltip: 'Retry Order',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 28),

            // "Pay Now" Action Button
            Obx(() {
              final isProcessing = _planController.isProcessingPayment.value || _isLoadingOrder;
              return ElevatedButton(
                onPressed: isProcessing
                    ? null
                    : () async {
                        if (_order == null || !_order!.success) {
                          await _prepareOrder();
                        }
                        if (context.mounted) {
                          await _planController.executePayment(
                            context: context,
                            plan: _plan,
                            order: _order,
                            billingPeriod: _billingPeriod,
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isRazorpay ? const Color(0xFF0C2340) : const Color(0xFF635BFF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
                child: isProcessing
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Connecting to Gateway...',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      )
                    : Text(
                        'Pay $displayAmount Now',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              );
            }),

            const SizedBox(height: 16),

            // Security note
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.verified_user_rounded, size: 14, color: AppColors.secondaryText),
                  SizedBox(width: 6),
                  Text(
                    'Safe & Secure 256-bit encrypted transaction',
                    style: TextStyle(fontSize: 12, color: AppColors.secondaryText),
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

  Widget _buildPriceRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.secondaryText),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppColors.text,
          ),
        ),
      ],
    );
  }
}
