import 'package:flutter/foundation.dart';
import '../models/invoice.dart';
import '../models/customer.dart';
import '../models/shop_settings.dart';
import '../services/invoice_service.dart';
import '../services/pdf_service.dart';
import '../database/database_helper.dart';

class InvoiceProvider extends ChangeNotifier {
  final InvoiceService _invoiceService = InvoiceService();
  final PdfService _pdfService = PdfService();
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  List<Invoice> _invoices = [];
  bool _isLoading = false;
  String? _error;

  List<Invoice> get invoices => _invoices;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load all invoices
  Future<void> loadInvoices() async {
    _setLoading(true);
    _setError(null);

    try {
      _invoices = await _invoiceService.getAllInvoices();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load invoices: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Create invoice from bill data
  Future<Invoice?> createInvoiceFromBill({
    required String customerName,
    required String customerPhone,
    required List<BillItemData> billItems,
    required double goldRate,
    required double silverRate,
    required int userId,
    double taxPercent = 0.0, // Default to 0 (no tax)
    String? notes,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      // Create invoice
      Invoice invoice = await _invoiceService.createInvoiceFromBillItems(
        customerName: customerName,
        customerPhone: customerPhone,
        billItems: billItems,
        goldRate: goldRate,
        silverRate: silverRate,
        userId: userId,
        taxPercent: taxPercent,
        notes: notes,
      );

      // Save to database
      int invoiceId = await _invoiceService.createInvoice(invoice);
      invoice = invoice.copyWith(id: invoiceId);

      // Add to local list
      _invoices.insert(0, invoice);
      notifyListeners();

      return invoice;
    } catch (e) {
      _setError('Failed to create invoice: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Generate and open PDF for invoice
  Future<String?> generateInvoicePdf(Invoice invoice) async {
    _setLoading(true);
    _setError(null);

    try {
      // Get customer details
      Customer? customer = await _databaseHelper.getCustomerById(
        invoice.customerId,
      );
      if (customer == null) {
        throw Exception('Customer not found');
      }

      // Get shop settings
      ShopSettings? shopSettings = await _databaseHelper.getShopSettings();

      // Generate and open PDF
      String filePath = await _pdfService.savePdfAndOpen(
        invoice: invoice,
        customer: customer,
        shopSettings: shopSettings,
      );

      return filePath;
    } catch (e) {
      _setError('Failed to generate PDF: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Get invoices by customer
  Future<List<Invoice>> getInvoicesByCustomer(int customerId) async {
    try {
      return await _invoiceService.getInvoicesByCustomer(customerId);
    } catch (e) {
      _setError('Failed to get customer invoices: $e');
      return [];
    }
  }

  // Get invoices by date range
  Future<List<Invoice>> getInvoicesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      return await _invoiceService.getInvoicesByDateRange(startDate, endDate);
    } catch (e) {
      _setError('Failed to get invoices by date range: $e');
      return [];
    }
  }

  // Update invoice payment status
  Future<bool> updateInvoicePaymentStatus(
    int invoiceId,
    PaymentStatus status,
  ) async {
    _setLoading(true);
    _setError(null);

    try {
      // Find invoice in local list
      int index = _invoices.indexWhere((inv) => inv.id == invoiceId);
      if (index == -1) {
        throw Exception('Invoice not found');
      }

      // Update invoice
      Invoice updatedInvoice = _invoices[index].copyWith(
        paymentStatus: status,
        updatedAt: DateTime.now(),
      );

      await _invoiceService.updateInvoice(updatedInvoice);

      // Update local list
      _invoices[index] = updatedInvoice;
      notifyListeners();

      return true;
    } catch (e) {
      _setError('Failed to update invoice: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Generate invoice number
  Future<String> generateInvoiceNumber() async {
    try {
      return await _invoiceService.generateInvoiceNumber();
    } catch (e) {
      _setError('Failed to generate invoice number: $e');
      return 'INV-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }
}

// Extension to add copyWith method to Invoice
extension InvoiceCopyWith on Invoice {
  Invoice copyWith({
    int? id,
    String? invoiceNumber,
    int? customerId,
    int? userId,
    DateTime? invoiceDate,
    List<InvoiceItem>? items,
    double? subtotal,
    double? discountAmount,
    double? discountPercent,
    double? taxPercent,
    double? taxAmount,
    double? totalAmount,
    PaymentStatus? paymentStatus,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Invoice(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      customerId: customerId ?? this.customerId,
      userId: userId ?? this.userId,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      discountAmount: discountAmount ?? this.discountAmount,
      discountPercent: discountPercent ?? this.discountPercent,
      taxPercent: taxPercent ?? this.taxPercent,
      taxAmount: taxAmount ?? this.taxAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// Extension to add copyWith method to Customer
extension CustomerCopyWith on Customer {
  Customer copyWith({
    int? id,
    String? name,
    String? phone,
    String? email,
    String? address,
    String? gstin,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      gstin: gstin ?? this.gstin,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
