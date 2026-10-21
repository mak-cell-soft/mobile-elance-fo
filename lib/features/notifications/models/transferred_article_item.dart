/// Transferred article line item for inter-site stock transfers.
/// Directly maps to `StockTransferDetailsDto` from the C# backend
/// (`ms.webapp.api.acya.core.Entities.DTOs.StockTransferDetailsDto`).
class TransferredArticleItem {
  /// Unique merchandise or transfer detail line identifier.
  final int id;

  /// Article alphanumeric business code / reference (e.g. 'ART-CHENE-01').
  final String articleReference;

  /// Clear descriptive text of the timber or article product.
  final String description;

  /// Transferred numeric quantity.
  final double quantity;

  /// Measurement unit (e.g. 'm³', 'pcs', 'ml').
  final String? unit;

  /// Physical package/bundle reference if assigned (e.g. 'PAQ-2026-09').
  final String? packageReference;

  /// Human-readable origin sales site name, if returned by backend transfer details.
  final String? originSiteName;

  /// Human-readable destination sales site name, if returned by backend transfer details.
  final String? destinationSiteName;

  /// Document numbers associated with this transfer movement.
  final String? exitDocNumber;
  final String? receiptDocNumber;

  const TransferredArticleItem({
    required this.id,
    required this.articleReference,
    required this.description,
    required this.quantity,
    this.unit,
    this.packageReference,
    this.originSiteName,
    this.destinationSiteName,
    this.exitDocNumber,
    this.receiptDocNumber,
  });

  /// Factory constructor to parse raw backend JSON from GET /stock/transfers/details.
  factory TransferredArticleItem.fromJson(Map<String, dynamic> json) {
    // 1. Resolve identifier
    final dynamic rawId = json['id'] ?? json['merchandiseId'] ?? json['articleId'] ?? 0;
    final int resolvedId = rawId is int ? rawId : int.tryParse(rawId.toString()) ?? 0;

    // 2. Resolve article reference (refMerchandise is authoritative in StockTransferDetailsDto)
    final String ref = json['refMerchandise']?.toString() ??
        json['articleReference']?.toString() ??
        json['ref']?.toString() ??
        '';

    // 3. Resolve description / designation
    final String desc = json['description']?.toString() ??
        json['articleDescription']?.toString() ??
        json['merchandiseDescription']?.toString() ??
        json['designation']?.toString() ??
        '';

    // 4. Resolve quantity
    final dynamic rawQty = json['quantity'] ?? json['stockQuantity'] ?? 0;
    final double qty = (rawQty is num) ? rawQty.toDouble() : double.tryParse(rawQty.toString()) ?? 0.0;

    // 5. Packaging and site metadata
    final String? pkg = json['refPaquet']?.toString() ?? json['packageReference']?.toString();
    final String? origin = json['origine']?.toString() ?? json['originSite']?.toString();
    final String? dest = json['destination']?.toString();
    final String? exitDoc = json['docSortie']?.toString() ?? json['exitDocNumber']?.toString();
    final String? receiptDoc = json['docReception']?.toString() ?? json['receiptDocNumber']?.toString();
    final String? unitVal = json['unit']?.toString();

    return TransferredArticleItem(
      id: resolvedId,
      articleReference: ref,
      description: desc,
      quantity: qty,
      unit: unitVal,
      packageReference: pkg,
      originSiteName: origin,
      destinationSiteName: dest,
      exitDocNumber: exitDoc,
      receiptDocNumber: receiptDoc,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'articleReference': articleReference,
        'description': description,
        'quantity': quantity,
        'unit': unit,
        'packageReference': packageReference,
        'originSiteName': originSiteName,
        'destinationSiteName': destinationSiteName,
        'exitDocNumber': exitDocNumber,
        'receiptDocNumber': receiptDocNumber,
      };
}
