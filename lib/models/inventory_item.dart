class InventoryItem {
  final String uid;
  final String sku;
  final String category;
  final String material;
  final String purity;
  final double grossWeight;
  final double netWeight;
  final double makingCharge;
  final int quantity;
  final String location;
  final String status;
  final String? photoPath;
  final DateTime createdAt;
  final DateTime updatedAt;

  InventoryItem({
    required this.uid,
    required this.sku,
    required this.category,
    required this.material,
    required this.purity,
    required this.grossWeight,
    required this.netWeight,
    required this.makingCharge,
    required this.quantity,
    required this.location,
    required this.status,
    this.photoPath,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'sku': sku,
      'category': category,
      'material': material,
      'purity': purity,
      'gross_weight': grossWeight,
      'net_weight': netWeight,
      'making_charge': makingCharge,
      'quantity': quantity,
      'location': location,
      'status': status,
      'photo_path': photoPath,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory InventoryItem.fromMap(Map<String, dynamic> map) {
    return InventoryItem(
      uid: map['uid'] as String,
      sku: map['sku'] as String,
      category: map['category'] as String,
      material: map['material'] as String,
      purity: map['purity'] as String,
      grossWeight: (map['gross_weight'] as num).toDouble(),
      netWeight: (map['net_weight'] as num).toDouble(),
      makingCharge: (map['making_charge'] as num).toDouble(),
      quantity: map['quantity'] as int,
      location: map['location'] as String,
      status: map['status'] as String,
      photoPath: map['photo_path'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  InventoryItem copyWith({
    String? uid,
    String? sku,
    String? category,
    String? material,
    String? purity,
    double? grossWeight,
    double? netWeight,
    double? makingCharge,
    int? quantity,
    String? location,
    String? status,
    String? photoPath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InventoryItem(
      uid: uid ?? this.uid,
      sku: sku ?? this.sku,
      category: category ?? this.category,
      material: material ?? this.material,
      purity: purity ?? this.purity,
      grossWeight: grossWeight ?? this.grossWeight,
      netWeight: netWeight ?? this.netWeight,
      makingCharge: makingCharge ?? this.makingCharge,
      quantity: quantity ?? this.quantity,
      location: location ?? this.location,
      status: status ?? this.status,
      photoPath: photoPath ?? this.photoPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toQRData() {
    return {'uid': uid, 'sku': sku};
  }
}

// Item categories
class ItemCategory {
  static const String ring = 'Ring';
  static const String chain = 'Chain';
  static const String necklace = 'Necklace';
  static const String bangle = 'Bangle';
  static const String earring = 'Earring';
  static const String bracelet = 'Bracelet';
  static const String pendant = 'Pendant';
  static const String anklet = 'Anklet';
  static const String nosePi = 'Nose Pin';
  static const String mangalsutra = 'Mangalsutra';
  static const String other = 'Other';

  static List<String> get all => [
    ring,
    chain,
    necklace,
    bangle,
    earring,
    bracelet,
    pendant,
    anklet,
    nosePi,
    mangalsutra,
    other,
  ];
}

// Item materials
class ItemMaterial {
  static const String gold = 'Gold';
  static const String silver = 'Silver';

  static List<String> get all => [gold, silver];
}

// Item purity levels
class ItemPurity {
  static const String k24 = '24K';
  static const String k22 = '22K';
  static const String k18 = '18K';
  static const String k14 = '14K';
  static const String s925 = '925 Silver';
  static const String s999 = '999 Silver';

  static List<String> goldPurities = [k24, k22, k18, k14];
  static List<String> silverPurities = [s925, s999];

  static List<String> getPuritiesForMaterial(String material) {
    if (material == ItemMaterial.gold) {
      return goldPurities;
    } else if (material == ItemMaterial.silver) {
      return silverPurities;
    }
    return [];
  }
}

// Item status
class ItemStatus {
  static const String inStock = 'in_stock';
  static const String sold = 'sold';
  static const String issued = 'issued';
  static const String returned = 'returned';

  static List<String> get all => [inStock, sold, issued, returned];

  static String getDisplayName(String status) {
    switch (status) {
      case inStock:
        return 'In Stock';
      case sold:
        return 'Sold';
      case issued:
        return 'Issued to Karigar';
      case returned:
        return 'Returned';
      default:
        return status;
    }
  }
}
