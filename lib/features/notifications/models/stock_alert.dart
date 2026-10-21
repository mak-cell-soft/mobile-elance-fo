/// Data model representing a low stock threshold alert.
/// Directly maps to `StockQuantityDto` from the C# backend
/// (`ms.webapp.api.acya.core.Entities.DTOs.StockQuantityDto`).
class StockAlert {
  /// Stock or Merchandise record identifier.
  final dynamic id;

  /// Primary article reference / code (e.g. 'ART-BR-50150').
  final String articleReference;

  /// Article or merchandise descriptive text (e.g. 'Bois Rouge 50x150 Traité').
  final String description;

  /// Physical packaging/bundle reference if applicable (e.g. 'PAQ-2024-001').
  final String? packageReference;

  /// Current on-hand quantity at the sales site.
  final double currentStock;

  /// Configured minimum warning threshold.
  final double minThreshold;

  /// Measurement unit (e.g. 'm³', 'pcs').
  final String? unit;

  /// Optional name or identifier of the sales site where stock is low.
  final String? siteName;

  /// Optional sales site identifier.
  final int? siteId;

  const StockAlert({
    required this.id,
    required this.articleReference,
    required this.description,
    this.packageReference,
    required this.currentStock,
    required this.minThreshold,
    this.unit,
    this.siteName,
    this.siteId,
  });

  /// Backwards-compatible alias for existing code referencing articleCode.
  String get articleCode => articleReference;

  /// Backwards-compatible alias for existing code referencing designation.
  String get designation {
    if (description.trim().isNotEmpty) {
      return description;
    }
    if (packageReference != null && packageReference!.trim().isNotEmpty) {
      return packageReference!;
    }
    return articleReference.isNotEmpty ? articleReference : 'Article';
  }

  factory StockAlert.fromJson(Map<String, dynamic> json) {
    // 1. Resolve Primary Article Reference (prioritized over package reference)
    final String resolvedRef = json['articleReference']?.toString() ??
        json['ArticleReference']?.toString() ??
        json['articleCode']?.toString() ??
        json['ArticleCode']?.toString() ??
        json['code']?.toString() ??
        json['Code']?.toString() ??
        json['ref']?.toString() ??
        '';

    // 2. Resolve Article Description / Designation
    // Never fall back to package reference as the primary description
    final String resolvedDesc = json['merchandiseDescription']?.toString() ??
        json['MerchandiseDescription']?.toString() ??
        json['description']?.toString() ??
        json['Description']?.toString() ??
        json['designation']?.toString() ??
        json['Designation']?.toString() ??
        json['articleDescription']?.toString() ??
        json['name']?.toString() ??
        '';

    // 3. Resolve Package Reference (specifically separated from article reference)
    final String? resolvedPkg = json['packageReference']?.toString() ??
        json['PackageReference']?.toString() ??
        json['refPaquet']?.toString() ??
        json['RefPaquet']?.toString();

    // 4. Resolve Stock Quantities and Thresholds
    final dynamic rawCurrent = json['stockQuantity'] ??
        json['StockQuantity'] ??
        json['quantity'] ??
        json['Quantity'] ??
        json['currentStock'] ??
        json['CurrentStock'] ??
        json['stock'] ??
        0;

    final dynamic rawMin = json['minimumStock'] ??
        json['MinimumStock'] ??
        json['minThreshold'] ??
        json['MinThreshold'] ??
        json['threshold'] ??
        json['Threshold'] ??
        0;

    final double currentStockVal = (rawCurrent is num)
        ? rawCurrent.toDouble()
        : double.tryParse(rawCurrent.toString()) ?? 0.0;

    final double minThresholdVal = (rawMin is num)
        ? rawMin.toDouble()
        : double.tryParse(rawMin.toString()) ?? 0.0;

    final int? resolvedSiteId = json['siteId'] is int
        ? json['siteId']
        : int.tryParse(json['siteId']?.toString() ?? json['SiteId']?.toString() ?? '');

    return StockAlert(
      id: json['id'] ?? json['stockId'] ?? json['StockId'] ?? json['merchandiseId'] ?? 0,
      articleReference: resolvedRef,
      description: resolvedDesc,
      packageReference: resolvedPkg,
      currentStock: currentStockVal,
      minThreshold: minThresholdVal,
      unit: json['unit']?.toString() ?? json['Unit']?.toString(),
      siteName: json['siteName']?.toString() ?? json['SiteName']?.toString(),
      siteId: resolvedSiteId,
    );
  }
}
