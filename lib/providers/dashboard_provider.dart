import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';

class DashboardProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Dashboard stats
  double _todaySales = 0.0;
  int _todayInvoiceCount = 0;
  double _monthSales = 0.0;
  int _monthInvoiceCount = 0;
  int _customerCount = 0;
  int _productCount = 0;
  int _pendingInvoiceCount = 0;
  double _pendingInvoiceAmount = 0.0;

  bool _isLoading = false;
  String? _error;

  // Getters
  double get todaySales => _todaySales;
  int get todayInvoiceCount => _todayInvoiceCount;
  double get monthSales => _monthSales;
  int get monthInvoiceCount => _monthInvoiceCount;
  int get customerCount => _customerCount;
  int get productCount => _productCount;
  int get pendingInvoiceCount => _pendingInvoiceCount;
  double get pendingInvoiceAmount => _pendingInvoiceAmount;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load all dashboard data from database
  Future<void> loadDashboardData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _dbHelper.getDashboardData();

      _todaySales = (data['todaySales'] as num).toDouble();
      _todayInvoiceCount = data['todayInvoiceCount'] as int;
      _monthSales = (data['monthSales'] as num).toDouble();
      _monthInvoiceCount = data['monthInvoiceCount'] as int;
      _customerCount = data['customerCount'] as int;
      _productCount = data['productCount'] as int;
      _pendingInvoiceCount = data['pendingInvoiceCount'] as int;
      _pendingInvoiceAmount = (data['pendingInvoiceAmount'] as num).toDouble();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load dashboard data: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh dashboard data
  Future<void> refresh() async {
    await loadDashboardData();
  }

  /// Format currency
  String formatCurrency(double amount) {
    return '₹${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }
}
