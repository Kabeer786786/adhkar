enum CharityType {
  sadaqah,
  zakat,
}

enum SadaqahCategory {
  general,
  sadaqahJariyah, // Continuous charity
  foodClothing,
  orphanSupport,
  medicalHelp,
  education,
  mosqueCommunity,
  zakatAlFitr,
  zakatAlMal,
  other,
}

class SadqaRecord {
  final String id;
  final CharityType type;
  final SadaqahCategory category;
  final double amount;
  final String currency;
  final DateTime date;
  final String recipient;
  final String note;

  const SadqaRecord({
    required this.id,
    required this.type,
    required this.category,
    required this.amount,
    this.currency = '₹',
    required this.date,
    this.recipient = '',
    this.note = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'category': category.name,
      'amount': amount,
      'currency': currency,
      'date': date.toIso8601String(),
      'recipient': recipient,
      'note': note,
    };
  }

  factory SadqaRecord.fromJson(Map<String, dynamic> json) {
    return SadqaRecord(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      type: CharityType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => CharityType.sadaqah,
      ),
      category: SadaqahCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => SadaqahCategory.general,
      ),
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? '₹',
      date: json['date'] != null
          ? DateTime.tryParse(json['date'] as String) ?? DateTime.now()
          : DateTime.now(),
      recipient: json['recipient'] as String? ?? '',
      note: json['note'] as String? ?? '',
    );
  }

  SadqaRecord copyWith({
    String? id,
    CharityType? type,
    SadaqahCategory? category,
    double? amount,
    String? currency,
    DateTime? date,
    String? recipient,
    String? note,
  }) {
    return SadqaRecord(
      id: id ?? this.id,
      type: type ?? this.type,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      date: date ?? this.date,
      recipient: recipient ?? this.recipient,
      note: note ?? this.note,
    );
  }
}
