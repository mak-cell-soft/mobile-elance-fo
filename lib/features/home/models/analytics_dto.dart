library;

/// Data Transfer Objects representing analytics data returned by the backend endpoints.
/// Used specifically for executive dashboard KPIs and charts.

class CustomerReceivableDto {
  final int id;
  final String name;
  final double totalInvoiced;
  final double totalPaid;
  final double outstanding;
  final int oldestInvoiceDays;

  const CustomerReceivableDto({
    required this.id,
    required this.name,
    required this.totalInvoiced,
    required this.totalPaid,
    required this.outstanding,
    required this.oldestInvoiceDays,
  });

  factory CustomerReceivableDto.fromJson(Map<String, dynamic> json) {
    return CustomerReceivableDto(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] as String?) ?? 'Client Inconnu',
      totalInvoiced: (json['totalInvoiced'] as num?)?.toDouble() ?? 0.0,
      totalPaid: (json['totalPaid'] as num?)?.toDouble() ?? 0.0,
      outstanding: (json['outstanding'] as num?)?.toDouble() ?? 0.0,
      oldestInvoiceDays: (json['oldestInvoiceDays'] as num?)?.toInt() ?? 0,
    );
  }
}

class DashboardKpiDto {
  final double dailySales;
  final double weeklySales;
  final double monthlySales;
  final int stockAlertCount;
  final List<CustomerReceivableDto> customerReceivables;

  const DashboardKpiDto({
    required this.dailySales,
    required this.weeklySales,
    required this.monthlySales,
    required this.stockAlertCount,
    required this.customerReceivables,
  });

  factory DashboardKpiDto.fromJson(Map<String, dynamic> json) {
    final receivablesJson = json['customerReceivables'] as List<dynamic>? ?? [];
    return DashboardKpiDto(
      dailySales: (json['dailySales'] as num?)?.toDouble() ?? 0.0,
      weeklySales: (json['weeklySales'] as num?)?.toDouble() ?? 0.0,
      monthlySales: (json['monthlySales'] as num?)?.toDouble() ?? 0.0,
      stockAlertCount: (json['stockAlertCount'] as num?)?.toInt() ?? 0,
      customerReceivables: receivablesJson
          .map((item) => CustomerReceivableDto.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SupplierChartPointDto {
  final int supplierId;
  final String name;
  final double purchases;
  final double payments;

  const SupplierChartPointDto({
    required this.supplierId,
    required this.name,
    required this.purchases,
    required this.payments,
  });
}

/// Data Transfer Object representing a top sold article within a sub-category.
class TopArticleDto {
  final int articleId;
  final String reference;
  final String articleName;
  final double quantitySold;
  final double revenueTTC;

  const TopArticleDto({
    required this.articleId,
    required this.reference,
    required this.articleName,
    required this.quantitySold,
    required this.revenueTTC,
  });

  factory TopArticleDto.fromJson(Map<String, dynamic> json) {
    return TopArticleDto(
      articleId: (json['articleId'] ?? json['ArticleId'] as num?)?.toInt() ?? 0,
      reference: (json['reference'] ?? json['Reference'] ?? '').toString(),
      articleName: (json['articleName'] ?? json['ArticleName'] ?? '').toString(),
      quantitySold: (json['quantitySold'] ?? json['QuantitySold'] as num?)?.toDouble() ?? 0.0,
      revenueTTC: (json['revenueTTC'] ?? json['RevenueTTC'] ?? json['revenueTtc'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Data Transfer Object representing a sub-category with sales metrics and its top sold articles.
class TopSubCategoryDto {
  final int subCategoryId;
  final String subCategoryName;
  final String categoryName;
  final double totalQuantitySold;
  final double totalRevenueTTC;
  final int articleCount;
  final List<TopArticleDto> topArticles;

  const TopSubCategoryDto({
    required this.subCategoryId,
    required this.subCategoryName,
    required this.categoryName,
    required this.totalQuantitySold,
    required this.totalRevenueTTC,
    required this.articleCount,
    required this.topArticles,
  });

  factory TopSubCategoryDto.fromJson(Map<String, dynamic> json) {
    final rawArticles = (json['topArticles'] ?? json['TopArticles']) as List<dynamic>? ?? [];
    return TopSubCategoryDto(
      subCategoryId: (json['subCategoryId'] ?? json['SubCategoryId'] as num?)?.toInt() ?? 0,
      subCategoryName: (json['subCategoryName'] ?? json['SubCategoryName'] ?? '').toString(),
      categoryName: (json['categoryName'] ?? json['CategoryName'] ?? '').toString(),
      totalQuantitySold: (json['totalQuantitySold'] ?? json['TotalQuantitySold'] as num?)?.toDouble() ?? 0.0,
      totalRevenueTTC: (json['totalRevenueTTC'] ?? json['TotalRevenueTTC'] ?? json['totalRevenueTtc'] as num?)?.toDouble() ?? 0.0,
      articleCount: (json['articleCount'] ?? json['ArticleCount'] as num?)?.toInt() ?? 0,
      topArticles: rawArticles
          .map((item) => TopArticleDto.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

