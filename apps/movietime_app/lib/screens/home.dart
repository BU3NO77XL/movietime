import 'dart:ui';

import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/content_service.dart';
import '../widgets/home_bottom_nav.dart';
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
  _HomeHeroItem? _heroItem;
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
    _authService.close();
    _contentService.close();
    super.dispose();
  }

  Future<void> _loadHome() async {
    try {
      final responses = await Future.wait([
        _contentService.tmdb(
          'trending/all/week',
          query: const {'language': 'pt-BR'},
        ),
        _contentService.tmdb(
          'trending/movie/week',
          query: const {'language': 'pt-BR'},
        ),
        _contentService.tmdb(
          'movie/top_rated',
          query: const {'language': 'pt-BR', 'page': '1'},
        ),
      ]);

      final trendingAll = _parseHomeItems(responses[0], fallbackMediaType: null);
      final trendingMovies = _parseHomeItems(
        responses[1],
        fallbackMediaType: 'movie',
      );
      final topRatedMovies = _parseHomeItems(
        responses[2],
        fallbackMediaType: 'movie',
      );

      var continueWatching = <_HomePosterItem>[];
      try {
        final user = await _authService.profile();
        final history = await _contentService.watchHistory(user.id);
        continueWatching = [
          for (final item in history.take(12))
            _HomePosterItem(
              tmdbId: item.tmdbId,
              mediaType: _normalizeMediaType(item.mediaType),
              title: item.title,
              posterUrl: item.posterUrl,
              backdropUrl: item.backdropUrl,
              overview: null,
            ),
        ];
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _heroItem = trendingAll.isNotEmpty
            ? _HomeHeroItem.fromPosterItem(trendingAll.first)
            : null;
        _continueWatching = continueWatching;
        _trendingItems = trendingMovies.take(12).toList();
        _topTenItems = topRatedMovies.take(10).toList();
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
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
                            padding: const EdgeInsets.fromLTRB(21, 58, 16, 12),
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
                                      fontFamily: 'Inter',
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
                            padding: const EdgeInsets.symmetric(horizontal: 22),
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
                          const _SectionTitle(title: 'Continue Assistindo'),
                          const SizedBox(height: 12),
                          _PosterRow(
                            items: _continueWatching,
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
                  fontFamily: 'Inter',
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

        return Container(
          width: double.infinity,
          height: cardHeight,
          clipBehavior: Clip.antiAlias,
          decoration: ShapeDecoration(
            color: Colors.black,
            shape: RoundedRectangleBorder(
              side: BorderSide(
                width: 1,
                color: Colors.white.withValues(alpha: 0.10),
              ),
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
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: _RemoteBackdrop(
                  imageUrl: item?.backdropUrl,
                  fallbackAsset: 'assets/home/images/image-2687-1462.png',
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
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          item?.title ?? 'MovieTime',
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: titleFontSize,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                            height: 1.08,
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    if (genres.isNotEmpty)
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 4,
                        children: [
                          for (var index = 0; index < genres.length; index++) ...[
                            Text(
                              genres[index],
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: categoryFontSize,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            if (index != genres.length - 1)
                              Text(
                                '•',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: categoryFontSize,
                                ),
                              ),
                          ],
                        ],
                      )
                    else
                      Text(
                        item?.mediaLabel ?? 'Em destaque',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: categoryFontSize,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w400,
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
                                          fontFamily: 'Inter',
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
                                          fontFamily: 'Inter',
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
  const _RemoteBackdrop({required this.imageUrl, required this.fallbackAsset});

  final String? imageUrl;
  final String fallbackAsset;

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return Image.asset(fallbackAsset, fit: BoxFit.cover);
    }

    return Image.network(
      imageUrl!,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Image.asset(fallbackAsset, fit: BoxFit.cover),
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
          fontFamily: 'Inter',
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
  });

  final List<_HomePosterItem> items;
  final bool loading;
  final String emptyMessage;
  final ValueChanged<_HomePosterItem> onTap;
  final bool showRanking;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: loading
          ? ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: 4,
              separatorBuilder: (context, index) => const SizedBox(width: 16),
              itemBuilder: (context, index) => Container(
                width: 120,
                height: 180,
                decoration: ShapeDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
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
                    fontFamily: 'Inter',
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
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 120,
                        height: 180,
                        clipBehavior: Clip.antiAlias,
                        decoration: ShapeDecoration(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: item.posterUrl == null || item.posterUrl!.isEmpty
                            ? Container(color: const Color(0xFF1A1A1A))
                            : Image.network(
                                item.posterUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                  color: const Color(0xFF1A1A1A),
                                ),
                              ),
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
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w700,
                              height: 1,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _HomePosterItem {
  const _HomePosterItem({
    required this.tmdbId,
    required this.mediaType,
    required this.title,
    this.posterUrl,
    this.backdropUrl,
    this.overview,
  });

  final int tmdbId;
  final String mediaType;
  final String title;
  final String? posterUrl;
  final String? backdropUrl;
  final String? overview;
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
    );
  }

  final List<String> genres;

  String get mediaLabel => mediaType == 'tv' ? 'Série' : 'Filme';
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
        ),
  ].where((item) => item.tmdbId > 0).toList();
}

String _normalizeMediaType(String mediaType) {
  return mediaType == 'series' ? 'tv' : mediaType;
}

String? _tmdbImageUrl(String? path, {String size = 'w780'}) {
  if (path == null || path.isEmpty) return null;
  if (path.startsWith('http://') || path.startsWith('https://')) return path;
  return 'https://image.tmdb.org/t/p/$size$path';
}
