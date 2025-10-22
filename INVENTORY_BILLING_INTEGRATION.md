# Inventory-Billing Integration

## Overview
The billing system now integrates with the inventory module, allowing you to add inventory items to bills by scanning their barcodes and automatically marking them as sold when the bill is generated.

## Features

### 1. Scan Items to Add to Bill
- **Location**: New Bill Screen → Items Section
- **Buttons**: 
  - **Scan** (Green button with QR scanner icon)
  - **Add** (Gold button for manual entry)

### 2. How It Works

#### Scanning an Inventory Item
1. Click the "Scan" button in the Items section
2. A barcode scanner dialog will appear
3. Position the barcode within the white frame
4. The app will automatically:
   - Look up the item by SKU in the inventory database
   - Check if the item is available for sale (status = "in_stock")
   - Prevent duplicate items from being added twice
   - Auto-fill item details (name, weight, purity, making charges, etc.)
   - Add the item to the bill

#### Auto-populated Fields from Inventory
When you scan an inventory item, the following fields are automatically filled:
- **Product Name**: Category name + SKU (e.g., "Ring (GOLD-RING-001)")
- **Type**: Gold or Silver (based on material)
- **Weight**: Net weight from inventory
- **Purity**: Extracted from inventory purity (22K → 22, 925 Silver → 92.5)
- **Making Charges**: From inventory item
- **Rate**: Current gold/silver rate
- **Wastage**: Current wastage percentage for the material

#### Automatic Inventory Status Update
When you generate a bill:
1. All scanned inventory items are automatically marked as **SOLD** in the inventory database
2. A transaction log is created with:
   - Action: "sold"
   - User: "admin" (can be customized)
   - Notes: "Sold in invoice INV-XXXX"
3. The inventory dashboard reflects the updated stock status

### 3. Validation & Safety Features

#### Duplicate Prevention
- The system tracks scanned items using their unique UIDs
- If you try to scan the same item twice, you'll see: "This item is already added to the bill"

#### Status Check
- Only items with status "in_stock" can be added to bills
- If you scan an item that's sold, issued, or returned, you'll see an error message

#### Manual Entry Still Available
- You can still manually add items using the "Add" button
- Manual items won't be linked to inventory (no automatic status update)
- Mix scanned and manual items in the same bill

### 4. Bill Item Indicators
- Scanned inventory items have their SKU shown in the product name
- Example: "Ring (GOLD-RING-001)" indicates this is a scanned inventory item

## Usage Example

### Creating a Bill with Inventory Items

1. **Open New Bill Screen**
   - Navigate to Billing → New Bill

2. **Add Customer Details**
   - Enter customer name (required)
   - Enter phone number (optional)

3. **Scan Inventory Items**
   - Click "Scan" button
   - Point camera at barcode on jewelry label
   - Item is automatically added with all details filled

4. **Add More Items** (if needed)
   - Scan more items using "Scan" button
   - Or manually add items using "Add" button

5. **Review & Generate Bill**
   - Check all items in the bill summary
   - Review total amount (subtotal + CGST + SGST)
   - Click the save icon in the app bar or scroll to bottom

6. **Automatic Inventory Update**
   - All scanned items are marked as "sold"
   - Transaction logs are created
   - Inventory dashboard updates automatically
   - PDF invoice is generated

## Technical Details

### Database Changes
No schema changes required. The system uses:
- Existing `inventory_items` table (status field updated to "sold")
- Existing `inventory_transactions` table (new transaction logged)
- Existing `invoices` and `invoice_items` tables

### Linking Mechanism
- Each `BillItem` has an optional `inventoryUid` field
- When an item is scanned, its UID is stored in the bill item
- On bill generation, the system looks for all bill items with `inventoryUid` set
- Those inventory items are marked as sold with a reference to the invoice number

### State Management
- Uses existing `InventoryProvider` for item lookup and status updates
- Uses existing `InvoiceProvider` for bill generation
- No new providers needed

## Benefits

1. **Reduced Data Entry**: No need to manually type item details
2. **Accuracy**: Eliminates manual entry errors
3. **Real-time Inventory**: Stock status updates automatically
4. **Traceability**: Know exactly which item was sold in which invoice
5. **Audit Trail**: Transaction logs maintain complete history
6. **Flexibility**: Mix scanned and manual items in the same bill

## Future Enhancements

Potential future improvements:
- User authentication to track which user sold the item
- Option to un-link items before generating bill
- Bulk scanning mode
- Scan history within the bill screen
- Export sold items report with invoice references

## Troubleshooting

### Camera Permission Issues
- Ensure camera permissions are granted in Android/iOS settings
- Check `AndroidManifest.xml` has `android.permission.CAMERA`

### Item Not Found
- Verify the barcode matches the SKU in inventory
- Check if item exists in inventory database
- Ensure barcode is readable and not damaged

### Item Already Sold
- Check item status in inventory
- If accidentally marked as sold, update status manually in inventory screen

### Duplicate Item Warning
- If you need to sell multiple identical items, they should have different SKUs
- Each physical item should have its own barcode/SKU

## Related Files

- `lib/screens/billing/new_bill_screen.dart` - Main billing screen with scan integration
- `lib/providers/inventory_provider.dart` - Inventory management
- `lib/models/inventory_item.dart` - Inventory item model
- `lib/screens/inventory/scan_screen.dart` - Original inventory scan screen (for reference)

## Dependencies

- `mobile_scanner: ^5.2.3` - Barcode scanning functionality
- `provider: ^6.1.2` - State management
- `sqflite` - Local database
