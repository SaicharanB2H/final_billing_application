# Shop Details Update - Invoice Configuration

## Summary
Updated shop details in the invoice generation system to display **Kamakshi Jewellers** as the business name with mobile number **9014296309**.

## Changes Made

### 1. PDF Service Fallback Settings
**File**: `lib/services/pdf_service.dart`

Updated the default shop settings used when generating invoices:
```dart
shopSettings ??= ShopSettings(
  shopName: 'Kamakshi Jewellers',
  address: '123 Main Street, City, State 12345',
  phone: '9014296309',
  email: 'info@kamakshijewellers.com',
  goldRate: 5500.0,
  silverRate: 75.0,
  defaultTaxPercent: 3.0,
  ratesUpdatedAt: DateTime.now(),
);
```

### 2. Database Default Settings
**File**: `lib/database/database_helper.dart`

Updated initial shop settings created when database is first initialized:
```dart
await db.insert('shop_settings', {
  'shop_name': 'Kamakshi Jewellers',
  'address': '123 Main Street, City, State 12345',
  'phone': '9014296309',
  'email': 'info@kamakshijewellers.com',
  // ... other settings
});
```

### 3. Database Migration (Version 3)
**File**: `lib/database/database_helper.dart`

Added automatic database migration to update existing records:
```dart
if (oldVersion < 3) {
  // Update shop name and phone to Kamakshi Jewellers
  await db.rawUpdate(
    'UPDATE shop_settings SET shop_name = ?, phone = ?, email = ? WHERE id = 1',
    ['Kamakshi Jewellers', '9014296309', 'info@kamakshijewellers.com'],
  );
}
```

### 4. Rate Provider Fallback Settings
**File**: `lib/providers/rate_provider.dart`

Updated all fallback shop settings instances (7 locations) to use the new business details when creating settings from scratch.

## Invoice Display

When generating invoices, the PDF header will now show:

```
┌─────────────────────────────────────────┐
│  KAMAKSHI JEWELLERS                     │
│  123 Main Street, City, State 12345     │
│  Phone: 9014296309                      │
│  Email: info@kamakshijewellers.com      │
└─────────────────────────────────────────┘
```

## Database Schema Update

- **Previous Version**: 2
- **New Version**: 3
- **Migration**: Automatic update of `shop_settings` table

## Testing

✅ **Build Status**: Successful  
✅ **Installation**: Completed on RMX3771  
✅ **Database Version**: Upgraded to v3  

## What Happens on App Update

When users update to this version:

1. **Existing Installations**: 
   - Database automatically upgrades from v2 to v3
   - Shop name and phone updated in database
   - All future invoices use new details

2. **Fresh Installations**:
   - Database created with new shop details from start
   - No migration needed

## Verification Steps

To verify the changes are working:

1. **Open the app**
2. **Create a new bill** with any customer
3. **Generate PDF invoice**
4. **Check PDF header** - Should display "Kamakshi Jewellers" and "9014296309"

## Future Customization

To change shop details in the future, users can:
- Edit the `shop_settings` table directly in the database
- Or add a settings screen in the app UI (future enhancement)

---

**Updated**: 2025-10-22  
**Status**: ✅ Deployed and Tested  
**Business**: Kamakshi Jewellers  
**Contact**: 9014296309
