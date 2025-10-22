import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../database/database_helper.dart';
import '../models/inventory_item.dart';
import '../models/inventory_transaction.dart';

class InventoryProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final Uuid _uuid = const Uuid();

  List<InventoryItem> _items = [];
  List<InventoryTransaction> _transactions = [];
  bool _isLoading = false;
  String? _error;

  // Dashboard stats
  Map<String, dynamic> _dashboardStats = {};

  List<InventoryItem> get items => _items;
  List<InventoryTransaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic> get dashboardStats => _dashboardStats;

  // Get items by status
  List<InventoryItem> get inStockItems =>
      _items.where((item) => item.status == ItemStatus.inStock).toList();

  List<InventoryItem> get soldItems =>
      _items.where((item) => item.status == ItemStatus.sold).toList();

  List<InventoryItem> get issuedItems =>
      _items.where((item) => item.status == ItemStatus.issued).toList();

  // Get items by material
  List<InventoryItem> get goldItems =>
      _items.where((item) => item.material == ItemMaterial.gold).toList();

  List<InventoryItem> get silverItems =>
      _items.where((item) => item.material == ItemMaterial.silver).toList();

  // Load all inventory items
  Future<void> loadInventoryItems() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final itemMaps = await _dbHelper.getAllInventoryItems();
      _items = itemMaps.map((map) => InventoryItem.fromMap(map)).toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load dashboard statistics
  Future<void> loadDashboardStats() async {
    try {
      _dashboardStats = await _dbHelper.getInventoryDashboardData();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Create new inventory item
  Future<InventoryItem?> createInventoryItem({
    required String category,
    required String material,
    required String purity,
    required double grossWeight,
    required double netWeight,
    required double makingCharge,
    required int quantity,
    required String location,
    String? photoPath,
    String user = 'admin',
  }) async {
    try {
      final uid = _uuid.v4();
      final sku = await _dbHelper.generateSKU(material, category);
      final now = DateTime.now();

      final item = InventoryItem(
        uid: uid,
        sku: sku,
        category: category,
        material: material,
        purity: purity,
        grossWeight: grossWeight,
        netWeight: netWeight,
        makingCharge: makingCharge,
        quantity: quantity,
        location: location,
        status: ItemStatus.inStock,
        photoPath: photoPath,
        createdAt: now,
        updatedAt: now,
      );

      await _dbHelper.insertInventoryItem(item.toMap());

      // Log transaction
      await _logTransaction(
        itemUid: uid,
        action: TransactionAction.created,
        user: user,
        notes: 'Item created: $sku',
      );

      await loadInventoryItems();
      await loadDashboardStats();
      return item;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Update inventory item
  Future<bool> updateInventoryItem({
    required String uid,
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
    String user = 'admin',
  }) async {
    try {
      final item = _items.firstWhere((item) => item.uid == uid);
      final updatedItem = item.copyWith(
        category: category,
        material: material,
        purity: purity,
        grossWeight: grossWeight,
        netWeight: netWeight,
        makingCharge: makingCharge,
        quantity: quantity,
        location: location,
        status: status,
        photoPath: photoPath,
        updatedAt: DateTime.now(),
      );

      await _dbHelper.updateInventoryItem(uid, updatedItem.toMap());

      // Log transaction
      await _logTransaction(
        itemUid: uid,
        action: TransactionAction.updated,
        user: user,
        notes: 'Item updated: ${item.sku}',
      );

      await loadInventoryItems();
      await loadDashboardStats();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Mark item as sold
  Future<bool> markItemAsSold({
    required String uid,
    String user = 'admin',
    String? notes,
  }) async {
    try {
      final item = _items.firstWhere((item) => item.uid == uid);
      final updatedItem = item.copyWith(
        status: ItemStatus.sold,
        updatedAt: DateTime.now(),
      );

      await _dbHelper.updateInventoryItem(uid, updatedItem.toMap());

      // Log transaction
      await _logTransaction(
        itemUid: uid,
        action: TransactionAction.sold,
        user: user,
        notes: notes ?? 'Item sold: ${item.sku}',
      );

      await loadInventoryItems();
      await loadDashboardStats();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Issue item to Karigar
  Future<bool> issueItemToKarigar({
    required String uid,
    required String karigarName,
    String user = 'admin',
    String? notes,
  }) async {
    try {
      final item = _items.firstWhere((item) => item.uid == uid);
      final updatedItem = item.copyWith(
        status: ItemStatus.issued,
        updatedAt: DateTime.now(),
      );

      await _dbHelper.updateInventoryItem(uid, updatedItem.toMap());

      // Log transaction
      await _logTransaction(
        itemUid: uid,
        action: TransactionAction.issued,
        user: user,
        notes: notes ?? 'Issued to Karigar: $karigarName',
      );

      await loadInventoryItems();
      await loadDashboardStats();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Return item from Karigar
  Future<bool> returnItemFromKarigar({
    required String uid,
    String user = 'admin',
    String? notes,
  }) async {
    try {
      final item = _items.firstWhere((item) => item.uid == uid);
      final updatedItem = item.copyWith(
        status: ItemStatus.returned,
        updatedAt: DateTime.now(),
      );

      await _dbHelper.updateInventoryItem(uid, updatedItem.toMap());

      // Log transaction
      await _logTransaction(
        itemUid: uid,
        action: TransactionAction.returned,
        user: user,
        notes: notes ?? 'Item returned: ${item.sku}',
      );

      await loadInventoryItems();
      await loadDashboardStats();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Delete item
  Future<bool> deleteInventoryItem({
    required String uid,
    String user = 'admin',
  }) async {
    try {
      final item = _items.firstWhere((item) => item.uid == uid);

      // Log transaction before deleting
      await _logTransaction(
        itemUid: uid,
        action: TransactionAction.deleted,
        user: user,
        notes: 'Item deleted: ${item.sku}',
      );

      await _dbHelper.deleteInventoryItem(uid);
      await loadInventoryItems();
      await loadDashboardStats();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Get item by UID
  Future<InventoryItem?> getItemByUid(String uid) async {
    try {
      final itemMap = await _dbHelper.getInventoryItemByUid(uid);
      if (itemMap != null) {
        return InventoryItem.fromMap(itemMap);
      }
      return null;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Get item by SKU
  Future<InventoryItem?> getItemBySku(String sku) async {
    try {
      final itemMap = await _dbHelper.getInventoryItemBySku(sku);
      if (itemMap != null) {
        return InventoryItem.fromMap(itemMap);
      }
      return null;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Search items
  Future<List<InventoryItem>> searchItems(String query) async {
    try {
      final itemMaps = await _dbHelper.searchInventoryItems(query);
      return itemMaps.map((map) => InventoryItem.fromMap(map)).toList();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  // Load transactions for an item
  Future<void> loadTransactionsForItem(String itemUid) async {
    try {
      final transactionMaps = await _dbHelper.getTransactionsByItemUid(itemUid);
      _transactions = transactionMaps
          .map((map) => InventoryTransaction.fromMap(map))
          .toList();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Load all transactions
  Future<void> loadAllTransactions() async {
    try {
      final transactionMaps = await _dbHelper.getAllInventoryTransactions();
      _transactions = transactionMaps
          .map((map) => InventoryTransaction.fromMap(map))
          .toList();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Private helper to log transactions
  Future<void> _logTransaction({
    required String itemUid,
    required String action,
    required String user,
    String? notes,
  }) async {
    final transaction = InventoryTransaction(
      itemUid: itemUid,
      action: action,
      user: user,
      timestamp: DateTime.now(),
      notes: notes,
    );

    await _dbHelper.insertInventoryTransaction(transaction.toMap());
  }

  // Get inventory report
  Future<Map<String, dynamic>> getInventoryReport({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      return await _dbHelper.getInventoryReportByDateRange(startDate, endDate);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return {};
    }
  }

  // Get top selling categories
  Future<List<Map<String, dynamic>>> getTopSellingCategories(int limit) async {
    try {
      return await _dbHelper.getTopSellingCategories(limit);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  // Filter items by category
  List<InventoryItem> filterByCategory(String category) {
    return _items.where((item) => item.category == category).toList();
  }

  // Filter items by material
  List<InventoryItem> filterByMaterial(String material) {
    return _items.where((item) => item.material == material).toList();
  }

  // Filter items by status
  List<InventoryItem> filterByStatus(String status) {
    return _items.where((item) => item.status == status).toList();
  }

  // Calculate total value of inventory
  double calculateTotalInventoryValue(double goldRate, double silverRate) {
    double total = 0.0;
    for (var item in inStockItems) {
      final rate = item.material == ItemMaterial.gold ? goldRate : silverRate;
      total += (item.netWeight * rate) + item.makingCharge;
    }
    return total;
  }

  // Get low stock items (quantity < 5)
  List<InventoryItem> getLowStockItems() {
    return _items
        .where((item) => item.quantity < 5 && item.status == ItemStatus.inStock)
        .toList();
  }
}
