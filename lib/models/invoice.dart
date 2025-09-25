import 'product.dart';

class Invoice {
  final int? id;
  final String invoiceNumber;
  final int customerId;
  final int userId; // Who created the invoice
  final DateTime invoiceDate;
  final List<InvoiceItem> items;
  final double subtotal;
  final double discountAmount;
  final double discountPercent;
  final double taxPercent; // GST percentage
  final double taxAmount;
  final double totalAmount;
  final PaymentStatus paymentStatus;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Invoice({
    this.id,
    required this.invoiceNumber,
    required this.customerId,
    required this.userId,
    required this.invoiceDate,
    required this.items,
    required this.subtotal,
    this.discountAmount = 0.0,
    this.discountPercent = 0.0,
    required this.taxPercent,
    required this.taxAmount,
    required this.totalAmount,
    this.paymentStatus = PaymentStatus.pending,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice_number': invoiceNumber,
      'customer_id': customerId,
      'user_id': userId,
      'invoice_date': invoiceDate.toIso8601String(),
      'subtotal': subtotal,
      'discount_amount': discountAmount,
      'discount_percent': discountPercent,
      'tax_percent': taxPercent,
      'tax_amount': taxAmount,
      'total_amount': totalAmount,
      'payment_status': paymentStatus.toString().split('.').last,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Invoice.fromMap(Map<String, dynamic> map, List<InvoiceItem> items) {
    return Invoice(
      id: map['id'],
      invoiceNumber: map['invoice_number'],
      customerId: map['customer_id'],
      userId: map['user_id'],
      invoiceDate: DateTime.parse(map['invoice_date']),
      items: items,
      subtotal: map['subtotal'].toDouble(),
      discountAmount: map['discount_amount'].toDouble(),
      discountPercent: map['discount_percent'].toDouble(),
      taxPercent: map['tax_percent'].toDouble(),
      taxAmount: map['tax_amount'].toDouble(),
      totalAmount: map['total_amount'].toDouble(),
      paymentStatus: PaymentStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['payment_status'],
      ),
      notes: map['notes'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : null,
    );
  }
}

class InvoiceItem {
  final int? id;
  final int? invoiceId;
  final int? productId; // nullable for custom items
  final String itemName;
  final ProductType itemType;
  final String purity;
  final double weight;
  final double currentRate; // Rate at time of sale
  final double makingCharges;
  final double wastagePercent;
  final double? stoneCharges;
  final double itemTotal;
  final int quantity;

  InvoiceItem({
    this.id,
    this.invoiceId,
    this.productId,
    required this.itemName,
    required this.itemType,
    required this.purity,
    required this.weight,
    required this.currentRate,
    required this.makingCharges,
    required this.wastagePercent,
    this.stoneCharges,
    required this.itemTotal,
    this.quantity = 1,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice_id': invoiceId,
      'product_id': productId,
      'item_name': itemName,
      'item_type': itemType.toString().split('.').last,
      'purity': purity,
      'weight': weight,
      'current_rate': currentRate,
      'making_charges': makingCharges,
      'wastage_percent': wastagePercent,
      'stone_charges': stoneCharges,
      'item_total': itemTotal,
      'quantity': quantity,
    };
  }

  factory InvoiceItem.fromMap(Map<String, dynamic> map) {
    return InvoiceItem(
      id: map['id'],
      invoiceId: map['invoice_id'],
      productId: map['product_id'],
      itemName: map['item_name'],
      itemType: ProductType.values.firstWhere(
        (e) => e.toString().split('.').last == map['item_type'],
      ),
      purity: map['purity'],
      weight: map['weight'].toDouble(),
      currentRate: map['current_rate'].toDouble(),
      makingCharges: map['making_charges'].toDouble(),
      wastagePercent: map['wastage_percent'].toDouble(),
      stoneCharges: map['stone_charges']?.toDouble(),
      itemTotal: map['item_total'].toDouble(),
      quantity: map['quantity'],
    );
  }

  factory InvoiceItem.fromProduct(
    Product product,
    double currentRate, {
    int quantity = 1,
  }) {
    double itemTotal = product.calculatePrice(currentRate, null) * quantity;

    return InvoiceItem(
      productId: product.id,
      itemName: product.name,
      itemType: product.type,
      purity: product.purity,
      weight: product.weight,
      currentRate: currentRate,
      makingCharges: product.makingCharges,
      wastagePercent: product.wastagePercent,
      stoneCharges: product.stoneCharges,
      itemTotal: itemTotal,
      quantity: quantity,
    );
  }
}

enum PaymentStatus { pending, partial, paid, cancelled }
