# Jewelry Shop Billing System

A comprehensive Flutter mobile application for jewelry shop billing and inventory management.

## Features

### 📱 **Bill Management**
- Create detailed jewelry bills with gold/silver items
- Automatic bill storage in local SQLite database
- Professional PDF invoice generation
- Bills history with search and filtering
- Payment status tracking

### 📊 **Data Export**
- Export bills data in multiple formats (CSV, Excel, JSON)
- Quick export from dashboard
- Filtered export from bills history
- Share exported files directly from the app

### 👥 **Customer Management**
- Add and manage customer information
- Customer billing history
- Search customers by name or phone

### ⚙️ **Additional Features**
- Real-time gold and silver rate management
- Dashboard with sales overview and statistics
- Touch-friendly mobile interface
- Offline functionality with local storage

## Technology Stack

- **Framework**: Flutter
- **State Management**: Provider (Riverpod pattern)
- **Database**: SQLite (sqflite)
- **PDF Generation**: pdf package with printing support
- **Export Formats**: CSV, Excel (excel package), JSON
- **UI**: Material Design with Google Fonts
- **Charts**: FL Chart for analytics

## Project Structure

```
lib/
├── database/           # SQLite database helper
├── models/            # Data models (Invoice, Customer, Product, etc.)
├── providers/         # State management providers
├── screens/           # UI screens
│   ├── billing/       # Bill creation and history
│   ├── customers/     # Customer management
│   └── dashboard/     # Main dashboard
├── services/          # Business logic services
│   ├── data_export_service.dart  # Export functionality
│   ├── invoice_service.dart       # Invoice operations
│   ├── pdf_service.dart          # PDF generation
│   └── ...
├── widgets/           # Reusable UI components
└── main.dart         # App entry point
```

## Getting Started

### Prerequisites
- Flutter SDK (latest stable version)
- Android Studio / VS Code with Flutter extensions
- Android/iOS device or emulator

### Installation

1. Clone the repository
2. Navigate to the project directory
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Run the app:
   ```bash
   flutter run
   ```

### Building for Release

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS (on macOS)
flutter build ios --release
```

## Usage

### Creating a Bill
1. Tap "New Bill" from dashboard or drawer
2. Enter customer details
3. Add jewelry items with weight, purity, and making charges
4. Generate bill - automatically saves to database and creates PDF

### Viewing Bills History
1. Tap "Bills History" from dashboard or drawer
2. Search by invoice number or filter by date/status
3. Tap any bill to view details
4. Generate PDF or update payment status as needed

### Exporting Data
1. Use "Export Data" from dashboard for quick export
2. Or use export button in Bills History for filtered export
3. Choose format (CSV, Excel, JSON)
4. Share the generated file

## Database Schema

The app uses SQLite with the following main tables:
- `invoices` - Invoice headers
- `invoice_items` - Individual line items
- `customers` - Customer information
- `products` - Product catalog
- `shop_settings` - Shop configuration

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions, please create an issue in the repository.

