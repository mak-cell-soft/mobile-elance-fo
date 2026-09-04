import 'notification_type.dart';

/// Data model representing a general system notification.
/// Mirrors `AppNotification` from `elance-app.ui`.
class AppNotification {
  final int id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime createdAt;
  final bool isRead;
  final String? actionUrl;
  final String? relatedEntityType;
  final String? relatedEntityId;
  final int? priority;

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    required this.isRead,
    this.actionUrl,
    this.relatedEntityType,
    this.relatedEntityId,
    this.priority,
  });

  /// True if this notification corresponds to a Chantier Caisse cash request
  bool get isCaisseRequest =>
      relatedEntityType == 'ChantierCaisseTransaction' ||
      title.toLowerCase().contains('caisse') ||
      title.toLowerCase().contains("demande d'argent");

  /// Extracts the Chantier ID from actionUrl (e.g. "/chantiers/12?tab=caisse") if available
  int? get chantierIdFromAction {
    if (actionUrl != null && actionUrl!.isNotEmpty) {
      final regExp = RegExp(r'chantiers/(\d+)');
      final match = regExp.firstMatch(actionUrl!);
      if (match != null) {
        return int.tryParse(match.group(1)!);
      }
    }
    return null;
  }

  /// Factory constructor to deserialize backend JSON.
  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString() ?? 'Notification',
      message: json['message']?.toString() ?? '',
      type: NotificationType.fromValue(json['type']),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isRead: json['isRead'] == true || json['isRead']?.toString().toLowerCase() == 'true',
      actionUrl: json['actionUrl']?.toString(),
      relatedEntityType: json['relatedEntityType']?.toString(),
      relatedEntityId: json['relatedEntityId']?.toString(),
      priority: json['priority'] is int
          ? json['priority']
          : int.tryParse(json['priority']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type.value,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      if (actionUrl != null) 'actionUrl': actionUrl,
      if (relatedEntityType != null) 'relatedEntityType': relatedEntityType,
      if (relatedEntityId != null) 'relatedEntityId': relatedEntityId,
      if (priority != null) 'priority': priority,
    };
  }

  /// Copy helper to produce an updated clone (e.g. when marking read).
  AppNotification copyWith({
    int? id,
    String? title,
    String? message,
    NotificationType? type,
    DateTime? createdAt,
    bool? isRead,
    String? actionUrl,
    String? relatedEntityType,
    String? relatedEntityId,
    int? priority,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      actionUrl: actionUrl ?? this.actionUrl,
      relatedEntityType: relatedEntityType ?? this.relatedEntityType,
      relatedEntityId: relatedEntityId ?? this.relatedEntityId,
      priority: priority ?? this.priority,
    );
  }
}
