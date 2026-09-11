class PlanModel {
  final String planId;
  final String name;
  final String description;
  final double priceMonthly;
  final double priceYearly;
  final double? monthlyEquivalentYearly;
  final String currency;
  final String currencySymbol;
  final List<String> features;
  final List<String> limitations;
  final bool isPopular;
  final bool showAds;
  final int order;
  final String? ctaLabel;

  PlanModel({
    required this.planId,
    required this.name,
    this.description = '',
    this.priceMonthly = 0.0,
    this.priceYearly = 0.0,
    this.monthlyEquivalentYearly,
    this.currency = 'INR',
    this.currencySymbol = '₹',
    this.features = const [],
    this.limitations = const [],
    this.isPopular = false,
    this.showAds = false,
    this.order = 0,
    this.ctaLabel,
  });

  bool get isFree => priceMonthly == 0 && priceYearly == 0;

  int get savingsPercentage {
    final annualIfMonthly = priceMonthly * 12;
    if (annualIfMonthly <= 0 || priceYearly <= 0) return 0;
    if (annualIfMonthly > priceYearly) {
      return (((annualIfMonthly - priceYearly) / annualIfMonthly) * 100).round();
    }
    return 0;
  }

  String _formatAmount(double amount) {
    if (amount % 1 == 0) {
      return amount.toInt().toString();
    }
    return amount.toStringAsFixed(2);
  }

  String formattedPrice(bool isYearly) {
    if (isFree) return 'Free';
    final amount = isYearly ? priceYearly : priceMonthly;
    final suffix = isYearly ? '/year' : '/month';
    return '$currencySymbol${_formatAmount(amount)}$suffix';
  }

  String formattedMonthlyEquivalent() {
    if (isFree) return 'Free';
    final equiv = monthlyEquivalentYearly ?? (priceYearly > 0 ? (priceYearly / 12) : priceMonthly);
    return '$currencySymbol${_formatAmount(equiv)}/mo';
  }

  factory PlanModel.fromJson(Map<String, dynamic> json) {
    final id = json['plan_id']?.toString() ?? json['id']?.toString() ?? '';
    final rawCurrency = json['currency']?.toString() ?? 'INR';
    final defaultSymbol = rawCurrency.toUpperCase() == 'USD' ? '\$' : '₹';
    final symbol = json['currency_symbol']?.toString() ?? defaultSymbol;

    final num? rawMonthly = json['price_monthly'] ?? json['monthly_price'];
    final num? rawYearly = json['price_yearly'] ?? json['yearly_price'];
    final num? rawEquiv = json['monthly_equivalent_yearly'];

    final featuresList = <String>[];
    if (json['features'] is List) {
      for (final f in json['features']) {
        if (f != null && f.toString().trim().isNotEmpty) {
          featuresList.add(f.toString().trim());
        }
      }
    }

    final limitationsList = <String>[];
    if (json['limitations'] is List) {
      for (final l in json['limitations']) {
        if (l != null && l.toString().trim().isNotEmpty) {
          limitationsList.add(l.toString().trim());
        }
      }
    }

    return PlanModel(
      planId: id,
      name: json['name']?.toString() ?? (id.isNotEmpty ? id[0].toUpperCase() + id.substring(1) : 'Plan'),
      description: json['description']?.toString() ?? '',
      priceMonthly: rawMonthly?.toDouble() ?? 0.0,
      priceYearly: rawYearly?.toDouble() ?? 0.0,
      monthlyEquivalentYearly: rawEquiv?.toDouble(),
      currency: rawCurrency,
      currencySymbol: symbol,
      features: featuresList,
      limitations: limitationsList,
      isPopular: json['is_popular'] == true || id.toLowerCase() == 'pro',
      showAds: json['show_ads'] == true,
      order: json['order'] is int ? json['order'] as int : (id == 'free' ? 1 : id == 'pro' ? 2 : 3),
      ctaLabel: json['cta_label']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'plan_id': planId,
      'name': name,
      'description': description,
      'price_monthly': priceMonthly,
      'price_yearly': priceYearly,
      'monthly_equivalent_yearly': monthlyEquivalentYearly,
      'currency': currency,
      'currency_symbol': currencySymbol,
      'features': features,
      'limitations': limitations,
      'is_popular': isPopular,
      'show_ads': showAds,
      'order': order,
      'cta_label': ctaLabel,
    };
  }
}
