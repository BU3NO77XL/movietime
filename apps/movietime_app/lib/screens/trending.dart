import 'dart:ui';

import 'package:flutter/material.dart';

import '../services/content_service.dart';
import '../widgets/home_bottom_nav.dart';
import '../widgets/logo_loader.dart';
import 'home.dart';
import 'mylist.dart';
import 'profile.dart';
import 'screen_transitions.dart';
import 'watch.dart';

class TrendingScreen extends StatefulWidget {
  const TrendingScreen({super.key});

  @override
  State<TrendingScreen> createState() => _TrendingScreenState();
}

class _TrendingScreenState extends State<TrendingScreen> {
  final ContentService _contentService = ContentService();
  bool _isLoading = true;
  String _filter = 'Tudo';
  List<_TrendingItem> _movies = const [];
  List<_TrendingItem> _series = const [];

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

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _contentService.tmdb('trending/movie/week', query: const {'language': 'pt-BR'}),
        _contentService.tmdb('trending/tv/week', query: const {'language': 'pt-BR'}),
      ]);
      final movies = _parse(results[0], 'movie');
      final series = _parse(results[1], 'tv');
      if (!mounted) return;
      setState(() {
        _movies = movies;
        _series = series;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  List<_TrendingItem> _parse(Map<String, dynamic> json, String type) {
    final results = json['results'];
    if (results is! List<dynamic>) return const [];
    return [
      for (final item in results)
        if (item is Map<String, dynamic>)
          _TrendingItem(
            tmdbId: (item['id'] as num?)?.toInt() ?? 0,
            mediaType: type,
            title: (item['title'] ?? item['name'] ?? 'Título').toString(),
            posterUrl: item['poster_path']?.toString() is String
                ? 'https://image.tmdb.org/t/p/w780${item['poster_path']}'
                : null,
            backdropUrl: item['backdrop_path']?.toString() is String
                ? 'https://image.tmdb.org/t/p/w1280${item['backdrop_path']}'
                : null,
            overview: item['overview']?.toString(),
          ),
    ].where((e) => e.tmdbId > 0).toList();
  }

  List<_TrendingItem> get _visible {
    switch (_filter) {
      case 'Filmes':
        return _movies;
      case 'Séries':
        return _series;
      default:
        return [..._movies, ..._series]..shuffle();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      bottomNavigationBar: HomeBottomNav(
        activeItem: HomeNavItemId.trending,
        onHomeTap: () => Navigator.of(context).pushReplacement(cinematicPageRoute(const Home())),
        onMyListTap: () => Navigator.of(context).pushReplacement(cinematicPageRoute(const MyListScreen())),
        onMyTimeTap: () => Navigator.of(context).pushReplacement(cinematicPageRoute(const ProfileScreen())),
        onTrendingTap: null,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              right: -175,
              top: -144,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 300, sigmaY: 300),
                child: Container(
                  width: 350,
                  height: 350,
                  decoration: const ShapeDecoration(
                    color: Color(0xFF2C2C2C),
                    shape: OvalBorder(),
                  ),
                ),
              ),
            ),
            if (_isLoading)
              const Center(child: LogoLoader())
            else
              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(22, 24, 22, 12),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Em Alta',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontFamily: 'Netflix Sans',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A1A),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                for (final label in ['Tudo', 'Filmes', 'Séries'])
                                  GestureDetector(
                                    onTap: () => setState(() => _filter = label),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: _filter == label ? Colors.white : Colors.transparent,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        label,
                                        style: TextStyle(
                                          color: _filter == label ? Colors.black : const Color(0xFF9E9E9E),
                                          fontSize: 12,
                                          fontFamily: 'Netflix Sans',
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 10,
                        childAspectRatio: 0.62,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = _visible[index];
                          return GestureDetector(
                            onTap: () => Navigator.of(context).push(
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
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: item.posterUrl == null
                                  ? Container(color: const Color(0xFF1A1A1A))
                                  : Image.network(item.posterUrl!, fit: BoxFit.cover),
                            ),
                          );
                        },
                        childCount: _visible.length,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _TrendingItem {
  const _TrendingItem({
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
