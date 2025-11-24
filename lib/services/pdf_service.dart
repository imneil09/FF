import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/company_model.dart';
import '../models/transaction_model.dart';

class PdfService {
  static Future<void> generateInvoice(Company company, AppTransaction tx) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.nunitoRegular();
    final bold = await PdfGoogleFonts.nunitoBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: font, bold: bold),
        build: (pw.Context context) {
          return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Company Header
                pw.Center(child: pw.Text(company.name, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold))),
                pw.Center(child: pw.Text(company.address)),
                pw.Center(child: pw.Text("Tripura (16) | GSTIN: ${company.gstin}")),
                pw.Divider(),

                // Invoice Info
                pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                  pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                    pw.Text("Bill To: ${tx.partyName ?? 'Cash Sale'}"),
                  ]),
                  pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                    pw.Text("Invoice #: ${tx.id}"),
                    pw.Text("Date: ${DateFormat('dd-MM-yyyy').format(tx.date)}"),
                  ])
                ]),
                pw.SizedBox(height: 20),

                // Items Table (Single Item for now based on logic)
                pw.Table.fromTextArray(
                    headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
                    headers: ['Item', 'Qty', 'Rate', 'Total'],
                    data: [
                      [
                        tx.productName ?? tx.remarks,
                        tx.quantity?.toString() ?? '-',
                        (tx.quantity != null && tx.quantity! > 0)
                            ? (tx.amount / tx.quantity!).toStringAsFixed(2)
                            : '-',
                        tx.amount.toStringAsFixed(2)
                      ]
                    ]
                ),

                pw.Spacer(),
                pw.Divider(),
                pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text("Total Amount:  Rs. ${tx.amount.toStringAsFixed(2)}", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold))),
              ]
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }
}