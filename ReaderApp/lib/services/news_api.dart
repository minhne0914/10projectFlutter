import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/article.dart';

class NewsApi {
  // Lấy API key từ --dart-define (khuyến nghị) hoặc fallback rỗng
  static const _apiKey =
  String.fromEnvironment('NEWSAPI_KEY', defaultValue: '');

  static const _baseUrl = 'https://newsapi.org/v2';

  /// Top headlines cho country/category, có thể kèm query (tìm kiếm).
  static Future<List<Article>> fetchTopHeadlines({
    String country = 'us',
    String? category, // business, entertainment, general, health, science, sports, technology
    String? query,
    int page = 1,
    int pageSize = 20,
  }) async {
    final uri = Uri.parse('$_baseUrl/top-headlines').replace(queryParameters: {
      'country': country,
      if (category != null && category.isNotEmpty) 'category': category,
      if (query != null && query.isNotEmpty) 'q': query,
      'page': '$page',
      'pageSize': '$pageSize',
      'apiKey': _apiKey,
    });

    final resp = await http.get(uri, headers: {
      'Accept': 'application/json',
    });

    if (resp.statusCode != 200) {
      throw Exception('HTTP ${resp.statusCode}: ${resp.reasonPhrase}');
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    if (data['status'] != 'ok') {
      final msg = data['message']?.toString() ?? 'Unknown API error';
      throw Exception('NewsAPI error: $msg');
    }

    final List articles = (data['articles'] as List?) ?? [];
    return articles.map((e) => Article.fromJson(Map<String, dynamic>.from(e))).toList();
  }
}
