import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:plainscan/core/constants/api_constants.dart';
import 'package:plainscan/core/services/storage_service.dart';
import 'package:plainscan/models/plan_model.dart';

class PlanService {
  static final http.Client _client = http.Client();

  /// Fetches all available subscription plans (Public API, no auth required)
  /// Backend auto-detects user location by IP and returns INR (Razorpay) or USD (Stripe).
  static Future<List<PlanModel>> getAllPlans() async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.listPlans}');
      final response = await _client.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is List) {
          final list = decoded
              .map((item) => PlanModel.fromJson(item as Map<String, dynamic>))
              .toList();

          // Sort by plan order
          list.sort((a, b) => a.order.compareTo(b.order));
          return list;
        }
      }
      debugPrint('Plans API error: ${response.statusCode} - ${response.body}');
    } catch (e) {
      debugPrint('Exception while fetching plans: $e');
    }

    return _fallbackPlans();
  }

  /// Fetches the authenticated user's current subscription plan
  /// Requires JWT token in `Authorization: Bearer <TOKEN>` header
  static Future<PlanModel?> getCurrentPlan() async {
    try {
      final token = await StorageService.getToken();
      if (token == null || token.isEmpty) {
        return null;
      }

      final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.currentPlan}');
      final response = await _client.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final plan = PlanModel.fromJson(decoded);
          await StorageService.savePlan(plan.planId);
          return plan;
        }
      } else {
        debugPrint('Current plan API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Exception while fetching current plan: $e');
    }
    return null;
  }

  /// Offline/Fallback plans if network is unreachable
  static List<PlanModel> _fallbackPlans() {
    return [
      PlanModel(
        planId: 'free',
        name: 'Free',
        description: 'Perfect for occasional use',
        priceMonthly: 0.0,
        priceYearly: 0.0,
        currency: 'INR',
        currencySymbol: '₹',
        features: [
          '4 documents per day',
          'Up to 50 MB file size',
          'Basic PDF tools',
          'Standard processing speed',
          'Ad-supported',
        ],
        limitations: [
          'No AI tools',
          'No priority support',
        ],
        isPopular: false,
        order: 1,
        ctaLabel: 'Get Started Free',
      ),
      PlanModel(
        planId: 'pro',
        name: 'Pro',
        description: 'For power users and professionals',
        priceMonthly: 764.0,
        priceYearly: 4584.0,
        monthlyEquivalentYearly: 382.0,
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
        isPopular: true,
        order: 2,
        ctaLabel: 'Upgrade to Pro',
      ),
    ];
  }
}
