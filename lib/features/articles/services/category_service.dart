import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/category.dart';

/// Service responsible for category and subcategory configuration fetching.
class CategoryService {
  final Dio _dio = ApiClient.instance.dio;

  /// GET /Category returns all categories with nested firstchildren (subcategories).
  Future<List<Category>> fetchAll() async {
    try {
      final response = await _dio.get('Category');
      final data = response.data as List<dynamic>;
      return data
          .map((json) => Category.fromJson(json as Map<String, dynamic>))
          .where((cat) => !(cat.isDeleted ?? false))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
