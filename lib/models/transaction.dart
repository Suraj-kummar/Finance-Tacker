import 'dart:convert';

class Transaction {
  final int? id;
  final String name;
  final double amount;
  final bool isIncome;
  final String category;
  final DateTime date;
  
  // Group related fields
  final int? groupId;
  final String? paidBy;
  final Map<String, dynamic>? split;
  
  // New fields
  final String? receiptPath;
  final bool isSettlement;

  const Transaction({
    this.id,
    required this.name,
    required this.amount,
    required this.isIncome,
    required this.category,
    required this.date,
    this.groupId,
    this.paidBy,
    this.split,
    this.receiptPath,
    this.isSettlement = false,
  });

  Transaction copyWith({
    int? id,
    String? name,
    double? amount,
    bool? isIncome,
    String? category,
    DateTime? date,
    int? groupId,
    String? paidBy,
    Map<String, dynamic>? split,
    String? receiptPath,
    bool? isSettlement,
  }) {
    return Transaction(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      isIncome: isIncome ?? this.isIncome,
      category: category ?? this.category,
      date: date ?? this.date,
      groupId: groupId ?? this.groupId,
      paidBy: paidBy ?? this.paidBy,
      split: split ?? this.split,
      receiptPath: receiptPath ?? this.receiptPath,
      isSettlement: isSettlement ?? this.isSettlement,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'isIncome': isIncome ? 1 : 0,
      'category': category,
      'date': date.toIso8601String(),
      'groupId': groupId,
      'paidBy': paidBy,
      'receiptPath': receiptPath,
      'isSettlement': isSettlement ? 1 : 0,
       // split handled by DBHelper
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      name: map['name'],
      amount: map['amount'],
      isIncome: (map['isIncome'] is int) ? (map['isIncome'] == 1) : (map['isIncome'] as bool),
      category: map['category'],
      date: DateTime.parse(map['date']),
      groupId: map['groupId'],
      paidBy: map['paidBy'],
      split: map['split'] != null 
          ? (map['split'] is String 
              ? Map<String, dynamic>.from(jsonDecode(map['split']))
              : Map<String, dynamic>.from(map['split']))
          : null,
      receiptPath: map['receiptPath'],
      isSettlement: map['isSettlement'] != null 
          ? ((map['isSettlement'] is int) ? (map['isSettlement'] == 1) : (map['isSettlement'] as bool))
          : false,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is Transaction &&
      other.id == id &&
      other.name == name &&
      other.amount == amount &&
      other.isIncome == isIncome &&
      other.category == category &&
      other.date == date &&
      other.groupId == groupId &&
      other.paidBy == paidBy &&
      other.receiptPath == receiptPath &&
      other.isSettlement == isSettlement;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      name.hashCode ^
      amount.hashCode ^
      isIncome.hashCode ^
      category.hashCode ^
      date.hashCode ^
      groupId.hashCode ^
      paidBy.hashCode ^
      receiptPath.hashCode ^
      isSettlement.hashCode;
  }

  @override
  String toString() {
    return 'Transaction(id: $id, name: $name, amount: $amount, isIncome: $isIncome, category: $category, date: $date, groupId: $groupId, paidBy: $paidBy, receiptPath: $receiptPath, isSettlement: $isSettlement)';
  }
}
