import 'package:uuid/uuid.dart';

class Expense {
  final String id;
  final double amount;
  final String description;
  final DateTime date;
  final String category;
  final String? iconName;

  Expense({
    String? id,
    required this.amount,
    required this.description,
    required this.date,
    required this.category,
    this.iconName,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'description': description,
      'date': date.toIso8601String(),
      'category': category,
      'iconName': iconName,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      amount: map['amount'],
      description: map['description'],
      date: DateTime.parse(map['date']),
      category: map['category'],
      iconName: map['iconName'],
    );
  }
} 