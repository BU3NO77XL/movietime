class WatchlistResponse {
  const WatchlistResponse({this.listName, this.items = const []});

  factory WatchlistResponse.fromJson(Map<String, dynamic> json) {
    return WatchlistResponse(
      listName: json['listName']?.toString(),
      items: switch (json['items']) {
        final List<dynamic> value => [
          for (final item in value)
            if (item is Map<String, dynamic>) WatchlistItem.fromJson(item),
        ],
        _ => const [],
      },
    );
  }

  final String? listName;
  final List<WatchlistItem> items;
}

class WatchlistItem {
  const WatchlistItem({
    required this.tmdbId,
    required this.mediaType,
    required this.title,
    this.posterUrl,
    this.backdropUrl,
  });

  factory WatchlistItem.fromJson(Map<String, dynamic> json) {
    return WatchlistItem(
      tmdbId: json['tmdb_id'] as int,
      mediaType: json['media_type']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      posterUrl: json['poster_url']?.toString(),
      backdropUrl: json['backdrop_url']?.toString(),
    );
  }

  final int tmdbId;
  final String mediaType;
  final String title;
  final String? posterUrl;
  final String? backdropUrl;
}

class WatchHistoryItem extends WatchlistItem {
  const WatchHistoryItem({
    required super.tmdbId,
    required super.mediaType,
    required super.title,
    super.posterUrl,
    super.backdropUrl,
    this.seasonNumber = 0,
    this.episodeNumber = 0,
    this.totalSeasons = 0,
    this.totalEpisodes = 0,
    this.seasonEpisodes = 0,
    this.progressPercent = 0,
    this.watchedAt,
  });

  factory WatchHistoryItem.fromJson(Map<String, dynamic> json) {
    return WatchHistoryItem(
      tmdbId: json['tmdb_id'] as int,
      mediaType: json['media_type']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      posterUrl: json['poster_url']?.toString(),
      backdropUrl: json['backdrop_url']?.toString(),
      seasonNumber: (json['season_number'] as num?)?.toInt() ?? 0,
      episodeNumber: (json['episode_number'] as num?)?.toInt() ?? 0,
      totalSeasons: (json['total_seasons'] as num?)?.toInt() ?? 0,
      totalEpisodes: (json['total_episodes'] as num?)?.toInt() ?? 0,
      seasonEpisodes: (json['season_episodes'] as num?)?.toInt() ?? 0,
      progressPercent: (json['progress_percent'] as num?)?.toInt() ?? 0,
      watchedAt: json['watched_at']?.toString(),
    );
  }

  final int seasonNumber;
  final int episodeNumber;
  final int totalSeasons;
  final int totalEpisodes;
  final int seasonEpisodes;
  final int progressPercent;
  final String? watchedAt;
}
