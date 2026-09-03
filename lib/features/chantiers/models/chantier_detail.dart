import 'package:flutter/material.dart';
import 'chantier_list_item.dart';

/// Progress entry within a chantier life cycle / timeline
class ChantierProgressEntry {
  final int id;
  final int chantierId;
  final String title;
  final String? description;
  final String entryType; // DailyReport, Milestone, Observation, Issue
  final String entryStatus; // Done, Pending, Cancelled
  final DateTime entryDate;
  final int recordedById;

  ChantierProgressEntry({
    required this.id,
    required this.chantierId,
    required this.title,
    this.description,
    required this.entryType,
    required this.entryStatus,
    required this.entryDate,
    required this.recordedById,
  });

  factory ChantierProgressEntry.fromJson(Map<String, dynamic> json) {
    return ChantierProgressEntry(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      chantierId: json['chantierId'] is int ? json['chantierId'] : int.tryParse(json['chantierId'].toString()) ?? 0,
      title: json['title']?.toString() ?? 'Entrée de journal',
      description: json['description']?.toString(),
      entryType: json['entryType']?.toString() ?? 'DailyReport',
      entryStatus: json['entryStatus']?.toString() ?? 'Done',
      entryDate: DateTime.tryParse(json['entryDate']?.toString() ?? '') ?? DateTime.now(),
      recordedById: json['recordedById'] is int ? json['recordedById'] : int.tryParse(json['recordedById'].toString()) ?? 0,
    );
  }

  bool get isDone => entryStatus.toLowerCase() == 'done' || entryStatus == '0';
}

/// Alert or vigilance notice attached to a chantier
class ChantierAlert {
  final int id;
  final int chantierId;
  final String message;
  final String alertType; // Critical, Warning, Info
  final bool isResolved;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  ChantierAlert({
    required this.id,
    required this.chantierId,
    required this.message,
    required this.alertType,
    required this.isResolved,
    required this.createdAt,
    this.resolvedAt,
  });

  factory ChantierAlert.fromJson(Map<String, dynamic> json) {
    return ChantierAlert(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      chantierId: json['chantierId'] is int ? json['chantierId'] : int.tryParse(json['chantierId'].toString()) ?? 0,
      message: json['message']?.toString() ?? '',
      alertType: json['alertType']?.toString() ?? 'Warning',
      isResolved: json['isResolved'] == true,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      resolvedAt: json['resolvedAt'] != null ? DateTime.tryParse(json['resolvedAt'].toString()) : null,
    );
  }

  bool get isCritical => alertType.toLowerCase() == 'critical' || alertType == '0';

  Color get badgeColor => isCritical ? const Color(0xFFDC2626) : const Color(0xFFD97706);
  Color get backgroundColor => isCritical ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB);
  Color get borderColor => isCritical ? const Color(0xFFFECACA) : const Color(0xFFFDE68A);
}

/// Detailed representation of a Chantier including rich collections
class ChantierDetail extends ChantierListItem {
  final String? internalNote;
  final int? clientCounterPartId;
  final List<ChantierProgressEntry> progressEntries;
  final List<ChantierAlert> alerts;

  const ChantierDetail({
    required super.id,
    super.guid,
    super.reference,
    required super.name,
    super.description,
    super.location,
    super.gouvernorate,
    super.startDate,
    super.plannedEndDate,
    super.actualEndDate,
    required super.status,
    required super.healthFlag,
    required super.progressPct,
    super.budgetTotal,
    super.architectPersonId,
    super.architectName,
    super.projectManagerPersonId,
    super.projectManagerName,
    super.activeTeamCount,
    super.openAlertsCount,
    super.creationDate,
    this.internalNote,
    this.clientCounterPartId,
    this.progressEntries = const [],
    this.alerts = const [],
  });

  factory ChantierDetail.fromJson(Map<String, dynamic> json) {
    final base = ChantierListItem.fromJson(json);

    List<ChantierProgressEntry> parseProgress(dynamic list) {
      if (list is List) {
        return list.map((e) => ChantierProgressEntry.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    }

    List<ChantierAlert> parseAlerts(dynamic list) {
      if (list is List) {
        return list.map((e) => ChantierAlert.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    }

    return ChantierDetail(
      id: base.id,
      guid: base.guid,
      reference: base.reference,
      name: base.name,
      description: base.description,
      location: base.location,
      gouvernorate: base.gouvernorate,
      startDate: base.startDate,
      plannedEndDate: base.plannedEndDate,
      actualEndDate: base.actualEndDate,
      status: base.status,
      healthFlag: base.healthFlag,
      progressPct: base.progressPct,
      budgetTotal: base.budgetTotal,
      architectPersonId: base.architectPersonId,
      architectName: base.architectName,
      projectManagerPersonId: base.projectManagerPersonId,
      projectManagerName: base.projectManagerName,
      activeTeamCount: base.activeTeamCount,
      openAlertsCount: base.openAlertsCount,
      creationDate: base.creationDate,
      internalNote: json['internalNote']?.toString(),
      clientCounterPartId: json['clientCounterPartId'] != null ? int.tryParse(json['clientCounterPartId'].toString()) : null,
      progressEntries: parseProgress(json['progressEntries']),
      alerts: parseAlerts(json['alerts']),
    );
  }
}
