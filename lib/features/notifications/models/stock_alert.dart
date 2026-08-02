/// Data model representing a low stock threshold alert.
class StockAlert {
  final dynamic id;
  final String articleCode;
  final String designation;
  final double currentStock;
  final double minThreshold;
  final String? siteName;

  const StockAlert({
    required this.id,
    required this.articleCode,
    required this.designation,
    required this.currentStock,
    required this.minThreshold,
    this.siteName,
  });

  factory StockAlert.fromJson(Map<String, dynamic> json) {
    return StockAlert(
      id: json['id'] ?? json['stockId'] ?? json['merchandiseId'] ?? 0,
      articleCode: json['articleReference']?.toString() ??
          json['articleCode']?.toString() ??
          json['code']?.toString() ??
          '',
      designation: json['packageReference']?.toString() ??
          json['merchandiseDescription']?.toString() ??
          json['designation']?.toString() ??
          json['name']?.toString() ??
          'Article',
      currentStock: (json['stockQuantity'] ??
              json['currentStock'] ??
              json['quantity'] ??
              json['stock'] ??
              0)
          .toDouble(),
      minThreshold: (json['minimumStock'] ??
              json['minThreshold'] ??
              json['threshold'] ??
              0)
          .toDouble(),
      siteName: json['siteName']?.toString(),
    );
  }
}
