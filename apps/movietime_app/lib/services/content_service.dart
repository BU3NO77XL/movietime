import 'api_client.dart';
import 'content_models.dart';
import 'session_store.dart';

class ContentService {
  ContentService({ApiClient? apiClient, SessionStore? sessionStore})
    : _apiClient =
          apiClient ??
          ApiClient(
            accessTokenProvider:
                (sessionStore ?? const SessionStore()).accessToken,
          );

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> tmdb(
    String path, {
    Map<String, String?> query = const {},
  }) {
    return _apiClient.getJson('/api/content/$path', query: query);
  }

  Future<WatchlistResponse> watchlistData(int userId) async {
    final data = await _apiClient.getJson(
      '/api/watchlist',
      query: {'userId': '$userId'},
    );

    return WatchlistResponse.fromJson(data);
  }

  Future<List<WatchlistItem>> watchlist(int userId) async {
    return (await watchlistData(userId)).items;
  }

  Future<void> addToWatchlist({
    required int userId,
    required int tmdbId,
    required String mediaType,
    required String title,
    String? listName,
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
        'listName': listName,
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
    return watchHistoryForItem(userId);
  }

  Future<List<WatchHistoryItem>> watchHistoryForItem(
    int userId, {
    int? tmdbId,
    String? mediaType,
  }) async {
    final data = await _apiClient.getJson(
      '/api/watch-history',
      query: {
        'userId': '$userId',
        'tmdbId': tmdbId?.toString(),
        'mediaType': mediaType,
      },
    );

    return _readItems(data, WatchHistoryItem.fromJson);
  }

  Future<void> saveWatchHistory({
    required int userId,
    required int tmdbId,
    required String mediaType,
    required String title,
    int? seasonNumber,
    int? episodeNumber,
    int? totalSeasons,
    int? totalEpisodes,
    int? seasonEpisodes,
    int progressPercent = 0,
    String? posterUrl,
    String? backdropUrl,
  }) async {
    await _apiClient.postJson(
      '/api/watch-history',
      body: {
        'userId': userId,
        'tmdbId': tmdbId,
        'mediaType': mediaType,
        'title': title,
        'seasonNumber': seasonNumber,
        'episodeNumber': episodeNumber,
        'totalSeasons': totalSeasons,
        'totalEpisodes': totalEpisodes,
        'seasonEpisodes': seasonEpisodes,
        'progressPercent': progressPercent,
        'posterUrl': posterUrl,
        'backdropUrl': backdropUrl,
      },
    );
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

  Future<void> deleteRating({
    required int userId,
    required int tmdbId,
    required String mediaType,
  }) async {
    await _apiClient.deleteJson(
      '/api/ratings',
      body: {'userId': userId, 'tmdbId': tmdbId, 'mediaType': mediaType},
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
