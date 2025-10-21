import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/invoice.dart';
import '../../models/customer.dart';
import '../../providers/invoice_provider.dart';
import '../../database/database_helper.dart';
import '../../services/data_export_service.dart';

class BillsHistoryScreen extends StatefulWidget {
  const BillsHistoryScreen({super.key});

  @override
  State<BillsHistoryScreen> createState() => _BillsHistoryScreenState();
}

class _BillsHistoryScreenState extends State<BillsHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final DataExportService _exportService = DataExportService();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  List<Invoice> _allInvoices = [];
  List<Invoice> _filteredInvoices = [];
  bool _isLoading = true;
  String _searchQuery = '';
  PaymentStatus? _selectedPaymentStatus;
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInvoices() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final invoiceProvider = Provider.of<InvoiceProvider>(
        context,
        listen: false,
      );
      await invoiceProvider.loadInvoices();

      setState(() {
        _allInvoices = invoiceProvider.invoices;
        _filteredInvoices = _allInvoices;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Failed to load invoices: $e');
    }
  }

  void _filterInvoices() {
    setState(() {
      _filteredInvoices = _allInvoices.where((invoice) {
        // Search filter
        bool matchesSearch = true;
        if (_searchQuery.isNotEmpty) {
          matchesSearch =
              invoice.invoiceNumber.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
              invoice.notes?.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ) ==
                  true;
        }

        // Payment status filter
        bool matchesPaymentStatus =
            _selectedPaymentStatus == null ||
            invoice.paymentStatus == _selectedPaymentStatus;

        // Date range filter
        bool matchesDateRange =
            _selectedDateRange == null ||
            (invoice.invoiceDate.isAfter(
                  _selectedDateRange!.start.subtract(Duration(days: 1)),
                ) &&
                invoice.invoiceDate.isBefore(
                  _selectedDateRange!.end.add(Duration(days: 1)),
                ));

        return matchesSearch && matchesPaymentStatus && matchesDateRange;
      }).toList();
    });
  }

  Future<void> _showFilterDialog() async {
    PaymentStatus? tempPaymentStatus = _selectedPaymentStatus;
    DateTimeRange? tempDateRange = _selectedDateRange;

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Filter Bills'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Payment Status:',
                    style: GoogleFonts.lato(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  DropdownButtonFormField<PaymentStatus?>(
                    initialValue: tempPaymentStatus,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'All Status',
                    ),
                    items: [
                      DropdownMenuItem<PaymentStatus?>(
                        value: null,
                        child: Text('All Status'),
                      ),
                      ...PaymentStatus.values.map((status) {
                        return DropdownMenuItem<PaymentStatus?>(
                          value: status,
                          child: Text(_getPaymentStatusText(status)),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        tempPaymentStatus = value;
                      });
                    },
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Date Range:',
                    style: GoogleFonts.lato(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      DateTimeRange? picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(Duration(days: 365)),
                        initialDateRange: tempDateRange,
                      );
                      if (picked != null) {
                        setDialogState(() {
                          tempDateRange = picked;
                        });
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.date_range),
                          SizedBox(width: 8),
                          Text(
                            tempDateRange == null
                                ? 'Select Date Range'
                                : '${DateFormat('dd/MM/yy').format(tempDateRange!.start)} - ${DateFormat('dd/MM/yy').format(tempDateRange!.end)}',
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (tempDateRange != null)
                    TextButton(
                      onPressed: () {
                        setDialogState(() {
                          tempDateRange = null;
                        });
                      },
                      child: Text('Clear Date Range'),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedPaymentStatus = tempPaymentStatus;
                      _selectedDateRange = tempDateRange;
                    });
                    _filterInvoices();
                    Navigator.of(context).pop();
                  },
                  child: Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showExportDialog() async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.download, color: Colors.blue),
              SizedBox(width: 8),
              Text('Export Bills'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Choose export format for ${_filteredInvoices.length} bills:',
              ),
              SizedBox(height: 16),
              _buildExportOption(
                icon: Icons.table_chart,
                title: 'Export to CSV',
                subtitle: 'Simple spreadsheet format',
                onTap: () => _exportData('csv'),
              ),
              _buildExportOption(
                icon: Icons.grid_on,
                title: 'Export to Excel',
                subtitle: 'Advanced spreadsheet with multiple sheets',
                onTap: () => _exportData('excel'),
              ),
              _buildExportOption(
                icon: Icons.code,
                title: 'Export to JSON',
                subtitle: 'Structured data format',
                onTap: () => _exportData('json'),
              ),
              _buildExportOption(
                icon: Icons.description,
                title: 'Detailed CSV Export',
                subtitle: 'CSV with individual item details',
                onTap: () => _exportData('detailed_csv'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExportOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }

  Future<void> _exportData(String format) async {
    Navigator.of(context).pop(); // Close export dialog

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Exporting data...'),
          ],
        ),
      ),
    );

    try {
      String filePath;
      DateTime? startDate = _selectedDateRange?.start;
      DateTime? endDate = _selectedDateRange?.end;

      switch (format) {
        case 'csv':
          filePath = await _exportService.exportInvoicesToCsv(
            startDate: startDate,
            endDate: endDate,
          );
          break;
        case 'excel':
          filePath = await _exportService.exportInvoicesToExcel(
            startDate: startDate,
            endDate: endDate,
          );
          break;
        case 'json':
          filePath = await _exportService.exportInvoicesToJson(
            startDate: startDate,
            endDate: endDate,
          );
          break;
        case 'detailed_csv':
          filePath = await _exportService.exportDetailedInvoicesToCsv(
            startDate: startDate,
            endDate: endDate,
          );
          break;
        default:
          throw Exception('Unsupported export format');
      }

      Navigator.of(context).pop(); // Close loading dialog

      // Show success dialog with option to share
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Export Successful'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('File exported successfully!'),
              SizedBox(height: 8),
              Text('Format: ${format.toUpperCase()}'),
              Text('Records: ${_filteredInvoices.length}'),
              Text('Location: ${filePath.split('/').last}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await _exportService.shareExportedFile(filePath);
                } catch (e) {
                  _showSnackBar('Failed to share file: $e');
                }
              },
              child: Text('Share'),
            ),
          ],
        ),
      );
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      _showSnackBar('Export failed: $e');
    }
  }

  Future<Customer?> _getCustomer(int customerId) async {
    return await _dbHelper.getCustomerById(customerId);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

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

  Color _getPaymentStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return Colors.green;
      case PaymentStatus.pending:
        return Colors.orange;
      case PaymentStatus.partial:
        return Colors.blue;
      case PaymentStatus.cancelled:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Bills History',
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFFFD700),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filter',
          ),
          IconButton(
            icon: Icon(Icons.download),
            onPressed: _showExportDialog,
            tooltip: 'Export Data',
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadInvoices,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and summary section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              children: [
                // Search bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by invoice number or notes...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                    _filterInvoices();
                  },
                ),
                const SizedBox(height: 12),

                // Summary row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSummaryCard(
                      'Total Bills',
                      '${_filteredInvoices.length}',
                      Icons.receipt,
                      Colors.blue,
                    ),
                    _buildSummaryCard(
                      'Total Amount',
                      '₹${NumberFormat('#,##,###').format(_filteredInvoices.fold(0.0, (sum, inv) => sum + inv.totalAmount))}',
                      Icons.currency_rupee,
                      Colors.green,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Active filters display
          if (_selectedPaymentStatus != null || _selectedDateRange != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.blue[50],
              child: Row(
                children: [
                  Text(
                    'Filters: ',
                    style: GoogleFonts.lato(fontWeight: FontWeight.bold),
                  ),
                  if (_selectedPaymentStatus != null) ...[
                    Chip(
                      label: Text(
                        _getPaymentStatusText(_selectedPaymentStatus!),
                      ),
                      onDeleted: () {
                        setState(() {
                          _selectedPaymentStatus = null;
                        });
                        _filterInvoices();
                      },
                    ),
                    SizedBox(width: 8),
                  ],
                  if (_selectedDateRange != null) ...[
                    Chip(
                      label: Text(
                        '${DateFormat('dd/MM/yy').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM/yy').format(_selectedDateRange!.end)}',
                      ),
                      onDeleted: () {
                        setState(() {
                          _selectedDateRange = null;
                        });
                        _filterInvoices();
                      },
                    ),
                  ],
                ],
              ),
            ),

          // Bills list
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _filteredInvoices.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _loadInvoices,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredInvoices.length,
                      itemBuilder: (context, index) {
                        final invoice = _filteredInvoices[index];
                        return _buildInvoiceCard(invoice);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.lato(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                title,
                style: GoogleFonts.lato(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No bills found',
            style: GoogleFonts.lato(fontSize: 20, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty ||
                    _selectedPaymentStatus != null ||
                    _selectedDateRange != null
                ? 'Try adjusting your filters'
                : 'Create your first bill to see it here',
            style: GoogleFonts.lato(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceCard(Invoice invoice) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: FutureBuilder<Customer?>(
        future: _getCustomer(invoice.customerId),
        builder: (context, snapshot) {
          final customer = snapshot.data;

          return ExpansionTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.receipt, color: const Color(0xFFFFD700)),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    invoice.invoiceNumber,
                    style: GoogleFonts.lato(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getPaymentStatusColor(invoice.paymentStatus),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getPaymentStatusText(invoice.paymentStatus),
                    style: GoogleFonts.lato(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  customer?.name ?? 'Loading...',
                  style: GoogleFonts.lato(fontSize: 14),
                ),
                Text(
                  '${DateFormat('dd/MM/yyyy').format(invoice.invoiceDate)} • ${invoice.items.length} items',
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            trailing: Text(
              '₹${NumberFormat('#,##,###.00').format(invoice.totalAmount)}',
              style: GoogleFonts.lato(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.green[700],
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Customer details
                    if (customer != null) ...[
                      Text(
                        'Customer Details:',
                        style: GoogleFonts.lato(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('Name: ${customer.name}'),
                      if (customer.phone.isNotEmpty)
                        Text('Phone: ${customer.phone}'),
                      if (customer.email?.isNotEmpty == true)
                        Text('Email: ${customer.email}'),
                      const SizedBox(height: 12),
                    ],

                    // Items list
                    Text(
                      'Items (${invoice.items.length}):',
                      style: GoogleFonts.lato(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...invoice.items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                item.itemName,
                                style: GoogleFonts.lato(fontSize: 12),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                '${item.weight.toStringAsFixed(2)}g',
                                style: GoogleFonts.lato(fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                '₹${NumberFormat('#,##,###').format(item.itemTotal)}',
                                style: GoogleFonts.lato(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),
                    const Divider(),

                    // Totals
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Subtotal:',
                          style: GoogleFonts.lato(fontSize: 12),
                        ),
                        Text(
                          '₹${NumberFormat('#,##,###.00').format(invoice.subtotal)}',
                        ),
                      ],
                    ),
                    // Tax section removed
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total:',
                          style: GoogleFonts.lato(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '₹${NumberFormat('#,##,###.00').format(invoice.totalAmount)}',
                          style: GoogleFonts.lato(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () async {
                            final invoiceProvider =
                                Provider.of<InvoiceProvider>(
                                  context,
                                  listen: false,
                                );

                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => AlertDialog(
                                content: Row(
                                  children: [
                                    CircularProgressIndicator(),
                                    SizedBox(width: 16),
                                    Text('Generating PDF...'),
                                  ],
                                ),
                              ),
                            );

                            try {
                              await invoiceProvider.generateInvoicePdf(invoice);
                              Navigator.of(context).pop();
                            } catch (e) {
                              Navigator.of(context).pop();
                              _showSnackBar('Failed to generate PDF: $e');
                            }
                          },
                          icon: Icon(Icons.picture_as_pdf, size: 16),
                          label: Text('PDF'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        if (invoice.paymentStatus != PaymentStatus.paid)
                          ElevatedButton.icon(
                            onPressed: () async {
                              final invoiceProvider =
                                  Provider.of<InvoiceProvider>(
                                    context,
                                    listen: false,
                                  );

                              bool success = await invoiceProvider
                                  .updateInvoicePaymentStatus(
                                    invoice.id!,
                                    PaymentStatus.paid,
                                  );

                              if (success) {
                                _showSnackBar('Payment status updated to PAID');
                                _loadInvoices();
                              } else {
                                _showSnackBar(
                                  'Failed to update payment status',
                                );
                              }
                            },
                            icon: Icon(Icons.payment, size: 16),
                            label: Text('Mark Paid'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                      ],
                    ),

                    if (invoice.notes?.isNotEmpty == true) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Notes:',
                        style: GoogleFonts.lato(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        invoice.notes!,
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
