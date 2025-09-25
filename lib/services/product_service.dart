import '../database/database_helper.dart';
import '../models/models.dart';

class ProductService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Get all products
  Future<List<Product>> getAllProducts() async {
    return await _dbHelper.getAllProducts();
  }

  // Get products by type
  Future<List<Product>> getProductsByType(ProductType type) async {
    return await _dbHelper.getProductsByType(type);
  }

  // Get product by ID
  Future<Product?> getProductById(int id) async {
    return await _dbHelper.getProductById(id);
  }

  // Add new product
  Future<ProductResult> addProduct(Product product) async {
    try {
      // Validate product data
      final validation = validateProduct(product);
      if (validation != null) {
        return ProductResult(success: false, message: validation);
      }

      final id = await _dbHelper.insertProduct(product);
      if (id > 0) {
        final newProduct = product.copyWith(id: id);
        return ProductResult(
          success: true,
          message: 'Product added successfully',
          product: newProduct,
        );
      } else {
        return ProductResult(success: false, message: 'Failed to add product');
      }
    } catch (e) {
      return ProductResult(
        success: false,
        message: 'Error adding product: ${e.toString()}',
      );
    }
  }

  // Update product
  Future<ProductResult> updateProduct(Product product) async {
    try {
      // Validate product data
      final validation = validateProduct(product);
      if (validation != null) {
        return ProductResult(success: false, message: validation);
      }

      final result = await _dbHelper.updateProduct(product);
      if (result > 0) {
        return ProductResult(
          success: true,
          message: 'Product updated successfully',
          product: product,
        );
      } else {
        return ProductResult(
          success: false,
          message: 'Failed to update product',
        );
      }
    } catch (e) {
      return ProductResult(
        success: false,
        message: 'Error updating product: ${e.toString()}',
      );
    }
  }

  // Delete product
  Future<ProductResult> deleteProduct(int id) async {
    try {
      final result = await _dbHelper.deleteProduct(id);
      if (result > 0) {
        return ProductResult(
          success: true,
          message: 'Product deleted successfully',
        );
      } else {
        return ProductResult(
          success: false,
          message: 'Failed to delete product',
        );
      }
    } catch (e) {
      return ProductResult(
        success: false,
        message: 'Error deleting product: ${e.toString()}',
      );
    }
  }

  // Calculate product price
  double calculateProductPrice(
    Product product,
    double currentRate, {
    double? discount,
  }) {
    return product.calculatePrice(currentRate, discount);
  }

  // Validate product data
  String? validateProduct(Product product) {
    if (product.name.trim().isEmpty) {
      return 'Product name is required';
    }

    if (product.weight <= 0) {
      return 'Weight must be greater than 0';
    }

    if (product.makingCharges < 0) {
      return 'Making charges cannot be negative';
    }

    if (product.wastagePercent < 0 || product.wastagePercent > 100) {
      return 'Wastage percentage must be between 0 and 100';
    }

    if (product.stoneCharges != null && product.stoneCharges! < 0) {
      return 'Stone charges cannot be negative';
    }

    if (product.stockQuantity != null && product.stockQuantity! < 0) {
      return 'Stock quantity cannot be negative';
    }

    // Validate purity based on product type
    if (product.type == ProductType.gold) {
      final validGoldPurities = ['24K', '22K', '18K', '14K'];
      if (!validGoldPurities.contains(product.purity)) {
        return 'Invalid gold purity. Use: ${validGoldPurities.join(', ')}';
      }
    } else if (product.type == ProductType.silver) {
      final validSilverPurities = ['99.9', '92.5'];
      if (!validSilverPurities.contains(product.purity)) {
        return 'Invalid silver purity. Use: ${validSilverPurities.join(', ')}';
      }
    }

    return null; // No validation errors
  }

  // Get purity options for product type
  List<String> getPurityOptions(ProductType type) {
    switch (type) {
      case ProductType.gold:
        return ['24K', '22K', '18K', '14K'];
      case ProductType.silver:
        return ['99.9', '92.5'];
    }
  }

  // Get default making charge for product type
  double getDefaultMakingCharge(ProductType type) {
    switch (type) {
      case ProductType.gold:
        return 500.0;
      case ProductType.silver:
        return 50.0;
    }
  }

  // Get default wastage percentage for product type
  double getDefaultWastagePercent(ProductType type) {
    switch (type) {
      case ProductType.gold:
        return 8.0;
      case ProductType.silver:
        return 5.0;
    }
  }

  // Search products
  Future<List<Product>> searchProducts(String query) async {
    if (query.isEmpty) {
      return await getAllProducts();
    }

    final allProducts = await getAllProducts();
    return allProducts.where((product) {
      return product.name.toLowerCase().contains(query.toLowerCase()) ||
          product.type.toString().toLowerCase().contains(query.toLowerCase()) ||
          product.purity.toLowerCase().contains(query.toLowerCase()) ||
          (product.description?.toLowerCase().contains(query.toLowerCase()) ??
              false);
    }).toList();
  }
}

class ProductResult {
  final bool success;
  final String message;
  final Product? product;

  ProductResult({required this.success, required this.message, this.product});
}
