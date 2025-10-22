class InventoryTransaction {
  final int? id;
  final String itemUid;
  final String action;
  final String user;
  final DateTime timestamp;
  final String? notes;

  InventoryTransaction({
    this.id,
    required this.itemUid,
    required this.action,
    required this.user,
    required this.timestamp,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'item_uid': itemUid,
      'action': action,
      'user': user,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'notes': notes,
    };
  }

  factory InventoryTransaction.fromMap(Map<String, dynamic> map) {
    return InventoryTransaction(
      id: map['id'] as int?,
      itemUid: map['item_uid'] as String,
      action: map['action'] as String,
      user: map['user'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      notes: map['notes'] as String?,
    );
  }
}

// Transaction actions
class TransactionAction {
  static const String created = 'created';
  static const String updated = 'updated';
  static const String sold = 'sold';
  static const String issued = 'issued';
  static const String returned = 'returned';
  static const String deleted = 'deleted';
  static const String addStock = 'add_stock';
  static const String removeStock = 'remove_stock';

  static List<String> get all => [
    created,
    updated,
    sold,
    issued,
    returned,
    deleted,
    addStock,
    removeStock,
  ];

  static String getDisplayName(String action) {
    switch (action) {
      case created:
        return 'Created';
      case updated:
        return 'Updated';
      case sold:
        return 'Sold';
      case issued:
        return 'Issued to Karigar';
      case returned:
        return 'Returned';
      case deleted:
        return 'Deleted';
      case addStock:
        return 'Stock Added';
      case removeStock:
        return 'Stock Removed';
      default:
        return action;
    }
  }
}
