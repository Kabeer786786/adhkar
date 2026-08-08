enum NisabStandard {
  gold,
  silver,
}

class ZakatCalculatorModel {
  final double cashAndBank;
  final double goldGrams;
  final double goldPricePerGram;
  final double silverGrams;
  final double silverPricePerGram;
  final double investments;
  final double businessGoods;
  final double moneyOwedToYou;
  final double liabilities;
  final NisabStandard nisabStandard;
  final String currencySymbol;

  const ZakatCalculatorModel({
    this.cashAndBank = 0.0,
    this.goldGrams = 0.0,
    this.goldPricePerGram = 7500.0, // Default reference gold price per gram in INR/unit
    this.silverGrams = 0.0,
    this.silverPricePerGram = 90.0, // Default reference silver price per gram in INR/unit
    this.investments = 0.0,
    this.businessGoods = 0.0,
    this.moneyOwedToYou = 0.0,
    this.liabilities = 0.0,
    this.nisabStandard = NisabStandard.silver, // Silver nisab is standard for benefiting poor
    this.currencySymbol = '₹',
  });

  double get totalGoldValue => goldGrams * goldPricePerGram;
  double get totalSilverValue => silverGrams * silverPricePerGram;

  double get grossZakatableAssets =>
      cashAndBank +
      totalGoldValue +
      totalSilverValue +
      investments +
      businessGoods +
      moneyOwedToYou;

  double get netZakatableAssets =>
      (grossZakatableAssets - liabilities).clamp(0.0, double.infinity);

  /// Gold Nisab = 87.48 grams | Silver Nisab = 612.36 grams
  double get nisabThreshold {
    if (nisabStandard == NisabStandard.gold) {
      return 87.48 * goldPricePerGram;
    } else {
      return 612.36 * silverPricePerGram;
    }
  }

  bool get isNisabReached => netZakatableAssets >= nisabThreshold;

  /// Zakat rate is 2.5% (1/40th) of net zakatable assets
  double get zakatPayable => isNisabReached ? (netZakatableAssets * 0.025) : 0.0;

  ZakatCalculatorModel copyWith({
    double? cashAndBank,
    double? goldGrams,
    double? goldPricePerGram,
    double? silverGrams,
    double? silverPricePerGram,
    double? investments,
    double? businessGoods,
    double? moneyOwedToYou,
    double? liabilities,
    NisabStandard? nisabStandard,
    String? currencySymbol,
  }) {
    return ZakatCalculatorModel(
      cashAndBank: cashAndBank ?? this.cashAndBank,
      goldGrams: goldGrams ?? this.goldGrams,
      goldPricePerGram: goldPricePerGram ?? this.goldPricePerGram,
      silverGrams: silverGrams ?? this.silverGrams,
      silverPricePerGram: silverPricePerGram ?? this.silverPricePerGram,
      investments: investments ?? this.investments,
      businessGoods: businessGoods ?? this.businessGoods,
      moneyOwedToYou: moneyOwedToYou ?? this.moneyOwedToYou,
      liabilities: liabilities ?? this.liabilities,
      nisabStandard: nisabStandard ?? this.nisabStandard,
      currencySymbol: currencySymbol ?? this.currencySymbol,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cashAndBank': cashAndBank,
      'goldGrams': goldGrams,
      'goldPricePerGram': goldPricePerGram,
      'silverGrams': silverGrams,
      'silverPricePerGram': silverPricePerGram,
      'investments': investments,
      'businessGoods': businessGoods,
      'moneyOwedToYou': moneyOwedToYou,
      'liabilities': liabilities,
      'nisabStandard': nisabStandard.name,
      'currencySymbol': currencySymbol,
    };
  }

  factory ZakatCalculatorModel.fromJson(Map<String, dynamic> json) {
    return ZakatCalculatorModel(
      cashAndBank: (json['cashAndBank'] as num?)?.toDouble() ?? 0.0,
      goldGrams: (json['goldGrams'] as num?)?.toDouble() ?? 0.0,
      goldPricePerGram: (json['goldPricePerGram'] as num?)?.toDouble() ?? 7500.0,
      silverGrams: (json['silverGrams'] as num?)?.toDouble() ?? 0.0,
      silverPricePerGram: (json['silverPricePerGram'] as num?)?.toDouble() ?? 90.0,
      investments: (json['investments'] as num?)?.toDouble() ?? 0.0,
      businessGoods: (json['businessGoods'] as num?)?.toDouble() ?? 0.0,
      moneyOwedToYou: (json['moneyOwedToYou'] as num?)?.toDouble() ?? 0.0,
      liabilities: (json['liabilities'] as num?)?.toDouble() ?? 0.0,
      nisabStandard: NisabStandard.values.firstWhere(
        (e) => e.name == json['nisabStandard'],
        orElse: () => NisabStandard.silver,
      ),
      currencySymbol: json['currencySymbol'] as String? ?? '₹',
    );
  }
}
