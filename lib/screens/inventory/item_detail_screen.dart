import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:barcode_widget/barcode_widget.dart';
import '../../providers/inventory_provider.dart';
import '../../models/inventory_item.dart';
import '../../models/inventory_transaction.dart';
import 'label_preview_screen.dart';

class ItemDetailScreen extends StatefulWidget {
  final InventoryItem item;

  const ItemDetailScreen({super.key, required this.item});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  List<InventoryTransaction> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final provider = Provider.of<InventoryProvider>(context, listen: false);
    await provider.loadTransactionsForItem(widget.item.uid);
    if (mounted) {
      setState(() {
        _transactions = provider.transactions;
      });
    }
  }

  Future<void> _markAsSold() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Sold'),
        content: const Text('Are you sure you want to mark this item as sold?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Mark Sold'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final provider = Provider.of<InventoryProvider>(context, listen: false);
      final success = await provider.markItemAsSold(
        uid: widget.item.uid,
        notes: 'Marked as sold via app',
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Item marked as sold')));
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update item'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _issueToKarigar() async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Issue to Karigar'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter Karigar name:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Karigar Name',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Issue'),
          ),
        ],
      ),
    );

    if (confirmed == true && controller.text.isNotEmpty && mounted) {
      final provider = Provider.of<InventoryProvider>(context, listen: false);
      final success = await provider.issueItemToKarigar(
        uid: widget.item.uid,
        karigarName: controller.text,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Issued to ${controller.text}')),
          );
          Navigator.pop(context);
        }
      }
    }
  }

  Future<void> _returnItem() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Return Item'),
        content: const Text('Mark this item as returned?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            child: const Text('Return'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final provider = Provider.of<InventoryProvider>(context, listen: false);
      final success = await provider.returnItemFromKarigar(
        uid: widget.item.uid,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Item returned')));
          Navigator.pop(context);
        }
      }
    }
  }

  Future<void> _deleteItem() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: const Text('Are you sure? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final provider = Provider.of<InventoryProvider>(context, listen: false);
      final success = await provider.deleteInventoryItem(uid: widget.item.uid);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Item deleted')));
          Navigator.pop(context);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item.sku),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'delete':
                  _deleteItem();
                  break;
                case 'label':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          LabelPreviewScreen(item: widget.item),
                    ),
                  );
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'label',
                child: Row(
                  children: [
                    Icon(Icons.code),
                    SizedBox(width: 8),
                    Text('View Label'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Barcode Section
            Container(
              padding: const EdgeInsets.all(24),
              color: Colors.white,
              child: Center(
                child: BarcodeWidget(
                  barcode: Barcode.code128(),
                  data: widget.item.sku,
                  width: 300,
                  height: 80,
                  drawText: true,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Item Details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildDetailsCard(),
                  const SizedBox(height: 16),
                  _buildWeightCard(),
                  const SizedBox(height: 16),
                  _buildPricingCard(),
                  const SizedBox(height: 16),
                  _buildTransactionsCard(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildActionButtons(),
    );
  }

  Widget _buildDetailsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Item Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                _buildStatusChip(widget.item.status),
              ],
            ),
            const Divider(),
            _buildInfoRow('SKU', widget.item.sku),
            _buildInfoRow('Category', widget.item.category),
            _buildInfoRow('Material', widget.item.material),
            _buildInfoRow('Purity', widget.item.purity),
            _buildInfoRow('Location', widget.item.location),
            _buildInfoRow('Quantity', '${widget.item.quantity}'),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Weight Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _buildInfoRow(
              'Gross Weight',
              '${widget.item.grossWeight.toStringAsFixed(2)} g',
            ),
            _buildInfoRow(
              'Net Weight',
              '${widget.item.netWeight.toStringAsFixed(2)} g',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pricing',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _buildInfoRow(
              'Making Charge',
              '₹${widget.item.makingCharge.toStringAsFixed(2)}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Transaction History',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            if (_transactions.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: Text('No transactions yet')),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _transactions.length,
                itemBuilder: (context, index) {
                  final transaction = _transactions[index];
                  return ListTile(
                    leading: Icon(_getTransactionIcon(transaction.action)),
                    title: Text(
                      TransactionAction.getDisplayName(transaction.action),
                    ),
                    subtitle: Text(
                      '${transaction.user} • ${_formatDate(transaction.timestamp)}',
                    ),
                    trailing: transaction.notes != null
                        ? Tooltip(
                            message: transaction.notes!,
                            child: const Icon(Icons.info_outline),
                          )
                        : null,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case ItemStatus.inStock:
        color = Colors.green;
        break;
      case ItemStatus.sold:
        color = Colors.blue;
        break;
      case ItemStatus.issued:
        color = Colors.orange;
        break;
      case ItemStatus.returned:
        color = Colors.purple;
        break;
      default:
        color = Colors.grey;
    }

    return Chip(
      label: Text(
        ItemStatus.getDisplayName(status),
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: color,
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: SafeArea(
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (widget.item.status == ItemStatus.inStock) ...[
              ElevatedButton.icon(
                onPressed: _markAsSold,
                icon: const Icon(Icons.sell),
                label: const Text('Mark as Sold'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              ),
              ElevatedButton.icon(
                onPressed: _issueToKarigar,
                icon: const Icon(Icons.send),
                label: const Text('Issue to Karigar'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              ),
            ],
            if (widget.item.status == ItemStatus.issued)
              ElevatedButton.icon(
                onPressed: _returnItem,
                icon: const Icon(Icons.keyboard_return),
                label: const Text('Mark as Returned'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getTransactionIcon(String action) {
    switch (action) {
      case TransactionAction.created:
        return Icons.add_circle;
      case TransactionAction.updated:
        return Icons.edit;
      case TransactionAction.sold:
        return Icons.sell;
      case TransactionAction.issued:
        return Icons.send;
      case TransactionAction.returned:
        return Icons.keyboard_return;
      case TransactionAction.deleted:
        return Icons.delete;
      default:
        return Icons.info;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
