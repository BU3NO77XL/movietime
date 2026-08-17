import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/content_models.dart';
import '../services/content_service.dart';
import 'screen_transitions.dart';
import 'watch.dart';

class WatchSeriesMyListScreen extends StatefulWidget {
  const WatchSeriesMyListScreen({
    required this.item,
    this.history,
    this.contentService,
    super.key,
  });
  final WatchlistItem item;
  final WatchHistoryItem? history;
  final ContentService? contentService;
  static const _bg = Color(0xFF0D0D0D);
  static const _card = Color(0xFF1A1A1A);
  static const _muted = Color(0xFF525252);
  static const _lightMuted = Color(0xFF9E9E9E);
  static const _primary = Color(0xFFA259FF);
  static const _primaryDark = Color(0xFF562199);
  @override
  State<WatchSeriesMyListScreen> createState() =>
      _WatchSeriesMyListScreenState();
}

class _WatchSeriesMyListScreenState extends State<WatchSeriesMyListScreen> {
  late final ContentService _contentService =
      widget.contentService ?? ContentService();
  _SeriesPageData? _data;
  int? _selectedEpisode;
  String? _errorMessage;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _contentService.close();
    super.dispose();
  }

  Future<void> _load({int? selectedSeasonNumber}) async {
    try {
      final details = await _contentService.tmdb(
        'tv/${widget.item.tmdbId}',
        query: const {'language': 'pt-BR'},
      );
      final seasons = details['seasons'] is List
          ? (details['seasons'] as List)
                .whereType<Map<String, dynamic>>()
                .where((item) => (item['season_number'] as num?)?.toInt() != 0)
                .toList()
          : const <Map<String, dynamic>>[];
      final requestedSeason =
          selectedSeasonNumber ?? widget.history?.seasonNumber ?? 0;
      final season = seasons.firstWhere(
        (item) => (item['season_number'] as num?)?.toInt() == requestedSeason,
        orElse: () => seasons.isNotEmpty ? seasons.last : <String, dynamic>{},
      );
      final seasonNumber =
          (season['season_number'] as num?)?.toInt() ??
          (requestedSeason > 0 ? requestedSeason : 1);
      final seasonData = await _contentService.tmdb(
        'tv/${widget.item.tmdbId}/season/$seasonNumber',
        query: const {'language': 'pt-BR'},
      );
      if (!mounted) return;
      setState(() {
        _data = _SeriesPageData.fromJson(
          details,
          seasonData,
          widget.item,
          widget.history,
          seasonNumber,
        );
        _selectedEpisode =
            widget.history?.seasonNumber == requestedSeason &&
                widget.history?.episodeNumber != null
            ? widget.history!.episodeNumber
            : null;
        _errorMessage = null;
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _errorMessage = 'Não foi possível carregar a série agora.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    return Scaffold(
      backgroundColor: WatchSeriesMyListScreen._bg,
      body: _errorMessage != null
          ? Center(
              child: _Status(message: _errorMessage!, onRetry: _load),
            )
          : data == null
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : LayoutBuilder(
              builder: (context, constraints) {
                final scale = constraints.maxWidth / 390;
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: SizedBox(
                    width: constraints.maxWidth,
                    height: math.max(
                      constraints.maxHeight,
                      math.max(844, 460 + data.episodes.length * 96 + 110) *
                          scale,
                    ),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Transform.scale(
                        scale: scale,
                        alignment: Alignment.topCenter,
                        child: SizedBox(
                          width: 390,
                          height: math.max(
                            844,
                            460 + data.episodes.length * 96 + 110,
                          ),
                          child: _WatchSeriesCanvas(
                            data: data,
                            selectedEpisode:
                                _selectedEpisode ?? data.continueEpisode,
                            onSeasonChanged: (season) =>
                                _load(selectedSeasonNumber: season),
                            onEpisodeSelected: (episode) =>
                                setState(() => _selectedEpisode = episode),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _SeriesPageData {
  const _SeriesPageData({
    required this.tmdbId,
    required this.title,
    required this.backdropUrl,
    required this.posterUrl,
    required this.rating,
    required this.year,
    required this.runtime,
    required this.seasonNumber,
    required this.episodes,
    required this.continueEpisode,
    required this.seasonNumbers,
  });
  factory _SeriesPageData.fromJson(
    Map<String, dynamic> details,
    Map<String, dynamic> season,
    WatchlistItem item,
    WatchHistoryItem? history,
    int seasonNumber,
  ) {
    final backdropPath = details['backdrop_path']?.toString();
    final posterPath = details['poster_path']?.toString();
    final seasonNumbers = details['seasons'] is List
        ? (details['seasons'] as List)
              .whereType<Map<String, dynamic>>()
              .map((item) => (item['season_number'] as num?)?.toInt() ?? 0)
              .where((number) => number > 0)
              .toList()
        : <int>[];
    final episodes =
        (season['episodes'] is List ? season['episodes'] as List : const [])
            .whereType<Map<String, dynamic>>()
            .map(_SeriesEpisode.fromJson)
            .toList();
    return _SeriesPageData(
      tmdbId: item.tmdbId,
      title: (details['name'] ?? details['original_name'] ?? item.title)
          .toString(),
      backdropUrl: backdropPath == null || backdropPath.isEmpty
          ? item.backdropUrl
          : 'https://image.tmdb.org/t/p/w1280$backdropPath',
      posterUrl: posterPath == null || posterPath.isEmpty
          ? item.posterUrl
          : 'https://image.tmdb.org/t/p/w780$posterPath',
      rating: (details['vote_average'] as num?)?.toDouble() ?? 0,
      year: (details['first_air_date']?.toString() ?? '').split('-').first,
      runtime:
          ((details['episode_run_time'] as List?)?.firstOrNull as num?)
              ?.toInt() ??
          0,
      seasonNumber: seasonNumber,
      episodes: episodes,
      continueEpisode:
          history?.seasonNumber == seasonNumber &&
              history?.episodeNumber != null
          ? history!.episodeNumber
          : (episodes.isNotEmpty ? episodes.first.episodeNumber : 1),
      seasonNumbers: seasonNumbers,
    );
  }
  final int tmdbId;
  final String title;
  final String? backdropUrl;
  final String? posterUrl;
  final double rating;
  final String year;
  final int runtime;
  final int seasonNumber;
  final List<_SeriesEpisode> episodes;
  final int continueEpisode;
  final List<int> seasonNumbers;
}

class _SeriesEpisode {
  const _SeriesEpisode({
    required this.episodeNumber,
    required this.title,
    required this.stillUrl,
    required this.runtime,
  });
  factory _SeriesEpisode.fromJson(Map<String, dynamic> json) => _SeriesEpisode(
    episodeNumber: (json['episode_number'] as num?)?.toInt() ?? 0,
    title: (json['name'] ?? 'Epis\u00f3dio').toString(),
    stillUrl: json['still_path'] == null
        ? null
        : 'https://image.tmdb.org/t/p/w300${json['still_path']}',
    runtime: (json['runtime'] as num?)?.toInt() ?? 0,
  );
  final int episodeNumber;
  final String title;
  final String? stillUrl;
  final int runtime;
}

class _Status extends StatelessWidget {
  const _Status({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(message, style: const TextStyle(color: Colors.white)),
      const SizedBox(height: 12),
      TextButton(onPressed: onRetry, child: const Text('Tentar novamente')),
    ],
  );
}

void _openWatch(
  BuildContext context,
  _SeriesPageData data,
  int selectedEpisode,
) {
  Navigator.of(context).push(
    cinematicPageRoute(
      WatchScreen(
        tmdbId: data.tmdbId,
        mediaType: 'tv',
        title: data.title,
        posterUrl: data.posterUrl,
        backdropUrl: data.backdropUrl,
        seasonNumber: data.seasonNumber,
        episodeNumber: selectedEpisode,
      ),
    ),
  );
}

class _WatchSeriesCanvas extends StatelessWidget {
  const _WatchSeriesCanvas({
    required this.data,
    required this.selectedEpisode,
    required this.onSeasonChanged,
    required this.onEpisodeSelected,
  });

  final _SeriesPageData data;
  final int selectedEpisode;
  final ValueChanged<int> onSeasonChanged;
  final ValueChanged<int> onEpisodeSelected;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        const ColoredBox(color: WatchSeriesMyListScreen._bg),
        Positioned(
          left: 0,
          top: 0,
          width: 390,
          height: 548,
          child: Stack(
            fit: StackFit.expand,
            children: [
              data.backdropUrl == null
                  ? Image.asset(
                      'assets/watch_series_mylist/images/rectangle-395047-f352f779.png',
                      fit: BoxFit.cover,
                    )
                  : Image.network(
                      data.backdropUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Image.asset(
                        'assets/watch_series_mylist/images/rectangle-395047-f352f779.png',
                        fit: BoxFit.cover,
                      ),
                    ),
              const ColoredBox(color: Color(0x330D0D0D)),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x000D0D0D),
                      Color(0x080D0D0D),
                      Color(0x220D0D0D),
                      Color(0x520D0D0D),
                      Color(0x920D0D0D),
                      Color(0xD90D0D0D),
                      WatchSeriesMyListScreen._bg,
                    ],
                    stops: [0.0, 0.22, 0.42, 0.62, 0.78, 0.92, 1.0],
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 24,
          top: 306,
          width: 342,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontFamily: 'Netflix Sans',
                  fontWeight: FontWeight.w500,
                  height: 38 / 28,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 20,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Color(0xFFFDC943),
                        size: 16,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        data.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontFamily: 'Netflix Sans',
                          fontWeight: FontWeight.w400,
                          height: 18 / 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        data.year,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontFamily: 'Netflix Sans',
                          fontWeight: FontWeight.w400,
                          height: 18 / 14,
                        ),
                      ),
                      if (data.runtime > 0) ...[
                        const SizedBox(width: 8),
                        Text(
                          '${data.runtime} min',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontFamily: 'Netflix Sans',
                            fontWeight: FontWeight.w400,
                            height: 18 / 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 24,
          top: 405,
          width: 342,
          height: 40,
          child: _SeasonHeader(
            data: data,
            selectedEpisode: selectedEpisode,
            onSeasonChanged: onSeasonChanged,
          ),
        ),
        ...data.episodes.asMap().entries.map((entry) {
          final index = entry.key;
          final episode = entry.value;
          final isSelected = episode.episodeNumber == selectedEpisode;
          return Positioned(
            left: 22,
            top: 460 + index * 96,
            width: 342,
            height: 96,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onEpisodeSelected(episode.episodeNumber),
              child: _EpisodeCard(
                image:
                    episode.stillUrl ??
                    'assets/watch_series_mylist/images/rectangle-395048-957b6c88.png',
                title: episode.title,
                meta:
                    'E${episode.episodeNumber} . ${episode.runtime > 0 ? episode.runtime : '--'} m',
                progressWidth: isSelected ? 52 : 0,
                filled: isSelected,
              ),
            ),
          );
        }),
        Positioned(
          left: 24,
          top: 460 + data.episodes.length * 96 + 8,
          width: 342,
          height: 50,
          child: _ContinueButton(
            onTap: () => _openWatch(context, data, selectedEpisode),
          ),
        ),
      ],
    );
  }
}

class _SeasonHeader extends StatelessWidget {
  const _SeasonHeader({
    required this.data,
    required this.selectedEpisode,
    required this.onSeasonChanged,
  });

  final _SeriesPageData data;
  final int selectedEpisode;
  final ValueChanged<int> onSeasonChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Epis\u00f3dio ${data.continueEpisode}',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontFamily: 'Netflix Sans',
            fontWeight: FontWeight.w600,
            height: 34 / 24,
          ),
        ),
        const Spacer(),
        Container(
          width: 121,
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: ShapeDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [WatchSeriesMyListScreen._card, Color(0x330D0D0D)],
            ),
            shape: RoundedRectangleBorder(
              side: const BorderSide(width: 1, color: Color(0xFF2C2C2C)),
              borderRadius: BorderRadius.circular(40),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: data.seasonNumbers.contains(data.seasonNumber)
                  ? data.seasonNumber
                  : null,
              hint: const Text(
                'Temporada',
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
              ),
              dropdownColor: WatchSeriesMyListScreen._card,
              selectedItemBuilder: (context) => data.seasonNumbers
                  .map(
                    (season) => Align(
                      alignment: Alignment.centerLeft,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Temporada $season',
                          maxLines: 1,
                          softWrap: false,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              isExpanded: true,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: WatchSeriesMyListScreen._lightMuted,
                size: 18,
              ),
              style: const TextStyle(
                color: WatchSeriesMyListScreen._lightMuted,
                fontSize: 12,
                fontFamily: 'Netflix Sans',
                fontWeight: FontWeight.w500,
              ),
              items: data.seasonNumbers
                  .map(
                    (season) => DropdownMenuItem<int>(
                      value: season,
                      child: Text('Temporada $season'),
                    ),
                  )
                  .toList(),
              onChanged: (season) {
                if (season != null && season != data.seasonNumber) {
                  onSeasonChanged(season);
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _EpisodeCard extends StatelessWidget {
  const _EpisodeCard({
    required this.image,
    required this.title,
    required this.meta,
    required this.progressWidth,
    this.filled = false,
  });

  final String image;
  final String title;
  final String meta;
  final double progressWidth;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 342,
      height: 96,
      padding: const EdgeInsets.all(10),
      decoration: filled
          ? ShapeDecoration(
              color: WatchSeriesMyListScreen._card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            )
          : const BoxDecoration(
              border: Border(
                bottom: BorderSide(width: 1, color: Color(0x33FFFFFF)),
              ),
            ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: image.startsWith('http')
                ? Image.network(
                    image,
                    width: 115,
                    height: 76,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const ColoredBox(
                      color: Color(0xFF262626),
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: Color(0xFF525252),
                      ),
                    ),
                  )
                : Image.asset(image, width: 115, height: 76, fit: BoxFit.cover),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: filled ? 1.5 : 7),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontFamily: 'Netflix Sans',
                      fontWeight: FontWeight.w500,
                      height: 22 / 14,
                    ),
                  ),
                  SizedBox(height: filled ? 1 : 5),
                  Text(
                    meta,
                    style: const TextStyle(
                      color: WatchSeriesMyListScreen._muted,
                      fontSize: 12,
                      fontFamily: 'Netflix Sans',
                      fontWeight: FontWeight.w500,
                      height: 16 / 12,
                    ),
                  ),
                  if (filled) ...[
                    const SizedBox(height: 11),
                    SizedBox(
                      width: 81,
                      height: 3,
                      child: Stack(
                        children: [
                          Container(
                            width: 81,
                            height: 3,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.40),
                              borderRadius: BorderRadius.circular(2.5),
                            ),
                          ),
                          Container(
                            width: progressWidth,
                            height: 3,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(2.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContinueButton extends StatefulWidget {
  const _ContinueButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_ContinueButton> createState() => _ContinueButtonState();
}

class _ContinueButtonState extends State<_ContinueButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => setState(() => _pressed = true),
      onPointerCancel: (_) => setState(() => _pressed = false),
      onPointerUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.975 : 1,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: Container(
          height: 50,
          decoration: ShapeDecoration(
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                WatchSeriesMyListScreen._primary,
                WatchSeriesMyListScreen._primaryDark,
              ],
            ),
            shape: RoundedRectangleBorder(
              side: const BorderSide(width: 1, color: Color(0xFFC49EFF)),
              borderRadius: BorderRadius.circular(40),
            ),
            shadows: const [
              BoxShadow(
                color: Color(0x33A259FF),
                blurRadius: 10,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              'Continue assistindo',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontFamily: 'Netflix Sans',
                fontWeight: FontWeight.w500,
                height: 22 / 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
