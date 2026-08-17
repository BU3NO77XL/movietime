import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../services/content_service.dart';
import 'screen_transitions.dart';
import 'watch.dart';

class HomeSearchScreen extends StatefulWidget {
  const HomeSearchScreen({
    super.key,
    this.scrollController,
    this.contentService,
  });

  final ScrollController? scrollController;
  final ContentService? contentService;

  static const bg = Color(0xFF0D0D0D);
  static const card = Color(0xFF1A1A1A);
  static const border = Color(0xFF262626);
  static const muted = Color(0xFF525252);
  static const lightMuted = Color(0xFF9E9E9E);
  static const primary = Color(0xFFA259FF);
  static const primaryDark = Color(0xFF562199);

  @override
  State<HomeSearchScreen> createState() => _HomeSearchScreenState();
}

class _HomeSearchScreenState extends State<HomeSearchScreen> {
  static const _typeFilters = ['Tudo', 'Filmes', 'Séries', 'Artistas'];

  late final ContentService _contentService =
      widget.contentService ?? ContentService();
  late final bool _ownsService = widget.contentService == null;

  final _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';
  int _searchSeq = 0;
  int _browseSeq = 0;
  int _selectedType = 0;
  int _selectedCategory = 0;
  bool _categoryFilterOpen = false;
  bool _sortFilterOpen = false;
  bool _gridView = true;
  bool _isBrowsingLoading = true;
  bool _isLoadingMore = false;
  bool _hasMoreBrowse = false;
  int _browsePage = 1;
  String _selectedSort = 'Mais populares';
  bool _isSearching = false;
  bool _isTypingArtistsLoading = false;

  List<_Genre> _genres = const [_Genre(id: null, name: 'Todas')];
  List<_SearchTitle> _browseTitles = const [];
  List<_SearchArtist> _browseArtists = const [];
  List<_SearchTitle> _typingTitles = const [];
  List<_SearchArtist> _typingArtists = const [];

  static const _sortOptions = [
    'Mais populares',
    'Melhor avaliados',
    'Mais recentes',
  ];

  @override
  void initState() {
    super.initState();
    _loadGenres();
    _loadBrowse();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    if (_ownsService) _contentService.close();
    super.dispose();
  }

  bool get _isArtistsType => _typeFilters[_selectedType] == 'Artistas';

  List<_SearchTitle> get _visibleTitles {
    return _browseTitles;
  }

  Future<void> _loadGenres() async {
    try {
      final responses = await Future.wait([
        _contentService.tmdb(
          'genre/movie/list',
          query: const {'language': 'pt-BR'},
        ),
        _contentService.tmdb(
          'genre/tv/list',
          query: const {'language': 'pt-BR'},
        ),
      ]);
      final genresById = <int, String>{};
      for (final data in responses) {
        final genres = data['genres'];
        if (genres is! List<dynamic>) continue;
        for (final genre in genres) {
          if (genre is! Map<String, dynamic>) continue;
          final id = (genre['id'] as num?)?.toInt();
          final name = genre['name']?.toString();
          if (id != null && name != null && name.isNotEmpty) {
            genresById[id] = name;
          }
        }
      }
      final genres = [
        const _Genre(id: null, name: 'Todas'),
        for (final entry in genresById.entries)
          _Genre(id: entry.key, name: entry.value),
      ];
      if (!mounted) return;
      setState(() => _genres = genres);
    } catch (_) {
      if (!mounted) return;
      setState(() => _genres = const [_Genre(id: null, name: 'Todas')]);
    }
  }

  Future<void> _loadBrowse({bool loadMore = false}) async {
    final seq = ++_browseSeq;
    if (!mounted) return;
    final page = loadMore ? _browsePage + 1 : 1;
    setState(() {
      _isBrowsingLoading = !loadMore;
      _isLoadingMore = loadMore;
      if (!loadMore) {
        _browsePage = 1;
        _hasMoreBrowse = false;
      }
    });
    try {
      final type = _typeFilters[_selectedType];
      if (type == 'Artistas') {
        final data = await _contentService.tmdb(
          'trending/person/week',
          query: const {'language': 'pt-BR'},
        );
        if (!mounted || seq != _browseSeq) return;
        setState(() {
          final parsed = _parseArtists(data);
          _browseArtists = loadMore ? [..._browseArtists, ...parsed] : parsed;
          _browseTitles = const [];
          _isBrowsingLoading = false;
          _isLoadingMore = false;
          _browsePage = page;
          _hasMoreBrowse = false;
        });
      } else {
        final responses = await _browseResponses(type, page);
        final parsed = [
          for (final response in responses)
            ..._parseTitles(response.data, defaultType: response.mediaType),
        ];
        final totalPages = responses.isEmpty
            ? 1
            : responses
                  .map((response) => response.totalPages)
                  .reduce((a, b) => a > b ? a : b);
        if (!mounted || seq != _browseSeq) return;
        setState(() {
          _browseTitles = loadMore
              ? _mergeTitles(_browseTitles, parsed)
              : parsed;
          _browseArtists = const [];
          _isBrowsingLoading = false;
          _isLoadingMore = false;
          _browsePage = page;
          _hasMoreBrowse = page < totalPages;
        });
      }
    } catch (_) {
      if (!mounted || seq != _browseSeq) return;
      setState(() {
        _browseTitles = const [];
        _browseArtists = const [];
        _isBrowsingLoading = false;
        _isLoadingMore = false;
        _hasMoreBrowse = false;
      });
    }
  }

  Future<List<_BrowseResponse>> _browseResponses(String type, int page) async {
    final selectedId =
        _selectedCategory > 0 && _selectedCategory < _genres.length
        ? _genres[_selectedCategory].id
        : null;
    final useDiscover = selectedId != null || _selectedSort != 'Mais populares';
    final mediaTypes = switch (type) {
      'Filmes' => const ['movie'],
      'Séries' => const ['tv'],
      _ => const ['movie', 'tv'],
    };

    return Future.wait(
      mediaTypes.map((mediaType) async {
        final query = <String, String>{'language': 'pt-BR', 'page': '$page'};
        String path;
        if (!useDiscover && mediaTypes.length == 1) {
          path = 'trending/$mediaType/week';
          query.remove('page');
        } else if (!useDiscover && mediaTypes.length == 2) {
          path = 'trending/$mediaType/week';
          query.remove('page');
        } else {
          path = 'discover/$mediaType';
          query['sort_by'] = switch (_selectedSort) {
            'Melhor avaliados' => 'vote_average.desc',
            'Mais recentes' =>
              mediaType == 'movie'
                  ? 'primary_release_date.desc'
                  : 'first_air_date.desc',
            _ => 'popularity.desc',
          };
          if (_selectedSort == 'Melhor avaliados') {
            query['vote_count.gte'] = '50';
          }
          if (selectedId != null) query['with_genres'] = '$selectedId';
        }
        final data = await _contentService.tmdb(path, query: query);
        return _BrowseResponse(
          data: data,
          mediaType: mediaType,
          totalPages: (data['total_pages'] as num?)?.toInt() ?? 1,
        );
      }),
    );
  }

  List<_SearchTitle> _mergeTitles(
    List<_SearchTitle> current,
    List<_SearchTitle> next,
  ) {
    final result = [...current];
    for (final item in next) {
      if (!result.any(
        (existing) =>
            existing.tmdbId == item.tmdbId &&
            existing.mediaType == item.mediaType,
      )) {
        result.add(item);
      }
    }
    return result;
  }

  void _onSelectType(int index) {
    setState(() => _selectedType = index);
    _loadBrowse();
  }

  void _onSelectCategory(int index) {
    setState(() {
      _selectedCategory = index;
      _categoryFilterOpen = false;
    });
    _loadBrowse();
  }

  void _onSelectSort(String value) {
    setState(() {
      _selectedSort = value;
      _sortFilterOpen = false;
    });
    _loadBrowse();
  }

  void _onQueryChanged(String value) {
    setState(() => _query = value);
    _debounce?.cancel();
    final normalized = value.trim();
    if (normalized.isEmpty) {
      setState(() {
        _typingTitles = const [];
        _typingArtists = const [];
        _isSearching = false;
        _isTypingArtistsLoading = false;
      });
      return;
    }
    _debounce = Timer(
      const Duration(milliseconds: 350),
      () => _runSearch(normalized),
    );
  }

  Future<void> _runSearch(String query) async {
    final seq = ++_searchSeq;
    setState(() => _isSearching = true);
    try {
      final data = await _contentService.tmdb(
        'search/multi',
        query: {'language': 'pt-BR', 'query': query},
      );
      if (!mounted || seq != _searchSeq) return;
      final titles = _parseSearchTitles(data);
      setState(() {
        _typingTitles = titles;
        _typingArtists = const [];
        _isSearching = false;
      });
      if (titles.isEmpty) return;
      setState(() => _isTypingArtistsLoading = true);
      try {
        final first = titles.first;
        final credits = await _contentService.tmdb(
          first.mediaType == 'tv'
              ? 'tv/${first.tmdbId}/credits'
              : 'movie/${first.tmdbId}/credits',
          query: const {'language': 'pt-BR'},
        );
        if (!mounted || seq != _searchSeq) return;
        setState(() {
          _typingArtists = _parseCreditsCast(credits);
          _isTypingArtistsLoading = false;
        });
      } catch (_) {
        if (!mounted || seq != _searchSeq) return;
        setState(() => _isTypingArtistsLoading = false);
      }
    } catch (_) {
      if (!mounted || seq != _searchSeq) return;
      setState(() {
        _typingTitles = const [];
        _typingArtists = const [];
        _isSearching = false;
        _isTypingArtistsLoading = false;
      });
    }
  }

  void _onClear() {
    _debounce?.cancel();
    _controller.clear();
    setState(() {
      _query = '';
      _typingTitles = const [];
      _typingArtists = const [];
      _isSearching = false;
      _isTypingArtistsLoading = false;
    });
  }

  void _openTitle(_SearchTitle item) {
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
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTyping = _query.trim().isNotEmpty;
    final categoryLabel =
        _genres[_selectedCategory.clamp(0, _genres.length - 1)].name;

    return Scaffold(
      backgroundColor: HomeSearchScreen.bg,
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
            SingleChildScrollView(
              controller: widget.scrollController,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(25, 18, 24, 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: ShapeDecoration(
                        color: HomeSearchScreen.muted,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Buscar',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontFamily: 'Netflix Sans',
                      fontWeight: FontWeight.w600,
                      height: 1.42,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _SearchField(
                    controller: _controller,
                    onChanged: _onQueryChanged,
                    onClear: _query.isEmpty
                        ? null
                        : () {
                            _onClear();
                          },
                  ),
                  if (isTyping) ...[
                    const SizedBox(height: 15),
                    _TypingSearchResults(
                      titles: _typingTitles,
                      artists: _typingArtists,
                      searching: _isSearching,
                      artistsLoading: _isTypingArtistsLoading,
                      onTitleTap: _openTitle,
                    ),
                  ] else ...[
                    const SizedBox(height: 20),
                    _CategoryChips(
                      categories: _typeFilters,
                      selectedIndex: _selectedType,
                      onSelect: _onSelectType,
                    ),
                    const SizedBox(height: 20),
                    _SearchViewToggles(
                      onSettingsTap: () {
                        setState(() {
                          _categoryFilterOpen = !_categoryFilterOpen;
                          _sortFilterOpen = false;
                        });
                      },
                      onSortTap: () => setState(() {
                        _sortFilterOpen = !_sortFilterOpen;
                        _categoryFilterOpen = false;
                      }),
                      categoryLabel: categoryLabel,
                      categoryActive: _selectedCategory > 0,
                      sortLabel: _selectedSort,
                      sortActive: _selectedSort != 'Mais populares',
                      viewLabel: _gridView ? 'Grade' : 'Lista',
                      viewActive: !_gridView,
                      onViewTap: () => setState(() => _gridView = !_gridView),
                    ),
                    const SizedBox(height: 20),
                    if (_isBrowsingLoading)
                      const Padding(
                        padding: EdgeInsets.only(top: 48),
                        child: Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      )
                    else if (_gridView)
                      _SearchGrid(
                        titles: _visibleTitles,
                        artists: _browseArtists,
                        isArtists: _isArtistsType,
                        onTitleTap: _openTitle,
                      )
                    else
                      _SearchList(
                        titles: _visibleTitles,
                        artists: _browseArtists,
                        isArtists: _isArtistsType,
                        onTitleTap: _openTitle,
                      ),
                    if (!_isArtistsType && _hasMoreBrowse)
                      _SearchLoadMore(
                        loading: _isLoadingMore,
                        onTap: () => _loadBrowse(loadMore: true),
                      ),
                  ],
                ],
              ),
            ),
            if (_categoryFilterOpen && !isTyping)
              Positioned.fill(
                child: _CategoryFilterModal(
                  options: _genres,
                  selectedIndex: _selectedCategory,
                  onClose: () => setState(() => _categoryFilterOpen = false),
                  onSelect: _onSelectCategory,
                ),
              ),
            if (_sortFilterOpen && !isTyping)
              Positioned.fill(
                child: _SortFilterModal(
                  options: _sortOptions,
                  selectedValue: _selectedSort,
                  onClose: () => setState(() => _sortFilterOpen = false),
                  onSelect: _onSelectSort,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: ShapeDecoration(
        color: HomeSearchScreen.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 15),
          const Icon(Icons.search_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: true,
              cursorColor: Colors.white,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontFamily: 'Netflix Sans',
                fontWeight: FontWeight.w500,
                height: 1.57,
              ),
              decoration: const InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: 'Artistas, Filmes, Séries ...',
                hintStyle: TextStyle(
                  color: HomeSearchScreen.muted,
                  fontSize: 14,
                  fontFamily: 'Netflix Sans',
                  fontWeight: FontWeight.w500,
                  height: 1.57,
                ),
              ),
            ),
          ),
          if (onClear != null)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onClear,
              child: const SizedBox(
                width: 44,
                height: 50,
                child: Icon(
                  Icons.close_rounded,
                  color: HomeSearchScreen.lightMuted,
                  size: 18,
                ),
              ),
            )
          else
            const SizedBox(width: 15),
        ],
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.categories,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<String> categories;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            for (var index = 0; index < categories.length; index++) ...[
              _CategoryChip(
                label: categories[index],
                selected: selectedIndex == index,
                onTap: () => onSelect(index),
              ),
              if (index < categories.length - 1) const SizedBox(width: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: ShapeDecoration(
          gradient: selected
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    HomeSearchScreen.primary,
                    HomeSearchScreen.primaryDark,
                  ],
                )
              : const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [HomeSearchScreen.card, Color(0x330D0D0D)],
                ),
          shape: RoundedRectangleBorder(
            side: BorderSide(
              width: 1,
              color: selected ? Colors.transparent : HomeSearchScreen.border,
            ),
            borderRadius: BorderRadius.circular(40),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : HomeSearchScreen.lightMuted,
              fontSize: 14,
              fontFamily: 'Netflix Sans',
              fontWeight: FontWeight.w500,
              height: 1.57,
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchViewToggles extends StatelessWidget {
  const _SearchViewToggles({
    required this.onSettingsTap,
    required this.onSortTap,
    required this.categoryLabel,
    required this.categoryActive,
    required this.sortLabel,
    required this.sortActive,
    required this.viewLabel,
    required this.viewActive,
    required this.onViewTap,
  });

  final VoidCallback onSettingsTap;
  final VoidCallback onSortTap;
  final String categoryLabel;
  final bool categoryActive;
  final String sortLabel;
  final bool sortActive;
  final String viewLabel;
  final bool viewActive;
  final VoidCallback onViewTap;

  @override
  Widget build(BuildContext context) {
    final categoryColor = categoryActive
        ? Colors.white
        : HomeSearchScreen.muted;
    final viewColor = viewActive ? Colors.white : HomeSearchScreen.muted;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _SearchToggleAction(
            key: const ValueKey('home_search_settings_filter'),
            onTap: onSettingsTap,
            icon: _StrokeIcon(
              painter: _Settings04Painter(color: categoryColor),
            ),
            label: categoryLabel,
            color: categoryColor,
          ),
          const SizedBox(width: 18),
          _SearchToggleAction(
            onTap: onSortTap,
            icon: Icon(
              Icons.sort_rounded,
              size: 20,
              color: sortActive ? Colors.white : HomeSearchScreen.muted,
            ),
            label: sortLabel,
            color: sortActive ? Colors.white : HomeSearchScreen.muted,
          ),
          const SizedBox(width: 22),
          _SearchToggleAction(
            onTap: onViewTap,
            icon: _StrokeIcon(
              painter: viewActive
                  ? _List01Painter(color: viewColor)
                  : _Grid01Painter(color: viewColor),
            ),
            label: viewLabel,
            color: viewColor,
          ),
        ],
      ),
    );
  }
}

class _SearchToggleAction extends StatelessWidget {
  const _SearchToggleAction({
    super.key,
    required this.onTap,
    required this.icon,
    required this.label,
    required this.color,
  });

  final VoidCallback onTap;
  final Widget icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontFamily: 'Netflix Sans',
              fontWeight: FontWeight.w500,
              height: 1.33,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchLoadMore extends StatelessWidget {
  const _SearchLoadMore({required this.loading, required this.onTap});

  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 26, bottom: 8),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: loading ? null : onTap,
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: ShapeDecoration(
              color: HomeSearchScreen.card,
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: HomeSearchScreen.border),
                borderRadius: BorderRadius.circular(40),
              ),
            ),
            child: loading
                ? const SizedBox(
                    width: 18,
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white70,
                      ),
                    ),
                  )
                : const Text(
                    'Ver mais',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontFamily: 'Netflix Sans',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _SortFilterModal extends StatelessWidget {
  const _SortFilterModal({
    required this.options,
    required this.selectedValue,
    required this.onClose,
    required this.onSelect,
  });

  final List<String> options;
  final String selectedValue;
  final VoidCallback onClose;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onClose,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: Container(color: const Color(0xCC0D0D0D)),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(25, 42, 24, 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Ordenar por',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontFamily: 'Netflix Sans',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      _SearchIconButton(
                        icon: Icons.close_rounded,
                        onTap: onClose,
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Escolha uma ordenação',
                    style: TextStyle(
                      color: HomeSearchScreen.lightMuted,
                      fontSize: 12,
                      fontFamily: 'Netflix Sans',
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (var index = 0; index < options.length; index++)
                    _CategoryFilterOption(
                      label: options[index],
                      selected: options[index] == selectedValue,
                      showDivider: index < options.length - 1,
                      onTap: () => onSelect(options[index]),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryFilterModal extends StatelessWidget {
  const _CategoryFilterModal({
    required this.options,
    required this.selectedIndex,
    required this.onClose,
    required this.onSelect,
  });

  final List<_Genre> options;
  final int selectedIndex;
  final VoidCallback onClose;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onClose,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: Container(color: const Color(0xCC0D0D0D)),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(25, 42, 24, 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Categorias',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontFamily: 'Netflix Sans',
                            fontWeight: FontWeight.w600,
                            height: 1.42,
                          ),
                        ),
                      ),
                      _SearchIconButton(
                        icon: Icons.close_rounded,
                        onTap: onClose,
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Escolha a categoria',
                    style: TextStyle(
                      color: HomeSearchScreen.lightMuted,
                      fontSize: 12,
                      fontFamily: 'Netflix Sans',
                      fontWeight: FontWeight.w500,
                      height: 1.33,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemCount: options.length,
                      itemBuilder: (context, index) => _CategoryFilterOption(
                        label: options[index].name,
                        selected: selectedIndex == index,
                        showDivider: index < options.length - 1,
                        onTap: () => onSelect(index),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryFilterOption extends StatelessWidget {
  const _CategoryFilterOption({
    required this.label,
    required this.selected,
    required this.showDivider,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool showDivider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          border: Border(
            bottom: showDivider
                ? const BorderSide(color: HomeSearchScreen.border, width: 1)
                : BorderSide.none,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontFamily: 'Netflix Sans',
                  fontWeight: FontWeight.w500,
                  height: 1.57,
                ),
              ),
            ),
            const SizedBox(width: 10),
            _TypeRadioDot(selected: selected),
          ],
        ),
      ),
    );
  }
}

class _TypeRadioDot extends StatelessWidget {
  const _TypeRadioDot({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 15,
      height: 15,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1),
      ),
      alignment: Alignment.center,
      child: selected
          ? Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
            )
          : null,
    );
  }
}

class _StrokeIcon extends StatelessWidget {
  const _StrokeIcon({required this.painter});

  final CustomPainter painter;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: painter),
    );
  }
}

class _Settings04Painter extends CustomPainter {
  const _Settings04Painter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawLine(
      const Offset(2.5, 6.66675),
      const Offset(12.5, 6.66675),
      paint,
    );
    canvas.drawCircle(const Offset(15, 6.66675), 2.5, paint);
    canvas.drawLine(
      const Offset(7.5, 13.3334),
      const Offset(17.5, 13.3334),
      paint,
    );
    canvas.drawCircle(const Offset(5, 13.3334), 2.5, paint);
  }

  @override
  bool shouldRepaint(covariant _Settings04Painter oldDelegate) =>
      oldDelegate.color != color;
}

class _Grid01Painter extends CustomPainter {
  const _Grid01Painter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    const cell = 5.83333;
    const radius = Radius.circular(1.33333);
    for (final offset in [
      Offset(2.5, 2.5),
      Offset(11.6667, 2.5),
      Offset(11.6667, 11.6667),
      Offset(2.5, 11.6667),
    ]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(offset.dx, offset.dy, cell, cell),
          radius,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _Grid01Painter oldDelegate) =>
      oldDelegate.color != color;
}

class _List01Painter extends CustomPainter {
  const _List01Painter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final y in [4.5, 10.0, 15.5]) {
      canvas.drawLine(Offset(3, y), Offset(17, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _List01Painter oldDelegate) =>
      oldDelegate.color != color;
}

class _SearchGrid extends StatelessWidget {
  const _SearchGrid({
    required this.titles,
    required this.artists,
    required this.isArtists,
    required this.onTitleTap,
  });

  final List<_SearchTitle> titles;
  final List<_SearchArtist> artists;
  final bool isArtists;
  final ValueChanged<_SearchTitle> onTitleTap;

  @override
  Widget build(BuildContext context) {
    final isEmpty = isArtists ? artists.isEmpty : titles.isEmpty;
    if (isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 48),
        child: Center(
          child: Text(
            'Nenhum resultado encontrado',
            style: TextStyle(
              color: HomeSearchScreen.lightMuted,
              fontSize: 14,
              fontFamily: 'Netflix Sans',
              fontWeight: FontWeight.w500,
              height: 1.57,
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 30) / 3;
        final cardHeight = cardWidth * 162 / 104;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: isArtists ? artists.length : titles.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 15,
            mainAxisSpacing: 20,
            mainAxisExtent: cardHeight,
          ),
          itemBuilder: (context, index) {
            if (isArtists) {
              return _ArtistGridCard(artist: artists[index], size: cardWidth);
            }
            final item = titles[index];
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onTitleTap(item),
              child: _SearchPoster(item: item),
            );
          },
        );
      },
    );
  }
}

class _SearchPoster extends StatelessWidget {
  const _SearchPoster({required this.item});

  final _SearchTitle item;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _TitlePoster(url: item.posterUrl),
          Positioned(
            top: 8,
            right: 8,
            child: _RatingBadge(rating: item.rating?.toStringAsFixed(1) ?? '—'),
          ),
        ],
      ),
    );
  }
}

class _ArtistGridCard extends StatelessWidget {
  const _ArtistGridCard({required this.artist, required this.size});

  final _SearchArtist artist;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ClipOval(
          child: _ProfileImage(
            url: artist.profileUrl,
            width: size,
            height: size,
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            artist.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontFamily: 'Netflix Sans',
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _TypingSearchResults extends StatelessWidget {
  const _TypingSearchResults({
    required this.titles,
    required this.artists,
    required this.searching,
    required this.artistsLoading,
    required this.onTitleTap,
  });

  final List<_SearchTitle> titles;
  final List<_SearchArtist> artists;
  final bool searching;
  final bool artistsLoading;
  final ValueChanged<_SearchTitle> onTitleTap;

  @override
  Widget build(BuildContext context) {
    if (searching && titles.isEmpty && artists.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 32),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white70,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SearchResultSectionHeader(title: 'Resultados'),
        const SizedBox(height: 20),
        if (titles.isEmpty)
          const _TypingEmptyHint()
        else
          SizedBox(
            height: 127,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              physics: const BouncingScrollPhysics(),
              itemCount: titles.length,
              separatorBuilder: (context, index) => const SizedBox(width: 15),
              itemBuilder: (context, index) {
                final item = titles[index];
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTitleTap(item),
                  child: _TypingMoviePoster(item: item),
                );
              },
            ),
          ),
        const SizedBox(height: 27),
        const _SearchResultSectionHeader(title: 'Elenco'),
        const SizedBox(height: 12),
        if (artistsLoading && artists.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white70,
                ),
              ),
            ),
          )
        else if (artists.isEmpty)
          const _TypingEmptyHint()
        else
          SizedBox(
            height: 106,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              physics: const BouncingScrollPhysics(),
              itemCount: artists.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) =>
                  _ArtistResultCard(artist: artists[index]),
            ),
          ),
      ],
    );
  }
}

class _TypingEmptyHint extends StatelessWidget {
  const _TypingEmptyHint();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 8, bottom: 8),
      child: Text(
        'Nenhum resultado encontrado',
        style: TextStyle(
          color: HomeSearchScreen.lightMuted,
          fontSize: 13,
          fontFamily: 'Netflix Sans',
          fontWeight: FontWeight.w500,
          height: 1.5,
        ),
      ),
    );
  }
}

class _SearchResultSectionHeader extends StatelessWidget {
  const _SearchResultSectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 22,
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontFamily: 'Netflix Sans',
                fontWeight: FontWeight.w500,
                height: 1.57,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingMoviePoster extends StatelessWidget {
  const _TypingMoviePoster({required this.item});

  final _SearchTitle item;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 104,
        height: 127,
        child: _TitlePoster(url: item.posterUrl),
      ),
    );
  }
}

class _ArtistResultCard extends StatelessWidget {
  const _ArtistResultCard({required this.artist});

  final _SearchArtist artist;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 77,
      height: 106,
      child: Column(
        children: [
          ClipOval(
            child: _ProfileImage(url: artist.profileUrl, width: 60, height: 60),
          ),
          const SizedBox(height: 10),
          Text(
            artist.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontFamily: 'Netflix Sans',
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchList extends StatelessWidget {
  const _SearchList({
    required this.titles,
    required this.artists,
    required this.isArtists,
    required this.onTitleTap,
  });

  final List<_SearchTitle> titles;
  final List<_SearchArtist> artists;
  final bool isArtists;
  final ValueChanged<_SearchTitle> onTitleTap;

  @override
  Widget build(BuildContext context) {
    final isEmpty = isArtists ? artists.isEmpty : titles.isEmpty;
    if (isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 48),
        child: Center(
          child: Text(
            'Nenhum resultado encontrado',
            style: TextStyle(
              color: HomeSearchScreen.lightMuted,
              fontSize: 14,
              fontFamily: 'Netflix Sans',
              fontWeight: FontWeight.w500,
              height: 1.57,
            ),
          ),
        ),
      );
    }

    final count = isArtists ? artists.length : titles.length;
    return Column(
      children: [
        for (var index = 0; index < count; index++)
          if (isArtists)
            _ArtistListTile(
              artist: artists[index],
              showDivider: index < count - 1,
            )
          else
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onTitleTap(titles[index]),
              child: _SearchListTile(
                item: titles[index],
                showDivider: index < count - 1,
              ),
            ),
      ],
    );
  }
}

class _ArtistListTile extends StatelessWidget {
  const _ArtistListTile({required this.artist, required this.showDivider});

  final _SearchArtist artist;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        border: Border(
          bottom: showDivider
              ? const BorderSide(color: HomeSearchScreen.border, width: 1)
              : BorderSide.none,
        ),
      ),
      child: Row(
        children: [
          ClipOval(
            child: _ProfileImage(url: artist.profileUrl, width: 60, height: 60),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  artist.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontFamily: 'Netflix Sans',
                    fontWeight: FontWeight.w500,
                    height: 1.57,
                  ),
                ),
                const Text(
                  'Artista',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: HomeSearchScreen.muted,
                    fontSize: 12,
                    fontFamily: 'Netflix Sans',
                    fontWeight: FontWeight.w500,
                    height: 1.33,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchListTile extends StatelessWidget {
  const _SearchListTile({required this.item, required this.showDivider});

  final _SearchTitle item;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        border: Border(
          bottom: showDivider
              ? const BorderSide(color: HomeSearchScreen.border, width: 1)
              : BorderSide.none,
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 60,
              height: 60,
              child: _TitlePoster(url: item.posterUrl),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontFamily: 'Netflix Sans',
                    fontWeight: FontWeight.w500,
                    height: 1.57,
                  ),
                ),
                Text(
                  item.year == null ? '—' : '${item.year}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: HomeSearchScreen.muted,
                    fontSize: 12,
                    fontFamily: 'Netflix Sans',
                    fontWeight: FontWeight.w500,
                    height: 1.33,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _RatingBadge(rating: item.rating?.toStringAsFixed(1) ?? '—'),
        ],
      ),
    );
  }
}

class _RatingBadge extends StatelessWidget {
  const _RatingBadge({required this.rating});

  final String rating;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 59,
      height: 30,
      decoration: ShapeDecoration(
        color: const Color(0xB30D0D0D),
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: HomeSearchScreen.border, width: 1),
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: Icon(Icons.star_rounded, color: Color(0xFFFFC24B), size: 14),
          ),
          const SizedBox(width: 5.2),
          Text(
            rating,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontFamily: 'Netflix Sans',
              fontWeight: FontWeight.w500,
              height: 1.33,
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _RatingStarPainter extends CustomPainter {
  const _RatingStarPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(5.80562, 0.549118)
      ..cubicTo(5.95928, 0.237826, 6.03611, 0.0821792, 6.14041, 0.0324501)
      ..cubicTo(6.23115, -0.0108167, 6.33658, -0.0108167, 6.42732, 0.0324501)
      ..cubicTo(6.53162, 0.0821792, 6.60845, 0.237826, 6.76211, 0.549118)
      ..lineTo(8.21989, 3.50243)
      ..cubicTo(8.26526, 3.59433, 8.28794, 3.64028, 8.32109, 3.67596)
      ..cubicTo(8.35044, 3.70755, 8.38563, 3.73314, 8.42473, 3.75132)
      ..cubicTo(8.46889, 3.77186, 8.51959, 3.77927, 8.621, 3.79409)
      ..lineTo(11.8818, 4.27071)
      ..cubicTo(12.2252, 4.3209, 12.3969, 4.346, 12.4764, 4.42987)
      ..cubicTo(12.5455, 4.50284, 12.578, 4.60311, 12.5649, 4.70276)
      ..cubicTo(12.5497, 4.81729, 12.4254, 4.93836, 12.1768, 5.1805)
      ..lineTo(9.81815, 7.47785)
      ..cubicTo(9.74463, 7.54947, 9.70786, 7.58528, 9.68414, 7.62788)
      ..cubicTo(9.66314, 7.66561, 9.64966, 7.70705, 9.64446, 7.74991)
      ..cubicTo(9.63859, 7.79832, 9.64727, 7.8489, 9.66462, 7.95007)
      ..lineTo(10.2212, 11.195)
      ..cubicTo(12.2799, 11.5372, 12.3092, 11.7084, 12.2541, 11.8099)
      ..cubicTo(12.2061, 11.8983, 12.1208, 11.9602, 12.0219, 11.9786)
      ..cubicTo(11.90827, 11.9996, 11.7546, 11.9188, 11.44726, 11.7572)
      ..lineTo(8.53211, 10.2241)
      ..cubicTo(8.44128, 10.1764, 8.39586, 10.1525, 8.34802, 10.1431)
      ..cubicTo(8.30565, 10.1348, 8.26208, 10.1348, 8.21972, 10.1431)
      ..cubicTo(8.17187, 10.1525, 8.12645, 10.1764, 8.03563, 10.2241)
      ..lineTo(5.12047, 11.7572)
      ..cubicTo(4.81313, 11.9188, 4.65946, 11.9996, 4.54584, 11.9786)
      ..cubicTo(4.44698, 11.9602, 4.36167, 11.8983, 4.31368, 11.8099)
      ..cubicTo(4.25852, 11.7084, 4.28787, 11.5372, 4.34657, 11.195)
      ..lineTo(4.90311, 7.95007)
      ..cubicTo(4.92046, 7.8489, 4.92914, 7.79832, 4.92327, 7.74991)
      ..cubicTo(4.91807, 7.70705, 4.9046, 7.66561, 4.88359, 7.62788)
      ..cubicTo(4.85987, 7.58528, 4.82311, 7.54947, 4.74958, 7.47785)
      ..lineTo(2.390894, 5.18049)
      ..cubicTo(2.142296, 4.93836, 2.0179973, 4.81729, 2.00287169, 4.70276)
      ..cubicTo(1.98971159, 4.60311, 2.0222232, 4.50284, 2.0913546, 4.42987)
      ..cubicTo(2.170811, 4.346, 2.342502, 4.3209, 2.685883, 4.27071)
      ..lineTo(5.94673, 3.79409)
      ..cubicTo(6.04814, 3.77927, 6.09884, 3.77186, 6.143, 3.75132)
      ..cubicTo(6.1821, 3.73314, 6.2173, 3.70755, 6.24664, 3.67596)
      ..cubicTo(6.27979, 3.64028, 6.30247, 3.59433, 6.34784, 3.50243)
      ..lineTo(5.80562, 0.549118)
      ..close();

    canvas.scale(size.width / 13, size.height / 12);
    canvas.drawPath(path, Paint()..color = const Color(0xFFFFC24B));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SearchIconButton extends StatelessWidget {
  const _SearchIconButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: ShapeDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [HomeSearchScreen.card, Color(0x330D0D0D)],
          ),
          shape: RoundedRectangleBorder(
            side: const BorderSide(width: 1, color: HomeSearchScreen.border),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}

class _TitlePoster extends StatelessWidget {
  const _TitlePoster({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return const _TitlePosterFallback();
    }

    return Image.network(
      url!,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const _TitlePosterFallback(),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const _TitlePosterFallback(loading: true);
      },
    );
  }
}

class _TitlePosterFallback extends StatelessWidget {
  const _TitlePosterFallback({this.loading = false});

  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1A1A),
      alignment: Alignment.center,
      child: loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white70,
              ),
            )
          : const Icon(
              Icons.image_not_supported_outlined,
              color: Color(0xFF525252),
              size: 28,
            ),
    );
  }
}

class _ProfileImage extends StatelessWidget {
  const _ProfileImage({required this.url, this.width, this.height});

  final String? url;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return _ProfileFallback(width: width, height: height);
    }

    return Image.network(
      url!,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _ProfileFallback(width: width, height: height),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return _ProfileFallback(width: width, height: height);
      },
    );
  }
}

class _ProfileFallback extends StatelessWidget {
  const _ProfileFallback({this.width, this.height});

  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2C2C2C), Color(0xFF111111)],
        ),
      ),
      child: const Center(
        child: Icon(Icons.person_rounded, color: Colors.white54, size: 28),
      ),
    );
  }
}

class _Genre {
  const _Genre({required this.id, required this.name});

  final int? id;
  final String name;
}

class _BrowseResponse {
  const _BrowseResponse({
    required this.data,
    required this.mediaType,
    required this.totalPages,
  });

  final Map<String, dynamic> data;
  final String mediaType;
  final int totalPages;
}

class _SearchTitle {
  const _SearchTitle({
    required this.tmdbId,
    required this.mediaType,
    required this.title,
    required this.posterUrl,
    required this.backdropUrl,
    required this.year,
    required this.rating,
    required this.genreIds,
    this.overview,
  });

  final int tmdbId;
  final String mediaType;
  final String title;
  final String? posterUrl;
  final String? backdropUrl;
  final int? year;
  final double? rating;
  final List<int> genreIds;
  final String? overview;
}

class _SearchArtist {
  const _SearchArtist({
    required this.personId,
    required this.name,
    required this.profileUrl,
  });

  final int personId;
  final String name;
  final String? profileUrl;
}

List<_SearchTitle> _parseTitles(
  Map<String, dynamic> json, {
  String? defaultType,
}) {
  final results = json['results'];
  if (results is! List<dynamic>) return const [];

  return [
    for (final raw in results)
      if (raw is Map<String, dynamic>)
        _parseTitle(raw, defaultType: defaultType),
  ].whereType<_SearchTitle>().toList();
}

List<_SearchTitle> _parseSearchTitles(Map<String, dynamic> json) {
  final results = json['results'];
  if (results is! List<dynamic>) return const [];

  return [
    for (final raw in results)
      if (raw is Map<String, dynamic> &&
          ((raw['media_type']?.toString() ?? '') == 'movie' ||
              (raw['media_type']?.toString() ?? '') == 'tv'))
        _parseTitle(raw, defaultType: raw['media_type']?.toString()),
  ].whereType<_SearchTitle>().toList();
}

_SearchTitle? _parseTitle(Map<String, dynamic> raw, {String? defaultType}) {
  final tmdbId = (raw['id'] as num?)?.toInt();
  if (tmdbId == null || tmdbId <= 0) return null;

  final mediaType = (raw['media_type']?.toString() ?? defaultType ?? 'movie')
      .replaceAll('series', 'tv');
  if (mediaType != 'movie' && mediaType != 'tv') return null;

  final title = (raw['title'] ?? raw['name'] ?? '').toString();
  if (title.isEmpty) return null;

  final date = (raw['release_date'] ?? raw['first_air_date'])?.toString();
  return _SearchTitle(
    tmdbId: tmdbId,
    mediaType: mediaType,
    title: title,
    posterUrl: _tmdbImageUrl(raw['poster_path']?.toString()),
    backdropUrl: _tmdbImageUrl(raw['backdrop_path']?.toString(), size: 'w1280'),
    overview: raw['overview']?.toString(),
    year: date != null && date.length >= 4
        ? int.tryParse(date.substring(0, 4))
        : null,
    rating: (raw['vote_average'] as num?)?.toDouble(),
    genreIds: [
      for (final genre in (raw['genre_ids'] as List<dynamic>? ?? const []))
        if (genre is num) genre.toInt(),
    ],
  );
}

List<_SearchArtist> _parseArtists(Map<String, dynamic> json) {
  final results = json['results'];
  if (results is! List<dynamic>) return const [];

  return [
    for (final raw in results)
      if (raw is Map<String, dynamic>)
        _SearchArtist(
          personId: (raw['id'] as num?)?.toInt() ?? 0,
          name: (raw['name'] ?? '').toString(),
          profileUrl: _tmdbImageUrl(
            raw['profile_path']?.toString(),
            size: 'w185',
          ),
        ),
  ].where((artist) => artist.personId > 0 && artist.name.isNotEmpty).toList();
}

List<_SearchArtist> _parseCreditsCast(Map<String, dynamic> json) {
  final cast = json['cast'];
  if (cast is! List<dynamic>) return const [];

  return [
    for (final raw in cast)
      if (raw is Map<String, dynamic>)
        _SearchArtist(
          personId: (raw['id'] as num?)?.toInt() ?? 0,
          name: (raw['name'] ?? '').toString(),
          profileUrl: _tmdbImageUrl(
            raw['profile_path']?.toString(),
            size: 'w185',
          ),
        ),
  ].where((artist) => artist.personId > 0 && artist.name.isNotEmpty).toList();
}

String? _tmdbImageUrl(String? path, {String size = 'w780'}) {
  if (path == null || path.isEmpty) return null;
  if (path.startsWith('http://') || path.startsWith('https://')) return path;
  return 'https://image.tmdb.org/t/p/$size$path';
}
