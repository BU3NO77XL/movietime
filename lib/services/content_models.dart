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
    this.progressPercent = 0,
  });

  factory WatchHistoryItem.fromJson(Map<String, dynamic> json) {
    return WatchHistoryItem(
      tmdbId: json['tmdb_id'] as int,
      mediaType: json['media_type']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      posterUrl: json['poster_url']?.toString(),
      backdropUrl: json['backdrop_url']?.toString(),
      seasonNumber: json['season_number'] as int? ?? 0,
      episodeNumber: json['episode_number'] as int? ?? 0,
      progressPercent: json['progress_percent'] as int? ?? 0,
    );
  }

  final int seasonNumber;
  final int episodeNumber;
  final int progressPercent;
}
