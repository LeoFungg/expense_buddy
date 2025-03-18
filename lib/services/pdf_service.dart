import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart' as share;
import '../models/expense.dart';
import '../models/expense_category.dart';
import 'package:intl/intl.dart';

class PDFService {
  static Future<String?> exportToPDF({
    required DateTime month,
    required List<Expense> expenses,
    required List<ExpenseCategory> categories,
  }) async {
    final pdf = pw.Document();

    // Add page with table
    pdf.addPage(
      pw.Page(
        build: (context) {
          // Calculate total
          double total = 0;
          for (var expense in expenses) {
            total += expense.amount;
          }

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Title
              pw.Text(
                'Monthly Expenses - ${DateFormat('MMMM yyyy').format(month)}',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),

              // Table
              pw.Table.fromTextArray(
                headers: ['Date', 'Description', 'Category', 'Amount'],
                data: expenses.map((expense) {
                  final category = categories.firstWhere(
                    (cat) => cat.id == expense.category,
                    orElse: () => categories.last,
                  );
                  return [
                    DateFormat('MM/dd/yyyy').format(expense.date),
                    expense.description,
                    category.name,
                    '\$${expense.amount.toStringAsFixed(2)}',
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headerDecoration: pw.BoxDecoration(
                  color: PdfColors.grey300,
                ),
                cellHeight: 30,
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.centerLeft,
                  3: pw.Alignment.centerRight,
                },
              ),
              pw.SizedBox(height: 20),

              // Total
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text(
                    'Total: \$${total.toStringAsFixed(2)}',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    try {
      // Get the documents directory
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'expenses_${DateFormat('yyyy_MM').format(month)}.pdf';
      final filePath = '${directory.path}/$fileName';
      
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());
      return filePath;
    } catch (e) {
      print('Error saving PDF file: $e');
      return null;
    }
  }

  static Future<void> pickAndSaveFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        final fileName = filePath.split('/').last;
        await share.Share.shareXFiles(
          [share.XFile.fromData(bytes, name: fileName)],
          subject: 'Monthly Expenses Report',
        );
      }
    } catch (e) {
      print('Error sharing file: $e');
      throw Exception('Failed to share file: $e');
    }
  }
} 