import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../models/invoice.dart';
import '../models/customer.dart';
import '../models/inventory_item.dart';
import '../database/database_helper.dart';

class DataExportService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Export invoices to CSV format
  Future<String> exportInvoicesToCsv({
    DateTime? startDate,
    DateTime? endDate,
    int? customerId,
  }) async {
    try {
      List<Invoice> invoices = await _getFilteredInvoices(
        startDate: startDate,
        endDate: endDate,
        customerId: customerId,
      );

      StringBuffer csvContent = StringBuffer();

      // Add CSV headers
      csvContent.writeln(
        'Invoice Number,Customer Name,Customer Phone,Invoice Date,'
        'Items Count,Subtotal,Tax Amount,Total Amount,Payment Status,Notes',
      );

      // Add invoice data
      for (var invoice in invoices) {
        Customer? customer = await _dbHelper.getCustomerById(
          invoice.customerId,
        );

        csvContent.writeln(
          '"${invoice.invoiceNumber}",'
          '"${customer?.name ?? 'Unknown'}",'
          '"${customer?.phone ?? ''}",'
          '"${DateFormat('dd/MM/yyyy').format(invoice.invoiceDate)}",'
          '${invoice.items.length},'
          '${invoice.subtotal.toStringAsFixed(2)},'
          '${invoice.taxAmount.toStringAsFixed(2)},'
          '${invoice.totalAmount.toStringAsFixed(2)},'
          '"${_getPaymentStatusText(invoice.paymentStatus)}",'
          '"${invoice.notes ?? ''}"',
        );
      }

      // Save CSV file
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'invoices_export_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
      final filePath = '${directory.path}/$fileName';

      final file = File(filePath);
      await file.writeAsString(csvContent.toString());

      return filePath;
    } catch (e) {
      throw Exception('Failed to export invoices to CSV: $e');
    }
  }

  // Export detailed invoices with items to CSV
  Future<String> exportDetailedInvoicesToCsv({
    DateTime? startDate,
    DateTime? endDate,
    int? customerId,
  }) async {
    try {
      List<Invoice> invoices = await _getFilteredInvoices(
        startDate: startDate,
        endDate: endDate,
        customerId: customerId,
      );

      StringBuffer csvContent = StringBuffer();

      // Add CSV headers
      csvContent.writeln(
        'Invoice Number,Customer Name,Customer Phone,Invoice Date,'
        'Item Name,Item Type,Weight,Purity,Rate,Making Charges,Item Total,'
        'Invoice Subtotal,Tax Amount,Total Amount,Payment Status',
      );

      // Add detailed invoice data
      for (var invoice in invoices) {
        Customer? customer = await _dbHelper.getCustomerById(
          invoice.customerId,
        );

        for (var item in invoice.items) {
          csvContent.writeln(
            '"${invoice.invoiceNumber}",'
            '"${customer?.name ?? 'Unknown'}",'
            '"${customer?.phone ?? ''}",'
            '"${DateFormat('dd/MM/yyyy').format(invoice.invoiceDate)}",'
            '"${item.itemName}",'
            '"${item.itemType.toString().split('.').last.toUpperCase()}",'
            '${item.weight.toStringAsFixed(3)},'
            '"${item.purity}",'
            '${item.currentRate.toStringAsFixed(2)},'
            '${item.makingCharges.toStringAsFixed(2)},'
            '${item.itemTotal.toStringAsFixed(2)},'
            '${invoice.subtotal.toStringAsFixed(2)},'
            '${invoice.taxAmount.toStringAsFixed(2)},'
            '${invoice.totalAmount.toStringAsFixed(2)},'
            '"${_getPaymentStatusText(invoice.paymentStatus)}"',
          );
        }
      }

      // Save CSV file
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'detailed_invoices_export_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
      final filePath = '${directory.path}/$fileName';

      final file = File(filePath);
      await file.writeAsString(csvContent.toString());

      return filePath;
    } catch (e) {
      throw Exception('Failed to export detailed invoices to CSV: $e');
    }
  }

  // Export invoices to Excel format
  Future<String> exportInvoicesToExcel({
    DateTime? startDate,
    DateTime? endDate,
    int? customerId,
  }) async {
    try {
      List<Invoice> invoices = await _getFilteredInvoices(
        startDate: startDate,
        endDate: endDate,
        customerId: customerId,
      );

      var excel = Excel.createExcel();
      Sheet sheet = excel['Invoices'];

      // Add headers
      sheet.cell(CellIndex.indexByString('A1')).value = TextCellValue(
        'Invoice Number',
      );
      sheet.cell(CellIndex.indexByString('B1')).value = TextCellValue(
        'Customer Name',
      );
      sheet.cell(CellIndex.indexByString('C1')).value = TextCellValue(
        'Customer Phone',
      );
      sheet.cell(CellIndex.indexByString('D1')).value = TextCellValue(
        'Invoice Date',
      );
      sheet.cell(CellIndex.indexByString('E1')).value = TextCellValue(
        'Items Count',
      );
      sheet.cell(CellIndex.indexByString('F1')).value = TextCellValue(
        'Subtotal',
      );
      sheet.cell(CellIndex.indexByString('G1')).value = TextCellValue(
        'Tax Amount',
      );
      sheet.cell(CellIndex.indexByString('H1')).value = TextCellValue(
        'Total Amount',
      );
      sheet.cell(CellIndex.indexByString('I1')).value = TextCellValue(
        'Payment Status',
      );
      sheet.cell(CellIndex.indexByString('J1')).value = TextCellValue('Notes');

      // Add invoice data
      int row = 2;
      for (var invoice in invoices) {
        Customer? customer = await _dbHelper.getCustomerById(
          invoice.customerId,
        );

        sheet.cell(CellIndex.indexByString('A$row')).value = TextCellValue(
          invoice.invoiceNumber,
        );
        sheet.cell(CellIndex.indexByString('B$row')).value = TextCellValue(
          customer?.name ?? 'Unknown',
        );
        sheet.cell(CellIndex.indexByString('C$row')).value = TextCellValue(
          customer?.phone ?? '',
        );
        sheet.cell(CellIndex.indexByString('D$row')).value = TextCellValue(
          DateFormat('dd/MM/yyyy').format(invoice.invoiceDate),
        );
        sheet.cell(CellIndex.indexByString('E$row')).value = IntCellValue(
          invoice.items.length,
        );
        sheet.cell(CellIndex.indexByString('F$row')).value = DoubleCellValue(
          invoice.subtotal,
        );
        sheet.cell(CellIndex.indexByString('G$row')).value = DoubleCellValue(
          invoice.taxAmount,
        );
        sheet.cell(CellIndex.indexByString('H$row')).value = DoubleCellValue(
          invoice.totalAmount,
        );
        sheet.cell(CellIndex.indexByString('I$row')).value = TextCellValue(
          _getPaymentStatusText(invoice.paymentStatus),
        );
        sheet.cell(CellIndex.indexByString('J$row')).value = TextCellValue(
          invoice.notes ?? '',
        );

        row++;
      }

      // Create detailed items sheet
      Sheet itemsSheet = excel['Invoice Items'];

      // Add headers for items sheet
      itemsSheet.cell(CellIndex.indexByString('A1')).value = TextCellValue(
        'Invoice Number',
      );
      itemsSheet.cell(CellIndex.indexByString('B1')).value = TextCellValue(
        'Customer Name',
      );
      itemsSheet.cell(CellIndex.indexByString('C1')).value = TextCellValue(
        'Item Name',
      );
      itemsSheet.cell(CellIndex.indexByString('D1')).value = TextCellValue(
        'Item Type',
      );
      itemsSheet.cell(CellIndex.indexByString('E1')).value = TextCellValue(
        'Weight (g)',
      );
      itemsSheet.cell(CellIndex.indexByString('F1')).value = TextCellValue(
        'Purity',
      );
      itemsSheet.cell(CellIndex.indexByString('G1')).value = TextCellValue(
        'Rate per gram',
      );
      itemsSheet.cell(CellIndex.indexByString('H1')).value = TextCellValue(
        'Making Charges',
      );
      itemsSheet.cell(CellIndex.indexByString('I1')).value = TextCellValue(
        'Item Total',
      );

      // Add items data
      int itemRow = 2;
      for (var invoice in invoices) {
        Customer? customer = await _dbHelper.getCustomerById(
          invoice.customerId,
        );

        for (var item in invoice.items) {
          itemsSheet.cell(CellIndex.indexByString('A$itemRow')).value =
              TextCellValue(invoice.invoiceNumber);
          itemsSheet.cell(CellIndex.indexByString('B$itemRow')).value =
              TextCellValue(customer?.name ?? 'Unknown');
          itemsSheet.cell(CellIndex.indexByString('C$itemRow')).value =
              TextCellValue(item.itemName);
          itemsSheet
              .cell(CellIndex.indexByString('D$itemRow'))
              .value = TextCellValue(
            item.itemType.toString().split('.').last.toUpperCase(),
          );
          itemsSheet.cell(CellIndex.indexByString('E$itemRow')).value =
              DoubleCellValue(item.weight);
          itemsSheet.cell(CellIndex.indexByString('F$itemRow')).value =
              TextCellValue(item.purity);
          itemsSheet.cell(CellIndex.indexByString('G$itemRow')).value =
              DoubleCellValue(item.currentRate);
          itemsSheet.cell(CellIndex.indexByString('H$itemRow')).value =
              DoubleCellValue(item.makingCharges);
          itemsSheet.cell(CellIndex.indexByString('I$itemRow')).value =
              DoubleCellValue(item.itemTotal);

          itemRow++;
        }
      }

      // Save Excel file
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'invoices_export_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
      final filePath = '${directory.path}/$fileName';

      List<int>? excelBytes = excel.save();
      if (excelBytes == null) {
        throw Exception('Failed to generate Excel file');
      }
      final file = File(filePath);
      await file.writeAsBytes(excelBytes);

      return filePath;
    } catch (e) {
      throw Exception('Failed to export invoices to Excel: $e');
    }
  }

  // Export invoices to JSON format
  Future<String> exportInvoicesToJson({
    DateTime? startDate,
    DateTime? endDate,
    int? customerId,
  }) async {
    try {
      List<Invoice> invoices = await _getFilteredInvoices(
        startDate: startDate,
        endDate: endDate,
        customerId: customerId,
      );

      List<Map<String, dynamic>> exportData = [];

      for (var invoice in invoices) {
        Customer? customer = await _dbHelper.getCustomerById(
          invoice.customerId,
        );

        Map<String, dynamic> invoiceData = {
          'invoiceNumber': invoice.invoiceNumber,
          'customer': {
            'id': customer?.id,
            'name': customer?.name ?? 'Unknown',
            'phone': customer?.phone ?? '',
            'email': customer?.email,
            'address': customer?.address,
          },
          'invoiceDate': invoice.invoiceDate.toIso8601String(),
          'items': invoice.items
              .map(
                (item) => {
                  'itemName': item.itemName,
                  'itemType': item.itemType.toString().split('.').last,
                  'weight': item.weight,
                  'purity': item.purity,
                  'currentRate': item.currentRate,
                  'makingCharges': item.makingCharges,
                  'wastagePercent': item.wastagePercent,
                  'stoneCharges': item.stoneCharges,
                  'itemTotal': item.itemTotal,
                  'quantity': item.quantity,
                },
              )
              .toList(),
          'subtotal': invoice.subtotal,
          'discountAmount': invoice.discountAmount,
          'discountPercent': invoice.discountPercent,
          // Tax fields removed from export
          'totalAmount': invoice.totalAmount,
          'paymentStatus': invoice.paymentStatus.toString().split('.').last,
          'notes': invoice.notes,
          'createdAt': invoice.createdAt.toIso8601String(),
          'updatedAt': invoice.updatedAt?.toIso8601String(),
        };

        exportData.add(invoiceData);
      }

      Map<String, dynamic> finalData = {
        'exportDate': DateTime.now().toIso8601String(),
        'totalInvoices': exportData.length,
        'dateRange': {
          'startDate': startDate?.toIso8601String(),
          'endDate': endDate?.toIso8601String(),
        },
        'invoices': exportData,
      };

      // Save JSON file
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'invoices_export_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.json';
      final filePath = '${directory.path}/$fileName';

      final file = File(filePath);
      await file.writeAsString(jsonEncode(finalData));

      return filePath;
    } catch (e) {
      throw Exception('Failed to export invoices to JSON: $e');
    }
  }

  // Share exported file
  Future<void> shareExportedFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        final fileName = filePath.split('/').last;

        await Printing.sharePdf(
          bytes: Uint8List.fromList(bytes),
          filename: fileName,
        );
      } else {
        throw Exception('File not found');
      }
    } catch (e) {
      throw Exception('Failed to share file: $e');
    }
  }

  // Get filtered invoices based on criteria
  Future<List<Invoice>> _getFilteredInvoices({
    DateTime? startDate,
    DateTime? endDate,
    int? customerId,
  }) async {
    if (startDate != null && endDate != null) {
      return await _dbHelper.getInvoicesByDateRange(startDate, endDate);
    } else if (customerId != null) {
      return await _dbHelper.getInvoicesByCustomer(customerId);
    } else {
      return await _dbHelper.getAllInvoices();
    }
  }

  // Get payment status text
  String _getPaymentStatusText(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return 'PAID';
      case PaymentStatus.pending:
        return 'PENDING';
      case PaymentStatus.partial:
        return 'PARTIAL';
      case PaymentStatus.cancelled:
        return 'CANCELLED';
    }
  }

  // Get export statistics
  Future<Map<String, dynamic>> getExportStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      List<Invoice> invoices = await _getFilteredInvoices(
        startDate: startDate,
        endDate: endDate,
      );

      double totalSales = 0;
      double totalTax = 0;
      int goldItems = 0;
      int silverItems = 0;
      Map<String, int> paymentStatusCount = {
        'paid': 0,
        'pending': 0,
        'partial': 0,
        'cancelled': 0,
      };

      for (var invoice in invoices) {
        totalSales += invoice.totalAmount;
        totalTax += invoice.taxAmount;

        String status = invoice.paymentStatus.toString().split('.').last;
        paymentStatusCount[status] = (paymentStatusCount[status] ?? 0) + 1;

        for (var item in invoice.items) {
          if (item.itemType.toString().contains('gold')) {
            goldItems++;
          } else if (item.itemType.toString().contains('silver')) {
            silverItems++;
          }
        }
      }

      return {
        'totalInvoices': invoices.length,
        'totalSales': totalSales,
        'totalTax': totalTax,
        'goldItems': goldItems,
        'silverItems': silverItems,
        'paymentStatusCount': paymentStatusCount,
        'dateRange': {
          'startDate': startDate?.toIso8601String(),
          'endDate': endDate?.toIso8601String(),
        },
      };
    } catch (e) {
      throw Exception('Failed to get export statistics: $e');
    }
  }

  // Export inventory database file (SQLite)
  Future<String> exportInventoryDatabase() async {
    try {
      // Get the database file path
      final dbPath = join(await getDatabasesPath(), 'jewelry_shop.db');
      final dbFile = File(dbPath);

      if (!await dbFile.exists()) {
        throw Exception('Database file not found');
      }

      // Create export directory
      final directory = await getApplicationDocumentsDirectory();
      final exportDir = Directory('${directory.path}/exports');
      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }

      // Create export file with timestamp
      final fileName =
          'inventory_database_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.db';
      final filePath = '${exportDir.path}/$fileName';

      // Copy database file
      await dbFile.copy(filePath);

      return filePath;
    } catch (e) {
      throw Exception('Failed to export inventory database: $e');
    }
  }

  // Export inventory to Excel format
  Future<String> exportInventoryToExcel() async {
    try {
      // Get all inventory items from database
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> inventoryData = await db.query(
        'inventory_items',
        orderBy: 'created_at DESC',
      );

      var excel = Excel.createExcel();
      Sheet sheet = excel['Inventory Items'];

      // Add headers
      sheet.cell(CellIndex.indexByString('A1')).value = TextCellValue('UID');
      sheet.cell(CellIndex.indexByString('B1')).value = TextCellValue('SKU');
      sheet.cell(CellIndex.indexByString('C1')).value = TextCellValue(
        'Category',
      );
      sheet.cell(CellIndex.indexByString('D1')).value = TextCellValue(
        'Material',
      );
      sheet.cell(CellIndex.indexByString('E1')).value = TextCellValue('Purity');
      sheet.cell(CellIndex.indexByString('F1')).value = TextCellValue(
        'Gross Weight (g)',
      );
      sheet.cell(CellIndex.indexByString('G1')).value = TextCellValue(
        'Net Weight (g)',
      );
      sheet.cell(CellIndex.indexByString('H1')).value = TextCellValue(
        'Making Charge',
      );
      sheet.cell(CellIndex.indexByString('I1')).value = TextCellValue(
        'Quantity',
      );
      sheet.cell(CellIndex.indexByString('J1')).value = TextCellValue(
        'Location',
      );
      sheet.cell(CellIndex.indexByString('K1')).value = TextCellValue('Status');
      sheet.cell(CellIndex.indexByString('L1')).value = TextCellValue(
        'Created Date',
      );
      sheet.cell(CellIndex.indexByString('M1')).value = TextCellValue(
        'Updated Date',
      );

      // Add inventory data
      int row = 2;
      for (var item in inventoryData) {
        sheet.cell(CellIndex.indexByString('A$row')).value = TextCellValue(
          item['uid'] as String,
        );
        sheet.cell(CellIndex.indexByString('B$row')).value = TextCellValue(
          item['sku'] as String,
        );
        sheet.cell(CellIndex.indexByString('C$row')).value = TextCellValue(
          item['category'] as String,
        );
        sheet.cell(CellIndex.indexByString('D$row')).value = TextCellValue(
          item['material'] as String,
        );
        sheet.cell(CellIndex.indexByString('E$row')).value = TextCellValue(
          item['purity'] as String,
        );
        sheet.cell(CellIndex.indexByString('F$row')).value = DoubleCellValue(
          (item['gross_weight'] as num).toDouble(),
        );
        sheet.cell(CellIndex.indexByString('G$row')).value = DoubleCellValue(
          (item['net_weight'] as num).toDouble(),
        );
        sheet.cell(CellIndex.indexByString('H$row')).value = DoubleCellValue(
          (item['making_charge'] as num).toDouble(),
        );
        sheet.cell(CellIndex.indexByString('I$row')).value = IntCellValue(
          item['quantity'] as int,
        );
        sheet.cell(CellIndex.indexByString('J$row')).value = TextCellValue(
          item['location'] as String,
        );
        sheet.cell(CellIndex.indexByString('K$row')).value = TextCellValue(
          _getInventoryStatusText(item['status'] as String),
        );
        sheet.cell(CellIndex.indexByString('L$row')).value = TextCellValue(
          DateFormat('dd/MM/yyyy HH:mm').format(
            DateTime.fromMillisecondsSinceEpoch(item['created_at'] as int),
          ),
        );
        sheet.cell(CellIndex.indexByString('M$row')).value = TextCellValue(
          DateFormat('dd/MM/yyyy HH:mm').format(
            DateTime.fromMillisecondsSinceEpoch(item['updated_at'] as int),
          ),
        );

        row++;
      }

      // Create summary sheet
      Sheet summarySheet = excel['Summary'];

      summarySheet.cell(CellIndex.indexByString('A1')).value = TextCellValue(
        'Inventory Summary Report',
      );
      summarySheet.cell(CellIndex.indexByString('A2')).value = TextCellValue(
        'Generated: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
      );

      summarySheet.cell(CellIndex.indexByString('A4')).value = TextCellValue(
        'Total Items:',
      );
      summarySheet.cell(CellIndex.indexByString('B4')).value = IntCellValue(
        inventoryData.length,
      );

      // Calculate stats
      int goldCount = inventoryData
          .where((item) => item['material'] == ItemMaterial.gold)
          .length;
      int silverCount = inventoryData
          .where((item) => item['material'] == ItemMaterial.silver)
          .length;
      int inStockCount = inventoryData
          .where((item) => item['status'] == ItemStatus.inStock)
          .length;
      int soldCount = inventoryData
          .where((item) => item['status'] == ItemStatus.sold)
          .length;

      double totalGoldWeight = inventoryData
          .where(
            (item) =>
                item['material'] == ItemMaterial.gold &&
                item['status'] == ItemStatus.inStock,
          )
          .fold(0.0, (sum, item) => sum + (item['net_weight'] as num));

      double totalSilverWeight = inventoryData
          .where(
            (item) =>
                item['material'] == ItemMaterial.silver &&
                item['status'] == ItemStatus.inStock,
          )
          .fold(0.0, (sum, item) => sum + (item['net_weight'] as num));

      summarySheet.cell(CellIndex.indexByString('A5')).value = TextCellValue(
        'Gold Items:',
      );
      summarySheet.cell(CellIndex.indexByString('B5')).value = IntCellValue(
        goldCount,
      );

      summarySheet.cell(CellIndex.indexByString('A6')).value = TextCellValue(
        'Silver Items:',
      );
      summarySheet.cell(CellIndex.indexByString('B6')).value = IntCellValue(
        silverCount,
      );

      summarySheet.cell(CellIndex.indexByString('A7')).value = TextCellValue(
        'In Stock:',
      );
      summarySheet.cell(CellIndex.indexByString('B7')).value = IntCellValue(
        inStockCount,
      );

      summarySheet.cell(CellIndex.indexByString('A8')).value = TextCellValue(
        'Sold:',
      );
      summarySheet.cell(CellIndex.indexByString('B8')).value = IntCellValue(
        soldCount,
      );

      summarySheet.cell(CellIndex.indexByString('A10')).value = TextCellValue(
        'Total Gold Weight (in stock):',
      );
      summarySheet.cell(CellIndex.indexByString('B10')).value = TextCellValue(
        '${totalGoldWeight.toStringAsFixed(2)} g',
      );

      summarySheet.cell(CellIndex.indexByString('A11')).value = TextCellValue(
        'Total Silver Weight (in stock):',
      );
      summarySheet.cell(CellIndex.indexByString('B11')).value = TextCellValue(
        '${totalSilverWeight.toStringAsFixed(2)} g',
      );

      // Save Excel file
      final directory = await getApplicationDocumentsDirectory();
      final exportDir = Directory('${directory.path}/exports');
      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }

      final fileName =
          'inventory_export_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
      final filePath = '${exportDir.path}/$fileName';

      List<int>? excelBytes = excel.save();
      if (excelBytes == null) {
        throw Exception('Failed to generate Excel file');
      }
      final file = File(filePath);
      await file.writeAsBytes(excelBytes);

      return filePath;
    } catch (e) {
      throw Exception('Failed to export inventory to Excel: $e');
    }
  }

  // Get inventory status text
  String _getInventoryStatusText(String status) {
    return ItemStatus.getDisplayName(status);
  }
}
