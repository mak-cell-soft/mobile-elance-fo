import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/article.dart';

class ArticleService {
  final Dio _dio = ApiClient.instance.dio;

  /// GET /api/article returns the entire non-deleted catalog — there is no
  /// server-side pagination, search, or filtering to reuse here.
  Future<List<Article>> fetchAll() async {
    try {
      final response = await _dio.get('article');
      final data = response.data as List<dynamic>;
      return data
          .map((json) => Article.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
