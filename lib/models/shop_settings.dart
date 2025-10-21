
class ShopSettings {
  final int? id;
  final String shopName;
  final String address;
  final String phone;
  final String? email;
  final String? gstin;
  final String? logoPath;
  final String? signaturePath;
  final double goldRate; // Current gold rate per gram
  final double silverRate; // Current silver rate per gram
  final double defaultTaxPercent; // Default GST percentage
  final double defaultMakingChargeGold; // Default making charge for gold
  final double defaultMakingChargeSilver; // Default making charge for silver
  final double defaultWastageGold; // Default wastage % for gold
  final double defaultWastageSilver; // Default wastage % for silver
  final String currencySymbol;
  final DateTime ratesUpdatedAt;
  final DateTime? updatedAt;
  // New fields for CGST and SGST
  final double cgstPercent;
  final double sgstPercent;

  ShopSettings({
    this.id,
    required this.shopName,
    required this.address,
    required this.phone,
    this.email,
    this.gstin,
    this.logoPath,
    this.signaturePath,
    required this.goldRate,
    required this.silverRate,
    this.defaultTaxPercent = 3.0, // 3% GST on jewelry
    this.defaultMakingChargeGold = 500.0,
    this.defaultMakingChargeSilver = 50.0,
    this.defaultWastageGold = 8.0,
    this.defaultWastageSilver = 5.0,
    this.currencySymbol = '₹',
    required this.ratesUpdatedAt,
    this.updatedAt,
    this.cgstPercent = 1.5, // Default CGST 1.5%
    this.sgstPercent = 1.5, // Default SGST 1.5%
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'shop_name': shopName,
      'address': address,
      'phone': phone,
      'email': email,
      'gstin': gstin,
      'logo_path': logoPath,
      'signature_path': signaturePath,
      'gold_rate': goldRate,
      'silver_rate': silverRate,
      'default_tax_percent': defaultTaxPercent,
      'default_making_charge_gold': defaultMakingChargeGold,
      'default_making_charge_silver': defaultMakingChargeSilver,
      'default_wastage_gold': defaultWastageGold,
      'default_wastage_silver': defaultWastageSilver,
      'currency_symbol': currencySymbol,
      'rates_updated_at': ratesUpdatedAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'cgst_percent': cgstPercent,
      'sgst_percent': sgstPercent,
    };
  }

  factory ShopSettings.fromMap(Map<String, dynamic> map) {
    return ShopSettings(
      id: map['id'],
      shopName: map['shop_name'],
      address: map['address'],
      phone: map['phone'],
      email: map['email'],
      gstin: map['gstin'],
      logoPath: map['logo_path'],
      signaturePath: map['signature_path'],
      goldRate: map['gold_rate'].toDouble(),
      silverRate: map['silver_rate'].toDouble(),
      defaultTaxPercent: map['default_tax_percent'].toDouble(),
      defaultMakingChargeGold: map['default_making_charge_gold'].toDouble(),
      defaultMakingChargeSilver: map['default_making_charge_silver'].toDouble(),
      defaultWastageGold: map['default_wastage_gold'].toDouble(),
      defaultWastageSilver: map['default_wastage_silver'].toDouble(),
      currencySymbol: map['currency_symbol'],
      ratesUpdatedAt: DateTime.parse(map['rates_updated_at']),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : null,
      cgstPercent: map['cgst_percent']?.toDouble() ?? 1.5,
      sgstPercent: map['sgst_percent']?.toDouble() ?? 1.5,
    );
  }

  ShopSettings copyWith({
    int? id,
    String? shopName,
    String? address,
    String? phone,
    String? email,
    String? gstin,
    String? logoPath,
    String? signaturePath,
    double? goldRate,
    double? silverRate,
    double? defaultTaxPercent,
    double? defaultMakingChargeGold,
    double? defaultMakingChargeSilver,
    double? defaultWastageGold,
    double? defaultWastageSilver,
    String? currencySymbol,
    DateTime? ratesUpdatedAt,
    DateTime? updatedAt,
    double? cgstPercent,
    double? sgstPercent,
  }) {
    return ShopSettings(
      id: id ?? this.id,
      shopName: shopName ?? this.shopName,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      gstin: gstin ?? this.gstin,
      logoPath: logoPath ?? this.logoPath,
      signaturePath: signaturePath ?? this.signaturePath,
      goldRate: goldRate ?? this.goldRate,
      silverRate: silverRate ?? this.silverRate,
      defaultTaxPercent: defaultTaxPercent ?? this.defaultTaxPercent,
      defaultMakingChargeGold:
          defaultMakingChargeGold ?? this.defaultMakingChargeGold,
      defaultMakingChargeSilver:
          defaultMakingChargeSilver ?? this.defaultMakingChargeSilver,
      defaultWastageGold: defaultWastageGold ?? this.defaultWastageGold,
      defaultWastageSilver: defaultWastageSilver ?? this.defaultWastageSilver,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      ratesUpdatedAt: ratesUpdatedAt ?? this.ratesUpdatedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      cgstPercent: cgstPercent ?? this.cgstPercent,
      sgstPercent: sgstPercent ?? this.sgstPercent,
    );
  }
}