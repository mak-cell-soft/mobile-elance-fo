import 'dart:convert';

/// Data model representing an inter-site stock transfer notification.
/// Mirrors `TransferNotification` from `elance-app.ui`.
class TransferNotification {
  final int id;
  final String transferRef;
  final int originSite;
  final DateTime date;
  final int itemsCount;
  final String exitDocNumber;
  final String receiptDocNumber;
  final int destinationSiteId;

  const TransferNotification({
    required this.id,
    required this.transferRef,
    required this.originSite,
    required this.date,
    required this.itemsCount,
    required this.exitDocNumber,
    required this.receiptDocNumber,
    required this.destinationSiteId,
  });

  /// Factory constructor to parse raw backend JSON or PendingNotification content string.
  /// Exactly matches the parsing logic in `use-notifications.tsx`.
  factory TransferNotification.fromPendingJson(Map<String, dynamic> item) {
    int transferId = item['id'] is int ? item['id'] : int.tryParse(item['id']?.toString() ?? '0') ?? 0;
    String ref = 'Transfert';
    int origin = 0;
    int items = 0;
    String exitDoc = '';
    String receiptDoc = '';
    int targetSite = int.tryParse(item['targetGroup']?.toString() ?? '0') ?? 0;
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
        if (content['OriginSite'] != null) {
          origin = content['OriginSite'] is int
              ? content['OriginSite']
              : int.tryParse(content['OriginSite'].toString()) ?? 0;
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
        }
      } catch (_) {}
    }

    return TransferNotification(
      id: transferId,
      transferRef: ref,
      originSite: origin,
      date: createdAt,
      itemsCount: items,
      exitDocNumber: exitDoc,
      receiptDocNumber: receiptDoc,
      destinationSiteId: targetSite,
    );
  }
}
