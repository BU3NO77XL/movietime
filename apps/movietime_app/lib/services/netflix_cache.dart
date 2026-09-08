import 'content_service.dart';

class NetflixCache {
  NetflixCache._();

  static final Map<String, bool> _cache = {};

  static String _key(int tmdbId, String mediaType) => '$tmdbId:$mediaType';

  static bool? getCached(int tmdbId, String mediaType) {
    return _cache[_key(tmdbId, mediaType)];
  }

  static Future<bool> isOnNetflix(
    int tmdbId,
    String mediaType, {
    ContentService? contentService,
  }) async {
    final key = _key(tmdbId, mediaType);
    if (_cache.containsKey(key)) return _cache[key]!;

    // Verifica tipo oposto já cacheado (evita re-fetch quando tipo errado)
    final opposite = mediaType == 'tv' ? 'movie' : 'tv';
    final oppositeKey = _key(tmdbId, opposite);
    if (_cache.containsKey(oppositeKey)) {
      final v = _cache[oppositeKey]!;
      _cache[key] = v;
      return v;
    }

    try {
      final service = contentService ?? ContentService();
      final isSeries = mediaType == 'tv' || mediaType == 'series';
      final path = isSeries ? 'tv/$tmdbId/watch/providers' : 'movie/$tmdbId/watch/providers';
      final data = await service.tmdb(path);
      final results = data['results'];
      bool onNetflix = false;
      if (results is Map<String, dynamic>) {
        // TMDB retorna providers por país (ex: BR, US). Verifica qualquer país.
        for (final countryData in results.values) {
          if (countryData is Map<String, dynamic>) {
            final flatrate = countryData['flatrate'];
            if (flatrate is List) {
              if (flatrate.any((p) =>
                  p is Map<String, dynamic> &&
                  p['provider_name']?.toString().toLowerCase().contains('netflix') == true)) {
                onNetflix = true;
                break;
              }
            }
          }
        }
      }
      _cache[key] = onNetflix;
      // Propaga para tipo oposto também para evitar segundo fetch
      _cache[oppositeKey] = onNetflix;
      return onNetflix;
    } catch (_) {
      return false;
    }
  }
}
