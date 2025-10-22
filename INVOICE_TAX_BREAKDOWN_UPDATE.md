# Invoice Tax Breakdown - CGST & SGST Display

## Update Summary
Added detailed CGST and SGST tax breakdown in the invoice PDF with individual amounts and percentages.

## Changes Made

### 📄 PDF Invoice Enhancement

**File**: `lib/services/pdf_service.dart`

#### Updated Total Section Display

The invoice now shows a comprehensive tax breakdown:

```
┌─────────────────────────────────┐
│ Subtotal:           Rs.10,000.00│
│ ─────────────────────────────── │
│ ┌─── Tax Breakdown ───────────┐ │
│ │ CGST (1.5%):      Rs.150.00 │ │
│ │ SGST (1.5%):      Rs.150.00 │ │
│ └─────────────────────────────┘ │
│ Total Tax:            Rs.300.00 │
│ ═══════════════════════════════ │
│ Total Amount:      Rs.10,300.00 │
└─────────────────────────────────┘
```

### Key Improvements

1. **Separate CGST Display**
   - Shows CGST percentage (1.5%)
   - Displays calculated CGST amount
   - Blue color coding for easy identification

2. **Separate SGST Display**
   - Shows SGST percentage (1.5%)
   - Displays calculated SGST amount
   - Green color coding for distinction

3. **Tax Summary**
   - Combined "Total Tax" line showing CGST + SGST
   - Clear visual separation from other amounts
   - Highlighted background for tax section

4. **Visual Enhancements**
   - Bordered tax breakdown section
   - Color-coded amounts (Blue for CGST, Green for SGST)
   - Larger width (250px vs 200px) for better readability
   - Background highlighting for emphasis

## Tax Calculation

The system automatically calculates:

```dart
// From shop settings (configurable via Dashboard)
cgstPercent = 1.5%
sgstPercent = 1.5%

// Calculation
cgstAmount = subtotal × (cgstPercent / 100)
sgstAmount = subtotal × (sgstPercent / 100)
totalTax = cgstAmount + sgstAmount
totalAmount = subtotal + totalTax
```

### Example Calculation

For a bill with **Subtotal: Rs.10,000**:

| Description | Calculation | Amount |
|-------------|-------------|--------|
| Subtotal | - | Rs.10,000.00 |
| CGST (1.5%) | 10,000 × 1.5% | Rs.150.00 |
| SGST (1.5%) | 10,000 × 1.5% | Rs.150.00 |
| **Total Tax** | 150 + 150 | **Rs.300.00** |
| **Grand Total** | 10,000 + 300 | **Rs.10,300.00** |

## Invoice PDF Layout

### Header Section
```
╔═══════════════════════════════════════╗
║  KAMAKSHI JEWELLERS                   ║
║  Phone: 9014296309                    ║
║  Email: info@kamakshijewellers.com    ║
╚═══════════════════════════════════════╝
```

### Items Table
- Item details with weight, purity, rate
- Making charges
- Individual item totals

### Totals Section (NEW ENHANCED)
```
┌─────────────────────────────────┐
│ Subtotal:           Rs.10,000.00│
├─────────────────────────────────┤
│   Tax Breakdown (Highlighted)    │
│ ┌─────────────────────────────┐ │
│ │ CGST (1.5%):    Rs.150.00  │ │  ← Blue text
│ │ SGST (1.5%):    Rs.150.00  │ │  ← Green text
│ └─────────────────────────────┘ │
│                                  │
│ Total Tax:            Rs.300.00 │
├═════════════════════════════════┤
│ Total Amount:      Rs.10,300.00 │  ← Bold, large
└─────────────────────────────────┘
```

## Configuration

Tax percentages can be adjusted via:

1. **Dashboard Settings**
   - Navigate to Dashboard
   - Click on CGST/SGST cards
   - Edit percentages
   - Save changes

2. **Database Direct**
   - Table: `shop_settings`
   - Fields: `cgst_percent`, `sgst_percent`

## Benefits

✅ **Tax Transparency**: Customers can see exact tax breakdown  
✅ **GST Compliance**: Separate CGST/SGST as per Indian tax regulations  
✅ **Professional Look**: Enhanced invoice design  
✅ **Easy Verification**: Clear calculation trail  
✅ **Color Coded**: Quick visual identification  

## Technical Details

### Method Signature Change
```dart
// Before
_buildTotalSection(Invoice invoice)

// After
_buildTotalSection(Invoice invoice, ShopSettings shopSettings)
```

### Tax Calculation Logic
```dart
double cgstPercent = shopSettings.cgstPercent;  // Default: 1.5%
double sgstPercent = shopSettings.sgstPercent;  // Default: 1.5%

double cgstAmount = invoice.subtotal * (cgstPercent / 100);
double sgstAmount = invoice.subtotal * (sgstPercent / 100);
```

### Styling
- **CGST**: Blue color (`PdfColors.blue800`)
- **SGST**: Green color (`PdfColors.green800`)
- **Background**: Light grey (`PdfColors.grey50`)
- **Border**: Grey borders for section separation
- **Total Amount**: Amber background with bold text

## Testing

### To Verify the Update:

1. **Open the app** on your device
2. **Create a new bill** with any items
3. **Generate PDF invoice**
4. **Check the totals section** should show:
   - Subtotal
   - CGST with percentage and amount
   - SGST with percentage and amount
   - Total Tax
   - Grand Total

### Sample Test Data

```
Item: Gold Necklace
Weight: 10g
Rate: Rs.6,000/g
Making: Rs.500
Wastage: 8%

Calculation:
- Base: 10 × 6,000 = 60,000
- Wastage: 60,000 × 8% = 4,800
- Making: 500
- Subtotal: 65,300
- CGST (1.5%): 979.50
- SGST (1.5%): 979.50
- Total: 67,259.00
```

## Deployment

- **Built**: October 22, 2025
- **APK Size**: 52.2 MB
- **Installed**: RMX3771 (Realme - Android 15)
- **Status**: ✅ Active

---

**Updated**: 2025-10-22  
**Feature**: Tax Breakdown Display  
**Compliance**: Indian GST Regulations  
**Business**: Kamakshi Jewellers
