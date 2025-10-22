import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/inventory_provider.dart';
import '../../models/inventory_item.dart';
import 'item_detail_screen.dart';

class AllItemsScreen extends StatefulWidget {
  final bool filterLowStock;

  const AllItemsScreen({super.key, this.filterLowStock = false});

  @override
  State<AllItemsScreen> createState() => _AllItemsScreenState();
}

class _AllItemsScreenState extends State<AllItemsScreen> {
  String _searchQuery = '';
  String? _filterMaterial;
  String? _filterCategory;
  String? _filterStatus;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    await Provider.of<InventoryProvider>(
      context,
      listen: false,
    ).loadInventoryItems();
  }

  List<InventoryItem> _getFilteredItems(List<InventoryItem> items) {
    var filtered = items;

    // Low stock filter
    if (widget.filterLowStock) {
      filtered = filtered
          .where(
            (item) => item.quantity < 5 && item.status == ItemStatus.inStock,
          )
          .toList();
    }

    // Search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((item) {
        return item.sku.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            item.category.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            item.location.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Material filter
    if (_filterMaterial != null) {
      filtered = filtered
          .where((item) => item.material == _filterMaterial)
          .toList();
    }

    // Category filter
    if (_filterCategory != null) {
      filtered = filtered
          .where((item) => item.category == _filterCategory)
          .toList();
    }

    // Status filter
    if (_filterStatus != null) {
      filtered = filtered
          .where((item) => item.status == _filterStatus)
          .toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.filterLowStock ? 'Low Stock Items' : 'All Items'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by SKU, category, or location...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadItems,
        child: Consumer<InventoryProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final items = _getFilteredItems(provider.items);

            if (items.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inventory_2, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No items found',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                // Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('Gold'),
                        selected: _filterMaterial == ItemMaterial.gold,
                        onSelected: (selected) {
                          setState(() {
                            _filterMaterial = selected
                                ? ItemMaterial.gold
                                : null;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Silver'),
                        selected: _filterMaterial == ItemMaterial.silver,
                        onSelected: (selected) {
                          setState(() {
                            _filterMaterial = selected
                                ? ItemMaterial.silver
                                : null;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('In Stock'),
                        selected: _filterStatus == ItemStatus.inStock,
                        onSelected: (selected) {
                          setState(() {
                            _filterStatus = selected
                                ? ItemStatus.inStock
                                : null;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Sold'),
                        selected: _filterStatus == ItemStatus.sold,
                        onSelected: (selected) {
                          setState(() {
                            _filterStatus = selected ? ItemStatus.sold : null;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                // Items list
                Expanded(
                  child: ListView.builder(
                    itemCount: items.length,
                    padding: const EdgeInsets.all(8),
                    itemBuilder: (context, index) {
                      return _buildItemCard(items[index]);
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildItemCard(InventoryItem item) {
    final materialColor = item.material == ItemMaterial.gold
        ? const Color(0xFFFFD700)
        : const Color(0xFFC0C0C0);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: materialColor.withOpacity(0.2),
          child: Icon(_getCategoryIcon(item.category), color: materialColor),
        ),
        title: Text(
          item.sku,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${item.category} • ${item.material} • ${item.purity}'),
            Text(
              'Net: ${item.netWeight.toStringAsFixed(2)} g • Qty: ${item.quantity}',
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildStatusChip(item.status),
            if (item.quantity < 5 && item.status == ItemStatus.inStock)
              const Icon(Icons.warning, color: Colors.red, size: 16),
          ],
        ),
        isThreeLine: true,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ItemDetailScreen(item: item),
            ),
          ).then((_) => _loadItems());
        },
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        ItemStatus.getDisplayName(status),
        style: const TextStyle(color: Colors.white, fontSize: 10),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case ItemCategory.ring:
        return Icons.circle;
      case ItemCategory.chain:
        return Icons.link;
      case ItemCategory.necklace:
        return Icons.style;
      case ItemCategory.bangle:
        return Icons.panorama_fish_eye;
      case ItemCategory.earring:
        return Icons.earbuds;
      default:
        return Icons.star;
    }
  }
}
