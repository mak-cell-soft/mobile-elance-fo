import 'chantier_caisse_transaction.dart';

/// Aggregated caisse summary metrics for a specific Chantier.
/// Matches `ChantierCaisseSummary` in fo-acya-app/elance-app.ui.
class ChantierCaisseSummary {
  final int chantierId;
  final double currentBalance;
  final double totalAlimentations;
  final double totalSorties;
  final int pendingRequestsCount;
  final double pendingRequestsAmount;
  final DateTime? lastMovementDate;
  final List<ChantierCaisseTransaction> recentTransactions;

  ChantierCaisseSummary({
    required this.chantierId,
    required this.currentBalance,
    required this.totalAlimentations,
    required this.totalSorties,
    this.pendingRequestsCount = 0,
    this.pendingRequestsAmount = 0.0,
    this.lastMovementDate,
    this.recentTransactions = const [],
  });

  factory ChantierCaisseSummary.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    double parseDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    List<ChantierCaisseTransaction> parseTxs(dynamic list) {
      if (list is List) {
        return list
            .map((e) => ChantierCaisseTransaction.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    }

    return ChantierCaisseSummary(
      chantierId: parseInt(json['chantierId']),
      currentBalance: parseDouble(json['currentBalance']),
      totalAlimentations: parseDouble(json['totalAlimentations']),
      totalSorties: parseDouble(json['totalSorties']),
      pendingRequestsCount: parseInt(json['pendingRequestsCount']),
      pendingRequestsAmount: parseDouble(json['pendingRequestsAmount']),
      lastMovementDate: json['lastMovementDate'] != null
          ? DateTime.tryParse(json['lastMovementDate'].toString())
          : null,
      recentTransactions: parseTxs(json['recentTransactions']),
    );
  }
}
