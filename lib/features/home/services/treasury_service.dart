import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/treasury_dto.dart';

/// Service responsible for fetching Caisse Principale & Caisse par Point de Vente balances.
/// Connects to backend endpoints matching the web application (`caisse.service.ts`):
/// - GET /Caisse/principale/balance
/// - GET /Caisse/all
class TreasuryService {
  final Dio _dio = ApiClient.instance.dio;

  /// Fetches the Caisse Principale balance (Central Vault cash balance).
  Future<double> fetchCaissePrincipaleBalance() async {
    try {
      final response = await _dio.get('Caisse/principale/balance');
      final data = response.data;
      if (data is num) {
        return data.toDouble();
      } else if (data is Map<String, dynamic> && data.containsKey('balance')) {
        return (data['balance'] as num).toDouble();
      }
      return double.tryParse(data.toString()) ?? 0.0;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (_) {
      return 0.0;
    }
  }

  /// Fetches all point of sale caisse balances (`Caisse par Point de Vente`).
  Future<List<SiteCaisseBalanceDto>> fetchAllCaisseBalances() async {
    try {
      final response = await _dio.get('Caisse/all');
      final rawList = response.data as List<dynamic>? ?? [];
      return rawList
          .map((item) => SiteCaisseBalanceDto.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (_) {
      return [];
    }
  }
}
