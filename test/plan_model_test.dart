import 'package:flutter_test/flutter_test.dart';
import 'package:plainscan/models/plan_model.dart';

void main() {
  group('PlanModel tests', () {
    test('parses accurately from documentation API response format (Free)', () {
      final json = {
        'plan_id': 'free',
        'name': 'Free',
        'price_monthly': 0,
        'price_yearly': 0,
        'features': ['5 credits/month', 'Basic tools'],
      };

      final plan = PlanModel.fromJson(json);

      expect(plan.planId, 'free');
      expect(plan.name, 'Free');
      expect(plan.priceMonthly, 0.0);
      expect(plan.priceYearly, 0.0);
      expect(plan.isFree, isTrue);
      expect(plan.features.length, 2);
      expect(plan.features[0], '5 credits/month');
      expect(plan.formattedPrice(false), 'Free');
      expect(plan.formattedPrice(true), 'Free');
    });

    test('parses accurately from documentation API response format (Pro)', () {
      final json = {
        'plan_id': 'pro',
        'name': 'Pro',
        'price_monthly': 9.99,
        'price_yearly': 79.99,
        'features': ['200 credits/month', 'All tools', 'Priority support'],
        'currency': 'USD',
        'currency_symbol': '\$',
      };

      final plan = PlanModel.fromJson(json);

      expect(plan.planId, 'pro');
      expect(plan.name, 'Pro');
      expect(plan.priceMonthly, 9.99);
      expect(plan.priceYearly, 79.99);
      expect(plan.currencySymbol, '\$');
      expect(plan.isFree, isFalse);
      expect(plan.isPopular, isTrue);
      expect(plan.features.length, 3);
      expect(plan.formattedPrice(false), '\$9.99/month');
      expect(plan.formattedPrice(true), '\$79.99/year');
      expect(plan.savingsPercentage, greaterThan(0));
    });

    test('parses live backend response with INR currency', () {
      final liveJson = {
        'id': 'pro',
        'plan_id': 'pro',
        'name': 'Pro',
        'description': 'For power users and professionals',
        'price_monthly': 764,
        'monthly_price': 764,
        'price_yearly': 4584,
        'yearly_price': 4584,
        'monthly_equivalent_yearly': 382,
        'currency': 'INR',
        'currency_symbol': '₹',
        'show_ads': false,
        'features': [
          'Unlimited documents per day',
          'Unlimited file size',
          '3,000 AI Credits / month',
        ],
        'is_popular': true,
        'order': 2,
        'cta_label': 'Upgrade to Pro',
      };

      final plan = PlanModel.fromJson(liveJson);

      expect(plan.planId, 'pro');
      expect(plan.name, 'Pro');
      expect(plan.currency, 'INR');
      expect(plan.currencySymbol, '₹');
      expect(plan.priceMonthly, 764.0);
      expect(plan.priceYearly, 4584.0);
      expect(plan.monthlyEquivalentYearly, 382.0);
      expect(plan.formattedPrice(false), '₹764/month');
      expect(plan.formattedPrice(true), '₹4584/year');
      expect(plan.formattedMonthlyEquivalent(), '₹382/mo');
      expect(plan.ctaLabel, 'Upgrade to Pro');
    });

    test('calculates correct savings percentage for yearly billing', () {
      // Monthly: 100 * 12 = 1200. Yearly: 720. Savings: (1200 - 720) / 1200 = 40%
      final plan = PlanModel(
        planId: 'pro',
        name: 'Pro',
        priceMonthly: 100,
        priceYearly: 720,
      );

      expect(plan.savingsPercentage, 40);
    });
  });
}
