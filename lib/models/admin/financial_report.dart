import 'package:intl/intl.dart';

class DailyRevenue {
  final DateTime date;
  final double amount;

  DailyRevenue({required this.date, required this.amount});
}

class FinancialReport {
  final double totalRevenue;
  final double platformFees;
  final double driverPayouts;
  final List<FinancialTransaction> transactions;
  final DateTime startDate;
  final DateTime endDate;
  
  // Getter para receitas diárias
  List<DailyRevenue> get dailyRevenues {
    // Agrupa transações de crédito por dia
    final Map<String, double> dailyRevenueMap = {};
    
    for (var transaction in transactions) {
      if (transaction.type == 'credit') {
        final dateKey = DateFormat('yyyy-MM-dd').format(transaction.date);
        dailyRevenueMap[dateKey] = 
          (dailyRevenueMap[dateKey] ?? 0) + transaction.amount;
      }
    }
    
    return dailyRevenueMap.entries.map((entry) {
      return DailyRevenue(
        date: DateTime.parse(entry.key),
        amount: entry.value
      );
    }).toList()
    // Ordena por data para manter a consistência
    ..sort((a, b) => a.date.compareTo(b.date));
  }
  
  FinancialReport({
    required this.totalRevenue,
    required this.platformFees,
    required this.driverPayouts,
    required this.transactions,
    required this.startDate,
    required this.endDate,
  });
  
  factory FinancialReport.fromJson(Map<String, dynamic> json) {
    return FinancialReport(
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
      platformFees: (json['platformFees'] ?? 0).toDouble(),
      driverPayouts: (json['driverPayouts'] ?? 0).toDouble(),
      transactions: (json['transactions'] as List? ?? [])
          .map((transactionJson) => FinancialTransaction.fromJson(transactionJson))
          .toList(),
      startDate: DateTime.fromMillisecondsSinceEpoch(json['startDate'] ?? 0),
      endDate: DateTime.fromMillisecondsSinceEpoch(json['endDate'] ?? 0),
    );
  }
}

class FinancialTransaction {
  final String id;
  final String type; // 'credit' ou 'debit'
  final double amount;
  final String description;
  final DateTime date;
  final String? rideId;
  final String? userId;
  
  FinancialTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.date,
    this.rideId,
    this.userId,
  });
  
  factory FinancialTransaction.fromJson(Map<String, dynamic> json) {
    return FinancialTransaction(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      description: json['description'] ?? '',
      date: DateTime.fromMillisecondsSinceEpoch(json['date'] ?? 0),
      rideId: json['rideId'],
      userId: json['userId'],
    );
  }
}