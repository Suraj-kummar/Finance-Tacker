class ImportedTransaction {
  final int? id;
  final DateTime date;
  final String personName;
  final String upiId;
  final double amount;
  final String type; // 'CREDIT' or 'DEBIT'
  final String category;
  final String note;
  final String sourceBank;
  final bool isEditable;

  ImportedTransaction({
    this.id,
    required this.date,
    required this.personName,
    required this.upiId,
    required this.amount,
    required this.type,
    this.category = 'Uncategorized',
    this.note = '',
    required this.sourceBank,
    this.isEditable = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'personName': personName,
      'upiId': upiId,
      'amount': amount,
      'type': type,
      'category': category,
      'note': note,
      'sourceBank': sourceBank,
      'isEditable': isEditable ? 1 : 0,
    };
  }

  factory ImportedTransaction.fromMap(Map<String, dynamic> map) {
    return ImportedTransaction(
      id: map['id'],
      date: DateTime.parse(map['date']),
      personName: map['personName'],
      upiId: map['upiId'] ?? '',
      amount: map['amount'],
      type: map['type'],
      category: map['category'] ?? 'Uncategorized',
      note: map['note'] ?? '',
      sourceBank: map['sourceBank'] ?? 'Unknown',
      isEditable: (map['isEditable'] ?? 1) == 1,
    );
  }
}
