import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../screens/billing/bills_history_screen.dart';
import '../screens/billing/new_bill_screen.dart';
import '../screens/customers/customers_screen.dart';
import '../screens/inventory/inventory_dashboard_screen.dart';
import '../screens/inventory/add_item_screen.dart';
import '../screens/inventory/scan_screen.dart';
import '../screens/inventory/all_items_screen.dart';
import '../screens/inventory/inventory_reports_screen.dart';

class MainDrawer extends StatelessWidget {
  const MainDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // Header
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
              ),
            ),
            accountName: Text(
              'Jewelry Shop Admin',
              style: GoogleFonts.lato(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            accountEmail: Text(
              'admin@jewelryshop.com',
              style: GoogleFonts.lato(fontSize: 14),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                'A',
                style: GoogleFonts.lato(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFFD700),
                ),
              ),
            ),
          ),

          // Menu Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  icon: Icons.dashboard,
                  title: 'Dashboard',
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to dashboard
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.people,
                  title: 'Customers',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const CustomersScreen(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.inventory,
                  title: 'Products',
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to products
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.receipt_long,
                  title: 'New Bill',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const NewBillScreen(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.history,
                  title: 'Bills History',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const BillsHistoryScreen(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.analytics,
                  title: 'Reports',
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to reports
                  },
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    'INVENTORY MANAGEMENT',
                    style: GoogleFonts.lato(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                _buildDrawerItem(
                  icon: Icons.dashboard_outlined,
                  title: 'Inventory Dashboard',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const InventoryDashboardScreen(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.add_box_outlined,
                  title: 'Add New Item',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const AddItemScreen(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.qr_code_scanner,
                  title: 'Scan Barcode',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ScanScreen(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.list_alt,
                  title: 'View All Items',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const AllItemsScreen(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.assessment_outlined,
                  title: 'Inventory Reports',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const InventoryReportsScreen(),
                      ),
                    );
                  },
                ),
                const Divider(),
                _buildDrawerItem(
                  icon: Icons.price_change,
                  title: 'Gold/Silver Rates',
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to rates
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.settings,
                  title: 'Settings',
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to settings
                  },
                ),
              ],
            ),
          ),

          // Footer
          const Divider(),
          _buildDrawerItem(
            icon: Icons.help_outline,
            title: 'Help & Support',
            onTap: () {
              Navigator.pop(context);
              // Show help dialog
            },
          ),
          _buildDrawerItem(
            icon: Icons.info_outline,
            title: 'About',
            onTap: () {
              Navigator.pop(context);
              _showAboutDialog(context);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFFFFD700)),
      title: Text(title, style: GoogleFonts.lato(fontWeight: FontWeight.w500)),
      onTap: onTap,
      dense: true,
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Jewelry Shop Billing',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 60,
        height: 60,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
          ),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.diamond, color: Colors.white, size: 30),
      ),
      children: [
        Text(
          'A comprehensive billing solution for gold and silver jewelry shops. '
          'Manage customers, products, invoicing, and reports all in one place.',
          style: GoogleFonts.lato(),
        ),
      ],
    );
  }
}
