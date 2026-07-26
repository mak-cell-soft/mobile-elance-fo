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
