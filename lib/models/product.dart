class Product {
  final int? id;
  final String name;
  final ProductType type; // Gold or Silver
  final String purity; // 22K, 24K, 92.5, etc.
  final double weight; // in grams
  final double makingCharges;
  final double wastagePercent;
  final double? stoneCharges;
  final String? description;
  final int? stockQuantity;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Product({
    this.id,
    required this.name,
    required this.type,
    required this.purity,
    required this.weight,
    required this.makingCharges,
    required this.wastagePercent,
    this.stoneCharges,
    this.description,
    this.stockQuantity,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.toString().split('.').last,
      'purity': purity,
      'weight': weight,
      'making_charges': makingCharges,
      'wastage_percent': wastagePercent,
      'stone_charges': stoneCharges,
      'description': description,
      'stock_quantity': stockQuantity,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      type: ProductType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
      ),
      purity: map['purity'],
      weight: map['weight'].toDouble(),
      makingCharges: map['making_charges'].toDouble(),
      wastagePercent: map['wastage_percent'].toDouble(),
      stoneCharges: map['stone_charges']?.toDouble(),
      description: map['description'],
      stockQuantity: map['stock_quantity'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : null,
    );
  }

  Product copyWith({
    int? id,
    String? name,
    ProductType? type,
    String? purity,
    double? weight,
    double? makingCharges,
    double? wastagePercent,
    double? stoneCharges,
    String? description,
    int? stockQuantity,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      purity: purity ?? this.purity,
      weight: weight ?? this.weight,
      makingCharges: makingCharges ?? this.makingCharges,
      wastagePercent: wastagePercent ?? this.wastagePercent,
      stoneCharges: stoneCharges ?? this.stoneCharges,
      description: description ?? this.description,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  double calculatePrice(double currentRate, double? discount) {
    // Get purity factor
    double purityFactor = _getPurityFactor();

    // Base price calculation
    double basePrice = weight * currentRate * purityFactor;

    // Add wastage
    double wastageAmount = basePrice * (wastagePercent / 100);
    basePrice += wastageAmount;

    // Add making charges
    basePrice += makingCharges;

    // Add stone charges
    if (stoneCharges != null) {
      basePrice += stoneCharges!;
    }

    // Apply discount
    if (discount != null && discount > 0) {
      basePrice -= discount;
    }

    return basePrice;
  }

  double _getPurityFactor() {
    switch (type) {
      case ProductType.gold:
        switch (purity) {
          case '24K':
            return 1.0;
          case '22K':
            return 22.0 / 24.0;
          case '18K':
            return 18.0 / 24.0;
          case '14K':
            return 14.0 / 24.0;
          default:
            return 1.0;
        }
      case ProductType.silver:
        switch (purity) {
          case '99.9':
            return 1.0;
          case '92.5':
            return 0.925;
          default:
            return 1.0;
        }
    }
  }
}

enum ProductType { gold, silver }
