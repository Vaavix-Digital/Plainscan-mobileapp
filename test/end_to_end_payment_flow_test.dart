import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:plainscan/features/profile/pages/payment_page.dart';
import 'package:plainscan/features/profile/pages/subscription_success_page.dart';
import 'package:plainscan/models/plan_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Get.testMode = true;
  });

  tearDown(() {
    Get.reset();
  });

  group('Payment Page Widget Tests', () {
    testWidgets('PaymentPage renders selected plan, all 8 features, breakdown, and Pay Now button',
        (WidgetTester tester) async {
      final proPlan = PlanModel(
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

      // Provide arguments via Get.to / Get.testMode
      await tester.pumpWidget(
        GetMaterialApp(
          home: PaymentPage(
            plan: proPlan,
            billingPeriod: 'monthly',
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Header verification
      expect(find.text('Checkout & Payment'), findsOneWidget);
      expect(find.text('SSL Encrypted'), findsOneWidget);

      // Plan Details Card
      expect(find.text('PlainScan Pro'), findsAtLeastNWidgets(1));
      expect(find.text('Billed Monthly'), findsOneWidget);

      // All 8 Pro features verified on screen
      expect(find.text('Unlimited documents per day'), findsOneWidget);
      expect(find.text('Unlimited file size'), findsOneWidget);
      expect(find.text('All PDF & media tools'), findsOneWidget);
      expect(find.text('Full AI-powered features'), findsOneWidget);
      expect(find.text('3,000 AI Credits / month'), findsOneWidget);
      expect(find.text('Priority processing speed'), findsOneWidget);
      expect(find.text('No ads'), findsOneWidget);
      expect(find.text('Email notifications'), findsOneWidget);

      // Provider details card
      expect(find.textContaining('Razorpay Secure Gateway'), findsOneWidget);
      expect(find.textContaining('Supports UPI'), findsOneWidget);

      // Price breakdown
      expect(find.text('Total Payable Amount'), findsOneWidget);
      expect(find.text('₹764'), findsAtLeastNWidgets(1));
      expect(find.text('Taxes & Fees'), findsOneWidget);

      // "Pay Now" action button with exact plan amount
      expect(find.text('Pay ₹764 Now'), findsOneWidget);
    });

    testWidgets('PaymentPage renders yearly plan price ₹4584 correctly',
        (WidgetTester tester) async {
      final proPlan = PlanModel(
        planId: 'pro',
        name: 'Pro',
        priceMonthly: 764.0,
        priceYearly: 4584.0,
        currency: 'INR',
        currencySymbol: '₹',
        features: [
          'Unlimited documents per day',
          '3,000 AI Credits / month',
        ],
      );

      await tester.pumpWidget(
        GetMaterialApp(
          home: PaymentPage(
            plan: proPlan,
            billingPeriod: 'yearly',
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Total Payable Amount'), findsOneWidget);
      expect(find.text('₹4584'), findsAtLeastNWidgets(1));
      expect(find.text('Pay ₹4584 Now'), findsOneWidget);
    });
  });

  group('Subscription Success Page Widget Tests', () {
    testWidgets('SubscriptionSuccessPage renders confirmation, receipt details, and dashboard button',
        (WidgetTester tester) async {
      final proPlan = PlanModel(
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

      await tester.pumpWidget(
        GetMaterialApp(
          initialRoute: '/',
          getPages: [
            GetPage(name: '/', page: () => const Scaffold(body: Text('Home'))),
            GetPage(
              name: '/payment-success',
              page: () => const SubscriptionSuccessPage(),
            ),
          ],
        ),
      );

      Get.toNamed('/payment-success', arguments: {
        'plan': proPlan,
        'billingPeriod': 'monthly',
        'paymentId': 'pay_test_987654',
        'amount': '₹764',
        'provider': 'razorpay',
      });

      await tester.pumpAndSettle();

      // Celebration title & description
      expect(find.text('Subscription Activated! 🎉'), findsOneWidget);
      expect(find.textContaining('Congratulations! You are now subscribed to PlainScan Pro'), findsOneWidget);

      // Receipt card fields
      expect(find.text('₹764'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Razorpay (India)'), findsOneWidget);
      expect(find.text('pay_test_987654'), findsOneWidget);

      // Unlocked perks listed
      expect(find.text('Unlocked Perks'), findsOneWidget);
      expect(find.text('Unlimited documents per day'), findsOneWidget);
      expect(find.text('3,000 AI Credits / month'), findsOneWidget);

      // CTA Buttons
      expect(find.text('Start Using PlainScan Pro'), findsOneWidget);
      expect(find.text('View My Plan Details'), findsOneWidget);
    });

    testWidgets('SubscriptionSuccessPage renders Stripe payment details accurately',
        (WidgetTester tester) async {
      final proPlan = PlanModel(
        planId: 'pro',
        name: 'Pro',
        priceMonthly: 9.99,
        priceYearly: 79.99,
        currency: 'USD',
        currencySymbol: '\$',
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

      await tester.pumpWidget(
        GetMaterialApp(
          initialRoute: '/',
          getPages: [
            GetPage(name: '/', page: () => const Scaffold(body: Text('Home'))),
            GetPage(
              name: '/payment-success',
              page: () => const SubscriptionSuccessPage(),
            ),
          ],
        ),
      );

      Get.toNamed('/payment-success', arguments: {
        'plan': proPlan,
        'billingPeriod': 'yearly',
        'paymentId': 'cs_test_session_123',
        'amount': '\$79.99',
        'provider': 'stripe',
      });

      await tester.pumpAndSettle();

      expect(find.text('Subscription Activated! 🎉'), findsOneWidget);
      expect(find.text('Stripe Global'), findsOneWidget);
      expect(find.text('\$79.99'), findsOneWidget);
      expect(find.text('cs_test_session_123'), findsOneWidget);
    });
  });
}
