import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/expense_provider.dart';
import 'screens/home_screen.dart';
import 'screens/add_expense_screen.dart';
import 'screens/all_expenses_screen.dart';
import 'screens/monthly_summary_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ExpenseProvider(),
      child: MaterialApp(
        title: 'Expense Tracker',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          cardTheme: const CardTheme(
            elevation: 2,
            margin: EdgeInsets.symmetric(vertical: 4),
          ),
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
            // backgroundColor: Colors.transparent,
            // foregroundColor: Colors.white,
          ),
        ),
        home: const HomeScreen(),
        routes: {
          '/add-expense': (context) => const AddExpenseScreen(),
          '/all-expenses': (context) => const AllExpensesScreen(),
          '/monthly-summary': (context) => const MonthlySummaryScreen(),
          '/settings': (context) => const SettingsScreen(),
        },
      ),
    );
  }
}
