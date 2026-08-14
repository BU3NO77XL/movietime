import 'api_client.dart';
import 'content_models.dart';

class ContentService {
  ContentService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> tmdb(
    String path, {
    Map<String, String?> query = const {},
  }) {
    return _apiClient.getJson('/api/content/$path', query: query);
  }

  Future<List<WatchlistItem>> watchlist(int userId) async {
    final data = await _apiClient.getJson(
      '/api/watchlist',
      query: {'userId': '$userId'},
    );

    return _readItems(data, WatchlistItem.fromJson);
  }

  Future<void> addToWatchlist({
    required int userId,
    required int tmdbId,
    required String mediaType,
    required String title,
    String? posterUrl,
    String? backdropUrl,
  }) async {
    await _apiClient.postJson(
      '/api/watchlist',
      body: {
        'userId': userId,
        'tmdbId': tmdbId,
        'mediaType': mediaType,
        'title': title,
        'posterUrl': posterUrl,
        'backdropUrl': backdropUrl,
      },
    );
  }

  Future<void> removeFromWatchlist({
    required int userId,
    required int tmdbId,
    required String mediaType,
  }) async {
    await _apiClient.deleteJson(
      '/api/watchlist',
      body: {'userId': userId, 'tmdbId': tmdbId, 'mediaType': mediaType},
    );
  }

  Future<List<WatchHistoryItem>> watchHistory(int userId) async {
    final data = await _apiClient.getJson(
      '/api/watch-history',
      query: {'userId': '$userId'},
    );

    return _readItems(data, WatchHistoryItem.fromJson);
  }

  Future<void> saveRating({
    required int userId,
    required int tmdbId,
    required String mediaType,
    required String value,
  }) async {
    await _apiClient.postJson(
      '/api/ratings',
      body: {
        'userId': userId,
        'tmdbId': tmdbId,
        'mediaType': mediaType,
        'value': value,
      },
    );
  }

  Future<Map<String, String>> ratings(int userId) async {
    final data = await _apiClient.getJson(
      '/api/ratings',
      query: {'userId': '$userId'},
    );
    final ratings = data['ratings'];
    if (ratings is! Map<String, dynamic>) return const {};

    return ratings.map((key, value) => MapEntry(key, '$value'));
  }

  List<T> _readItems<T>(
    Map<String, dynamic> data,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final items = data['items'];
    if (items is! List<dynamic>) return const [];

    return [
      for (final item in items)
        if (item is Map<String, dynamic>) fromJson(item),
    ];
  }

  void close() => _apiClient.close();
}
