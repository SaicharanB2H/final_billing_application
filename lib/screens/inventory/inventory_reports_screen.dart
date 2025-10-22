import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/inventory_provider.dart';

class InventoryReportsScreen extends StatefulWidget {
  const InventoryReportsScreen({super.key});

  @override
  State<InventoryReportsScreen> createState() => _InventoryReportsScreenState();
}

class _InventoryReportsScreenState extends State<InventoryReportsScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  Map<String, dynamic> _reportData = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _generateReport();
  }

  Future<void> _generateReport() async {
    setState(() {
      _isLoading = true;
    });

    final provider = Provider.of<InventoryProvider>(context, listen: false);
    final data = await provider.getInventoryReport(
      startDate: _startDate,
      endDate: _endDate,
    );

    setState(() {
      _reportData = data;
      _isLoading = false;
    });
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _generateReport();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Export functionality coming soon!'),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date Range Selector
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.date_range),
                      title: const Text('Report Period'),
                      subtitle: Text(
                        '${DateFormat('MMM dd, yyyy').format(_startDate)} - ${DateFormat('MMM dd, yyyy').format(_endDate)}',
                      ),
                      trailing: const Icon(Icons.edit),
                      onTap: _selectDateRange,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Summary Cards
                  const Text(
                    'Summary',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryCard(
                    'Items Sold',
                    '${_reportData['soldCount'] ?? 0}',
                    Icons.sell,
                    Colors.blue,
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryCard(
                    'Weight Sold',
                    '${(_reportData['soldWeight'] ?? 0.0).toStringAsFixed(2)} g',
                    Icons.scale,
                    Colors.orange,
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryCard(
                    'Making Charges',
                    '₹${(_reportData['soldMakingCharges'] ?? 0.0).toStringAsFixed(2)}',
                    Icons.currency_rupee,
                    Colors.green,
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryCard(
                    'Items Added',
                    '${_reportData['addedCount'] ?? 0}',
                    Icons.add_box,
                    Colors.purple,
                  ),
                  const SizedBox(height: 24),

                  // Top Selling Categories
                  const Text(
                    'Top Selling Categories',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Consumer<InventoryProvider>(
                    builder: (context, provider, child) {
                      return FutureBuilder<List<Map<String, dynamic>>>(
                        future: provider.getTopSellingCategories(5),
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                            return Card(
                              child: ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: snapshot.data!.length,
                                itemBuilder: (context, index) {
                                  final item = snapshot.data![index];
                                  return ListTile(
                                    leading: CircleAvatar(
                                      child: Text('${index + 1}'),
                                    ),
                                    title: Text(item['category'] as String),
                                    subtitle: Text(
                                      '${(item['total_weight'] as num).toStringAsFixed(2)} g',
                                    ),
                                    trailing: Text(
                                      '${item['count']} items',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          } else {
                            return const Card(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: Text('No sales data available'),
                                ),
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Current Stock
                  Consumer<InventoryProvider>(
                    builder: (context, provider, child) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Current Stock',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStockCard(
                                  'Gold',
                                  provider.goldItems.length,
                                  provider.goldItems.fold(
                                    0.0,
                                    (sum, item) => sum + item.netWeight,
                                  ),
                                  const Color(0xFFFFD700),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStockCard(
                                  'Silver',
                                  provider.silverItems.length,
                                  provider.silverItems.fold(
                                    0.0,
                                    (sum, item) => sum + item.netWeight,
                                  ),
                                  const Color(0xFFC0C0C0),
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

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        trailing: Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildStockCard(
    String material,
    int count,
    double weight,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              material == 'Gold' ? Icons.star : Icons.brightness_1,
              color: color,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              material,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text('$count items', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 4),
            Text(
              '${weight.toStringAsFixed(2)} g',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
