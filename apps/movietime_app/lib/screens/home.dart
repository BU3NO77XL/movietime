import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/content_service.dart';
import '../services/content_models.dart';
import '../widgets/home_bottom_nav.dart';
import '../widgets/logo_loader.dart';
import '../widgets/netflix_badge.dart';
import 'home_search.dart';
import 'mylist.dart';
import 'profile.dart';
import 'screen_transitions.dart';
import 'watch.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final AuthService _authService = AuthService();
  final ContentService _contentService = ContentService();

  bool _isLoading = true;
  List<_HomeHeroItem> _heroItems = const [];
  int _heroIndex = 0;
  Timer? _heroRotationTimer;
  List<_HomePosterItem> _continueWatching = const [];
  List<_HomePosterItem> _trendingItems = const [];
  List<_HomePosterItem> _topTenItems = const [];

  @override
  void initState() {
    super.initState();
    _loadHome();
  }

  @override
  void dispose() {
    _heroRotationTimer?.cancel();
    _authService.close();
    _contentService.close();
    super.dispose();
  }

  _HomeHeroItem? get _heroItem {
    if (_heroItems.isEmpty) return null;
    final safeIndex = _heroIndex.clamp(0, _heroItems.length - 1);
    return _heroItems[safeIndex];
  }

  Future<void> _loadHome() async {
    try {
      final responses = await Future.wait([
        _contentService.tmdb(
          'trending/movie/week',
          query: const {'language': 'pt-BR'},
        ),
        _contentService.tmdb(
          'movie/top_rated',
          query: const {'language': 'pt-BR', 'page': '1'},
        ),
      ]);

      final trendingMovies = _parseHomeItems(
        responses[0],
        fallbackMediaType: 'movie',
      );
      final topRatedMovies = _parseHomeItems(
        responses[1],
        fallbackMediaType: 'movie',
      );
      final heroItems = await _buildHeroItems(trendingMovies.take(6).toList());
      await _precacheHeroAssets(heroItems.isEmpty ? null : heroItems.first);

      var continueWatching = <_HomePosterItem>[];
      try {
        final user = await _authService.profile();
        final history = await _contentService.watchHistory(user.id);
        continueWatching = await _buildContinueWatchingItems(history);
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _heroItems = heroItems;
        _heroIndex = 0;
        _continueWatching = continueWatching;
        _trendingItems = trendingMovies.take(12).toList();
        _topTenItems = topRatedMovies.take(10).toList();
        _isLoading = false;
      });
      _restartHeroRotation();
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _precacheHeroAssets(_HomeHeroItem? item) async {
    if (item == null || !mounted) return;

    final imageUrls = <String>{
      if (item.backdropUrl?.isNotEmpty == true) item.backdropUrl!,
      if (item.titleLogoUrl?.isNotEmpty == true) item.titleLogoUrl!,
    };

    for (final imageUrl in imageUrls) {
      try {
        await precacheImage(
          NetworkImage(imageUrl),
          context,
        ).timeout(const Duration(seconds: 12));
      } catch (_) {
        // O widget possui fallback local e o título possui fallback em texto.
      }
    }
  }

  Future<List<_HomeHeroItem>> _buildHeroItems(
    List<_HomePosterItem> items,
  ) async {
    if (items.isEmpty) return const [];

    final enriched = await Future.wait(items.map(_buildHeroItem));
    return enriched;
  }

  Future<_HomeHeroItem> _buildHeroItem(_HomePosterItem item) async {
    final isSeries = item.mediaType == 'tv';
    final pathPrefix = isSeries ? 'tv' : 'movie';

    try {
      final responses = await Future.wait([
        _contentService.tmdb(
          '$pathPrefix/${item.tmdbId}',
          query: const {'language': 'pt-BR'},
        ),
        _contentService.tmdb(
          '$pathPrefix/${item.tmdbId}/images',
          query: const {'include_image_language': 'pt,null,en'},
        ),
      ]);

      final details = responses[0];
      final images = responses[1];
      final title = (details['title'] ?? details['name'] ?? item.title)
          .toString();
      final backdropUrl =
          _tmdbImageUrl(details['backdrop_path']?.toString(), size: 'w1280') ??
          item.backdropUrl;
      final overview = details['overview']?.toString() ?? item.overview;
      final genres = switch (details['genres']) {
        final List<dynamic> values => [
          for (final genre in values)
            if (genre is Map<String, dynamic>) _genreNameFromJson(genre),
        ].whereType<String>().take(3).toList(),
        _ => const <String>[],
      };

      return _HomeHeroItem(
        tmdbId: item.tmdbId,
        mediaType: item.mediaType,
        title: title,
        posterUrl: item.posterUrl,
        backdropUrl: backdropUrl,
        overview: overview,
        genres: genres,
        titleLogoUrl: _resolveLogoUrl(images),
        isNetflix: _isNetflixNetwork(details['networks']),
      );
    } catch (_) {
      return _HomeHeroItem.fromPosterItem(item);
    }
  }

  String? _resolveLogoUrl(Map<String, dynamic> json) {
    final logos = json['logos'];
    if (logos is! List<dynamic> || logos.isEmpty) return null;

    final candidates = [
      for (final logo in logos)
        if (logo is Map<String, dynamic> &&
            (logo['file_path']?.toString().isNotEmpty ?? false))
          logo,
    ];
    if (candidates.isEmpty) return null;

    int languagePriority(String? code) {
      switch (code) {
        case 'pt':
          return 0;
        case null:
        case '':
          return 1;
        case 'en':
          return 2;
        default:
          return 3;
      }
    }

    candidates.sort((a, b) {
      final byLanguage = languagePriority(
        a['iso_639_1']?.toString(),
      ).compareTo(languagePriority(b['iso_639_1']?.toString()));
      if (byLanguage != 0) return byLanguage;

      final byVote = ((b['vote_average'] as num?)?.toDouble() ?? 0).compareTo(
        (a['vote_average'] as num?)?.toDouble() ?? 0,
      );
      if (byVote != 0) return byVote;

      return ((b['width'] as num?)?.toInt() ?? 0).compareTo(
        (a['width'] as num?)?.toInt() ?? 0,
      );
    });

    return _tmdbImageUrl(
      candidates.first['file_path']?.toString(),
      size: 'original',
    );
  }

  Future<List<_HomePosterItem>> _buildContinueWatchingItems(
    List<WatchHistoryItem> history,
  ) async {
    final latestByTmdbId = <int, WatchHistoryItem>{};
    for (final item in history) {
      final existing = latestByTmdbId[item.tmdbId];
      final itemDate = DateTime.tryParse(item.watchedAt ?? '') ?? DateTime(0);
      final existingDate =
          DateTime.tryParse(existing?.watchedAt ?? '') ?? DateTime(0);
      if (existing == null || !itemDate.isBefore(existingDate)) {
        latestByTmdbId[item.tmdbId] = item;
      }
    }

    return Future.wait(
      latestByTmdbId.values.take(12).map((historyItem) async {
        final mediaType = _normalizeMediaType(historyItem.mediaType);
        final pathPrefix = mediaType == 'tv' ? 'tv' : 'movie';
        Map<String, dynamic> details = const {};
        try {
          details = await _contentService.tmdb(
            '$pathPrefix/${historyItem.tmdbId}',
            query: const {'language': 'pt-BR'},
          );
        } catch (_) {}

        final date = (details['first_air_date'] ?? details['release_date'])
            ?.toString();
        return _HomePosterItem(
          tmdbId: historyItem.tmdbId,
          mediaType: mediaType,
          title: historyItem.title,
          posterUrl: historyItem.posterUrl,
          backdropUrl: historyItem.backdropUrl,
          overview: details['overview']?.toString(),
          year: date != null && date.length >= 4
              ? int.tryParse(date.substring(0, 4))
              : null,
          seasonNumber: historyItem.seasonNumber,
          episodeNumber: historyItem.episodeNumber,
          totalSeasons: historyItem.totalSeasons > 0
              ? historyItem.totalSeasons
              : (details['number_of_seasons'] as num?)?.toInt() ?? 0,
          totalEpisodes: historyItem.totalEpisodes > 0
              ? historyItem.totalEpisodes
              : (details['number_of_episodes'] as num?)?.toInt() ?? 0,
          seasonEpisodes: historyItem.seasonEpisodes,
          progressPercent: historyItem.progressPercent,
        );
      }),
    );
  }

  String? _genreNameFromJson(Map<String, dynamic> genre) {
    final genreId = (genre['id'] as num?)?.toInt();
    return genreId == null ? null : _tmdbGenreNamesPtBr[genreId];
  }

  void _restartHeroRotation() {
    _heroRotationTimer?.cancel();
    if (_heroItems.length <= 1) return;

    _heroRotationTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!mounted || _heroItems.length <= 1) return;
      setState(() {
        _heroIndex = (_heroIndex + 1) % _heroItems.length;
      });
    });
  }

  void _openWatch(_HomePosterItem item) {
    Navigator.of(context).push(
      cinematicPageRoute(
        WatchScreen(
          tmdbId: item.tmdbId,
          mediaType: item.mediaType,
          title: item.title,
          posterUrl: item.posterUrl,
          backdropUrl: item.backdropUrl,
          overview: item.overview,
          initialYear: item.year,
          initialVoteAverage: item.rating,
          seasonNumber: item.seasonNumber,
          episodeNumber: item.episodeNumber,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      bottomNavigationBar: HomeBottomNav(
        onMyListTap: () {
          Navigator.of(context).push(cinematicPageRoute(const MyListScreen()));
        },
        onMyTimeTap: () {
          Navigator.of(context).push(cinematicPageRoute(const ProfileScreen()));
        },
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrowScreen = constraints.maxWidth < 320;
            final headerLogoSize = isNarrowScreen ? 32.0 : 36.0;
            final headerIconSize = isNarrowScreen ? 28.0 : 32.0;
            final headerTitleSize = isNarrowScreen ? 20.0 : 24.0;
            final headerGap = isNarrowScreen ? 6.0 : 8.0;
            final headerIconGap = isNarrowScreen ? 8.0 : 12.0;
            const heroBlurHeight = 920.0;
            const heroBlurFadeHeight = 180.0;
            const chipInnerSideRadius = Radius.circular(12);
            const chipOuterSideRadius = Radius.circular(22);

            return Stack(
              fit: StackFit.expand,
              children: [
                const ColoredBox(color: Color(0xFF0D0D0D)),
                if (_isLoading)
                  const Center(child: LogoLoader())
                else
                  SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Stack(
                      children: [
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: heroBlurHeight,
                          child: ClipRect(
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                ImageFiltered(
                                  imageFilter: ImageFilter.blur(
                                    sigmaX: 48,
                                    sigmaY: 48,
                                  ),
                                  child: _RemoteBackdrop(
                                    imageUrl: _heroItem?.backdropUrl,
                                    fallbackAsset:
                                        'assets/home/images/image-4929e57e7d013ce2bef71f7eaf6511776f15bbaf.png',
                                  ),
                                ),
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: 0,
                                  height: heroBlurFadeHeight,
                                  child: const DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Color(0x000D0D0D),
                                          Color(0x660D0D0D),
                                          Color(0xFF0D0D0D),
                                        ],
                                        stops: [0.0, 0.72, 1.0],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                21,
                                58,
                                16,
                                12,
                              ),
                              child: Row(
                                children: [
                                  Image.asset(
                                    'assets/home/vectors/vector-2688-1528.png',
                                    width: headerLogoSize,
                                    height: headerLogoSize,
                                    fit: BoxFit.contain,
                                  ),
                                  SizedBox(width: headerGap),
                                  Expanded(
                                    child: Text(
                                      'Início',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: headerTitleSize,
                                        fontFamily: 'Netflix Sans',
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Image.asset(
                                    'assets/home/vectors/vector-2688-1548.png',
                                    width: headerIconSize,
                                    height: headerIconSize,
                                    fit: BoxFit.contain,
                                  ),
                                  SizedBox(width: headerIconGap),
                                  GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () {
                                      showModalBottomSheet<void>(
                                        context: context,
                                        enableDrag: true,
                                        isScrollControlled: true,
                                        useSafeArea: false,
                                        backgroundColor: Colors.transparent,
                                        barrierColor: Colors.black54,
                                        builder: (context) =>
                                            const _HomeSearchDrawer(),
                                      );
                                    },
                                    child: Image.asset(
                                      'assets/home/vectors/vector-2688-1549.png',
                                      width: headerIconSize,
                                      height: headerIconSize,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              height: 48,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                clipBehavior: Clip.none,
                                physics: const BouncingScrollPhysics(),
                                child: SizedBox(
                                  width: 418,
                                  height: 48,
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Positioned(
                                        left: 21,
                                        top: 2,
                                        child: _FilterChip(
                                          label: 'Séries',
                                          width: 75,
                                          radius: const BorderRadius.only(
                                            topLeft: chipOuterSideRadius,
                                            bottomLeft: chipOuterSideRadius,
                                            topRight: chipInnerSideRadius,
                                            bottomRight: chipInnerSideRadius,
                                          ),
                                        ),
                                      ),
                                      const Positioned(
                                        left: 103,
                                        top: 2,
                                        child: _FilterChip(
                                          label: 'Filmes',
                                          width: 77,
                                        ),
                                      ),
                                      const Positioned(
                                        left: 187,
                                        top: 2,
                                        child: _FilterChip(
                                          label: 'Novidades',
                                          width: 105,
                                        ),
                                      ),
                                      const Positioned(
                                        left: 299,
                                        top: 2,
                                        child: _FilterChip(
                                          label: 'Categorias',
                                          width: 119,
                                          hasArrow: true,
                                          radius: BorderRadius.only(
                                            topLeft: chipInnerSideRadius,
                                            bottomLeft: chipInnerSideRadius,
                                            topRight: chipOuterSideRadius,
                                            bottomRight: chipOuterSideRadius,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 22,
                              ),
                              child: _HeroCard(
                                item: _heroItem,
                                loading: _isLoading,
                                onWatch: _heroItem == null
                                    ? null
                                    : () => _openWatch(_heroItem!),
                                onMyListTap: () {
                                  Navigator.of(context).push(
                                    cinematicPageRoute(const MyListScreen()),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 24),
                            const _SectionTitle(title: 'Continuar assistindo'),
                            const SizedBox(height: 12),
                            _PosterRow(
                              items: _continueWatching,
                              showContinuePlay: true,
                              loading: _isLoading,
                              emptyMessage:
                                  'Quando você começar a assistir, os títulos aparecem aqui.',
                              onTap: _openWatch,
                            ),
                            const SizedBox(height: 24),
                            const _SectionTitle(title: 'Em Alta'),
                            const SizedBox(height: 12),
                            _PosterRow(
                              items: _trendingItems,
                              loading: _isLoading,
                              emptyMessage:
                                  'Não foi possível carregar os títulos em alta agora.',
                              onTap: _openWatch,
                            ),
                            const SizedBox(height: 24),
                            const _SectionTitle(title: 'Top 10 no Brasil'),
                            const SizedBox(height: 12),
                            _PosterRow(
                              items: _topTenItems,
                              loading: _isLoading,
                              emptyMessage:
                                  'Não foi possível carregar o Top 10 agora.',
                              onTap: _openWatch,
                              showRanking: true,
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    this.width,
    this.radius,
    this.hasArrow = false,
  });

  final String label;
  final double? width;
  final BorderRadius? radius;
  final bool hasArrow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 44,
      padding: EdgeInsets.only(left: 16, right: hasArrow ? 12 : 16),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0x2DB7B7B7),
        border: Border.all(
          width: 1,
          color: Colors.white.withValues(alpha: 0.30),
        ),
        borderRadius: radius ?? BorderRadius.circular(12),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                softWrap: false,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.80),
                  fontSize: 14,
                  fontFamily: 'Netflix Sans',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          if (hasArrow)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.white.withValues(alpha: 0.80),
                size: 12,
              ),
            ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.item,
    required this.loading,
    required this.onWatch,
    required this.onMyListTap,
  });

  final _HomeHeroItem? item;
  final bool loading;
  final VoidCallback? onWatch;
  final VoidCallback onMyListTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardHeight = (constraints.maxWidth * 487 / 345)
            .clamp(360.0, 487.0)
            .toDouble();
        final isCompactHero = constraints.maxWidth < 260;
        final titleFontSize = isCompactHero ? 24.0 : 30.0;
        final categoryFontSize = isCompactHero ? 13.0 : 14.0;
        final bottomSpacing = isCompactHero ? 10.0 : 16.0;
        final genres = item?.genres.take(3).toList() ?? const <String>[];
        final logoHeight = isCompactHero ? 56.0 : 72.0;

        return Container(
          width: double.infinity,
          height: cardHeight,
          clipBehavior: Clip.antiAlias,
          decoration: ShapeDecoration(
            color: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            shadows: const [
              BoxShadow(
                color: Color(0x28000000),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          foregroundDecoration: ShapeDecoration(
            shape: RoundedRectangleBorder(
              side: BorderSide(
                width: 1,
                color: Colors.white.withValues(alpha: 0.10),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 700),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  layoutBuilder: (currentChild, previousChildren) {
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        ...previousChildren,
                        ...?(currentChild == null ? null : [currentChild]),
                      ],
                    );
                  },
                  transitionBuilder: (child, animation) =>
                      FadeTransition(opacity: animation, child: child),
                  child: _RemoteBackdrop(
                    key: ValueKey(item?.tmdbId ?? 'hero-fallback'),
                    imageUrl: item?.backdropUrl ?? item?.posterUrl,
                    fallbackAsset: 'assets/home/images/image-2687-1462.png',
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 218,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(0.50, 0.00),
                      end: Alignment(0.50, 1.00),
                      colors: [Color(0x000F0E14), Color(0xFF0F0E14)],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (loading)
                      Container(
                        width: double.infinity,
                        height: 120,
                        alignment: Alignment.center,
                        child: const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                      )
                    else
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (item?.isNetflix == true) ...[
                            NetflixBadge(showSeries: item?.mediaType == 'tv'),
                            const SizedBox(height: 6),
                          ],
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 500),
                              switchInCurve: Curves.easeOut,
                              switchOutCurve: Curves.easeIn,
                              transitionBuilder: (child, animation) =>
                                  FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  ),
                              child: _HeroTitle(
                                key: ValueKey(
                                  '${item?.tmdbId ?? 'hero'}-${item?.titleLogoUrl ?? item?.title ?? 'MovieTime'}',
                                ),
                                title: item?.title ?? 'MovieTime',
                                titleLogoUrl: item?.titleLogoUrl,
                                titleFontSize: titleFontSize,
                                logoHeight: logoHeight,
                              ),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 8),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, animation) =>
                          FadeTransition(opacity: animation, child: child),
                      child: genres.isNotEmpty
                          ? Wrap(
                              key: ValueKey(
                                '${item?.tmdbId ?? 'hero'}-${genres.join('|')}',
                              ),
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 4,
                              children: [
                                for (
                                  var index = 0;
                                  index < genres.length;
                                  index++
                                ) ...[
                                  Text(
                                    genres[index],
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: categoryFontSize,
                                      fontFamily: 'Netflix Sans',
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  if (index != genres.length - 1)
                                    Text(
                                      '\u2022',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: categoryFontSize,
                                      ),
                                    ),
                                ],
                              ],
                            )
                          : Text(
                              item?.mediaLabel ?? 'Em destaque',
                              key: ValueKey(
                                '${item?.tmdbId ?? 'hero'}-media-label',
                              ),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: categoryFontSize,
                                fontFamily: 'Netflix Sans',
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: onWatch,
                              child: Container(
                                height: 40,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.play_arrow,
                                      color: Colors.black,
                                      size: 28,
                                    ),
                                    SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        'Assistir',
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 16,
                                          fontFamily: 'Netflix Sans',
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: onMyListTap,
                              child: Container(
                                height: 40,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xCC212121),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                    SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        'Minha Lista',
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontFamily: 'Netflix Sans',
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: bottomSpacing),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RemoteBackdrop extends StatelessWidget {
  const _RemoteBackdrop({
    super.key,
    required this.imageUrl,
    required this.fallbackAsset,
  });

  final String? imageUrl;
  final String fallbackAsset;

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return SizedBox.expand(
        child: Image.asset(fallbackAsset, fit: BoxFit.cover),
      );
    }

    return SizedBox.expand(
      child: Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) =>
            Image.asset(fallbackAsset, fit: BoxFit.cover),
      ),
    );
  }
}

class _HeroTitle extends StatelessWidget {
  const _HeroTitle({
    super.key,
    required this.title,
    required this.titleLogoUrl,
    required this.titleFontSize,
    required this.logoHeight,
  });

  final String title;
  final String? titleLogoUrl;
  final double titleFontSize;
  final double logoHeight;

  @override
  Widget build(BuildContext context) {
    final textFallback = Text(
      title,
      maxLines: 2,
      textAlign: TextAlign.center,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: Colors.white,
        fontSize: titleFontSize,
        fontFamily: 'Netflix Sans',
        fontWeight: FontWeight.w700,
        height: 1.08,
      ),
    );

    if (titleLogoUrl == null || titleLogoUrl!.isEmpty) {
      return textFallback;
    }

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: logoHeight),
      child: Image.network(
        titleLogoUrl!,
        height: logoHeight,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => textFallback,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return SizedBox(height: logoHeight);
        },
      ),
    );
  }
}

class _HomeSearchDrawer extends StatelessWidget {
  const _HomeSearchDrawer();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.96,
      minChildSize: 0.55,
      maxChildSize: 0.96,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: HomeSearchScreen(scrollController: scrollController),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontFamily: 'Netflix Sans',
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _PosterRow extends StatelessWidget {
  const _PosterRow({
    required this.items,
    required this.loading,
    required this.emptyMessage,
    required this.onTap,
    this.showRanking = false,
    this.showContinuePlay = false,
  });

  final List<_HomePosterItem> items;
  final bool loading;
  final String emptyMessage;
  final ValueChanged<_HomePosterItem> onTap;
  final bool showRanking;
  final bool showContinuePlay;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 226,
      child: loading
          ? ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: 4,
              separatorBuilder: (context, index) => const SizedBox(width: 16),
              itemBuilder: (context, index) => Container(
                width: 120,
                height: 180,
                alignment: Alignment.center,
                clipBehavior: Clip.antiAlias,
                decoration: ShapeDecoration(
                  color: const Color(0xFF1A1A1A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          : items.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: ShapeDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  emptyMessage,
                  style: const TextStyle(
                    color: Color(0xB3FFFFFF),
                    fontSize: 13,
                    fontFamily: 'Netflix Sans',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            )
          : ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                final item = items[index];
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(item),
                  child: SizedBox(
                    width: 120,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 120,
                              height: 180,
                              clipBehavior: Clip.antiAlias,
                              alignment: Alignment.center,
                              decoration: ShapeDecoration(
                                color: const Color(0xFF1A1A1A),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Hero(
                                tag:
                                    'watch-poster-${item.mediaType}-${item.tmdbId}',
                                child:
                                    item.posterUrl == null ||
                                        item.posterUrl!.isEmpty
                                    ? Container(color: const Color(0xFF1A1A1A))
                                    : Image.network(
                                        item.posterUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Container(
                                                  color: const Color(
                                                    0xFF1A1A1A,
                                                  ),
                                                ),
                                        loadingBuilder:
                                            (context, child, progress) {
                                              if (progress == null) {
                                                return child;
                                              }
                                              return const SizedBox(
                                                width: 18,
                                                height: 18,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Colors.white,
                                                    ),
                                              );
                                            },
                                      ),
                              ),
                            ),
                            if (_hasWatchProgress(item))
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 0,
                                child: _ContinueProgressBar(
                                  progress: _historyProgress(item),
                                ),
                              ),
                            if (showContinuePlay)
                              const Positioned.fill(
                                child: Center(child: _ContinuePlayButton()),
                              ),
                            if (showRanking)
                              Positioned(
                                left: -4,
                                bottom: -8,
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.18),
                                    fontSize: 72,
                                    fontFamily: 'Netflix Sans',
                                    fontWeight: FontWeight.w700,
                                    height: 1,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (item.year != null || _hasEpisodeProgress(item))
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 6,
                              left: 2,
                              right: 2,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    [
                                      if (item.year != null) '${item.year}',
                                      if (_hasEpisodeProgress(item))
                                        'S${item.seasonNumber}:E${item.episodeNumber}',
                                    ].join('  '),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF9E9E9E),
                                      fontSize: 11,
                                      fontFamily: 'Netflix Sans',
                                    ),
                                  ),
                                ),
                                _historyStatus(item),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _ContinuePlayButton extends StatelessWidget {
  const _ContinuePlayButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: const Color(0x8A000000),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.81),
      ),
      child: const Icon(
        Icons.play_arrow_rounded,
        color: Colors.white,
        size: 36,
      ),
    );
  }
}

class _ContinueProgressBar extends StatelessWidget {
  const _ContinueProgressBar({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final clampedProgress = progress.clamp(0.0, 1.0).toDouble();

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
      child: SizedBox(
        height: 4,
        width: double.infinity,
        child: ColoredBox(
          color: const Color(0xFF999897),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final progressWidth = constraints.maxWidth * clampedProgress;
              return Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: progressWidth,
                  height: double.infinity,
                  child: const ColoredBox(color: Color(0xFFE50914)),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

bool _hasEpisodeProgress(_HomePosterItem item) {
  return item.seasonNumber > 0 && item.episodeNumber > 0;
}

bool _hasWatchProgress(_HomePosterItem item) {
  return item.progressPercent > 0 || _hasEpisodeProgress(item);
}

int _historyCumulativeEpisode(_HomePosterItem item) {
  if (item.totalEpisodes <= 0 || item.totalSeasons <= 0) return 0;
  final averageEpisodes = (item.totalEpisodes / item.totalSeasons).ceil();
  return (item.seasonNumber - 1) * averageEpisodes + item.episodeNumber;
}

bool _historyIsComplete(_HomePosterItem item) {
  if (!_hasEpisodeProgress(item)) return false;
  final averageEpisodes = item.totalEpisodes > 0 && item.totalSeasons > 0
      ? (item.totalEpisodes / item.totalSeasons).ceil()
      : 0;
  final lastSeason = item.seasonNumber >= item.totalSeasons;
  final lastEpisode = item.seasonEpisodes > 0
      ? item.episodeNumber >= item.seasonEpisodes
      : averageEpisodes > 0 && item.episodeNumber >= averageEpisodes;
  return lastSeason && lastEpisode;
}

double _historyProgress(_HomePosterItem item) {
  if (_historyIsComplete(item)) return 1;
  final cumulative = _historyCumulativeEpisode(item);
  if (cumulative > 0 && item.totalEpisodes > 0) {
    return (cumulative / item.totalEpisodes).clamp(0.1, 1.0).toDouble();
  }
  return (item.progressPercent / 100).clamp(0.1, 1.0).toDouble();
}

Widget _historyStatus(_HomePosterItem item) {
  if (!_hasEpisodeProgress(item)) return const SizedBox.shrink();
  if (_historyIsComplete(item)) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0x3346D369),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'Completo',
        style: TextStyle(
          color: Color(0xFF46D369),
          fontSize: 9,
          fontFamily: 'Netflix Sans',
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
  final cumulative = _historyCumulativeEpisode(item);
  if (cumulative > 0 && item.totalEpisodes > 0) {
    return Text(
      'Ep. $cumulative/${item.totalEpisodes}',
      style: const TextStyle(
        color: Color(0xFF9E9E9E),
        fontSize: 9,
        fontFamily: 'Netflix Sans',
      ),
    );
  }
  return const SizedBox.shrink();
}

class _HomePosterItem {
  const _HomePosterItem({
    required this.tmdbId,
    required this.mediaType,
    required this.title,
    this.posterUrl,
    this.backdropUrl,
    this.overview,
    this.year,
    this.rating,
    this.seasonNumber = 0,
    this.episodeNumber = 0,
    this.totalSeasons = 0,
    this.totalEpisodes = 0,
    this.seasonEpisodes = 0,
    this.progressPercent = 0,
  });

  final int tmdbId;
  final String mediaType;
  final String title;
  final String? posterUrl;
  final String? backdropUrl;
  final String? overview;
  final int? year;
  final double? rating;
  final int seasonNumber;
  final int episodeNumber;
  final int totalSeasons;
  final int totalEpisodes;
  final int seasonEpisodes;
  final int progressPercent;
}

class _HomeHeroItem extends _HomePosterItem {
  const _HomeHeroItem({
    required super.tmdbId,
    required super.mediaType,
    required super.title,
    super.posterUrl,
    super.backdropUrl,
    super.overview,
    this.genres = const [],
    this.titleLogoUrl,
    this.isNetflix = false,
  });

  factory _HomeHeroItem.fromPosterItem(_HomePosterItem item) {
    return _HomeHeroItem(
      tmdbId: item.tmdbId,
      mediaType: item.mediaType,
      title: item.title,
      posterUrl: item.posterUrl,
      backdropUrl: item.backdropUrl,
      overview: item.overview,
      genres: const [],
      titleLogoUrl: null,
      isNetflix: false,
    );
  }

  final List<String> genres;
  final String? titleLogoUrl;
  final bool isNetflix;

  String get mediaLabel => mediaType == 'tv' ? 'S\u00e9rie' : 'Filme';
}

bool _isNetflixNetwork(dynamic networks) {
  if (networks is! List<dynamic>) return false;
  return networks.any(
    (network) =>
        network is Map<String, dynamic> &&
        network['name']?.toString().toLowerCase() == 'netflix',
  );
}

List<_HomePosterItem> _parseHomeItems(
  Map<String, dynamic> json, {
  required String? fallbackMediaType,
}) {
  final results = json['results'];
  if (results is! List<dynamic>) return const [];

  return [
    for (final item in results)
      if (item is Map<String, dynamic>)
        _HomePosterItem(
          tmdbId: (item['id'] as num?)?.toInt() ?? 0,
          mediaType: _normalizeMediaType(
            item['media_type']?.toString() ?? fallbackMediaType ?? 'movie',
          ),
          title: (item['title'] ?? item['name'] ?? 'Título').toString(),
          posterUrl: _tmdbImageUrl(item['poster_path']?.toString()),
          backdropUrl: _tmdbImageUrl(
            item['backdrop_path']?.toString(),
            size: 'w1280',
          ),
          overview: item['overview']?.toString(),
          year:
              ((item['release_date'] ?? item['first_air_date'])
                          ?.toString()
                          .length ??
                      0) >=
                  4
              ? int.tryParse(
                  (item['release_date'] ?? item['first_air_date'])
                      .toString()
                      .substring(0, 4),
                )
              : null,
          rating: (item['vote_average'] as num?)?.toDouble(),
        ),
  ].where((item) => item.tmdbId > 0).toList();
}

String _normalizeMediaType(String mediaType) {
  return mediaType == 'series' ? 'tv' : mediaType;
}

const Map<int, String> _tmdbGenreNamesPtBr = {
  12: 'Aventura',
  14: 'Fantasia',
  16: 'Anima\u00e7\u00e3o',
  18: 'Drama',
  27: 'Terror',
  28: 'A\u00e7\u00e3o',
  35: 'Com\u00e9dia',
  36: 'Hist\u00f3ria',
  37: 'Faroeste',
  53: 'Suspense',
  80: 'Crime',
  99: 'Document\u00e1rio',
  878: 'Fic\u00e7\u00e3o cient\u00edfica',
  9648: 'Mist\u00e9rio',
  10402: 'M\u00fasica',
  10749: 'Romance',
  10751: 'Fam\u00edlia',
  10752: 'Guerra',
  10759: 'A\u00e7\u00e3o e aventura',
  10762: 'Infantil',
  10763: 'Not\u00edcias',
  10764: 'Reality',
  10765: 'Sci-Fi e fantasia',
  10766: 'Novela',
  10767: 'Talk show',
  10768: 'Guerra e pol\u00edtica',
  10770: 'Cinema TV',
};

String? _tmdbImageUrl(String? path, {String size = 'w780'}) {
  if (path == null || path.isEmpty) return null;
  if (path.startsWith('http://') || path.startsWith('https://')) return path;
  return 'https://image.tmdb.org/t/p/$size$path';
}
