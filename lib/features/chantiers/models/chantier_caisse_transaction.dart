import 'package:flutter/material.dart';

/// Chantier Caisse Transaction model representing cash fund injections (Alimentation)
/// and cash disbursements / expense requests (Sortie).
/// Matches `ChantierCaisseTransaction` in fo-acya-app/elance-app.ui.
class ChantierCaisseTransaction {
  final int id;
  final String? guid;
  final int chantierId;
  final int type; // 0: Alimentation (Entrée), 1: Sortie (Décaissement)
  final String typeName;
  final int status; // 0: Completed (Validée), 1: Pending (En attente), 2: Rejected (Rejetée)
  final String statusName;
  final double amount;
  final DateTime transactionDate;
  final String reason;
  final String? reference;
  final int? beneficiaryPersonId;
  final String? beneficiaryPersonName;
  final int? createdById;
  final int? validatedById;
  final DateTime? validationDate;
  final String? notes;
  final DateTime? creationDate;

  ChantierCaisseTransaction({
    required this.id,
    this.guid,
    required this.chantierId,
    required this.type,
    required this.typeName,
    required this.status,
    required this.statusName,
    required this.amount,
    required this.transactionDate,
    required this.reason,
    this.reference,
    this.beneficiaryPersonId,
    this.beneficiaryPersonName,
    this.createdById,
    this.validatedById,
    this.validationDate,
    this.notes,
    this.creationDate,
  });

  factory ChantierCaisseTransaction.fromJson(Map<String, dynamic> json) {
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

    DateTime parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      return DateTime.tryParse(v.toString()) ?? DateTime.now();
    }

    final rawType = parseInt(json['type']);
    final rawStatus = parseInt(json['status']);

    return ChantierCaisseTransaction(
      id: parseInt(json['id']),
      guid: json['guid']?.toString(),
      chantierId: parseInt(json['chantierId']),
      type: rawType,
      typeName: json['typeName']?.toString() ?? (rawType == 0 ? 'Alimentation' : 'Sortie'),
      status: rawStatus,
      statusName: json['statusName']?.toString() ??
          (rawStatus == 0
              ? 'Validée'
              : rawStatus == 1
                  ? 'En attente'
                  : 'Rejetée'),
      amount: parseDouble(json['amount']),
      transactionDate: parseDate(json['transactionDate']),
      reason: json['reason']?.toString() ?? 'Opération de caisse',
      reference: json['reference']?.toString(),
      beneficiaryPersonId: json['beneficiaryPersonId'] != null ? parseInt(json['beneficiaryPersonId']) : null,
      beneficiaryPersonName: json['beneficiaryPersonName']?.toString(),
      createdById: json['createdById'] != null ? parseInt(json['createdById']) : null,
      validatedById: json['validatedById'] != null ? parseInt(json['validatedById']) : null,
      validationDate: json['validationDate'] != null ? DateTime.tryParse(json['validationDate'].toString()) : null,
      notes: json['notes']?.toString(),
      creationDate: json['creationDate'] != null ? DateTime.tryParse(json['creationDate'].toString()) : null,
    );
  }

  // --- Convenience Properties ---

  bool get isEntree => type == 0;
  bool get isSortie => type == 1;

  bool get isCompleted => status == 0;
  bool get isPending => status == 1;
  bool get isRejected => status == 2;

  Color get amountColor => isEntree ? const Color(0xFF10B981) : const Color(0xFFDC2626);

  Color get statusBadgeBgColor {
    if (isPending) return const Color(0xFFFEF3C7); // Amber-100
    if (isCompleted) return const Color(0xFFECFDF5); // Emerald-50
    return const Color(0xFFFEF2F2); // Red-50
  }

  Color get statusBadgeTextColor {
    if (isPending) return const Color(0xFFB45309); // Amber-800
    if (isCompleted) return const Color(0xFF047857); // Emerald-700
    return const Color(0xFFB91C1C); // Red-700
  }

  String get statusDisplay {
    if (isPending) return 'En attente';
    if (isCompleted) return 'Effectué';
    return 'Rejeté';
  }
}
