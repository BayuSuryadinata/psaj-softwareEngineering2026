class Transaction {
  String id;
  String title;
  double amount;
  DateTime date;
  String category;
  String type; // 'income' or 'expense'
  String description;

  Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    required this.type,
    required this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'category': category,
      'type': type,
      'description': description,
    };
  }

  static Transaction fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      date: DateTime.tryParse(json['date']) ?? DateTime.now(),
      category: json['category'] ?? '',
      type: json['type'] ?? '',
      description: json['description'] ?? '',
    );
  }
}