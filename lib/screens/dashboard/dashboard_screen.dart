import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../billing/new_bill_screen.dart';
import '../billing/bills_history_screen.dart';
import '../customers/add_edit_customer_screen.dart';
import '../../services/data_export_service.dart';
import '../../widgets/main_drawer.dart';
import '../../providers/rate_provider.dart';
import '../../providers/dashboard_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DataExportService _exportService = DataExportService();

  @override
  void initState() {
    super.initState();
    // Load rates and dashboard data when dashboard initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RateProvider>(context, listen: false).loadRates();
      Provider.of<DashboardProvider>(
        context,
        listen: false,
      ).loadDashboardData();
    });
  }

  void _showRateEditDialog(String metalType) {
    final rateProvider = Provider.of<RateProvider>(context, listen: false);
    final currentRate = metalType == 'Gold'
        ? rateProvider.goldRate
        : rateProvider.silverRate;
    final TextEditingController tempController = TextEditingController(
      text: currentRate.toStringAsFixed(0),
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Edit $metalType Rate',
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: TextField(
            controller: tempController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: '$metalType Rate per gram (₹)',
              border: const OutlineInputBorder(),
              suffixText: '/g',
            ),
            style: GoogleFonts.lato(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: GoogleFonts.lato(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (tempController.text.isNotEmpty) {
                  final newRate = double.tryParse(tempController.text);
                  if (newRate != null && newRate > 0) {
                    bool success;
                    if (metalType == 'Gold') {
                      success = await rateProvider.updateGoldRate(newRate);
                    } else {
                      success = await rateProvider.updateSilverRate(newRate);
                    }

                    if (success) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('$metalType rate updated successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to update $metalType rate'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Please enter a valid rate'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: metalType == 'Gold'
                    ? const Color(0xFFFFD700)
                    : Colors.grey[600],
              ),
              child: Text(
                'Save',
                style: GoogleFonts.lato(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showWastageEditDialog(String metalType) {
    final rateProvider = Provider.of<RateProvider>(context, listen: false);
    final currentWastage = metalType == 'Gold'
        ? rateProvider.goldWastage
        : rateProvider.silverWastage;
    final TextEditingController tempController = TextEditingController(
      text: currentWastage.toStringAsFixed(1),
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Edit $metalType Wastage',
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: tempController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: '$metalType Wastage Percentage',
                  border: const OutlineInputBorder(),
                  suffixText: '%',
                  helperText: 'Enter wastage percentage (e.g., 8.0 for 8%)',
                ),
                style: GoogleFonts.lato(fontSize: 16),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Colors.blue,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Wastage is added to the base metal cost during calculation',
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: GoogleFonts.lato(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (tempController.text.isNotEmpty) {
                  final newWastage = double.tryParse(tempController.text);
                  if (newWastage != null &&
                      newWastage >= 0 &&
                      newWastage <= 100) {
                    bool success;
                    if (metalType == 'Gold') {
                      success = await rateProvider.updateGoldWastage(
                        newWastage,
                      );
                    } else {
                      success = await rateProvider.updateSilverWastage(
                        newWastage,
                      );
                    }

                    if (success) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '$metalType wastage updated successfully',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to update $metalType wastage'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Please enter a valid percentage (0-100)',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: metalType == 'Gold'
                    ? Colors.orange
                    : Colors.blue,
              ),
              child: Text(
                'Save',
                style: GoogleFonts.lato(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showCgstEditDialog() {
    final rateProvider = Provider.of<RateProvider>(context, listen: false);
    final currentCgst = rateProvider.cgstPercent;
    final TextEditingController tempController = TextEditingController(
      text: currentCgst.toStringAsFixed(1),
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Edit CGST Percentage',
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: tempController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'CGST Percentage',
                  border: const OutlineInputBorder(),
                  suffixText: '%',
                  helperText: 'Enter CGST percentage (e.g., 1.5 for 1.5%)',
                ),
                style: GoogleFonts.lato(fontSize: 16),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Colors.blue,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'CGST (Central Goods and Services Tax) is levied on intra-state sales',
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: GoogleFonts.lato(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (tempController.text.isNotEmpty) {
                  final newCgst = double.tryParse(tempController.text);
                  if (newCgst != null && newCgst >= 0 && newCgst <= 100) {
                    bool success = await rateProvider.updateCgstPercent(
                      newCgst,
                    );

                    if (success) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('CGST percentage updated successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to update CGST percentage'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Please enter a valid percentage (0-100)',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: Text(
                'Save',
                style: GoogleFonts.lato(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSgstEditDialog() {
    final rateProvider = Provider.of<RateProvider>(context, listen: false);
    final currentSgst = rateProvider.sgstPercent;
    final TextEditingController tempController = TextEditingController(
      text: currentSgst.toStringAsFixed(1),
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Edit SGST Percentage',
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: tempController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'SGST Percentage',
                  border: const OutlineInputBorder(),
                  suffixText: '%',
                  helperText: 'Enter SGST percentage (e.g., 1.5 for 1.5%)',
                ),
                style: GoogleFonts.lato(fontSize: 16),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Colors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'SGST (State Goods and Services Tax) is levied on intra-state sales',
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: GoogleFonts.lato(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (tempController.text.isNotEmpty) {
                  final newSgst = double.tryParse(tempController.text);
                  if (newSgst != null && newSgst >= 0 && newSgst <= 100) {
                    bool success = await rateProvider.updateSgstPercent(
                      newSgst,
                    );

                    if (success) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('SGST percentage updated successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to update SGST percentage'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Please enter a valid percentage (0-100)',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: Text(
                'Save',
                style: GoogleFonts.lato(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 200),
          child: Text(
            'Dashboard',
            style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        backgroundColor: const Color(0xFFFFD700),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await Provider.of<DashboardProvider>(
                context,
                listen: false,
              ).refresh();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Dashboard data refreshed'),
                  duration: Duration(seconds: 1),
                  backgroundColor: Colors.green,
                ),
              );
            },
            tooltip: 'Refresh Data',
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const BillsHistoryScreen(),
                ),
              );
            },
            tooltip: 'Bills History',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _showQuickExportDialog,
            tooltip: 'Export Data',
          ),
        ],
      ),
      drawer: const MainDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Message
            _buildWelcomeCard(),
            const SizedBox(height: 20),

            // Current Rates Card
            _buildCurrentRatesCard(),
            const SizedBox(height: 20),

            // Sales Overview
            Text(
              'Sales Overview',
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            Consumer<DashboardProvider>(
              builder: (context, dashboardProvider, child) {
                if (dashboardProvider.isLoading) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                return Row(
                  children: [
                    Expanded(
                      child: _buildSalesCard(
                        'Today\'s Sales',
                        dashboardProvider.todaySales,
                        dashboardProvider.todayInvoiceCount,
                        Icons.today,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSalesCard(
                        'This Month',
                        dashboardProvider.monthSales,
                        dashboardProvider.monthInvoiceCount,
                        Icons.calendar_month,
                        Colors.blue,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),

            // Quick Stats
            Text(
              'Quick Stats',
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            Consumer<DashboardProvider>(
              builder: (context, dashboardProvider, child) {
                if (dashboardProvider.isLoading) {
                  return const SizedBox.shrink();
                }

                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Customers',
                            dashboardProvider.customerCount.toString(),
                            Icons.people,
                            Colors.purple,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Products',
                            dashboardProvider.productCount.toString(),
                            Icons.inventory,
                            Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Pending Bills',
                            dashboardProvider.pendingInvoiceCount.toString(),
                            Icons.pending_actions,
                            Colors.red,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Pending Amount',
                            dashboardProvider.formatCurrency(
                              dashboardProvider.pendingInvoiceAmount,
                            ),
                            Icons.money,
                            Colors.amber,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),

            // Quick Actions
            Text(
              'Quick Actions',
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _buildActionCard(
                  'New Bill',
                  Icons.receipt_long,
                  Colors.green,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NewBillScreen(),
                      ),
                    );
                  },
                ),
                _buildActionCard(
                  'Bills History',
                  Icons.history,
                  Colors.blue,
                  () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const BillsHistoryScreen(),
                      ),
                    );
                  },
                ),
                _buildActionCard(
                  'Add Customer',
                  Icons.person_add,
                  Colors.orange,
                  () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const AddEditCustomerScreen(),
                      ),
                    );
                  },
                ),
                _buildActionCard(
                  'Export Data',
                  Icons.download,
                  Colors.purple,
                  () {
                    _showQuickExportDialog();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome Back!',
              style: GoogleFonts.playfairDisplay(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('EEEE, MMMM d, y').format(DateTime.now()),
              style: GoogleFonts.lato(
                fontSize: 16,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentRatesCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.price_change, color: Color(0xFFFFD700)),
                const SizedBox(width: 8),
                Text(
                  'Current Rates & Wastage',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Consumer<RateProvider>(
                  builder: (context, rateProvider, child) {
                    return Text(
                      'Last updated: ${DateFormat('HH:mm').format(DateTime.now())}',
                      style: GoogleFonts.lato(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Consumer<RateProvider>(
              builder: (context, rateProvider, child) {
                return Column(
                  children: [
                    // Rates Row
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.yellow.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.yellow.shade200),
                            ),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Color(0xFFFFD700),
                                  size: 30,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Gold (24K)',
                                  style: GoogleFonts.lato(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: () {
                                    _showRateEditDialog('Gold');
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                      horizontal: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: const Color(0xFFFFD700),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            rateProvider.getFormattedGoldRate(),
                                            style: GoogleFonts.lato(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFFFFD700),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(
                                          Icons.edit,
                                          size: 16,
                                          color: Color(0xFFFFD700),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.circle,
                                  color: Colors.grey.shade600,
                                  size: 30,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Silver (99.9%)',
                                  style: GoogleFonts.lato(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: () {
                                    _showRateEditDialog('Silver');
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                      horizontal: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: Colors.grey.shade400,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            rateProvider
                                                .getFormattedSilverRate(),
                                            style: GoogleFonts.lato(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.edit,
                                          size: 16,
                                          color: Colors.grey.shade600,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Wastage Row
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange.shade200),
                            ),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.warning_amber,
                                  color: Colors.orange,
                                  size: 24,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Gold Wastage',
                                  style: GoogleFonts.lato(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: () {
                                    _showWastageEditDialog('Gold');
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                      horizontal: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: Colors.orange,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            rateProvider
                                                .getFormattedGoldWastage(),
                                            style: GoogleFonts.lato(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.orange,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(
                                          Icons.edit,
                                          size: 16,
                                          color: Colors.orange,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.warning_amber,
                                  color: Colors.blue,
                                  size: 24,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Silver Wastage',
                                  style: GoogleFonts.lato(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: () {
                                    _showWastageEditDialog('Silver');
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                      horizontal: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: Colors.blue,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            rateProvider
                                                .getFormattedSilverWastage(),
                                            style: GoogleFonts.lato(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(
                                          Icons.edit,
                                          size: 16,
                                          color: Colors.blue,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // CGST and SGST Row
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.account_balance,
                                  color: Colors.blue,
                                  size: 24,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'CGST',
                                  style: GoogleFonts.lato(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: () {
                                    _showCgstEditDialog();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                      horizontal: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: Colors.blue,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            rateProvider
                                                .getFormattedCgstPercent(),
                                            style: GoogleFonts.lato(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(
                                          Icons.edit,
                                          size: 16,
                                          color: Colors.blue,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.account_balance,
                                  color: Colors.green,
                                  size: 24,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'SGST',
                                  style: GoogleFonts.lato(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: () {
                                    _showSgstEditDialog();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                      horizontal: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: Colors.green,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            rateProvider
                                                .getFormattedSgstPercent(),
                                            style: GoogleFonts.lato(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(
                                          Icons.edit,
                                          size: 16,
                                          color: Colors.green,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesCard(
    String title,
    double amount,
    int count,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '₹${NumberFormat('#,##,###').format(amount)}',
              style: GoogleFonts.lato(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$count invoices',
              style: GoogleFonts.lato(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: GoogleFonts.lato(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                title,
                style: GoogleFonts.lato(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showQuickExportDialog() async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.download, color: Colors.purple),
              const SizedBox(width: 8),
              Text('Quick Export'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Export all bills data in your preferred format:'),
              const SizedBox(height: 16),
              _buildQuickExportOption(
                icon: Icons.table_chart,
                title: 'Export to CSV',
                subtitle: 'Simple spreadsheet format',
                onTap: () => _quickExportData('csv'),
              ),
              _buildQuickExportOption(
                icon: Icons.grid_on,
                title: 'Export to Excel',
                subtitle: 'Advanced spreadsheet format',
                onTap: () => _quickExportData('excel'),
              ),
              _buildQuickExportOption(
                icon: Icons.code,
                title: 'Export to JSON',
                subtitle: 'Structured data format',
                onTap: () => _quickExportData('json'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickExportOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.purple),
        title: Text(title, style: GoogleFonts.lato(fontSize: 14)),
        subtitle: Text(subtitle, style: GoogleFonts.lato(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
        dense: true,
      ),
    );
  }

  Future<void> _quickExportData(String format) async {
    Navigator.of(context).pop(); // Close export dialog

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text('Exporting data...'),
          ],
        ),
      ),
    );

    try {
      String filePath;

      switch (format) {
        case 'csv':
          filePath = await _exportService.exportInvoicesToCsv();
          break;
        case 'excel':
          filePath = await _exportService.exportInvoicesToExcel();
          break;
        case 'json':
          filePath = await _exportService.exportInvoicesToJson();
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
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 8),
              Text('Export Successful'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('All bills exported successfully!'),
              const SizedBox(height: 8),
              Text('Format: ${format.toUpperCase()}'),
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to share file: $e')),
                  );
                }
              },
              child: Text('Share'),
            ),
          ],
        ),
      );
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }
}
