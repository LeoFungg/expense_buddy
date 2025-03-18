import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:local_auth/local_auth.dart';
import '../providers/expense_provider.dart';
import '../models/expense_category.dart';
import '../widgets/gradient_background.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final LocalAuthentication _auth = LocalAuthentication();
  bool _isAuthenticated = false;
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check biometric after dependencies are ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isAuthenticated && !_isAuthenticating) {
        _authenticateWithBiometric();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      setState(() {
        _isAuthenticated = false;
      });
    } else if (state == AppLifecycleState.resumed) {
      if (!_isAuthenticated && !_isAuthenticating) {
        _authenticateWithBiometric();
      }
    }
  }

  Future<void> _authenticateWithBiometric() async {
    if (_isAuthenticating || _isAuthenticated) return;

    final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
    if (!expenseProvider.biometricEnabled) {
      setState(() => _isAuthenticated = true);
      return;
    }
    
    try {
      _isAuthenticating = true;
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      
      if (!canAuthenticate) {
        if (mounted) {
          setState(() => _isAuthenticated = true);
        }
        return;
      }

      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: 'Please authenticate to access the app',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      
      if (mounted) {
        setState(() => _isAuthenticated = didAuthenticate);
      }
    } on PlatformException catch (e) {
      print('Error during authentication: ${e.message}');
      if (mounted) {
        setState(() => _isAuthenticated = false);
      }
    } finally {
      _isAuthenticating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: !_isAuthenticated ? _buildLockScreen() : _buildHomeScreen(),
    );
  }

  Widget _buildLockScreen() {
    return Scaffold(
      body: GradientBackground(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock_outline,
                size: 64,
                color: Colors.white,
              ),
              const SizedBox(height: 16),
              const Text(
                'App Locked',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please authenticate to continue',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _authenticateWithBiometric,
                child: const Text('Authenticate'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeScreen() {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Expense Tracker',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings, color: Colors.white),
                      onPressed: () => Navigator.pushNamed(
                        context,
                        '/settings',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Total Spending Card
                Consumer<ExpenseProvider>(
                  builder: (context, expenseProvider, child) {
                    return Card(
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
                              '\$${expenseProvider.totalSpentThisMonth.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: expenseProvider.totalSpentThisMonth /
                                  expenseProvider.monthlyBudget,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                expenseProvider.totalSpentThisMonth >
                                        expenseProvider.monthlyBudget
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
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Quick Actions
                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 16.0),
                        child: _buildQuickActionButton(
                          context,
                          icon: Icons.add,
                          label: 'Add Expense',
                          onPressed: () => Navigator.pushNamed(
                            context,
                            '/add-expense',
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 16.0),
                        child: _buildQuickActionButton(
                          context,
                          icon: Icons.list,
                          label: 'All Expenses',
                          onPressed: () => Navigator.pushNamed(
                            context,
                            '/all-expenses',
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 16.0),
                        child: _buildQuickActionButton(
                          context,
                          icon: Icons.pie_chart,
                          label: 'Monthly Summary',
                          onPressed: () => Navigator.pushNamed(
                            context,
                            '/monthly-summary',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: Consumer<ExpenseProvider>(
                    builder: (context, expenseProvider, child) {
                      final recentExpenses = expenseProvider.recentExpenses;
                      if (recentExpenses.isEmpty) {
                        return const Center(
                          child: Text(
                            'No expenses yet',
                            style: TextStyle(color: Colors.white),
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: recentExpenses.length,
                        itemBuilder: (context, index) {
                          final expense = recentExpenses[index];
                          final category = ExpenseCategory.defaultCategories
                              .firstWhere(
                                (cat) => cat.id == expense.category,
                                orElse: () => ExpenseCategory.defaultCategories.last,
                              );

                          return Card(
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
                                '${category.name} • ${expense.date.day}/${expense.date.month}/${expense.date.year}',
                              ),
                              trailing: Text(
                                '\$${expense.amount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
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
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(BuildContext context, {required IconData icon, required String label, required VoidCallback onPressed}) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
    );
  }
} 