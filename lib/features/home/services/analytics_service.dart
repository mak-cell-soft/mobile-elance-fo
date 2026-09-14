import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/analytics_dto.dart';

/// Service responsible for fetching analytics, KPIs, and financial aggregated chart data.
/// Connects to backend endpoints:
/// - GET /Analytics/dashboard
/// - GET /Counterpart/getall/Supplier
/// - GET /Document/_type?_type=3 (Supplier Invoices)
/// - GET /Document/_type?_type=7 (Supplier Return Invoices)
/// - POST /Payments/search
class AnalyticsService {
  final Dio _dio = ApiClient.instance.dio;

  /// Fetches overall dashboard KPIs including sales, stock alerts, and client receivables.
  Future<DashboardKpiDto> fetchDashboardKpis({int? month, int? year}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (month != null) queryParams['month'] = month;
      if (year != null) queryParams['year'] = year;

      final response = await _dio.get(
        'Analytics/dashboard',
        queryParameters: queryParams,
      );
      return DashboardKpiDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Calculates total purchase amount TTC (Achats TTC) by fetching
  /// supplier invoices (type 3) and subtracting supplier return invoices (type 7).
  /// If [month] is null, calculates for the entire selected [year].
  Future<double> fetchMonthlyPurchaseTtc({required int year, int? month}) async {
    try {
      final responses = await Future.wait([
        _dio.get('Document/_type', queryParameters: {'_type': 3}),
        _dio.get('Document/_type', queryParameters: {'_type': 7}),
      ]);

      final invoices = (responses[0].data as List<dynamic>? ?? []);
      final returns = (responses[1].data as List<dynamic>? ?? []);

      double totalInvoices = 0.0;
      for (final doc in invoices) {
        final dateStr = doc['creationdate'] ?? doc['creationDate'] ?? doc['CreationDate'];
        if (dateStr != null) {
          final date = DateTime.tryParse(dateStr.toString());
          if (date != null && date.year == year) {
            if (month == null || date.month == month) {
              final val = (doc['total_net_ttc'] ?? doc['totalNetTtc'] ?? doc['totalCostPriceTtc'] ?? 0) as num;
              totalInvoices += val.toDouble();
            }
          }
        }
      }

      double totalReturns = 0.0;
      for (final doc in returns) {
        final dateStr = doc['creationdate'] ?? doc['creationDate'] ?? doc['CreationDate'];
        if (dateStr != null) {
          final date = DateTime.tryParse(dateStr.toString());
          if (date != null && date.year == year) {
            if (month == null || date.month == month) {
              final val = (doc['total_net_ttc'] ?? doc['totalNetTtc'] ?? doc['totalCostPriceTtc'] ?? 0) as num;
              totalReturns += val.toDouble();
            }
          }
        }
      }

      return totalInvoices - totalReturns;
    } catch (_) {
      // Fallback gracefully on network error or missing data
      return 0.0;
    }
  }

  /// Computes Achats vs. Règlements par Fournisseur chart data point by aggregating
  /// supplier invoices and payments per supplier for the given year/month.
  Future<List<SupplierChartPointDto>> fetchSupplierPurchasePaymentChart({
    required int year,
    int? month,
  }) async {
    try {
      // 1. Fetch suppliers, supplier invoices (type 3), and payments concurrently
      final responses = await Future.wait([
        _dio.get('Counterpart/getall/Supplier'),
        _dio.get('Document/_type', queryParameters: {'_type': 3}),
        _dio.post('Payments/search', data: {'pageNumber': 1, 'pageSize': 100000}),
      ]);

      final suppliersList = responses[0].data as List<dynamic>? ?? [];
      final invoicesList = responses[1].data as List<dynamic>? ?? [];
      final rawPayments = responses[2].data;
      final paymentsList = (rawPayments is Map<String, dynamic>
              ? (rawPayments['items'] as List<dynamic>?)
              : (rawPayments as List<dynamic>?)) ??
          [];

      final List<SupplierChartPointDto> chartPoints = [];

      for (final s in suppliersList) {
        final supplierId = (s['id'] as num?)?.toInt();
        if (supplierId == null) continue;

        String name = s['name'] ?? s['Name'] ?? '${s['firstname'] ?? ''} ${s['lastname'] ?? ''}'.trim();
        if (name.isEmpty) name = 'Fournisseur #$supplierId';
        if (name.length > 16) {
          name = '${name.substring(0, 14)}...';
        }

        // Aggregate purchases (Invoices)
        double totalPurchases = 0.0;
        for (final inv in invoicesList) {
          final cId = inv['counterpart']?['id'] ?? inv['counterPart']?['id'] ?? inv['counterpartId'] ?? inv['counterpartid'];
          if (cId == supplierId) {
            final dateStr = inv['creationdate'] ?? inv['creationDate'] ?? inv['CreationDate'];
            if (dateStr != null) {
              final date = DateTime.tryParse(dateStr.toString());
              if (date != null && date.year == year) {
                if (month == null || date.month == month) {
                  final val = (inv['total_net_ttc'] ?? inv['totalNetTtc'] ?? inv['totalCostPriceTtc'] ?? 0) as num;
                  totalPurchases += val.toDouble();
                }
              }
            }
          }
        }

        // Aggregate payments
        double totalPayments = 0.0;
        for (final pay in paymentsList) {
          final cId = pay['customerId'] ?? pay['customerid'] ?? pay['CustomerId'] ?? pay['counterpartId'] ?? pay['counterpartid'];
          if (cId == supplierId) {
            String? dateStr = pay['paymentDate'] ?? pay['paymentdate'] ?? pay['PaymentDate'];
            final docId = pay['documentId'] ?? pay['documentid'] ?? pay['DocumentId'];
            if (docId != null) {
              final linkedInv = invoicesList.firstWhere(
                (inv) => inv['id'] == docId,
                orElse: () => null,
              );
              if (linkedInv != null) {
                dateStr = linkedInv['creationdate'] ?? linkedInv['creationDate'] ?? linkedInv['CreationDate'];
              }
            }

            if (dateStr != null) {
              final date = DateTime.tryParse(dateStr.toString());
              if (date != null && date.year == year) {
                if (month == null || date.month == month) {
                  final val = (pay['amount'] ?? pay['Amount'] ?? pay['total'] ?? 0) as num;
                  totalPayments += val.toDouble();
                }
              }
            }
          }
        }

        if (totalPurchases > 0 || totalPayments > 0) {
          chartPoints.add(SupplierChartPointDto(
            supplierId: supplierId,
            name: name,
            purchases: totalPurchases,
            payments: totalPayments,
          ));
        }
      }

      // Sort by highest purchases descending and take top 10
      chartPoints.sort((a, b) => b.purchases.compareTo(a.purchases));
      return chartPoints.take(10).toList();
    } catch (_) {
      // Fallback gracefully on network error
      return [];
    }
  }

  /// Fetches top selling sub-categories and their top articles for the specified [months] range (default 6).
  /// Connects to GET /Analytics/top-subcategories?months={months}.
  /// Accessible by all authenticated users to power the Top Ventes par Sous-Catégorie chart.
  Future<List<TopSubCategoryDto>> fetchTopSubCategories({int months = 6}) async {
    try {
      final response = await _dio.get(
        'Analytics/top-subcategories',
        queryParameters: {'months': months},
      );

      final rawList = response.data as List<dynamic>? ?? [];
      return rawList
          .map((item) => TopSubCategoryDto.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}

