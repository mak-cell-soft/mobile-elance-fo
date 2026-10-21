import 'dart:convert';
import 'transferred_article_item.dart';

/// Data model representing an inter-site stock transfer notification.
/// Mirrors `TransferNotification` from `elance-app.ui`.
class TransferNotification {
  /// The business transfer ID, matching the backend endpoint contract DELETE /notifications/{transferId}.
  final int id;

  /// The database primary key of the pending notification record in the PendingNotifications table.
  final int? pendingNotificationId;

  final String transferRef;
  final int originSite;
  final String? originSiteName;
  final DateTime date;
  final int itemsCount;
  final String exitDocNumber;
  final String receiptDocNumber;
  final int destinationSiteId;
  final String? destinationSiteName;

  /// Optional pre-embedded or cached transferred article lines.
  final List<TransferredArticleItem>? inlineArticles;

  const TransferNotification({
    required this.id,
    this.pendingNotificationId,
    required this.transferRef,
    required this.originSite,
    this.originSiteName,
    required this.date,
    required this.itemsCount,
    required this.exitDocNumber,
    required this.receiptDocNumber,
    required this.destinationSiteId,
    this.destinationSiteName,
    this.inlineArticles,
  });

  /// Human-readable origin label with safe fallback, strictly avoiding `#0`.
  String get displayOriginSite {
    if (originSiteName != null && originSiteName!.trim().isNotEmpty) {
      return originSiteName!;
    }
    if (originSite > 0) {
      return 'Site #$originSite';
    }
    return 'Site indisponible';
  }

  /// Human-readable destination label with safe fallback, strictly avoiding `#0`.
  String get displayDestinationSite {
    if (destinationSiteName != null && destinationSiteName!.trim().isNotEmpty) {
      return destinationSiteName!;
    }
    if (destinationSiteId > 0) {
      return 'Site #$destinationSiteId';
    }
    return 'Site indisponible';
  }

  /// Factory constructor to parse raw backend JSON or PendingNotification content string.
  /// Exactly matches the parsing logic in `use-notifications.tsx`.
  factory TransferNotification.fromPendingJson(Map<String, dynamic> item) {
    final int pendingId = item['id'] is int ? item['id'] : int.tryParse(item['id']?.toString() ?? '0') ?? 0;
    int transferId = pendingId;
    String ref = 'Transfert';
    int origin = 0;
    String? originName;
    int items = 0;
    String exitDoc = '';
    String receiptDoc = '';
    String? destName;
    List<TransferredArticleItem>? parsedArticles;

    // Parse targetGroup (can be plain int "2" or tenant-scoped "tenant:slug:site-2")
    final String rawTargetGroup = item['targetGroup']?.toString() ?? '';
    int targetSite = int.tryParse(rawTargetGroup) ?? 0;
    if (targetSite == 0 && rawTargetGroup.contains('site-')) {
      final match = RegExp(r'site-(\d+)').firstMatch(rawTargetGroup);
      if (match != null) {
        targetSite = int.tryParse(match.group(1)!) ?? 0;
      }
    }

    DateTime createdAt = item['createdAt'] != null
        ? DateTime.tryParse(item['createdAt'].toString()) ?? DateTime.now()
        : DateTime.now();

    final rawContent = item['content'];
    if (rawContent != null && rawContent is String && rawContent.isNotEmpty) {
      try {
        final Map<String, dynamic> content = jsonDecode(rawContent);
        if (content['TransferId'] != null) {
          transferId = content['TransferId'] is int
              ? content['TransferId']
              : int.tryParse(content['TransferId'].toString()) ?? transferId;
        }
        if (content['Reference'] != null) {
          ref = content['Reference'].toString();
        }

        // Handle OriginSite: could be an int, numeric string, or text address like "Dépôt Sfax"
        if (content['OriginSite'] != null) {
          final rawOrigin = content['OriginSite'];
          if (rawOrigin is int) {
            origin = rawOrigin;
          } else {
            final parsed = int.tryParse(rawOrigin.toString());
            if (parsed != null && parsed > 0) {
              origin = parsed;
            } else if (rawOrigin.toString().trim().isNotEmpty) {
              originName = rawOrigin.toString().trim();
            }
          }
        }
        if (content['OriginSiteName'] != null) {
          originName = content['OriginSiteName'].toString().trim();
        }
        if (content['DestinationSiteName'] != null) {
          destName = content['DestinationSiteName'].toString().trim();
        }

        if (content['ItemsCount'] != null) {
          items = content['ItemsCount'] is int
              ? content['ItemsCount']
              : int.tryParse(content['ItemsCount'].toString()) ?? 0;
        }

        dynamic addData = content['AdditionalData'];
        if (addData is String && addData.isNotEmpty) {
          try {
            addData = jsonDecode(addData);
          } catch (_) {}
        }
        if (addData is Map<String, dynamic>) {
          exitDoc = addData['ExitDocNumber']?.toString() ?? '';
          receiptDoc = addData['ReceiptDocNumber']?.toString() ?? '';
          if (addData['OriginSiteName'] != null) {
            originName = addData['OriginSiteName'].toString();
          }
          if (addData['DestinationSiteName'] != null) {
            destName = addData['DestinationSiteName'].toString();
          }
        }

        // Optional embedded articles
        final rawItems = content['Items'] ?? content['merchandisesItems'] ?? content['items'];
        if (rawItems is List && rawItems.isNotEmpty) {
          parsedArticles = rawItems
              .whereType<Map<String, dynamic>>()
              .map((j) => TransferredArticleItem.fromJson(j))
              .toList();
          if (items == 0) items = parsedArticles.length;
        }
      } catch (_) {}
    }

    return TransferNotification(
      id: transferId,
      pendingNotificationId: pendingId,
      transferRef: ref,
      originSite: origin,
      originSiteName: originName,
      date: createdAt,
      itemsCount: items,
      exitDocNumber: exitDoc,
      receiptDocNumber: receiptDoc,
      destinationSiteId: targetSite,
      destinationSiteName: destName,
      inlineArticles: parsedArticles,
    );
  }

  /// Copies this notification with optionally updated fields (e.g. after fetching details).
  TransferNotification copyWith({
    String? originSiteName,
    String? destinationSiteName,
    List<TransferredArticleItem>? inlineArticles,
    int? itemsCount,
  }) {
    return TransferNotification(
      id: id,
      pendingNotificationId: pendingNotificationId,
      transferRef: transferRef,
      originSite: originSite,
      originSiteName: originSiteName ?? this.originSiteName,
      date: date,
      itemsCount: itemsCount ?? this.itemsCount,
      exitDocNumber: exitDocNumber,
      receiptDocNumber: receiptDocNumber,
      destinationSiteId: destinationSiteId,
      destinationSiteName: destinationSiteName ?? this.destinationSiteName,
      inlineArticles: inlineArticles ?? this.inlineArticles,
    );
  }
}
