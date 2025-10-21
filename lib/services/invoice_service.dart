import '../models/invoice.dart';
import '../models/customer.dart';
import '../database/database_helper.dart';
import '../models/product.dart';

class InvoiceService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Get all invoices
  Future<List<Invoice>> getAllInvoices() async {
    try {
      return await _dbHelper.getAllInvoices();
    } catch (e) {
      throw Exception('Failed to get all invoices: $e');
    }
  }

  // Get invoices by customer
  Future<List<Invoice>> getInvoicesByCustomer(int customerId) async {
    try {
      return await _dbHelper.getInvoicesByCustomer(customerId);
    } catch (e) {
      throw Exception('Failed to get invoices by customer: $e');
    }
  }

  // Get invoices by date range
  Future<List<Invoice>> getInvoicesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      return await _dbHelper.getInvoicesByDateRange(startDate, endDate);
    } catch (e) {
      throw Exception('Failed to get invoices by date range: $e');
    }
  }

  // Update invoice
  Future<int> updateInvoice(Invoice invoice) async {
    try {
      return await _dbHelper.updateInvoice(invoice);
    } catch (e) {
      throw Exception('Failed to update invoice: $e');
    }
  }

  // Create invoice
  Future<int> createInvoice(Invoice invoice) async {
    try {
      return await _dbHelper.insertInvoice(invoice);
    } catch (e) {
      throw Exception('Failed to create invoice: $e');
    }
  }

  // Generate unique invoice number
  Future<String> generateInvoiceNumber() async {
    try {
      return await _dbHelper.generateInvoiceNumber();
    } catch (e) {
      throw Exception('Failed to generate invoice number: $e');
    }
  }

  // Create invoice from bill items
  Future<Invoice> createInvoiceFromBillItems({
    required String customerName,
    required String customerPhone,
    required List<BillItemData> billItems,
    required double goldRate,
    required double silverRate,
    required int userId,
    double taxPercent = 3.0,
    String? notes,
    double cgstPercent = 1.5,
    double sgstPercent = 1.5,
  }) async {
    try {
      // Create or get customer
      Customer? customer = await _findOrCreateCustomer(
        customerName,
        customerPhone,
      );

      // Generate invoice number
      String invoiceNumber = await generateInvoiceNumber();

      // Convert bill items to invoice items
      List<InvoiceItem> invoiceItems = [];
      double subtotal = 0.0;

      for (var billItem in billItems) {
        double rate = billItem.productType == ProductType.gold
            ? goldRate
            : silverRate;
        double purityFactor = billItem.productType == ProductType.gold
            ? billItem.purity / 24.0
            : billItem.purity / 100.0;

        double metalValue = billItem.weight * rate * purityFactor;

        // Add wastage to metal value
        double wastageAmount = metalValue * (billItem.wastagePercent / 100.0);

        // Calculate total: Metal Value + Wastage + Making Charges
        double itemTotal = metalValue + wastageAmount + billItem.makingCharges;

        InvoiceItem invoiceItem = InvoiceItem(
          itemName: billItem.productName,
          itemType: billItem.productType,
          purity: billItem.productType == ProductType.gold
              ? '${billItem.purity}K'
              : '${billItem.purity}%',
          weight: billItem.weight,
          currentRate: rate,
          makingCharges: billItem.makingCharges,
          wastagePercent: billItem.wastagePercent,
          itemTotal: itemTotal,
          quantity: 1,
        );

        invoiceItems.add(invoiceItem);
        subtotal += itemTotal;
      }

      // Calculate CGST and SGST
      double cgstAmount = subtotal * (cgstPercent / 100);
      double sgstAmount = subtotal * (sgstPercent / 100);
      double taxAmount = cgstAmount + sgstAmount;
      
      // Calculate total with taxes
      double totalAmount = subtotal + taxAmount;

      // Create invoice
      Invoice invoice = Invoice(
        invoiceNumber: invoiceNumber,
        customerId: customer.id!,
        userId: userId,
        invoiceDate: DateTime.now(),
        items: invoiceItems,
        subtotal: subtotal,
        taxPercent: taxAmount, // Using this field to store total tax for database compatibility
        taxAmount: taxAmount,
        totalAmount: totalAmount,
        createdAt: DateTime.now(),
        notes: notes,
      );

      return invoice;
    } catch (e) {
      throw Exception('Failed to create invoice from bill items: $e');
    }
  }

  // Find existing customer or create new one
  Future<Customer> _findOrCreateCustomer(String name, String phone) async {
    try {
      // Try to find existing customer by phone
      if (phone.isNotEmpty) {
        List<Customer> customers = await DatabaseHelper().searchCustomers(
          phone,
        );
        if (customers.isNotEmpty) {
          return customers.first;
        }
      }

      // Create new customer
      Customer newCustomer = Customer(
        name: name,
        phone: phone,
        createdAt: DateTime.now(),
      );

      int customerId = await DatabaseHelper().insertCustomer(newCustomer);
      return newCustomer.copyWith(id: customerId);
    } catch (e) {
      throw Exception('Failed to find or create customer: $e');
    }
  }
}

// Data class for bill items from the UI
class BillItemData {
  final String productName;
  final ProductType productType;
  final double weight;
  final double purity;
  final double makingCharges;
  final double wastagePercent;

  BillItemData({
    required this.productName,
    required this.productType,
    required this.weight,
    required this.purity,
    required this.makingCharges,
    this.wastagePercent = 0.0,
  });
}