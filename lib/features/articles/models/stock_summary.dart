/// Stores stock quantity aggregated for a specific sales site / depot.
class StockSiteBreakdown {
  final String siteName;
  final double quantity;
  final String unit;

  StockSiteBreakdown({
    required this.siteName,
    required this.quantity,
    required this.unit,
  });

  String get formattedQuantity => formatStockQuantity(quantity, unit);
}

/// Stores total stock quantity and per-site breakdown for an article.
class StockSummary {
  final double total;
  final List<StockSiteBreakdown> breakdown;

  StockSummary({
    required this.total,
    required this.breakdown,
  });

  bool get isOutOfStock => total <= 0;

  String formattedTotal(String? defaultUnit) {
    final unit = breakdown.isNotEmpty ? breakdown.first.unit : (defaultUnit ?? 'PCS');
    return formatStockQuantity(total, unit);
  }
}

/// Formats stock quantities matching the web app logic:
/// 3 decimal digits if unit is M3 / Mètre 3, else up to 3 digits.
String formatStockQuantity(double qty, String? unit) {
  final u = unit?.toUpperCase() ?? '';
  final isM3 = u.contains('M3') || u.contains('MÈTRE 3') || u.contains('METRE 3');

  if (isM3) {
    return qty.toStringAsFixed(3);
  } else {
    // If integer, display without decimal, else up to 3 decimal places
    if (qty == qty.roundToDouble()) {
      return qty.toInt().toString();
    }
    return qty.toStringAsFixed(3).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }
}
