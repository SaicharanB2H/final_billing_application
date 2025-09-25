import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../providers/invoice_provider.dart';
import '../../providers/rate_provider.dart';
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
  double _totalAmount = 0.0;
  double _goldRate = 5500.0;
  double _silverRate = 75.0;
  double _goldWastage = 8.0;
  double _silverWastage = 5.0;

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
    });
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    super.dispose();
  }

  void _addBillItem() {
    setState(() {
      _billItems.add(
        BillItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          productName: '',
          productType: BillProductType.gold,
          weight: 0.0,
          purity: 22,
          makingCharges: 0.0,
          rate: _goldRate,
          wastagePercent: _goldWastage,
        ),
      );
    });
  }

  void _removeBillItem(int index) {
    setState(() {
      _billItems.removeAt(index);
      _calculateTotal();
    });
  }

  void _calculateTotal() {
    double total = 0.0;
    for (var item in _billItems) {
      total += item.totalAmount;
    }
    setState(() {
      _totalAmount = total;
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
      );

      // Close loading dialog
      Navigator.pop(context);

      if (invoice != null) {
        // Generate and open PDF
        final pdfPath = await invoiceProvider.generateInvoicePdf(invoice);

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
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context); // Go back to dashboard
                  },
                  child: Text('OK'),
                ),
              ],
            ),
          );
        } else {
          _showSnackBar(
            'Bill saved but PDF generation failed: ${invoiceProvider.error}',
          );
        }
      } else {
        _showSnackBar('Failed to create bill: ${invoiceProvider.error}');
      }
    } catch (e) {
      // Close loading dialog if still open
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
            _silverWastage != rateProvider.silverWastage) {
          _goldRate = rateProvider.goldRate;
          _silverRate = rateProvider.silverRate;
          _goldWastage = rateProvider.goldWastage;
          _silverWastage = rateProvider.silverWastage;
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
                    ElevatedButton.icon(
                      onPressed: _addBillItem,
                      icon: Icon(Icons.add),
                      label: Text('Add Item'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Bill Items List
                if (_billItems.isEmpty)
                  _buildEmptyItemsWidget()
                else
                  ..._billItems.asMap().entries.map((entry) {
                    int index = entry.key;
                    BillItem item = entry.value;
                    return _buildBillItemCard(item, index);
                  }),

                const SizedBox(height: 20),

                // Total Section
                _buildTotalCard(),

                const SizedBox(height: 20),

                // Generate Bill Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _generateBill,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Generate Bill',
                      style: GoogleFonts.lato(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
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
            const SizedBox(height: 16),
            TextField(
              controller: _customerNameController,
              decoration: InputDecoration(
                labelText: 'Customer Name *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: Icon(Icons.person),
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
                prefixIcon: Icon(Icons.phone),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyItemsWidget() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.inventory_outlined, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No items added yet',
              style: GoogleFonts.lato(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap "Add Item" to start adding jewelry items',
              style: GoogleFonts.lato(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
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
                  child: Text(
                    'Item ${index + 1}',
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
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
                        item.calculateTotal();
                        _calculateTotal();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
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
