import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../models/product.dart';
import '../../models/inventory_item.dart';
import '../../providers/invoice_provider.dart';
import '../../providers/rate_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../services/invoice_service.dart';

class NewBillScreen extends StatefulWidget {
  const NewBillScreen({super.key});

  @override
  State<NewBillScreen> createState() => _NewBillScreenState();
}

class _NewBillScreenState extends State<NewBillScreen> {
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customerPhoneController =
      TextEditingController();
  final List<BillItem> _billItems = [];
  final List<String> _scannedInventoryUids =
      []; // Track scanned inventory items
  double _subtotal = 0.0;
  double _cgstAmount = 0.0;
  double _sgstAmount = 0.0;
  double _totalAmount = 0.0;
  double _goldRate = 5500.0;
  double _silverRate = 75.0;
  double _goldWastage = 8.0;
  double _silverWastage = 5.0;
  double _cgstPercent = 1.5;
  double _sgstPercent = 1.5;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRates();
    });
  }

  void _loadRates() {
    final rateProvider = Provider.of<RateProvider>(context, listen: false);
    setState(() {
      _goldRate = rateProvider.goldRate;
      _silverRate = rateProvider.silverRate;
      _goldWastage = rateProvider.goldWastage;
      _silverWastage = rateProvider.silverWastage;
      _cgstPercent = rateProvider.cgstPercent;
      _sgstPercent = rateProvider.sgstPercent;
    });
  }

  void _addNewBillItem() {
    setState(() {
      _billItems.add(
        BillItem(
          id: DateTime.now().toString(),
          productName: '',
          productType: BillProductType.gold,
          weight: 0.0,
          purity: 22.0,
          makingCharges: 0.0,
          rate: _goldRate,
          wastagePercent: _goldWastage,
        ),
      );
    });
  }

  void _scanInventoryItem() async {
    final result = await showDialog<InventoryItem?>(
      context: context,
      builder: (context) => const _BarcodeScannerDialog(),
    );

    if (result != null) {
      // Check if item is already scanned
      if (_scannedInventoryUids.contains(result.uid)) {
        _showSnackBar('This item is already added to the bill');
        return;
      }

      // Check if item is available for sale
      if (result.status != ItemStatus.inStock) {
        _showSnackBar(
          'This item is not available for sale (Status: ${ItemStatus.getDisplayName(result.status)})',
        );
        return;
      }

      // Add inventory item to bill with pre-filled values
      setState(() {
        final productType = result.material == ItemMaterial.gold
            ? BillProductType.gold
            : BillProductType.silver;

        final rate = productType == BillProductType.gold
            ? _goldRate
            : _silverRate;
        final wastage = productType == BillProductType.gold
            ? _goldWastage
            : _silverWastage;

        // Extract purity value (e.g., "22K" -> 22, "925 Silver" -> 92.5)
        double purityValue = _extractPurityValue(
          result.purity,
          result.material,
        );

        final billItem = BillItem(
          id: DateTime.now().toString(),
          productName: '${result.category} (${result.sku})',
          productType: productType,
          weight: result.netWeight,
          purity: purityValue,
          makingCharges: result.makingCharge,
          rate: rate,
          wastagePercent: wastage,
          inventoryUid: result.uid, // Link to inventory item
        );

        billItem.calculateTotal();
        _billItems.add(billItem);
        _scannedInventoryUids.add(result.uid);
        _calculateTotal();
      });

      _showSnackBar(
        'Added ${result.category} (${result.sku}) to bill - Review details below',
      );
    }
  }

  double _extractPurityValue(String purity, String material) {
    // Extract numeric value from purity string
    if (material == ItemMaterial.gold) {
      // For gold: "22K" -> 22, "18K" -> 18, etc.
      final match = RegExp(r'(\d+)K').firstMatch(purity);
      if (match != null) {
        return double.parse(match.group(1)!);
      }
      return 22.0; // Default
    } else {
      // For silver: "925 Silver" -> 92.5, "999 Silver" -> 99.9
      if (purity.contains('925')) return 92.5;
      if (purity.contains('999')) return 99.9;
      return 92.5; // Default
    }
  }

  void _removeBillItem(int index) {
    setState(() {
      _billItems.removeAt(index);
      _calculateTotal();
    });
  }

  void _calculateTotal() {
    double subtotal = 0.0;
    for (var item in _billItems) {
      subtotal += item.totalAmount;
    }

    // Calculate CGST and SGST
    double cgstAmount = subtotal * (_cgstPercent / 100);
    double sgstAmount = subtotal * (_sgstPercent / 100);
    double totalAmount = subtotal + cgstAmount + sgstAmount;

    setState(() {
      _subtotal = subtotal;
      _cgstAmount = cgstAmount;
      _sgstAmount = sgstAmount;
      _totalAmount = totalAmount;
    });
  }

  void _generateBill() async {
    if (_customerNameController.text.isEmpty) {
      _showSnackBar('Please enter customer name');
      return;
    }
    if (_billItems.isEmpty) {
      _showSnackBar('Please add at least one item');
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Generating bill...'),
          ],
        ),
      ),
    );

    try {
      final invoiceProvider = Provider.of<InvoiceProvider>(
        context,
        listen: false,
      );
      final inventoryProvider = Provider.of<InventoryProvider>(
        context,
        listen: false,
      );

      // Convert BillItem objects to BillItemData
      List<BillItemData> billItemsData = _billItems
          .map(
            (item) => BillItemData(
              productName: item.productName,
              productType: item.productType == BillProductType.gold
                  ? ProductType.gold
                  : ProductType.silver,
              weight: item.weight,
              purity: item.purity,
              makingCharges: item.makingCharges,
              wastagePercent: item.wastagePercent,
            ),
          )
          .toList();

      // Create invoice in database
      final invoice = await invoiceProvider.createInvoiceFromBill(
        customerName: _customerNameController.text.trim(),
        customerPhone: _customerPhoneController.text.trim(),
        billItems: billItemsData,
        goldRate: _goldRate,
        silverRate: _silverRate,
        userId: 1, // Default user ID, should be from auth provider
        notes: 'Generated from billing screen',
        cgstPercent: _cgstPercent,
        sgstPercent: _sgstPercent,
      );

      // Close loading dialog
      if (!mounted) return;
      Navigator.pop(context);

      if (invoice != null) {
        // Mark scanned inventory items as sold
        for (final billItem in _billItems) {
          if (billItem.inventoryUid != null) {
            await inventoryProvider.markItemAsSold(
              uid: billItem.inventoryUid!,
              user: 'admin', // Can be updated with actual user
              notes: 'Sold in invoice ${invoice.invoiceNumber}',
            );
          }
        }

        // Generate and open PDF
        final pdfPath = await invoiceProvider.generateInvoicePdf(invoice);

        if (!mounted) return;
        if (pdfPath != null) {
          // Show success dialog
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 28),
                  SizedBox(width: 8),
                  Text('Bill Generated'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Invoice Number: ${invoice.invoiceNumber}'),
                  Text('Customer: ${_customerNameController.text}'),
                  Text('Total Items: ${_billItems.length}'),
                  Text(
                    'Total Amount: ₹${NumberFormat('#,##,###.00').format(_totalAmount)}',
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Bill has been saved to database and PDF generated successfully!',
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    // Refresh dashboard data before going back
                    await Provider.of<DashboardProvider>(
                      context,
                      listen: false,
                    ).refresh();
                    Navigator.pop(context); // Go back to dashboard
                  },
                  child: Text('OK'),
                ),
              ],
            ),
          );
        } else {
          if (!mounted) return;
          _showSnackBar(
            'Bill saved but PDF generation failed: ${invoiceProvider.error}',
          );
        }
      } else {
        if (!mounted) return;
        _showSnackBar('Failed to create bill: ${invoiceProvider.error}');
      }
    } catch (e) {
      // Close loading dialog if still open
      if (!mounted) return;
      Navigator.pop(context);
      _showSnackBar('Error generating bill: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RateProvider>(
      builder: (context, rateProvider, child) {
        // Update rates if they've changed
        if (_goldRate != rateProvider.goldRate ||
            _silverRate != rateProvider.silverRate ||
            _goldWastage != rateProvider.goldWastage ||
            _silverWastage != rateProvider.silverWastage ||
            _cgstPercent != rateProvider.cgstPercent ||
            _sgstPercent != rateProvider.sgstPercent) {
          _goldRate = rateProvider.goldRate;
          _silverRate = rateProvider.silverRate;
          _goldWastage = rateProvider.goldWastage;
          _silverWastage = rateProvider.silverWastage;
          _cgstPercent = rateProvider.cgstPercent;
          _sgstPercent = rateProvider.sgstPercent;
          // Recalculate all items with new rates and wastage
          for (var item in _billItems) {
            item.rate = item.productType == BillProductType.gold
                ? _goldRate
                : _silverRate;
            item.wastagePercent = item.productType == BillProductType.gold
                ? _goldWastage
                : _silverWastage;
            item.calculateTotal();
          }
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _calculateTotal();
          });
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(
              'New Bill',
              style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold),
            ),
            backgroundColor: const Color(0xFFFFD700),
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              IconButton(
                icon: Icon(Icons.save),
                onPressed: _generateBill,
                tooltip: 'Generate Bill',
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Customer Details Card
                _buildCustomerDetailsCard(),
                const SizedBox(height: 20),

                // Items Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Items',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _scanInventoryItem,
                          icon: const Icon(Icons.qr_code_scanner),
                          label: Text('Scan'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _addNewBillItem,
                          icon: const Icon(Icons.add),
                          label: Text('Add'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFD700),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Bill Items
                for (int i = 0; i < _billItems.length; i++)
                  _buildBillItemCard(_billItems[i], i),

                const SizedBox(height: 20),

                // Add Item Buttons (at bottom as well)
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _scanInventoryItem,
                        icon: const Icon(Icons.qr_code_scanner),
                        label: Text('Scan Item'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _addNewBillItem,
                        icon: const Icon(Icons.add),
                        label: Text('Add Manual Item'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD700),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Total Card
                _buildTotalCard(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCustomerDetailsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Customer Details',
              style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _customerNameController,
              decoration: InputDecoration(
                labelText: 'Customer Name *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _customerPhoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillItemCard(BillItem item, int index) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        'Item ${index + 1}',
                        style: GoogleFonts.lato(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (item.inventoryUid != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.qr_code_scanner,
                                size: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Scanned',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeBillItem(index),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: TextEditingController(text: item.productName),
              decoration: InputDecoration(
                labelText: 'Product Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  item.productName = value;
                });
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<BillProductType>(
                    initialValue: item.productType,
                    decoration: InputDecoration(
                      labelText: 'Type',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: BillProductType.gold,
                        child: Text('Gold'),
                      ),
                      DropdownMenuItem(
                        value: BillProductType.silver,
                        child: Text('Silver'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        item.productType = value!;
                        item.rate = value == BillProductType.gold
                            ? _goldRate
                            : _silverRate;
                        item.wastagePercent = value == BillProductType.gold
                            ? _goldWastage
                            : _silverWastage;
                        item.calculateTotal();
                        _calculateTotal();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: TextEditingController(
                      text: item.weight > 0 ? item.weight.toString() : '',
                    ),
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Weight (g)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        item.weight = double.tryParse(value) ?? 0.0;
                        item.calculateTotal();
                        _calculateTotal();
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: TextEditingController(
                      text: item.purity > 0 ? item.purity.toString() : '',
                    ),
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: item.productType == BillProductType.gold
                          ? 'Purity (K)'
                          : 'Purity (%)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        item.purity =
                            double.tryParse(value) ??
                            (item.productType == BillProductType.gold
                                ? 22
                                : 99.9);
                        item.calculateTotal();
                        _calculateTotal();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: TextEditingController(
                      text: item.makingCharges > 0
                          ? item.makingCharges.toString()
                          : '',
                    ),
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Making Charges',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        item.makingCharges = double.tryParse(value) ?? 0.0;
                        item.calculateTotal();
                        _calculateTotal();
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Item Total: ₹${NumberFormat('#,##,###.00').format(item.totalAmount)}',
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFFFD700),
                    ),
                  ),
                  Text(
                    'Rate: ₹${NumberFormat('#,##,###.00').format(item.rate)}/g',
                    style: GoogleFonts.lato(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
          ),
        ),
        child: Column(
          children: [
            Text(
              'Bill Summary',
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Subtotal:',
                  style: GoogleFonts.lato(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                Text(
                  '₹${NumberFormat('#,##,###.00').format(_subtotal)}',
                  style: GoogleFonts.lato(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'CGST (${_cgstPercent.toStringAsFixed(1)}%):',
                  style: GoogleFonts.lato(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                Text(
                  '₹${NumberFormat('#,##,###.00').format(_cgstAmount)}',
                  style: GoogleFonts.lato(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'SGST (${_sgstPercent.toStringAsFixed(1)}%):',
                  style: GoogleFonts.lato(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                Text(
                  '₹${NumberFormat('#,##,###.00').format(_sgstAmount)}',
                  style: GoogleFonts.lato(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white, height: 32),
            Text(
              'Total Amount',
              style: GoogleFonts.lato(
                fontSize: 16,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '₹${NumberFormat('#,##,###.00').format(_totalAmount)}',
              style: GoogleFonts.playfairDisplay(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum BillProductType { gold, silver }

class BillItem {
  String id;
  String productName;
  BillProductType productType;
  double weight;
  double purity;
  double makingCharges;
  double rate;
  double wastagePercent;
  double totalAmount;
  String? inventoryUid; // Link to inventory item if scanned

  BillItem({
    required this.id,
    required this.productName,
    required this.productType,
    required this.weight,
    required this.purity,
    required this.makingCharges,
    required this.rate,
    this.wastagePercent = 0.0,
    this.totalAmount = 0.0,
    this.inventoryUid,
  });

  void calculateTotal() {
    // Calculate based on weight, rate, purity, making charges, and wastage
    double purityFactor = productType == BillProductType.gold
        ? purity /
              24.0 // For gold: purity in karats (22K, 18K, etc.)
        : purity / 100.0; // For silver: purity in percentage (99.9%, etc.)

    double metalValue = weight * rate * purityFactor;

    // Add wastage percentage to metal value
    double wastageAmount = metalValue * (wastagePercent / 100.0);

    // Final calculation: Metal Value + Wastage + Making Charges
    totalAmount = metalValue + wastageAmount + makingCharges;
  }
}

// Barcode Scanner Dialog
class _BarcodeScannerDialog extends StatefulWidget {
  const _BarcodeScannerDialog();

  @override
  State<_BarcodeScannerDialog> createState() => _BarcodeScannerDialogState();
}

class _BarcodeScannerDialogState extends State<_BarcodeScannerDialog> {
  MobileScannerController cameraController = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  void _handleBarcode(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? code = barcodes.first.rawValue;
    if (code == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // The code is the SKU (barcode data)
      final sku = code;

      // Fetch item from database by SKU
      final provider = Provider.of<InventoryProvider>(context, listen: false);
      final item = await provider.getItemBySku(sku);

      if (!mounted) return;

      if (item != null) {
        // Return the item and close dialog
        Navigator.of(context).pop(item);
      } else {
        _showError('Item not found: $sku');
        setState(() {
          _isProcessing = false;
        });
      }
    } catch (e) {
      _showError('Invalid barcode: $e');
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        height: 500,
        child: Column(
          children: [
            AppBar(
              title: const Text('Scan Barcode'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.flash_on),
                  onPressed: () => cameraController.toggleTorch(),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Expanded(
              child: Stack(
                children: [
                  MobileScanner(
                    controller: cameraController,
                    onDetect: _handleBarcode,
                  ),
                  // Scanning overlay
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                    ),
                    child: Center(
                      child: Container(
                        width: 250,
                        height: 100,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  // Instructions
                  Positioned(
                    bottom: 20,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      child: const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'Position the barcode within the frame',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Processing indicator
                  if (_isProcessing)
                    Container(
                      color: Colors.black54,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
