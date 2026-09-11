import 'package:flutter_test/flutter_test.dart';
import 'package:plainscan/core/services/plan_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('PlanService live and fallback tests', () {
    test('getAllPlans returns valid list of plans', () async {
      final plans = await PlanService.getAllPlans();
      expect(plans, isNotEmpty);

      // Check that at least free and pro plans are present
      final hasFree = plans.any((p) => p.planId.toLowerCase() == 'free');
      final hasPro = plans.any((p) => p.planId.toLowerCase() == 'pro');

      expect(hasFree, isTrue);
      expect(hasPro, isTrue);

      for (final plan in plans) {
        expect(plan.planId, isNotEmpty);
        expect(plan.name, isNotEmpty);
        expect(plan.currencySymbol, isNotEmpty);
      }
    });

    test('getCurrentPlan returns null safely when unauthenticated', () async {
      final currentPlan = await PlanService.getCurrentPlan();
      expect(currentPlan, isNull);
    });
  });
}
