import '../database/database_helper.dart';
import '../models/models.dart';

class CustomerService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Get all customers
  Future<List<Customer>> getAllCustomers() async {
    return await _dbHelper.getAllCustomers();
  }

  // Search customers
  Future<List<Customer>> searchCustomers(String query) async {
    if (query.isEmpty) {
      return await getAllCustomers();
    }
    return await _dbHelper.searchCustomers(query);
  }

  // Get customer by ID
  Future<Customer?> getCustomerById(int id) async {
    return await _dbHelper.getCustomerById(id);
  }

  // Add new customer
  Future<CustomerResult> addCustomer(Customer customer) async {
    try {
      // Check if phone number already exists
      final existingCustomers = await searchCustomers(customer.phone);
      if (existingCustomers.any((c) => c.phone == customer.phone)) {
        return CustomerResult(
          success: false,
          message: 'Customer with this phone number already exists',
        );
      }

      final id = await _dbHelper.insertCustomer(customer);
      if (id > 0) {
        final newCustomer = customer.copyWith(id: id);
        return CustomerResult(
          success: true,
          message: 'Customer added successfully',
          customer: newCustomer,
        );
      } else {
        return CustomerResult(
          success: false,
          message: 'Failed to add customer',
        );
      }
    } catch (e) {
      return CustomerResult(
        success: false,
        message: 'Error adding customer: ${e.toString()}',
      );
    }
  }

  // Update customer
  Future<CustomerResult> updateCustomer(Customer customer) async {
    try {
      // Check if phone number already exists for other customers
      final existingCustomers = await searchCustomers(customer.phone);
      if (existingCustomers.any(
        (c) => c.phone == customer.phone && c.id != customer.id,
      )) {
        return CustomerResult(
          success: false,
          message: 'Another customer with this phone number already exists',
        );
      }

      final result = await _dbHelper.updateCustomer(customer);
      if (result > 0) {
        return CustomerResult(
          success: true,
          message: 'Customer updated successfully',
          customer: customer,
        );
      } else {
        return CustomerResult(
          success: false,
          message: 'Failed to update customer',
        );
      }
    } catch (e) {
      return CustomerResult(
        success: false,
        message: 'Error updating customer: ${e.toString()}',
      );
    }
  }

  // Delete customer
  Future<CustomerResult> deleteCustomer(int id) async {
    try {
      // Check if customer has any invoices
      final invoices = await _dbHelper.getInvoicesByCustomer(id);
      if (invoices.isNotEmpty) {
        return CustomerResult(
          success: false,
          message: 'Cannot delete customer with existing invoices',
        );
      }

      final result = await _dbHelper.deleteCustomer(id);
      if (result > 0) {
        return CustomerResult(
          success: true,
          message: 'Customer deleted successfully',
        );
      } else {
        return CustomerResult(
          success: false,
          message: 'Failed to delete customer',
        );
      }
    } catch (e) {
      return CustomerResult(
        success: false,
        message: 'Error deleting customer: ${e.toString()}',
      );
    }
  }

  // Get customer purchase history
  Future<List<Invoice>> getCustomerPurchaseHistory(int customerId) async {
    return await _dbHelper.getInvoicesByCustomer(customerId);
  }

  // Validate customer data
  String? validateCustomer(Customer customer) {
    if (customer.name.trim().isEmpty) {
      return 'Customer name is required';
    }

    if (customer.phone.trim().isEmpty) {
      return 'Phone number is required';
    }

    if (customer.phone.length < 10) {
      return 'Phone number must be at least 10 digits';
    }

    // Validate GSTIN format if provided
    if (customer.gstin != null && customer.gstin!.isNotEmpty) {
      final gstinRegex = RegExp(
        r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$',
      );
      if (!gstinRegex.hasMatch(customer.gstin!)) {
        return 'Invalid GSTIN format';
      }
    }

    return null; // No validation errors
  }
}

class CustomerResult {
  final bool success;
  final String message;
  final Customer? customer;

  CustomerResult({required this.success, required this.message, this.customer});
}
