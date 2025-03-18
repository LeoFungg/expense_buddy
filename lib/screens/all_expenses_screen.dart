import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../models/expense_category.dart';
import '../providers/expense_provider.dart';
import '../widgets/gradient_background.dart';
import 'add_expense_screen.dart';

class AllExpensesScreen extends StatefulWidget {
  const AllExpensesScreen({super.key});

  @override
  State<AllExpensesScreen> createState() => _AllExpensesScreenState();
}

class _AllExpensesScreenState extends State<AllExpensesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCategory;
  DateTimeRange? _selectedDateRange;
  double? _minAmount;
  double? _maxAmount;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
    );
    if (picked != null && picked != _selectedDateRange) {
      setState(() {
        _selectedDateRange = picked;
      });
      Provider.of<ExpenseProvider>(context, listen: false)
          .setDateRange(picked);
    }
  }

  void _showAmountRangeDialog(BuildContext context) {
    final minController = TextEditingController(
      text: _minAmount?.toString() ?? '',
    );
    final maxController = TextEditingController(
      text: _maxAmount?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Amount Range'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: minController,
              decoration: const InputDecoration(
                labelText: 'Minimum Amount',
                prefixText: '\$',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: maxController,
              decoration: const InputDecoration(
                labelText: 'Maximum Amount',
                prefixText: '\$',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final min = double.tryParse(minController.text);
              final max = double.tryParse(maxController.text);
              setState(() {
                _minAmount = min;
                _maxAmount = max;
              });
              Provider.of<ExpenseProvider>(context, listen: false)
                  .setAmountRange(min, max);
              Navigator.pop(context);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Expense expense) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense'),
        content: Text('Are you sure you want to delete this expense?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Provider.of<ExpenseProvider>(context, listen: false)
                  .deleteExpense(expense.id);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showSortOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Consumer<ExpenseProvider>(
        builder: (context, provider, child) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('Date (Newest First)'),
                  leading: const Icon(Icons.calendar_today),
                  trailing: provider.sortOption == SortOption.dateNewest
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () {
                    provider.setSortOption(SortOption.dateNewest);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: const Text('Date (Oldest First)'),
                  leading: const Icon(Icons.calendar_today),
                  trailing: provider.sortOption == SortOption.dateOldest
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () {
                    provider.setSortOption(SortOption.dateOldest);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: const Text('Amount (High to Low)'),
                  leading: const Icon(Icons.arrow_downward),
                  trailing: provider.sortOption == SortOption.amountHigh
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () {
                    provider.setSortOption(SortOption.amountHigh);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: const Text('Amount (Low to High)'),
                  leading: const Icon(Icons.arrow_upward),
                  trailing: provider.sortOption == SortOption.amountLow
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () {
                    provider.setSortOption(SortOption.amountLow);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: const Text('Category'),
                  leading: const Icon(Icons.category),
                  trailing: provider.sortOption == SortOption.category
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () {
                    provider.setSortOption(SortOption.category);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
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
          title: const Text('All Expenses'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.sort),
              onPressed: () => _showSortOptions(context),
            ),
          ],
        ),
        body: GradientBackground(
          child: Column(
            children: [
              // Search and Filter Bar
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search expenses...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        Provider.of<ExpenseProvider>(context, listen: false)
                            .setSearchQuery(value);
                      },
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          // Category Filter
                          FilterChip(
                            label: Text(_selectedCategory == null
                                ? 'All Categories'
                                : ExpenseCategory.defaultCategories
                                    .firstWhere((cat) => cat.id == _selectedCategory)
                                    .name),
                            selected: _selectedCategory != null,
                            onSelected: (selected) {
                              if (!selected) {
                                setState(() {
                                  _selectedCategory = null;
                                });
                                Provider.of<ExpenseProvider>(context, listen: false)
                                    .setSelectedCategory(null);
                              }
                            },
                            avatar: _selectedCategory != null
                                ? Icon(
                                    ExpenseCategory.defaultCategories
                                        .firstWhere((cat) => cat.id == _selectedCategory)
                                        .icon,
                                    size: 16,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 8),
                          // Date Range Filter
                          FilterChip(
                            label: Text(_selectedDateRange == null
                                ? 'Date Range'
                                : '${DateFormat('MMM d').format(_selectedDateRange!.start)} - ${DateFormat('MMM d').format(_selectedDateRange!.end)}'),
                            selected: _selectedDateRange != null,
                            onSelected: (selected) {
                              if (!selected) {
                                setState(() {
                                  _selectedDateRange = null;
                                });
                                Provider.of<ExpenseProvider>(context, listen: false)
                                    .setDateRange(null);
                              } else {
                                _selectDateRange(context);
                              }
                            },
                            avatar: const Icon(Icons.calendar_today, size: 16),
                          ),
                          const SizedBox(width: 8),
                          // Amount Range Filter
                          FilterChip(
                            label: Text(_minAmount == null && _maxAmount == null
                                ? 'Amount Range'
                                : '${_minAmount ?? 0} - ${_maxAmount ?? '∞'}'),
                            selected: _minAmount != null || _maxAmount != null,
                            onSelected: (selected) {
                              if (!selected) {
                                setState(() {
                                  _minAmount = null;
                                  _maxAmount = null;
                                });
                                Provider.of<ExpenseProvider>(context, listen: false)
                                    .setAmountRange(null, null);
                              } else {
                                _showAmountRangeDialog(context);
                              }
                            },
                            avatar: const Icon(Icons.attach_money, size: 16),
                          ),
                          const SizedBox(width: 8),
                          // Clear Filters
                          FilterChip(
                            label: const Text('Clear All'),
                            selected: false,
                            onSelected: (selected) {
                              setState(() {
                                _selectedCategory = null;
                                _selectedDateRange = null;
                                _minAmount = null;
                                _maxAmount = null;
                                _searchController.clear();
                              });
                              Provider.of<ExpenseProvider>(context, listen: false)
                                  .clearFilters();
                            },
                            avatar: const Icon(Icons.clear, size: 16),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Expenses List
              Expanded(
                child: Consumer<ExpenseProvider>(
                  builder: (context, expenseProvider, child) {
                    final expenses = expenseProvider.expenses;
                    if (expenses.isEmpty) {
                      return const Center(
                        child: Text('No expenses found'),
                      );
                    }

                    return ListView.builder(
                      itemCount: expenses.length,
                      itemBuilder: (context, index) {
                        final expense = expenses[index];
                        final category = ExpenseCategory.defaultCategories
                            .firstWhere(
                              (cat) => cat.id == expense.category,
                              orElse: () => ExpenseCategory.defaultCategories.last,
                            );

                        return Dismissible(
                          key: Key(expense.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 16),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          onDismissed: (direction) {
                            _showDeleteConfirmation(context, expense);
                          },
                          child: Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: category.color,
                                child: Icon(
                                  category.icon,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(expense.description),
                              subtitle: Text(
                                DateFormat('MMM d, y').format(expense.date),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '\$${expense.amount.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => AddExpenseScreen(
                                            expense: expense,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddExpenseScreen(),
              ),
            );
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
} 