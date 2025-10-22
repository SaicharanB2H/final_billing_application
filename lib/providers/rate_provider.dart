import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/shop_settings.dart';

class RateProvider extends ChangeNotifier {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  double _goldRate = 5500.0; // Default fallback
  double _silverRate = 75.0; // Default fallback
  double _goldWastage = 8.0; // Default gold wastage %
  double _silverWastage = 5.0; // Default silver wastage %
  double _cgstPercent = 1.5; // Default CGST %
  double _sgstPercent = 1.5; // Default SGST %
  bool _isLoading = false;
  String? _error;

  double get goldRate => _goldRate;
  double get silverRate => _silverRate;
  double get goldWastage => _goldWastage;
  double get silverWastage => _silverWastage;
  double get cgstPercent => _cgstPercent;
  double get sgstPercent => _sgstPercent;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load current rates from database
  Future<void> loadRates() async {
    _setLoading(true);
    _setError(null);

    try {
      final shopSettings = await _databaseHelper.getShopSettings();
      if (shopSettings != null) {
        _goldRate = shopSettings.goldRate;
        _silverRate = shopSettings.silverRate;
        _goldWastage = shopSettings.defaultWastageGold;
        _silverWastage = shopSettings.defaultWastageSilver;
        _cgstPercent = shopSettings.cgstPercent;
        _sgstPercent = shopSettings.sgstPercent;
      }
      notifyListeners();
    } catch (e) {
      _setError('Failed to load rates: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Update gold rate
  Future<bool> updateGoldRate(double newRate) async {
    _setLoading(true);
    _setError(null);

    try {
      final shopSettings = await _databaseHelper.getShopSettings();
      if (shopSettings != null) {
        final updatedSettings = shopSettings.copyWith(
          goldRate: newRate,
          ratesUpdatedAt: DateTime.now(),
        );
        await _databaseHelper.updateShopSettings(updatedSettings);

        _goldRate = newRate;
        notifyListeners();
        return true;
      } else {
        // Create new shop settings if none exist
        final newSettings = ShopSettings(
          shopName: 'Kamakshi Jewellers',
          address: '123 Main Street, City, State 12345',
          phone: '9014296309',
          goldRate: newRate,
          silverRate: _silverRate,
          defaultTaxPercent: 3.0,
          ratesUpdatedAt: DateTime.now(),
          cgstPercent: _cgstPercent,
          sgstPercent: _sgstPercent,
        );
        await _databaseHelper.updateShopSettings(newSettings);

        _goldRate = newRate;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _setError('Failed to update gold rate: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update silver rate
  Future<bool> updateSilverRate(double newRate) async {
    _setLoading(true);
    _setError(null);

    try {
      final shopSettings = await _databaseHelper.getShopSettings();
      if (shopSettings != null) {
        final updatedSettings = shopSettings.copyWith(
          silverRate: newRate,
          ratesUpdatedAt: DateTime.now(),
        );
        await _databaseHelper.updateShopSettings(updatedSettings);

        _silverRate = newRate;
        notifyListeners();
        return true;
      } else {
        // Create new shop settings if none exist
        final newSettings = ShopSettings(
          shopName: 'Kamakshi Jewellers',
          address: '123 Main Street, City, State 12345',
          phone: '9014296309',
          goldRate: _goldRate,
          silverRate: newRate,
          defaultTaxPercent: 3.0,
          ratesUpdatedAt: DateTime.now(),
          cgstPercent: _cgstPercent,
          sgstPercent: _sgstPercent,
        );
        await _databaseHelper.updateShopSettings(newSettings);

        _silverRate = newRate;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _setError('Failed to update silver rate: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update both rates at once
  Future<bool> updateRates(double goldRate, double silverRate) async {
    _setLoading(true);
    _setError(null);

    try {
      final shopSettings = await _databaseHelper.getShopSettings();
      if (shopSettings != null) {
        final updatedSettings = shopSettings.copyWith(
          goldRate: goldRate,
          silverRate: silverRate,
          ratesUpdatedAt: DateTime.now(),
        );
        await _databaseHelper.updateShopSettings(updatedSettings);
      } else {
        // Create new shop settings if none exist
        final newSettings = ShopSettings(
          shopName: 'Kamakshi Jewellers',
          address: '123 Main Street, City, State 12345',
          phone: '9014296309',
          goldRate: goldRate,
          silverRate: silverRate,
          defaultTaxPercent: 3.0,
          ratesUpdatedAt: DateTime.now(),
          cgstPercent: _cgstPercent,
          sgstPercent: _sgstPercent,
        );
        await _databaseHelper.updateShopSettings(newSettings);
      }

      _goldRate = goldRate;
      _silverRate = silverRate;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update rates: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update gold wastage percentage
  Future<bool> updateGoldWastage(double newWastage) async {
    _setLoading(true);
    _setError(null);

    try {
      final shopSettings = await _databaseHelper.getShopSettings();
      if (shopSettings != null) {
        final updatedSettings = shopSettings.copyWith(
          defaultWastageGold: newWastage,
          ratesUpdatedAt: DateTime.now(),
        );
        await _databaseHelper.updateShopSettings(updatedSettings);

        _goldWastage = newWastage;
        notifyListeners();
        return true;
      } else {
        // Create new shop settings if none exist
        final newSettings = ShopSettings(
          shopName: 'Kamakshi Jewellers',
          address: '123 Main Street, City, State 12345',
          phone: '9014296309',
          goldRate: _goldRate,
          silverRate: _silverRate,
          defaultWastageGold: newWastage,
          defaultWastageSilver: _silverWastage,
          defaultTaxPercent: 3.0,
          ratesUpdatedAt: DateTime.now(),
          cgstPercent: _cgstPercent,
          sgstPercent: _sgstPercent,
        );
        await _databaseHelper.updateShopSettings(newSettings);

        _goldWastage = newWastage;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _setError('Failed to update gold wastage: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update silver wastage percentage
  Future<bool> updateSilverWastage(double newWastage) async {
    _setLoading(true);
    _setError(null);

    try {
      final shopSettings = await _databaseHelper.getShopSettings();
      if (shopSettings != null) {
        final updatedSettings = shopSettings.copyWith(
          defaultWastageSilver: newWastage,
          ratesUpdatedAt: DateTime.now(),
        );
        await _databaseHelper.updateShopSettings(updatedSettings);

        _silverWastage = newWastage;
        notifyListeners();
        return true;
      } else {
        // Create new shop settings if none exist
        final newSettings = ShopSettings(
          shopName: 'Kamakshi Jewellers',
          address: '123 Main Street, City, State 12345',
          phone: '9014296309',
          goldRate: _goldRate,
          silverRate: _silverRate,
          defaultWastageGold: _goldWastage,
          defaultWastageSilver: newWastage,
          defaultTaxPercent: 3.0,
          ratesUpdatedAt: DateTime.now(),
          cgstPercent: _cgstPercent,
          sgstPercent: _sgstPercent,
        );
        await _databaseHelper.updateShopSettings(newSettings);

        _silverWastage = newWastage;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _setError('Failed to update silver wastage: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update CGST percentage
  Future<bool> updateCgstPercent(double newCgst) async {
    _setLoading(true);
    _setError(null);

    try {
      final shopSettings = await _databaseHelper.getShopSettings();
      if (shopSettings != null) {
        final updatedSettings = shopSettings.copyWith(
          cgstPercent: newCgst,
          ratesUpdatedAt: DateTime.now(),
        );
        await _databaseHelper.updateShopSettings(updatedSettings);

        _cgstPercent = newCgst;
        notifyListeners();
        return true;
      } else {
        // Create new shop settings if none exist
        final newSettings = ShopSettings(
          shopName: 'Kamakshi Jewellers',
          address: '123 Main Street, City, State 12345',
          phone: '9014296309',
          goldRate: _goldRate,
          silverRate: _silverRate,
          defaultWastageGold: _goldWastage,
          defaultWastageSilver: _silverWastage,
          defaultTaxPercent: 3.0,
          ratesUpdatedAt: DateTime.now(),
          cgstPercent: newCgst,
          sgstPercent: _sgstPercent,
        );
        await _databaseHelper.updateShopSettings(newSettings);

        _cgstPercent = newCgst;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _setError('Failed to update CGST percentage: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update SGST percentage
  Future<bool> updateSgstPercent(double newSgst) async {
    _setLoading(true);
    _setError(null);

    try {
      final shopSettings = await _databaseHelper.getShopSettings();
      if (shopSettings != null) {
        final updatedSettings = shopSettings.copyWith(
          sgstPercent: newSgst,
          ratesUpdatedAt: DateTime.now(),
        );
        await _databaseHelper.updateShopSettings(updatedSettings);

        _sgstPercent = newSgst;
        notifyListeners();
        return true;
      } else {
        // Create new shop settings if none exist
        final newSettings = ShopSettings(
          shopName: 'Kamakshi Jewellers',
          address: '123 Main Street, City, State 12345',
          phone: '9014296309',
          goldRate: _goldRate,
          silverRate: _silverRate,
          defaultWastageGold: _goldWastage,
          defaultWastageSilver: _silverWastage,
          defaultTaxPercent: 3.0,
          ratesUpdatedAt: DateTime.now(),
          cgstPercent: _cgstPercent,
          sgstPercent: newSgst,
        );
        await _databaseHelper.updateShopSettings(newSettings);

        _sgstPercent = newSgst;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _setError('Failed to update SGST percentage: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Get formatted rate display
  String getFormattedGoldRate() {
    return '₹${_goldRate.toStringAsFixed(0)}/g';
  }

  String getFormattedSilverRate() {
    return '₹${_silverRate.toStringAsFixed(0)}/g';
  }

  // Get formatted wastage display
  String getFormattedGoldWastage() {
    return '${_goldWastage.toStringAsFixed(1)}%';
  }

  String getFormattedSilverWastage() {
    return '${_silverWastage.toStringAsFixed(1)}%';
  }

  // Get formatted CGST/SGST display
  String getFormattedCgstPercent() {
    return '${_cgstPercent.toStringAsFixed(1)}%';
  }

  String getFormattedSgstPercent() {
    return '${_sgstPercent.toStringAsFixed(1)}%';
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
