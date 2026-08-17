import 'api_client.dart';
import 'session_store.dart';

class AdminService {
  AdminService({ApiClient? apiClient, SessionStore? sessionStore})
    : _apiClient =
          apiClient ??
          ApiClient(
            accessTokenProvider:
                (sessionStore ?? const SessionStore()).accessToken,
          );

  final ApiClient _apiClient;

  Future<List<AdminUser>> users({required int requesterId}) async {
    final data = await _apiClient.getJson(
      '/api/admin/users',
      query: {'userId': requesterId.toString()},
    );

    final rawUsers = data['users'];
    if (rawUsers is! List) return const [];

    return rawUsers
        .whereType<Map<String, dynamic>>()
        .map(AdminUser.fromJson)
        .toList(growable: false);
  }

  Future<void> updateRole({
    required int requesterId,
    required int targetUserId,
    required String role,
  }) async {
    await _apiClient.patchJson(
      '/api/admin/role',
      body: {'userId': requesterId, 'targetUserId': targetUserId, 'role': role},
    );
  }

  Future<void> deleteHistory({
    required int requesterId,
    required int targetProfileId,
    required int tmdbId,
    required String mediaType,
  }) async {
    await _apiClient.deleteJson(
      '/api/admin/watch-history',
      body: {
        'userId': requesterId,
        'targetProfileId': targetProfileId,
        'tmdbId': tmdbId,
        'mediaType': mediaType,
      },
    );
  }

  Future<void> deleteRating({
    required int requesterId,
    required int targetProfileId,
    required int tmdbId,
    required String mediaType,
  }) async {
    await _apiClient.deleteJson(
      '/api/admin/ratings',
      body: {
        'userId': requesterId,
        'targetProfileId': targetProfileId,
        'tmdbId': tmdbId,
        'mediaType': mediaType,
      },
    );
  }

  void close() => _apiClient.close();
}

class AdminUser {
  const AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.createdAt,
    required this.movieCount,
    required this.seriesCount,
    required this.totalHistory,
    required this.ratingsCount,
    required this.ratings,
    required this.recentActivity,
    required this.preferences,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: _asInt(json['id']),
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'user',
      createdAt: json['createdAt']?.toString(),
      movieCount: _asInt(json['movieCount']),
      seriesCount: _asInt(json['seriesCount']),
      totalHistory: _asInt(json['totalHistory']),
      ratingsCount: _asInt(json['ratingsCount']),
      ratings: switch (json['ratings']) {
        final List<dynamic> values =>
          values
              .whereType<Map<String, dynamic>>()
              .map(AdminRating.fromJson)
              .toList(growable: false),
        _ => const [],
      },
      recentActivity: switch (json['recentActivity']) {
        final List<dynamic> values =>
          values
              .whereType<Map<String, dynamic>>()
              .map(AdminRecentActivity.fromJson)
              .toList(growable: false),
        _ => const [],
      },
      preferences: json['preferences'] is Map<String, dynamic>
          ? AdminUserPreferences.fromJson(
              json['preferences'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  final int id;
  final String name;
  final String email;
  final String role;
  final String? createdAt;
  final int movieCount;
  final int seriesCount;
  final int totalHistory;
  final int ratingsCount;
  final List<AdminRating> ratings;
  final List<AdminRecentActivity> recentActivity;
  final AdminUserPreferences? preferences;

  AdminUser copyWith({
    String? role,
    int? movieCount,
    int? seriesCount,
    int? totalHistory,
    int? ratingsCount,
    List<AdminRating>? ratings,
    List<AdminRecentActivity>? recentActivity,
  }) {
    return AdminUser(
      id: id,
      name: name,
      email: email,
      role: role ?? this.role,
      createdAt: createdAt,
      movieCount: movieCount ?? this.movieCount,
      seriesCount: seriesCount ?? this.seriesCount,
      totalHistory: totalHistory ?? this.totalHistory,
      ratingsCount: ratingsCount ?? this.ratingsCount,
      ratings: ratings ?? this.ratings,
      recentActivity: recentActivity ?? this.recentActivity,
      preferences: preferences,
    );
  }
}

class AdminRating {
  const AdminRating({
    required this.tmdbId,
    required this.mediaType,
    required this.value,
  });

  factory AdminRating.fromJson(Map<String, dynamic> json) {
    return AdminRating(
      tmdbId: _asInt(json['tmdb_id']),
      mediaType: json['media_type']?.toString() ?? '',
      value: json['value']?.toString() ?? '',
    );
  }

  final int tmdbId;
  final String mediaType;
  final String value;
}

class AdminRecentActivity {
  const AdminRecentActivity({
    required this.tmdbId,
    required this.mediaType,
    required this.title,
    required this.seasonNumber,
    required this.episodeNumber,
    required this.posterUrl,
    required this.watchedAt,
  });

  factory AdminRecentActivity.fromJson(Map<String, dynamic> json) {
    return AdminRecentActivity(
      tmdbId: _asInt(json['tmdb_id']),
      mediaType: json['media_type']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      seasonNumber: _asInt(json['season_number']),
      episodeNumber: _asInt(json['episode_number']),
      posterUrl: json['poster_url']?.toString(),
      watchedAt: json['watched_at']?.toString(),
    );
  }

  final int tmdbId;
  final String mediaType;
  final String title;
  final int seasonNumber;
  final int episodeNumber;
  final String? posterUrl;
  final String? watchedAt;
}

class AdminUserPreferences {
  const AdminUserPreferences({required this.avatarIndex, required this.genres});

  factory AdminUserPreferences.fromJson(Map<String, dynamic> json) {
    return AdminUserPreferences(
      avatarIndex: _asNullableInt(json['avatarIndex']),
      genres: switch (json['genres']) {
        final List<dynamic> values =>
          values
              .map((value) => value.toString())
              .where((value) => value.trim().isNotEmpty)
              .toList(growable: false),
        _ => const [],
      },
    );
  }

  final int? avatarIndex;
  final List<String> genres;
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int? _asNullableInt(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}
