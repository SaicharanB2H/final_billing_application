import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/invoice.dart';
import '../models/customer.dart';
import '../models/shop_settings.dart';

class PdfService {
  // Generate PDF from invoice
  Future<Uint8List> generateInvoicePdf({
    required Invoice invoice,
    required Customer customer,
    ShopSettings? shopSettings,
  }) async {
    final pdf = pw.Document();

    // Default shop settings if not provided
    shopSettings ??= ShopSettings(
      shopName: 'Kamakshi Jewellers',
      address: '123 Main Street, City, State 12345',
      phone: '+91 7680959867',
      email: 'info@jewelryshop.com',
      goldRate: 5500.0,
      silverRate: 75.0,
      defaultTaxPercent: 3.0,
      ratesUpdatedAt: DateTime.now(),
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildHeader(shopSettings!),
            pw.SizedBox(height: 20),
            _buildInvoiceInfo(invoice),
            pw.SizedBox(height: 20),
            _buildCustomerInfo(customer),
            pw.SizedBox(height: 20),
            _buildItemsTable(invoice.items),
            pw.SizedBox(height: 20),
            _buildTotalSection(invoice),
            pw.SizedBox(height: 30),
            _buildFooter(),
          ];
        },
      ),
    );

    return pdf.save();
  }

  // Save PDF to device and open it
  Future<String> savePdfAndOpen({
    required Invoice invoice,
    required Customer customer,
    ShopSettings? shopSettings,
  }) async {
    try {
      // Generate PDF
      final pdfData = await generateInvoicePdf(
        invoice: invoice,
        customer: customer,
        shopSettings: shopSettings,
      );

      // Get documents directory
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'Invoice_${invoice.invoiceNumber}.pdf';
      final filePath = '${directory.path}/$fileName';

      // Save file
      final file = File(filePath);
      await file.writeAsBytes(pdfData);

      // Open PDF
      await Printing.sharePdf(bytes: pdfData, filename: fileName);

      return filePath;
    } catch (e) {
      throw Exception('Failed to save and open PDF: $e');
    }
  }

  // Build PDF header with shop information
  pw.Widget _buildHeader(ShopSettings shopSettings) {
    return pw.Container(
      padding: pw.EdgeInsets.only(bottom: 20),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey400, width: 1),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                shopSettings.shopName,
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.indigo800,
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                shopSettings.address,
                style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
              ),
              pw.Text(
                'Phone: ${shopSettings.phone}',
                style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
              ),
              if (shopSettings.email != null)
                pw.Text(
                  'Email: ${shopSettings.email}',
                  style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                ),
              if (shopSettings.gstin != null)
                pw.Text(
                  'GSTIN: ${shopSettings.gstin}',
                  style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                ),
            ],
          ),
          pw.Container(
            padding: pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.amber100,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Text(
              'INVOICE',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.amber800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build invoice information section
  pw.Widget _buildInvoiceInfo(Invoice invoice) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Invoice Number: ${invoice.invoiceNumber}',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              'Invoice Date: ${DateFormat('dd/MM/yyyy').format(invoice.invoiceDate)}',
              style: pw.TextStyle(fontSize: 12),
            ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Container(
              padding: pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: pw.BoxDecoration(
                color: _getPaymentStatusColor(invoice.paymentStatus),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Text(
                _getPaymentStatusText(invoice.paymentStatus),
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Build customer information section
  pw.Widget _buildCustomerInfo(Customer customer) {
    return pw.Container(
      padding: pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Bill To:',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.indigo800,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            customer.name,
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          if (customer.phone.isNotEmpty)
            pw.Text(
              'Phone: ${customer.phone}',
              style: pw.TextStyle(fontSize: 10),
            ),
          if (customer.email != null && customer.email!.isNotEmpty)
            pw.Text(
              'Email: ${customer.email}',
              style: pw.TextStyle(fontSize: 10),
            ),
          if (customer.address != null && customer.address!.isNotEmpty)
            pw.Text(
              'Address: ${customer.address}',
              style: pw.TextStyle(fontSize: 10),
            ),
        ],
      ),
    );
  }

  // Build items table
  pw.Widget _buildItemsTable(List<InvoiceItem> items) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: pw.FlexColumnWidth(3),
        1: pw.FlexColumnWidth(1),
        2: pw.FlexColumnWidth(1),
        3: pw.FlexColumnWidth(1),
        4: pw.FlexColumnWidth(1),
        5: pw.FlexColumnWidth(1.5),
        6: pw.FlexColumnWidth(1.5),
      },
      children: [
        // Header row
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _buildTableCell('Item Name', isHeader: true),
            _buildTableCell('Type', isHeader: true),
            _buildTableCell('Weight (g)', isHeader: true),
            _buildTableCell('Purity', isHeader: true),
            _buildTableCell('Rate/g', isHeader: true),
            _buildTableCell('Making', isHeader: true),
            _buildTableCell('Total', isHeader: true),
          ],
        ),
        // Data rows
        ...items.map(
          (item) => pw.TableRow(
            children: [
              _buildTableCell(item.itemName),
              _buildTableCell(
                item.itemType.toString().split('.').last.toUpperCase(),
              ),
              _buildTableCell(item.weight.toStringAsFixed(3)),
              _buildTableCell(item.purity),
              _buildTableCell(
                'Rs.${NumberFormat('#,##,###.00').format(item.currentRate)}',
              ),
              _buildTableCell(
                'Rs.${NumberFormat('#,##,###.00').format(item.makingCharges)}',
              ),
              _buildTableCell(
                'Rs.${NumberFormat('#,##,###.00').format(item.itemTotal)}',
                isBold: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Build table cell
  pw.Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    bool isBold = false,
  }) {
    return pw.Container(
      padding: pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 9,
          fontWeight: (isHeader || isBold)
              ? pw.FontWeight.bold
              : pw.FontWeight.normal,
          color: isHeader ? PdfColors.indigo800 : PdfColors.black,
        ),
        textAlign: isHeader ? pw.TextAlign.center : pw.TextAlign.left,
      ),
    );
  }

  // Build total section
  pw.Widget _buildTotalSection(Invoice invoice) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Container(
          width: 200,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              _buildTotalRow('Subtotal:', invoice.subtotal),
              if (invoice.discountAmount > 0)
                _buildTotalRow('Discount:', -invoice.discountAmount),
              // Tax section removed
              pw.Container(
                padding: pw.EdgeInsets.symmetric(vertical: 8),
                decoration: pw.BoxDecoration(
                  border: pw.Border(
                    top: pw.BorderSide(color: PdfColors.grey400, width: 1),
                  ),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Total Amount:',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.indigo800,
                      ),
                    ),
                    pw.Text(
                      'Rs.${NumberFormat('#,##,###.00').format(invoice.totalAmount)}',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.green800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Build total row
  pw.Widget _buildTotalRow(String label, double amount) {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 12)),
          pw.Text(
            'Rs.${NumberFormat('#,##,###.00').format(amount)}',
            style: pw.TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  // Build footer
  pw.Widget _buildFooter() {
    return pw.Container(
      padding: pw.EdgeInsets.only(top: 20),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey400, width: 1),
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Thank you for your business!',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.indigo800,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'Terms & Conditions:',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            '- All items are sold as per current market rates',
            style: pw.TextStyle(fontSize: 9),
          ),
          pw.Text(
            '- Making charges are non-refundable',
            style: pw.TextStyle(fontSize: 9),
          ),
          pw.Text(
            '- Goods once sold can be returned within 7 days from the date of purchase',
            style: pw.TextStyle(fontSize: 9),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Generated on: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
              ),
              pw.Text(
                'Authorized Signature',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Get payment status color
  PdfColor _getPaymentStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return PdfColors.green600;
      case PaymentStatus.pending:
        return PdfColors.orange600;
      case PaymentStatus.partial:
        return PdfColors.blue600;
      case PaymentStatus.cancelled:
        return PdfColors.red600;
    }
  }

  // Get payment status text
  String _getPaymentStatusText(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return 'PAID';
      case PaymentStatus.pending:
        return 'PENDING';
      case PaymentStatus.partial:
        return 'PARTIAL';
      case PaymentStatus.cancelled:
        return 'CANCELLED';
    }
  }
}
