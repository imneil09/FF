import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/company_model.dart';
import '../models/transaction_model.dart';
import '../models/product_model.dart';

class PdfService {
  static Future<void> generateInvoice(Company company, AppTransaction tx, Product product) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.nunitoRegular();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: font),
        build: (pw.Context context) {
          return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Text(company.name, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.Text("Tripura (Code 16)"),
                pw.Text(company.address),
                pw.Text("GSTIN: ${company.gstin}"),
                pw.Divider(),

                // Bill Details
                pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text("Bill To: ${tx.partyName ?? 'Cash Customer'}"),
                      pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                        pw.Text("Invoice #: ${tx.id}"),
                        pw.Text("Date: ${DateFormat('dd-MM-yyyy').format(tx.date)}"),
                      ])
                    ]
                ),
                pw.SizedBox(height: 20),

                // Table
                pw.Table.fromTextArray(
                    headers: ['Product', 'HSN', 'Qty', 'Rate', 'Total'],
                    data: [
                      [product.name, product.hsn, tx.quantity, (tx.amount / tx.quantity!).toStringAsFixed(2), tx.amount.toStringAsFixed(2)]
                    ]
                ),

                pw.Spacer(),
                pw.Divider(),
                pw.Align(
                    alignment: pw.Alignment.centerRight,
                    child: pw.Text("Grand Total: ₹ ${tx.amount.toStringAsFixed(2)}", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold))
                ),
              ]
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }
}