import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/models.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() {
    return _instance;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'jewelry_shop.db');
    return await openDatabase(
      path, 
      version: 2, // Updated version to 2
      onCreate: _onCreate,
      onUpgrade: _onUpgrade, // Added onUpgrade callback
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        full_name TEXT NOT NULL,
        email TEXT NOT NULL,
        phone TEXT NOT NULL,
        role TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');

    // Customers table
    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        email TEXT,
        address TEXT,
        gstin TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');

    // Products table
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        purity TEXT NOT NULL,
        weight REAL NOT NULL,
        making_charges REAL NOT NULL,
        wastage_percent REAL NOT NULL,
        stone_charges REAL,
        description TEXT,
        stock_quantity INTEGER,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');

    // Invoices table
    await db.execute('''
      CREATE TABLE invoices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_number TEXT UNIQUE NOT NULL,
        customer_id INTEGER NOT NULL,
        user_id INTEGER NOT NULL,
        invoice_date TEXT NOT NULL,
        subtotal REAL NOT NULL,
        discount_amount REAL NOT NULL DEFAULT 0,
        discount_percent REAL NOT NULL DEFAULT 0,
        tax_percent REAL NOT NULL,
        tax_amount REAL NOT NULL,
        total_amount REAL NOT NULL,
        payment_status TEXT NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        FOREIGN KEY (customer_id) REFERENCES customers (id),
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    // Invoice items table
    await db.execute('''
      CREATE TABLE invoice_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_id INTEGER NOT NULL,
        product_id INTEGER,
        item_name TEXT NOT NULL,
        item_type TEXT NOT NULL,
        purity TEXT NOT NULL,
        weight REAL NOT NULL,
        current_rate REAL NOT NULL,
        making_charges REAL NOT NULL,
        wastage_percent REAL NOT NULL,
        stone_charges REAL,
        item_total REAL NOT NULL,
        quantity INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (invoice_id) REFERENCES invoices (id),
        FOREIGN KEY (product_id) REFERENCES products (id)
      )
    ''');

    // Shop settings table
    await db.execute('''
      CREATE TABLE shop_settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        shop_name TEXT NOT NULL,
        address TEXT NOT NULL,
        phone TEXT NOT NULL,
        email TEXT,
        gstin TEXT,
        logo_path TEXT,
        signature_path TEXT,
        gold_rate REAL NOT NULL,
        silver_rate REAL NOT NULL,
        default_tax_percent REAL NOT NULL DEFAULT 3.0,
        default_making_charge_gold REAL NOT NULL DEFAULT 500.0,
        default_making_charge_silver REAL NOT NULL DEFAULT 50.0,
        default_wastage_gold REAL NOT NULL DEFAULT 8.0,
        default_wastage_silver REAL NOT NULL DEFAULT 5.0,
        currency_symbol TEXT NOT NULL DEFAULT '₹',
        rates_updated_at TEXT NOT NULL,
        updated_at TEXT,
        cgst_percent REAL NOT NULL DEFAULT 1.5,
        sgst_percent REAL NOT NULL DEFAULT 1.5
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_customers_phone ON customers (phone)');
    await db.execute('CREATE INDEX idx_customers_name ON customers (name)');
    await db.execute(
      'CREATE INDEX idx_invoices_customer_id ON invoices (customer_id)',
    );
    await db.execute(
      'CREATE INDEX idx_invoices_date ON invoices (invoice_date)',
    );
    await db.execute(
      'CREATE INDEX idx_invoice_items_invoice_id ON invoice_items (invoice_id)',
    );
    await db.execute('CREATE INDEX idx_products_type ON products (type)');

    // Insert default admin user
    await db.insert('users', {
      'username': 'admin',
      'password': 'admin123', // In production, this should be hashed
      'full_name': 'System Administrator',
      'email': 'admin@jewelryshop.com',
      'phone': '+1234567890',
      'role': 'admin',
      'is_active': 1,
      'created_at': DateTime.now().toIso8601String(),
    });

    // Insert default shop settings
    await db.insert('shop_settings', {
      'shop_name': 'Jewelry Shop',
      'address': '123 Main Street, City, State 12345',
      'phone': '+1234567890',
      'email': 'info@jewelryshop.com',
      'gold_rate': 5500.0, // Sample rate
      'silver_rate': 75.0, // Sample rate
      'default_tax_percent': 3.0,
      'default_making_charge_gold': 500.0,
      'default_making_charge_silver': 50.0,
      'default_wastage_gold': 8.0,
      'default_wastage_silver': 5.0,
      'currency_symbol': '₹',
      'rates_updated_at': DateTime.now().toIso8601String(),
      'cgst_percent': 1.5,
      'sgst_percent': 1.5,
    });
  }

  // Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add CGST and SGST columns to shop_settings table
      try {
        await db.execute('ALTER TABLE shop_settings ADD COLUMN cgst_percent REAL NOT NULL DEFAULT 1.5');
        await db.execute('ALTER TABLE shop_settings ADD COLUMN sgst_percent REAL NOT NULL DEFAULT 1.5');
      } catch (e) {
        // If columns already exist, update existing records
        await db.rawUpdate('UPDATE shop_settings SET cgst_percent = 1.5, sgst_percent = 1.5');
      }
    }
  }

  // User operations
  Future<int> insertUser(User user) async {
    final db = await database;
    return await db.insert('users', user.toMap());
  }

  Future<User?> getUserByUsername(String username) async {
    final db = await database;
    final maps = await db.query(
      'users',
      where: 'username = ? AND is_active = 1',
      whereArgs: [username],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<List<User>> getAllUsers() async {
    final db = await database;
    final maps = await db.query('users', orderBy: 'full_name ASC');
    return maps.map((map) => User.fromMap(map)).toList();
  }

  Future<int> updateUser(User user) async {
    final db = await database;
    return await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<int> deleteUser(int id) async {
    final db = await database;
    return await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  // Customer operations
  Future<int> insertCustomer(Customer customer) async {
    final db = await database;
    return await db.insert('customers', customer.toMap());
  }

  Future<List<Customer>> getAllCustomers() async {
    final db = await database;
    final maps = await db.query('customers', orderBy: 'name ASC');
    return maps.map((map) => Customer.fromMap(map)).toList();
  }

  Future<List<Customer>> searchCustomers(String query) async {
    final db = await database;
    final maps = await db.query(
      'customers',
      where: 'name LIKE ? OR phone LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'name ASC',
    );
    return maps.map((map) => Customer.fromMap(map)).toList();
  }

  Future<Customer?> getCustomerById(int id) async {
    final db = await database;
    final maps = await db.query('customers', where: 'id = ?', whereArgs: [id]);

    if (maps.isNotEmpty) {
      return Customer.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateCustomer(Customer customer) async {
    final db = await database;
    return await db.update(
      'customers',
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  Future<int> deleteCustomer(int id) async {
    final db = await database;
    return await db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }

  // Product operations
  Future<int> insertProduct(Product product) async {
    final db = await database;
    return await db.insert('products', product.toMap());
  }

  Future<List<Product>> getAllProducts() async {
    final db = await database;
    final maps = await db.query('products', orderBy: 'name ASC');
    return maps.map((map) => Product.fromMap(map)).toList();
  }

  Future<List<Product>> getProductsByType(ProductType type) async {
    final db = await database;
    final maps = await db.query(
      'products',
      where: 'type = ?',
      whereArgs: [type.toString().split('.').last],
      orderBy: 'name ASC',
    );
    return maps.map((map) => Product.fromMap(map)).toList();
  }

  Future<Product?> getProductById(int id) async {
    final db = await database;
    final maps = await db.query('products', where: 'id = ?', whereArgs: [id]);

    if (maps.isNotEmpty) {
      return Product.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateProduct(Product product) async {
    final db = await database;
    return await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await database;
    return await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  // Invoice operations
  Future<int> insertInvoice(Invoice invoice) async {
    final db = await database;

    return await db.transaction((txn) async {
      // Insert invoice
      final invoiceId = await txn.insert('invoices', invoice.toMap());

      // Insert invoice items
      for (final item in invoice.items) {
        final itemMap = item.toMap();
        itemMap['invoice_id'] = invoiceId;
        await txn.insert('invoice_items', itemMap);
      }

      return invoiceId;
    });
  }

  Future<List<Invoice>> getAllInvoices() async {
    final db = await database;
    final invoiceMaps = await db.query(
      'invoices',
      orderBy: 'invoice_date DESC',
    );

    List<Invoice> invoices = [];
    for (final invoiceMap in invoiceMaps) {
      final items = await getInvoiceItems(invoiceMap['id'] as int);
      invoices.add(Invoice.fromMap(invoiceMap, items));
    }

    return invoices;
  }

  Future<List<InvoiceItem>> getInvoiceItems(int invoiceId) async {
    final db = await database;
    final maps = await db.query(
      'invoice_items',
      where: 'invoice_id = ?',
      whereArgs: [invoiceId],
    );
    return maps.map((map) => InvoiceItem.fromMap(map)).toList();
  }

  Future<Invoice?> getInvoiceById(int id) async {
    final db = await database;
    final maps = await db.query('invoices', where: 'id = ?', whereArgs: [id]);

    if (maps.isNotEmpty) {
      final items = await getInvoiceItems(id);
      return Invoice.fromMap(maps.first, items);
    }
    return null;
  }

  Future<List<Invoice>> getInvoicesByCustomer(int customerId) async {
    final db = await database;
    final invoiceMaps = await db.query(
      'invoices',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'invoice_date DESC',
    );

    List<Invoice> invoices = [];
    for (final invoiceMap in invoiceMaps) {
      final items = await getInvoiceItems(invoiceMap['id'] as int);
      invoices.add(Invoice.fromMap(invoiceMap, items));
    }

    return invoices;
  }

  Future<List<Invoice>> getInvoicesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await database;
    final invoiceMaps = await db.query(
      'invoices',
      where: 'invoice_date BETWEEN ? AND ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
      orderBy: 'invoice_date DESC',
    );

    List<Invoice> invoices = [];
    for (final invoiceMap in invoiceMaps) {
      final items = await getInvoiceItems(invoiceMap['id'] as int);
      invoices.add(Invoice.fromMap(invoiceMap, items));
    }

    return invoices;
  }

  Future<int> updateInvoice(Invoice invoice) async {
    final db = await database;
    return await db.update(
      'invoices',
      invoice.toMap(),
      where: 'id = ?',
      whereArgs: [invoice.id],
    );
  }

  Future<String> generateInvoiceNumber() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM invoices WHERE invoice_date LIKE ?',
      ['${DateTime.now().year}%'],
    );

    final count = result.first['count'] as int;
    final invoiceNumber =
        'INV-${DateTime.now().year}-${(count + 1).toString().padLeft(4, '0')}';
    return invoiceNumber;
  }

  // Shop settings operations
  Future<ShopSettings?> getShopSettings() async {
    final db = await database;
    final maps = await db.query('shop_settings', limit: 1);

    if (maps.isNotEmpty) {
      return ShopSettings.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateShopSettings(ShopSettings settings) async {
    final db = await database;
    final maps = await db.query('shop_settings', limit: 1);

    if (maps.isNotEmpty) {
      return await db.update(
        'shop_settings',
        settings.toMap(),
        where: 'id = ?',
        whereArgs: [maps.first['id']],
      );
    } else {
      return await db.insert('shop_settings', settings.toMap());
    }
  }

  // Analytics and reports
  Future<Map<String, dynamic>> getDashboardData() async {
    final db = await database;

    // Today's sales
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    final todaySalesResult = await db.rawQuery(
      '''
      SELECT SUM(total_amount) as total, COUNT(*) as count 
      FROM invoices 
      WHERE invoice_date BETWEEN ? AND ? AND payment_status != 'cancelled'
    ''',
      [todayStart.toIso8601String(), todayEnd.toIso8601String()],
    );

    // This month's sales
    final monthStart = DateTime(today.year, today.month, 1);
    final monthEnd = DateTime(today.year, today.month + 1, 1);

    final monthSalesResult = await db.rawQuery(
      '''
      SELECT SUM(total_amount) as total, COUNT(*) as count 
      FROM invoices 
      WHERE invoice_date BETWEEN ? AND ? AND payment_status != 'cancelled'
    ''',
      [monthStart.toIso8601String(), monthEnd.toIso8601String()],
    );

    // Total customers
    final customerCountResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM customers',
    );

    // Total products
    final productCountResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM products',
    );

    // Pending invoices
    final pendingInvoicesResult = await db.rawQuery('''
      SELECT COUNT(*) as count, SUM(total_amount) as total 
      FROM invoices 
      WHERE payment_status = 'pending'
    ''');

    return {
      'todaySales': todaySalesResult.first['total'] ?? 0.0,
      'todayInvoiceCount': todaySalesResult.first['count'] ?? 0,
      'monthSales': monthSalesResult.first['total'] ?? 0.0,
      'monthInvoiceCount': monthSalesResult.first['count'] ?? 0,
      'customerCount': customerCountResult.first['count'] ?? 0,
      'productCount': productCountResult.first['count'] ?? 0,
      'pendingInvoiceCount': pendingInvoicesResult.first['count'] ?? 0,
      'pendingInvoiceAmount': pendingInvoicesResult.first['total'] ?? 0.0,
    };
  }

  Future<List<Map<String, dynamic>>> getSalesReportByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await database;

    return await db.rawQuery(
      '''
      SELECT 
        DATE(invoice_date) as date,
        COUNT(*) as invoice_count,
        SUM(total_amount) as total_sales,
        SUM(tax_amount) as total_tax
      FROM invoices 
      WHERE invoice_date BETWEEN ? AND ? 
        AND payment_status != 'cancelled'
      GROUP BY DATE(invoice_date)
      ORDER BY date DESC
    ''',
      [startDate.toIso8601String(), endDate.toIso8601String()],
    );
  }

  Future<List<Map<String, dynamic>>> getTopCustomers(int limit) async {
    final db = await database;

    return await db.rawQuery(
      '''
      SELECT 
        c.id,
        c.name,
        c.phone,
        COUNT(i.id) as invoice_count,
        SUM(i.total_amount) as total_purchases
      FROM customers c
      LEFT JOIN invoices i ON c.id = i.customer_id
      WHERE i.payment_status != 'cancelled' OR i.payment_status IS NULL
      GROUP BY c.id, c.name, c.phone
      ORDER BY total_purchases DESC
      LIMIT ?
    ''',
      [limit],
    );
  }

  Future<List<Map<String, dynamic>>> getTopProducts(int limit) async {
    final db = await database;

    return await db.rawQuery(
      '''
      SELECT 
        ii.item_name,
        ii.item_type,
        SUM(ii.quantity) as total_quantity,
        SUM(ii.item_total) as total_sales,
        COUNT(DISTINCT ii.invoice_id) as invoice_count
      FROM invoice_items ii
      JOIN invoices i ON ii.invoice_id = i.id
      WHERE i.payment_status != 'cancelled'
      GROUP BY ii.item_name, ii.item_type
      ORDER BY total_sales DESC
      LIMIT ?
    ''',
      [limit],
    );
  }

  // Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
