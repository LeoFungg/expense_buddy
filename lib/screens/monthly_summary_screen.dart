import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fl_chart/src/chart/pie_chart/pie_chart_data.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../models/expense_category.dart';
import '../providers/expense_provider.dart';
import '../widgets/gradient_background.dart';
import '../services/pdf_service.dart';

class MonthlySummaryScreen extends StatefulWidget {
  const MonthlySummaryScreen({super.key});

  @override
  State<MonthlySummaryScreen> createState() => _MonthlySummaryScreenState();
}

class _MonthlySummaryScreenState extends State<MonthlySummaryScreen> {
  int touchedIndex = -1;

  Future<void> _exportToExcel(BuildContext context) async {
    final expenseProvider = context.read<ExpenseProvider>();
    final now = DateTime.now();
    final monthlyExpenses = expenseProvider.expenses
        .where((expense) =>
            expense.date.year == now.year &&
            expense.date.month == now.month)
        .toList();

    if (monthlyExpenses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No expenses to export for this month'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final filePath = await PDFService.exportToPDF(
        month: now,
        expenses: monthlyExpenses,
        categories: expenseProvider.allCategories,
      );

      if (filePath != null) {
        await PDFService.pickAndSaveFile(filePath);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Expenses exported successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting expenses: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Monthly Summary'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.file_download),
              onPressed: () => _exportToExcel(context),
              tooltip: 'Export to Excel',
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => _showBudgetSettings(context),
            ),
          ],
        ),
        body: GradientBackground(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Consumer<ExpenseProvider>(
              builder: (context, expenseProvider, child) {
                final monthlyExpenses = expenseProvider.expenses
                    .where((expense) =>
                        expense.date.year == DateTime.now().year &&
                        expense.date.month == DateTime.now().month)
                    .toList();

                if (monthlyExpenses.isEmpty) {
                  return const Center(
                    child: Text(
                      'No expenses for this month',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }

                // Calculate category totals
                final Map<String, double> categoryTotals = {};
                double totalSpent = 0;

                for (var expense in monthlyExpenses) {
                  categoryTotals[expense.category] =
                      (categoryTotals[expense.category] ?? 0) + expense.amount;
                  totalSpent += expense.amount;
                }

                // Create pie chart sections
                final List<PieChartSectionData> sections = [];

                categoryTotals.forEach((categoryId, amount) {
                  final category = ExpenseCategory.defaultCategories
                      .firstWhere((cat) => cat.id == categoryId);
                  final percentage = (amount / totalSpent) * 100;

                  sections.add(
                    PieChartSectionData(
                      color: category.color,
                      value: amount,
                      title: touchedIndex == sections.length
                          ? '${percentage.toStringAsFixed(1)}%'
                          : '',
                      radius: touchedIndex == sections.length ? 110 : 100,
                      titleStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  );
                });

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Total Spending Card
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Spending This Month',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '\$${totalSpent.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: totalSpent / expenseProvider.monthlyBudget,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                totalSpent > expenseProvider.monthlyBudget
                                    ? Colors.red
                                    : Colors.green,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Budget: \$${expenseProvider.monthlyBudget.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Pie Chart
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Spending by Category',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 300,
                              child: PieChart(
                                PieChartData(
                                  sections: sections,
                                  sectionsSpace: 2,
                                  centerSpaceRadius: 40,
                                  pieTouchData: PieTouchData(
                                    touchCallback: (event, response) {
                                      if (response == null || response.touchedSection == null) {
                                        return;
                                      }
                                      touchedIndex = response.touchedSection!.touchedSectionIndex;
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Category Breakdown
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Category Breakdown',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ...categoryTotals.entries.map((entry) {
                              final category = ExpenseCategory.defaultCategories
                                  .firstWhere((cat) => cat.id == entry.key);
                              final percentage =
                                  (entry.value / totalSpent) * 100;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: category.color,
                                      child: Icon(
                                        category.icon,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            category.name,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Text(
                                            '${percentage.toStringAsFixed(1)}% of total',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '\$${entry.value.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _showBudgetSettings(BuildContext context) {
    final controller = TextEditingController(
      text: context.read<ExpenseProvider>().monthlyBudget.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Monthly Budget'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Monthly Budget',
            prefixText: '\$',
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final budget = double.tryParse(controller.text);
              if (budget != null) {
                context.read<ExpenseProvider>().setMonthlyBudget(budget);
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
} 