import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../models/models.dart';
import '../services/customer_service.dart';

class CustomerProvider with ChangeNotifier {
  final CustomerService _customerService = CustomerService();

  List<Customer> _customers = [];
  List<Customer> _filteredCustomers = [];
  bool _isLoading = false;
  String _searchQuery = '';
  Customer? _selectedCustomer;

  List<Customer> get customers => _filteredCustomers;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  Customer? get selectedCustomer => _selectedCustomer;

  // Load all customers
  Future<void> loadCustomers() async {
    if (_isLoading) return; // Prevent multiple simultaneous loads

    _setLoading(true);

    try {
      _customers = await _customerService.getAllCustomers();
      _filteredCustomers = List.from(_customers);
    } catch (e) {
      // Handle error
    }

    _setLoading(false);
  }

  // Search customers
  Future<void> searchCustomers(String query) async {
    _searchQuery = query;

    if (query.isEmpty) {
      _filteredCustomers = List.from(_customers);
      notifyListeners();
    } else {
      // Only set loading if we're actually doing a search
      if (_customers.isEmpty) {
        _setLoading(true);

        try {
          _filteredCustomers = await _customerService.searchCustomers(query);
        } catch (e) {
          // Handle error
        }

        _setLoading(false);
      } else {
        // Filter locally without loading state
        _filteredCustomers = _customers.where((customer) {
          return customer.name.toLowerCase().contains(query.toLowerCase()) ||
              customer.phone.contains(query);
        }).toList();
        notifyListeners();
      }
    }
  }

  // Add customer
  Future<CustomerResult> addCustomer(Customer customer) async {
    _setLoading(true);

    try {
      final result = await _customerService.addCustomer(customer);

      if (result.success) {
        _customers.add(result.customer!);
        _applySearchFilter();
      }

      _setLoading(false);
      return result;
    } catch (e) {
      _setLoading(false);
      return CustomerResult(
        success: false,
        message: 'Error adding customer: ${e.toString()}',
      );
    }
  }

  // Update customer
  Future<CustomerResult> updateCustomer(Customer customer) async {
    _setLoading(true);

    try {
      final result = await _customerService.updateCustomer(customer);

      if (result.success) {
        final index = _customers.indexWhere((c) => c.id == customer.id);
        if (index != -1) {
          _customers[index] = customer;
          _applySearchFilter();
        }

        if (_selectedCustomer?.id == customer.id) {
          _selectedCustomer = customer;
        }
      }

      _setLoading(false);
      return result;
    } catch (e) {
      _setLoading(false);
      return CustomerResult(
        success: false,
        message: 'Error updating customer: ${e.toString()}',
      );
    }
  }

  // Delete customer
  Future<CustomerResult> deleteCustomer(int customerId) async {
    _setLoading(true);

    try {
      final result = await _customerService.deleteCustomer(customerId);

      if (result.success) {
        _customers.removeWhere((c) => c.id == customerId);
        _applySearchFilter();

        if (_selectedCustomer?.id == customerId) {
          _selectedCustomer = null;
        }
      }

      _setLoading(false);
      return result;
    } catch (e) {
      _setLoading(false);
      return CustomerResult(
        success: false,
        message: 'Error deleting customer: ${e.toString()}',
      );
    }
  }

  // Select customer
  void selectCustomer(Customer? customer) {
    _selectedCustomer = customer;
    notifyListeners();
  }

  // Get customer by ID
  Future<Customer?> getCustomerById(int id) async {
    return await _customerService.getCustomerById(id);
  }

  // Get customer purchase history
  Future<List<Invoice>> getCustomerPurchaseHistory(int customerId) async {
    return await _customerService.getCustomerPurchaseHistory(customerId);
  }

  // Validate customer
  String? validateCustomer(Customer customer) {
    return _customerService.validateCustomer(customer);
  }

  // Clear search
  void clearSearch() {
    _searchQuery = '';
    _filteredCustomers = List.from(_customers);
    notifyListeners();
  }

  // Apply search filter
  void _applySearchFilter() {
    if (_searchQuery.isEmpty) {
      _filteredCustomers = List.from(_customers);
    } else {
      _filteredCustomers = _customers
          .where(
            (customer) =>
                customer.name.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                customer.phone.contains(_searchQuery),
          )
          .toList();
    }
    // Notify listeners without causing setState during build
    notifyListeners();
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Refresh customers
  Future<void> refresh() async {
    await loadCustomers();
  }
}
