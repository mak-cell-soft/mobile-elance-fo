import 'package:flutter/material.dart';

/// Representation of a construction site (Chantier) in summary/list views.
/// Mirrors `ChantierListItem` in fo-acya-app/elance-app.ui/src/types/chantier.ts.
class ChantierListItem {
  final int id;
  final String? guid;
  final String? reference;
  final String name;
  final String? description;
  final String? location;
  final String? gouvernorate;
  final DateTime? startDate;
  final DateTime? plannedEndDate;
  final DateTime? actualEndDate;
  final String status; // Planned, InProgress, OnHold, Completed, Cancelled
  final String healthFlag; // Green, Orange, Red
  final double progressPct;
  final double? budgetTotal;
  final int? architectPersonId;
  final String? architectName;
  final int? projectManagerPersonId;
  final String? projectManagerName;
  final int activeTeamCount;
  final int openAlertsCount;
  final DateTime? creationDate;

  const ChantierListItem({
    required this.id,
    this.guid,
    this.reference,
    required this.name,
    this.description,
    this.location,
    this.gouvernorate,
    this.startDate,
    this.plannedEndDate,
    this.actualEndDate,
    required this.status,
    required this.healthFlag,
    required this.progressPct,
    this.budgetTotal,
    this.architectPersonId,
    this.architectName,
    this.projectManagerPersonId,
    this.projectManagerName,
    this.activeTeamCount = 0,
    this.openAlertsCount = 0,
    this.creationDate,
  });

  /// Status mapper supporting both integer codes and string values from .NET API
  static String parseStatus(dynamic value) {
    if (value is int) {
      switch (value) {
        case 0:
          return 'Planned';
        case 1:
          return 'InProgress';
        case 2:
          return 'OnHold';
        case 3:
          return 'Completed';
        case 4:
          return 'Cancelled';
        default:
          return 'Planned';
      }
    }
    return value?.toString() ?? 'Planned';
  }

  /// Flag mapper supporting both integer codes and string values from .NET API
  static String parseFlag(dynamic value) {
    if (value is int) {
      switch (value) {
        case 0:
          return 'Green';
        case 1:
          return 'Orange';
        case 2:
          return 'Red';
        default:
          return 'Green';
      }
    }
    return value?.toString() ?? 'Green';
  }

  factory ChantierListItem.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      return DateTime.tryParse(v.toString());
    }

    double parseDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    int parseInt(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    return ChantierListItem(
      id: parseInt(json['id']),
      guid: json['guid']?.toString(),
      reference: json['reference']?.toString(),
      name: json['name']?.toString() ?? 'Chantier #${json['id']}',
      description: json['description']?.toString(),
      location: json['location']?.toString(),
      gouvernorate: json['gouvernorate']?.toString(),
      startDate: parseDate(json['startDate']),
      plannedEndDate: parseDate(json['plannedEndDate']),
      actualEndDate: parseDate(json['actualEndDate']),
      status: parseStatus(json['status']),
      healthFlag: parseFlag(json['healthFlag']),
      progressPct: parseDouble(json['progressPct']),
      budgetTotal: json['budgetTotal'] != null ? parseDouble(json['budgetTotal']) : null,
      architectPersonId: json['architectPersonId'] != null ? parseInt(json['architectPersonId']) : null,
      architectName: json['architectName']?.toString(),
      projectManagerPersonId: json['projectManagerPersonId'] != null ? parseInt(json['projectManagerPersonId']) : null,
      projectManagerName: json['projectManagerName']?.toString(),
      activeTeamCount: parseInt(json['activeTeamCount']),
      openAlertsCount: parseInt(json['openAlertsCount']),
      creationDate: parseDate(json['creationDate']),
    );
  }

  // --- Display Helpers ---

  String get statusDisplayLabel {
    switch (status.toLowerCase()) {
      case 'inprogress':
        return 'En cours';
      case 'planned':
        return 'Planifié';
      case 'onhold':
        return 'En pause';
      case 'completed':
        return 'Terminé';
      case 'cancelled':
        return 'Annulé';
      default:
        return status;
    }
  }

  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'inprogress':
        return const Color(0xFF2563EB); // Vibrant Blue
      case 'completed':
        return const Color(0xFF10B981); // Emerald
      case 'onhold':
        return const Color(0xFFF59E0B); // Amber
      case 'cancelled':
        return const Color(0xFFEF4444); // Crimson
      default:
        return const Color(0xFF6B7280); // Slate Gray
    }
  }

  Color get flagColor {
    switch (healthFlag.toLowerCase()) {
      case 'red':
        return const Color(0xFFE24B4A);
      case 'orange':
        return const Color(0xFFF59E0B);
      case 'green':
      default:
        return const Color(0xFF639922);
    }
  }

  String get flagLabel {
    switch (healthFlag.toLowerCase()) {
      case 'red':
        return 'Critique';
      case 'orange':
        return 'Attention';
      case 'green':
      default:
        return 'Sain';
    }
  }
}
