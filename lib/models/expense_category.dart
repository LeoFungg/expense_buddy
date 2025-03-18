import 'package:flutter/material.dart';

class ExpenseCategory {
  final String id;
  final String name;
  final IconData icon;
  final Color color;

  const ExpenseCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });

  static List<ExpenseCategory> defaultCategories = [
    ExpenseCategory(
      id: 'food',
      name: 'Food',
      icon: Icons.restaurant,
      color: Colors.orange,
    ),
    ExpenseCategory(
      id: 'transport',
      name: 'Transport',
      icon: Icons.directions_car,
      color: Colors.blue,
    ),
    ExpenseCategory(
      id: 'shopping',
      name: 'Shopping',
      icon: Icons.shopping_bag,
      color: Colors.purple,
    ),
    ExpenseCategory(
      id: 'utilities',
      name: 'Utilities',
      icon: Icons.lightbulb,
      color: Colors.yellow,
    ),
    ExpenseCategory(
      id: 'entertainment',
      name: 'Entertainment',
      icon: Icons.movie,
      color: Colors.red,
    ),
    ExpenseCategory(
      id: 'health',
      name: 'Health',
      icon: Icons.medical_services,
      color: Colors.green,
    ),
    ExpenseCategory(
      id: 'other',
      name: 'Other',
      icon: Icons.more_horiz,
      color: Colors.grey,
    ),
  ];
} 