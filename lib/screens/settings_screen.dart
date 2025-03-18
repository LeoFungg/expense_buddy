import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:local_auth/local_auth.dart';
import '../providers/expense_provider.dart';
import '../models/expense_category.dart';
import '../widgets/gradient_background.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<bool> _checkBiometricAvailability() async {
    final LocalAuthentication auth = LocalAuthentication();
    try {
      final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await auth.isDeviceSupported();
      return canAuthenticate;
    } on PlatformException catch (_) {
      return false;
    }
  }

  Future<void> _authenticateWithBiometrics(BuildContext context) async {
    final LocalAuthentication auth = LocalAuthentication();
    try {
      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Please authenticate to enable biometric login',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      if (didAuthenticate) {
        context.read<ExpenseProvider>().setBiometricEnabled(true);
      }
    } on PlatformException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.message}'),
          backgroundColor: Colors.red,
        ),
      );
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
          title: const Text('Settings'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: GradientBackground(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Consumer<ExpenseProvider>(
              builder: (context, expenseProvider, child) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Budget Settings
                    _buildSection(
                      title: 'Budget Settings',
                      child: Column(
                        children: [
                          ListTile(
                            title: const Text('Monthly Budget'),
                            subtitle: Text(
                              '\$${expenseProvider.monthlyBudget.toStringAsFixed(2)}',
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showBudgetDialog(context, expenseProvider),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Category Management
                    _buildSection(
                      title: 'Category Management',
                      child: Column(
                        children: [
                          ListTile(
                            title: const Text('Custom Categories'),
                            subtitle: const Text('Add or remove expense categories'),
                            trailing: IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () => _showAddCategoryDialog(context, expenseProvider),
                            ),
                          ),
                          const Divider(),
                          ...ExpenseCategory.defaultCategories.map((category) {
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: category.color,
                                child: Icon(category.icon, color: Colors.white),
                              ),
                              title: Text(category.name),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _showDeleteCategoryDialog(
                                  context,
                                  expenseProvider,
                                  category,
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Currency Settings
                    _buildSection(
                      title: 'Currency Settings',
                      child: ListTile(
                        title: const Text('Default Currency'),
                        subtitle: Text(expenseProvider.currency),
                        trailing: DropdownButton<String>(
                          value: expenseProvider.currency,
                          items: const [
                            DropdownMenuItem(value: 'HKD', child: Text('HKD')),
                            DropdownMenuItem(value: 'USD', child: Text('USD')),
                            DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                            DropdownMenuItem(value: 'GBP', child: Text('GBP')),
                            DropdownMenuItem(value: 'JPY', child: Text('JPY')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              expenseProvider.setCurrency(value);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Notification Settings
                    _buildSection(
                      title: 'Notification Settings',
                      child: ListTile(
                        title: const Text('Overspending Alerts'),
                        subtitle: const Text('Get notified when you exceed your budget'),
                        trailing: Switch(
                          value: true, // TODO: Implement notification state
                          onChanged: (value) {
                            // TODO: Implement notification toggle
                          },
                        ),
                      ),
                    ),

                    // Security Settings
                    _buildSection(
                      title: 'Security',
                      child: Column(
                        children: [
                          FutureBuilder<bool>(
                            future: _checkBiometricAvailability(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }
                              
                              final bool canUseBiometrics = snapshot.data ?? false;
                              if (!canUseBiometrics) {
                                return const ListTile(
                                  title: Text('Biometric Authentication'),
                                  subtitle: Text('Biometric authentication is not available on this device'),
                                  enabled: false,
                                );
                              }

                              return ListTile(
                                title: const Text('Biometric Authentication'),
                                subtitle: const Text('Use fingerprint or face ID to secure the app'),
                                trailing: Switch(
                                  value: expenseProvider.biometricEnabled,
                                  onChanged: (value) async {
                                    if (value) {
                                      await _authenticateWithBiometrics(context);
                                    } else {
                                      expenseProvider.setBiometricEnabled(false);
                                    }
                                  },
                                ),
                              );
                            },
                          ),
                        ],
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

  Widget _buildSection({
    required String title,
    required Widget child,
  }) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  void _showBudgetDialog(BuildContext context, ExpenseProvider provider) {
    final controller = TextEditingController(
      text: provider.monthlyBudget.toString(),
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
                provider.setMonthlyBudget(budget);
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context, ExpenseProvider provider) {
    final nameController = TextEditingController();
    final colorController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Category Name',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: colorController,
              decoration: const InputDecoration(
                labelText: 'Color (hex)',
                hintText: '#FF0000',
              ),
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
              // TODO: Implement category addition
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showDeleteCategoryDialog(
    BuildContext context,
    ExpenseProvider provider,
    ExpenseCategory category,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              // TODO: Implement category deletion
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
} 