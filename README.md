# 💎 Jewelry Shop Billing System

[![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

A comprehensive, offline-capable Flutter mobile application designed specifically for jewelry shop billing and inventory management. Generate professional invoices, manage customers, track sales, and export data—all with a beautiful, touch-friendly interface.

## ✨ Features

### 📱 Bill Management
- ✅ Create detailed jewelry bills with gold/silver items
- ✅ Automatic bill storage in local SQLite database
- ✅ Professional PDF invoice generation with tax breakdown (CGST/SGST)
- ✅ Comprehensive bills history with search and filtering
- ✅ Payment status tracking (Paid, Pending, Partial)
- ✅ Real-time total calculations with making charges

### 📊 Data Export & Reporting
- ✅ Export bills data in multiple formats (CSV, Excel, JSON)
- ✅ Quick export from dashboard for all records
- ✅ Filtered export from bills history
- ✅ Direct file sharing integration
- ✅ Date-range based export filtering

### 👥 Customer Management
- ✅ Add and manage customer information
- ✅ Complete customer billing history
- ✅ Advanced search by name or phone number
- ✅ Customer profile with transaction details

### 📈 Dashboard & Analytics
- ✅ Real-time sales overview and statistics
- ✅ Daily, weekly, and monthly revenue tracking
- ✅ Visual charts and graphs using FL Chart
- ✅ Quick access to recent transactions

### ⚙️ Shop Settings
- ✅ Real-time gold and silver rate management
- ✅ Configurable shop details (name, address, GST, phone)
- ✅ Customizable making charges and tax rates
- ✅ Rate history tracking

### 🎯 Additional Highlights
- ✅ **100% Offline** - Works without internet connection
- ✅ **Touch-Optimized** - Mobile-friendly interface
- ✅ **Fast & Responsive** - Optimized performance
- ✅ **Secure** - Local data storage with SQLite

## 🛠️ Technology Stack

| Category | Technology |
|----------|------------|
| **Framework** | Flutter 3.0+ |
| **Language** | Dart 3.0+ |
| **State Management** | Provider (Riverpod pattern) |
| **Database** | SQLite (sqflite package) |
| **PDF Generation** | pdf package with printing support |
| **Data Export** | CSV, Excel (excel package), JSON |
| **UI Framework** | Material Design 3 |
| **Typography** | Google Fonts |
| **Charts & Graphs** | FL Chart |
| **Date/Time** | intl package for localization |

## 📁 Project Structure

```
lib/
├── database/
│   └── database_helper.dart         # SQLite database setup and migrations
├── models/
│   ├── invoice.dart                 # Invoice and InvoiceItem models
│   ├── customer.dart                # Customer data model
│   ├── product.dart                 # Product/Jewelry item model
│   ├── shop_settings.dart           # Shop configuration model
│   └── user.dart                    # User model
├── providers/
│   ├── invoice_provider.dart        # Invoice state management
│   ├── customer_provider.dart       # Customer state management
│   ├── product_provider.dart        # Product state management
│   ├── rate_provider.dart           # Gold/Silver rate management
│   └── dashboard_provider.dart      # Dashboard analytics state
├── screens/
│   ├── billing/
│   │   ├── new_bill_screen.dart     # Create new invoice
│   │   └── bills_history_screen.dart # View all invoices
│   ├── customers/
│   │   ├── customers_screen.dart    # Customer listing
│   │   ├── customer_detail_screen.dart
│   │   └── add_edit_customer_screen.dart
│   └── dashboard/
│       └── dashboard_screen.dart    # Main dashboard with stats
├── services/
│   ├── invoice_service.dart         # Invoice CRUD operations
│   ├── customer_service.dart        # Customer CRUD operations
│   ├── product_service.dart         # Product CRUD operations
│   ├── pdf_service.dart             # PDF generation logic
│   ├── data_export_service.dart     # CSV/Excel/JSON export
│   └── auth_service.dart            # Authentication service
├── widgets/
│   └── main_drawer.dart             # Navigation drawer widget
└── main.dart                        # Application entry point
```

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK**: 3.0 or higher ([Install Flutter](https://flutter.dev/docs/get-started/install))
- **Dart SDK**: 3.0 or higher (included with Flutter)
- **IDE**: Android Studio, VS Code, or IntelliJ IDEA with Flutter/Dart plugins
- **Device**: Android/iOS device or emulator/simulator
- **Java**: JDK 17 (for Android builds)

### Installation Steps

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd price_calculator
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Java (Windows)**
   ```bash
   flutter config --jdk-dir="C:\Program Files\Eclipse Adoptium\jdk-17.0.6.10-hotspot\"
   ```

4. **Enable Windows Developer Mode** (for Windows development)
   ```bash
   start ms-settings:developers
   ```

5. **Run the app**
   ```bash
   # Debug mode
   flutter run
   
   # Release mode
   flutter run --release
   ```

### Building for Release

#### Android
```bash
# Build APK
flutter build apk --release

# Build App Bundle (recommended for Google Play)
flutter build appbundle --release

# Build split APKs per ABI (smaller file size)
flutter build apk --split-per-abi --release
```

#### iOS (macOS only)
```bash
# Build iOS app
flutter build ios --release

# Build IPA for distribution
flutter build ipa --release
```

#### Desktop
```bash
# Windows
flutter build windows --release

# Linux
flutter build linux --release

# macOS
flutter build macos --release
```

## 📖 Usage Guide

### Creating a New Bill
1. Navigate to **Dashboard** → Tap **"New Bill"** button
2. Select or add a new **customer**
3. Add jewelry items:
   - Enter item description (e.g., "Gold Chain")
   - Specify weight in grams
   - Select purity (e.g., 22K, 24K)
   - Enter making charges (optional)
4. Review the **auto-calculated total** (including CGST/SGST)
5. Tap **"Generate Bill"**
6. Bill is automatically saved to database and PDF is generated

### Managing Bills History
1. Open **"Bills History"** from drawer menu
2. **Search** by invoice number, customer name, or date
3. **Filter** by:
   - Payment status (Paid/Pending/Partial)
   - Date range
4. Tap any bill to:
   - View detailed breakdown
   - Regenerate PDF
   - Update payment status
   - Share invoice

### Exporting Data
1. **Quick Export** (All records):
   - Dashboard → **"Export Data"** card
   - Select format (CSV/Excel/JSON)
   - File is saved and ready to share

2. **Filtered Export**:
   - Bills History → Apply filters
   - Tap **Export** icon
   - Choose format
   - Share filtered data

### Managing Customers
1. Navigate to **"Customers"** from drawer
2. **Add new customer**: Tap "+" button
3. **View customer**: Tap on customer card
4. **Edit/Delete**: Use customer detail screen
5. **Search**: Use search bar to find customers

### Configuring Shop Settings
1. Open **Settings** from drawer
2. Update:
   - Shop name, address, GST number
   - Contact details
   - Current gold/silver rates
   - Making charges percentage
   - Tax rates (CGST/SGST)

## 🗄️ Database Schema

The application uses **SQLite** for local data storage with the following tables:

### Core Tables

| Table | Description | Key Fields |
|-------|-------------|------------|
| **invoices** | Invoice headers | id, invoice_number, customer_id, date, total_amount, cgst, sgst, payment_status |
| **invoice_items** | Line items for each invoice | id, invoice_id, description, weight, purity, rate, making_charges, amount |
| **customers** | Customer directory | id, name, phone, email, address, created_at |
| **products** | Jewelry product catalog | id, name, category, description, base_price |
| **shop_settings** | Shop configuration | id, shop_name, address, gst_number, phone, gold_rate, silver_rate, making_charge_percent, tax_rate |
| **users** | User authentication | id, username, password_hash, role |

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. **Fork** the repository
2. **Create** a feature branch
   ```bash
   git checkout -b feature/AmazingFeature
   ```
3. **Commit** your changes
   ```bash
   git commit -m 'Add some AmazingFeature'
   ```
4. **Push** to the branch
   ```bash
   git push origin feature/AmazingFeature
   ```
5. **Open** a Pull Request

### Code Style
- Follow [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- Run `flutter analyze` before committing
- Format code with `flutter format .`
- Write meaningful commit messages

## 📸 Screenshots

_(Add screenshots of your app here)_

## 🔒 Security

- All data is stored **locally** on the device
- No data is transmitted to external servers
- SQLite database is stored in app's private directory
- **Important**: Never commit sensitive files like keystores or API keys

## 📝 Documentation

For detailed implementation guides, see:
- [`BILL_STORAGE_EXPORT_IMPLEMENTATION.md`](BILL_STORAGE_EXPORT_IMPLEMENTATION.md) - Bill storage and export features
- [`INVOICE_TAX_BREAKDOWN_UPDATE.md`](INVOICE_TAX_BREAKDOWN_UPDATE.md) - Tax calculation details
- [`CGST_SGST_VERIFICATION_GUIDE.md`](CGST_SGST_VERIFICATION_GUIDE.md) - Tax verification guide
- [`SHOP_DETAILS_UPDATE.md`](SHOP_DETAILS_UPDATE.md) - Shop settings configuration
- [`DASHBOARD_REALTIME_DATA_UPDATE.md`](DASHBOARD_REALTIME_DATA_UPDATE.md) - Dashboard updates
- [`BUILD_AND_DEPLOYMENT_LOG.md`](BUILD_AND_DEPLOYMENT_LOG.md) - Build logs and deployment

## 🐛 Known Issues

- None at the moment

## 📅 Roadmap

- [ ] Multi-language support
- [ ] Cloud backup integration
- [ ] Barcode scanning for products
- [ ] SMS/Email invoice sending
- [ ] Advanced analytics and reports
- [ ] Multi-store support

## 📄 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Author

**Your Name**
- GitHub: [@yourusername](https://github.com/yourusername)
- Email: your.email@example.com

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- All open-source package contributors
- Community feedback and suggestions

## 💬 Support

For support, questions, or feature requests:
- Create an [issue](https://github.com/yourusername/price_calculator/issues)
- Start a [discussion](https://github.com/yourusername/price_calculator/discussions)

---

⭐ **Star this repository if you find it helpful!**

