import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/product_service.dart';

class ProductProvider with ChangeNotifier {
  final ProductService _productService = ProductService();

  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = false;
  String _searchQuery = '';
  ProductType? _selectedType;
  Product? _selectedProduct;

  List<Product> get products => _filteredProducts;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  ProductType? get selectedType => _selectedType;
  Product? get selectedProduct => _selectedProduct;

  // Load all products
  Future<void> loadProducts() async {
    _setLoading(true);

    try {
      _products = await _productService.getAllProducts();
      _applyFilters();
    } catch (e) {
      // Handle error
    }

    _setLoading(false);
    notifyListeners();
  }

  // Load products by type
  Future<void> loadProductsByType(ProductType type) async {
    _setLoading(true);

    try {
      _products = await _productService.getProductsByType(type);
      _selectedType = type;
      _applyFilters();
    } catch (e) {
      // Handle error
    }

    _setLoading(false);
    notifyListeners();
  }

  // Search products
  Future<void> searchProducts(String query) async {
    _searchQuery = query;

    if (query.isEmpty) {
      _filteredProducts = List.from(_products);
    } else {
      _setLoading(true);

      try {
        _filteredProducts = await _productService.searchProducts(query);
      } catch (e) {
        // Handle error
      }

      _setLoading(false);
    }

    notifyListeners();
  }

  // Filter by type
  void filterByType(ProductType? type) {
    _selectedType = type;
    _applyFilters();
    notifyListeners();
  }

  // Add product
  Future<ProductResult> addProduct(Product product) async {
    _setLoading(true);

    try {
      final result = await _productService.addProduct(product);

      if (result.success) {
        _products.add(result.product!);
        _applyFilters();
      }

      _setLoading(false);
      return result;
    } catch (e) {
      _setLoading(false);
      return ProductResult(
        success: false,
        message: 'Error adding product: ${e.toString()}',
      );
    }
  }

  // Update product
  Future<ProductResult> updateProduct(Product product) async {
    _setLoading(true);

    try {
      final result = await _productService.updateProduct(product);

      if (result.success) {
        final index = _products.indexWhere((p) => p.id == product.id);
        if (index != -1) {
          _products[index] = product;
          _applyFilters();
        }

        if (_selectedProduct?.id == product.id) {
          _selectedProduct = product;
        }
      }

      _setLoading(false);
      return result;
    } catch (e) {
      _setLoading(false);
      return ProductResult(
        success: false,
        message: 'Error updating product: ${e.toString()}',
      );
    }
  }

  // Delete product
  Future<ProductResult> deleteProduct(int productId) async {
    _setLoading(true);

    try {
      final result = await _productService.deleteProduct(productId);

      if (result.success) {
        _products.removeWhere((p) => p.id == productId);
        _applyFilters();

        if (_selectedProduct?.id == productId) {
          _selectedProduct = null;
        }
      }

      _setLoading(false);
      return result;
    } catch (e) {
      _setLoading(false);
      return ProductResult(
        success: false,
        message: 'Error deleting product: ${e.toString()}',
      );
    }
  }

  // Select product
  void selectProduct(Product? product) {
    _selectedProduct = product;
    notifyListeners();
  }

  // Get product by ID
  Future<Product?> getProductById(int id) async {
    return await _productService.getProductById(id);
  }

  // Calculate product price
  double calculateProductPrice(
    Product product,
    double currentRate, {
    double? discount,
  }) {
    return _productService.calculateProductPrice(
      product,
      currentRate,
      discount: discount,
    );
  }

  // Validate product
  String? validateProduct(Product product) {
    return _productService.validateProduct(product);
  }

  // Get purity options
  List<String> getPurityOptions(ProductType type) {
    return _productService.getPurityOptions(type);
  }

  // Get default making charge
  double getDefaultMakingCharge(ProductType type) {
    return _productService.getDefaultMakingCharge(type);
  }

  // Get default wastage percentage
  double getDefaultWastagePercent(ProductType type) {
    return _productService.getDefaultWastagePercent(type);
  }

  // Clear search and filters
  void clearFilters() {
    _searchQuery = '';
    _selectedType = null;
    _filteredProducts = List.from(_products);
    notifyListeners();
  }

  // Apply filters
  void _applyFilters() {
    List<Product> filtered = List.from(_products);

    // Apply type filter
    if (_selectedType != null) {
      filtered = filtered
          .where((product) => product.type == _selectedType)
          .toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((product) {
        return product.name.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            product.type.toString().toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            product.purity.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (product.description?.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ??
                false);
      }).toList();
    }

    _filteredProducts = filtered;

    // Only notify listeners if we're not in the middle of loading
    if (!_isLoading) {
      notifyListeners();
    }
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Refresh products
  Future<void> refresh() async {
    await loadProducts();
  }

  // Get products summary
  Map<String, int> getProductsSummary() {
    final goldCount = _products.where((p) => p.type == ProductType.gold).length;
    final silverCount = _products
        .where((p) => p.type == ProductType.silver)
        .length;

    return {
      'total': _products.length,
      'gold': goldCount,
      'silver': silverCount,
    };
  }
}
