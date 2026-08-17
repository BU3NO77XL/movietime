import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/content_models.dart';
import '../services/content_service.dart';
import '../widgets/netflix_badge.dart';
import 'create_list_modal.dart';
import 'embedded_player.dart';
import '../widgets/logo_loader.dart';

class WatchScreen extends StatefulWidget {
  const WatchScreen({
    super.key,
    this.tmdbId = 335984,
    this.mediaType = 'movie',
    this.title = 'Blade Runner 2049',
    this.posterUrl,
    this.backdropUrl,
    this.overview,
    this.initialYear,
    this.initialVoteAverage,
    this.seasonNumber = 1,
    this.episodeNumber = 1,
  });

  factory WatchScreen.fromWatchlist(WatchlistItem item) {
    return WatchScreen(
      tmdbId: item.tmdbId,
      mediaType: item.mediaType,
      title: item.title,
      posterUrl: item.posterUrl,
      backdropUrl: item.backdropUrl,
    );
  }

  factory WatchScreen.fromHistory(WatchHistoryItem item) {
    return WatchScreen(
      tmdbId: item.tmdbId,
      mediaType: item.mediaType,
      title: item.title,
      posterUrl: item.posterUrl,
      backdropUrl: item.backdropUrl,
      seasonNumber: item.seasonNumber > 0 ? item.seasonNumber : 1,
      episodeNumber: item.episodeNumber > 0 ? item.episodeNumber : 1,
    );
  }

  static const _bg = Color(0xFF0D0D0D);
  static const _secondary = Color(0xFF1A1A1A);
  static const _border = Color(0xFF2C2C2C);
  static const _cardBorder = Color(0xFF262626);
  static const _muted = Color(0xFF525252);
  // Mantida para reativar o bloco antigo de informacoes comentado.
  // ignore: unused_field
  static const _lightMuted = Color(0xFF9E9E9E);
  // Mantida para reativar os botoes Buy / Trailer comentados no rodape.
  // ignore: unused_field
  static const _primary = Color(0xFFA259FF);

  final int tmdbId;
  final String mediaType;
  final String title;
  final String? posterUrl;
  final String? backdropUrl;
  final String? overview;
  final int? initialYear;
  final double? initialVoteAverage;
  final int seasonNumber;
  final int episodeNumber;

  @override
  State<WatchScreen> createState() => _WatchScreenState();
}

class _WatchScreenState extends State<WatchScreen> {
  final AuthService _authService = AuthService();
  final ContentService _contentService = ContentService();

  bool _isSaved = false;
  bool _isInMyList = false;
  bool _showRatingBadge = false;
  String? _selectedRating;
  String _selectedWatchTab = 'Episódios';
  bool _isSyncing = false;
  bool _isLoadingUserState = true;
  int? _userId;
  String? _userName;
  String? _listName;
  String? _interactionError;
  _WatchContentDetails? _details;
  int _selectedSeason = 1;
  int _selectedEpisode = 1;
  final Set<int> _watchedEpisodes = <int>{};
  bool _isLoadingSeason = false;
  String? _seasonError;
  _SeasonDetails? _seasonDetails;
  List<_CastPerson> _cast = const [];
  List<_RelatedWatchItem> _collectionItems = const [];
  List<_RelatedWatchItem> _similarItems = const [];
  final ScrollController _pageScrollController = ScrollController();
  final ScrollController _watchTabController = ScrollController();
  final GlobalKey _topCastKey = GlobalKey();
  final LayerLink _ratingBadgeLayerLink = LayerLink();
  OverlayEntry? _ratingBadgeOverlay;

  bool get _hasCollection => _details?.collectionId != null && !_isSeries;

  List<({String label, double width})> get _availableWatchTabs {
    if (_isSeries) {
      return const [
        (label: 'Episódios', width: 88),
        (label: 'Mais como este', width: 128),
        (label: 'Elenco principal', width: 150),
      ];
    }
    if (!_hasCollection) {
      return const [
        (label: 'Mais como este', width: 128),
        (label: 'Elenco principal', width: 150),
      ];
    }
    return const [
      (label: 'Coleção', width: 74),
      (label: 'Mais como este', width: 128),
      (label: 'Elenco principal', width: 150),
    ];
  }

  Map<String, ({double left, double width})> get _watchTabMetricsForType {
    final result = <String, ({double left, double width})>{};
    var left = 0.0;
    for (final tab in _availableWatchTabs) {
      result[tab.label] = (left: left, width: tab.width);
      left += tab.width + 16;
    }
    return result;
  }

  @override
  void initState() {
    super.initState();
    _details = _WatchContentDetails.fallback(
      mediaType: _normalizedMediaType,
      title: widget.title,
      posterUrl: widget.posterUrl,
      backdropUrl: widget.backdropUrl,
      overview: widget.overview,
      year: widget.initialYear?.toString(),
      voteAverageLabel: widget.initialVoteAverage?.toStringAsFixed(1),
    );
    _selectedSeason = widget.seasonNumber;
    _selectedEpisode = widget.episodeNumber;
    _selectedWatchTab = _availableWatchTabs.first.label;
    _loadUserState();
    _loadContentDetails();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollWatchTabIntoView(_selectedWatchTab, jump: true);
    });
  }

  @override
  void dispose() {
    _authService.close();
    _contentService.close();
    _ratingBadgeOverlay?.remove();
    _ratingBadgeOverlay = null;
    _pageScrollController.dispose();
    _watchTabController.dispose();
    super.dispose();
  }

  void _showRatingBadgeOverlay() {
    if (_ratingBadgeOverlay != null) return;

    setState(() => _showRatingBadge = true);
    _ratingBadgeOverlay = OverlayEntry(
      builder: (context) {
        return Positioned.fill(
          child: IgnorePointer(
            ignoring: !_showRatingBadge,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _hideRatingBadge,
              child: CompositedTransformFollower(
                link: _ratingBadgeLayerLink,
                showWhenUnlinked: false,
                offset: const Offset(65, -70),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: AnimatedOpacity(
                    opacity: _showRatingBadge ? 1 : 0,
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    child: AnimatedSlide(
                      offset: _showRatingBadge
                          ? Offset.zero
                          : const Offset(0, 0.12),
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      child: Material(
                        color: Colors.transparent,
                        child: _RatingBadge(
                          selectedRating: _selectedRating,
                          onSelected: _selectRating,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(_ratingBadgeOverlay!);
  }

  Future<void> _loadUserState() async {
    try {
      final user = await _authService.profile();
      final watchlist = await _contentService.watchlistData(user.id);
      final ratings = await _contentService.ratings(user.id);
      final history = _isSeries
          ? await _contentService.watchHistoryForItem(
              user.id,
              tmdbId: widget.tmdbId,
              mediaType: _normalizedMediaType,
            )
          : const <WatchHistoryItem>[];
      final key = '${widget.tmdbId}_$_normalizedMediaType';
      final savedHistory = history.isNotEmpty ? history.first : null;

      if (!mounted) return;
      setState(() {
        _userId = user.id;
        _userName = user.name;
        _listName = watchlist.listName ?? user.listName;
        _isInMyList = watchlist.items.any(
          (item) =>
              item.tmdbId == widget.tmdbId &&
              item.mediaType == _normalizedMediaType,
        );
        _isSaved = _isInMyList;
        _selectedRating = _ratingLabelFromApi(ratings[key]);
        if (savedHistory != null) {
          _selectedSeason = savedHistory.seasonNumber > 0
              ? savedHistory.seasonNumber
              : _selectedSeason;
          _selectedEpisode = savedHistory.episodeNumber > 0
              ? savedHistory.episodeNumber
              : _selectedEpisode;
        }
        for (final item in history) {
          if (item.progressPercent >= 100 && item.episodeNumber > 0) {
            _watchedEpisodes.add(item.episodeNumber);
          }
        }
        _interactionError = null;
        _isLoadingUserState = false;
      });
    } on ApiException {
      if (!mounted) return;
      setState(() {
        _interactionError = null;
        _isLoadingUserState = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _interactionError = null;
        _isLoadingUserState = false;
      });
    }
  }

  Future<void> _loadContentDetails() async {
    try {
      final endpoint = _isSeries
          ? 'tv/${widget.tmdbId}'
          : 'movie/${widget.tmdbId}';
      final responses = await Future.wait([
        _contentService.tmdb(endpoint, query: const {'language': 'pt-BR'}),
        _contentService.tmdb(
          '$endpoint/credits',
          query: const {'language': 'pt-BR'},
        ),
        _contentService.tmdb(
          '$endpoint/similar',
          query: const {'language': 'pt-BR', 'page': '1'},
        ),
      ]);
      final data = responses[0];
      final credits = responses[1];
      final similar = responses[2];
      final nextDetails = _WatchContentDetails.fromJson(
        data,
        mediaType: _normalizedMediaType,
        fallbackTitle: widget.title,
        fallbackPosterUrl: widget.posterUrl,
        fallbackBackdropUrl: widget.backdropUrl,
        fallbackOverview: widget.overview,
      );
      if (!mounted) return;
      setState(() {
        _details = nextDetails;
        _cast = _parseCast(credits);
        _similarItems = _parseRelatedItems(similar, _normalizedMediaType);
        if (_isSeries) {
          final validSeasons = nextDetails.seasons
              .where((season) => season.seasonNumber > 0)
              .toList();
          if (validSeasons.isNotEmpty) {
            final hasSelectedSeason = validSeasons.any(
              (season) => season.seasonNumber == _selectedSeason,
            );
            if (!hasSelectedSeason) {
              _selectedSeason = validSeasons.first.seasonNumber;
            }
          }
        }
      });
      if (!_isSeries && nextDetails.collectionId != null) {
        try {
          final collectionData = await _contentService.tmdb(
            'collection/${nextDetails.collectionId}',
            query: const {'language': 'pt-BR'},
          );
          if (!mounted) return;
          setState(() {
            _collectionItems = _parseCollectionItems(collectionData);
          });
        } catch (_) {}
      } else if (mounted) {
        setState(() => _collectionItems = const []);
      }
      if (_isSeries) {
        await _loadSeasonDetails(_selectedSeason);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _details = _WatchContentDetails.fallback(
          mediaType: _normalizedMediaType,
          title: widget.title,
          posterUrl: widget.posterUrl,
          backdropUrl: widget.backdropUrl,
          overview: widget.overview,
        );
        _cast = const [];
        _collectionItems = const [];
        _similarItems = const [];
      });
    }
  }

  Future<void> _loadSeasonDetails(int seasonNumber) async {
    if (!_isSeries) return;

    setState(() {
      _isLoadingSeason = true;
      _seasonError = null;
    });

    try {
      final data = await _contentService.tmdb(
        'tv/${widget.tmdbId}/season/$seasonNumber',
        query: const {'language': 'pt-BR'},
      );
      final nextDetails = _SeasonDetails.fromJson(data);
      if (!mounted) return;
      setState(() {
        _selectedSeason = seasonNumber;
        _seasonDetails = nextDetails;
        final hasSelectedEpisode = nextDetails.episodes.any(
          (episode) => episode.episodeNumber == _selectedEpisode,
        );
        _selectedEpisode = hasSelectedEpisode
            ? _selectedEpisode
            : (nextDetails.episodes.isNotEmpty
                  ? nextDetails.episodes.first.episodeNumber
                  : 1);
        _isLoadingSeason = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoadingSeason = false;
        _seasonError = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingSeason = false;
        _seasonError = 'Não foi possível carregar os episódios agora.';
      });
    }
  }

  Future<void> _selectEpisode(int episodeNumber) async {
    if (episodeNumber == _selectedEpisode) return;

    final previousEpisode = _selectedEpisode;
    setState(() => _selectedEpisode = episodeNumber);

    final userId = _userId;
    if (userId == null) return;

    try {
      await _contentService.saveWatchHistory(
        userId: userId,
        tmdbId: widget.tmdbId,
        mediaType: _normalizedMediaType,
        title: widget.title,
        seasonNumber: _isSeries ? _selectedSeason : null,
        episodeNumber: previousEpisode,
        progressPercent: 100,
        posterUrl: widget.posterUrl,
        backdropUrl: widget.backdropUrl,
      );
      if (!mounted) return;
      setState(() => _watchedEpisodes.add(previousEpisode));
    } catch (_) {}
  }

  void _hideRatingBadge() {
    if (_ratingBadgeOverlay == null) return;

    if (mounted) {
      setState(() => _showRatingBadge = false);
    } else {
      _showRatingBadge = false;
    }
    final overlay = _ratingBadgeOverlay;
    _ratingBadgeOverlay = null;

    Future<void>.delayed(const Duration(milliseconds: 180), () {
      overlay?.remove();
    });
  }

  void _toggleRatingBadge() {
    if (_ratingBadgeOverlay == null) {
      _showRatingBadgeOverlay();
    } else {
      _hideRatingBadge();
    }
  }

  void _selectRating(String rating) {
    setState(() => _selectedRating = rating);
    _ratingBadgeOverlay?.markNeedsBuild();
    _persistRating(rating);
  }

  void _selectWatchTab(String label) {
    if (_selectedWatchTab == label) return;
    final available = _availableWatchTabs;
    if (!available.any((tab) => tab.label == label)) return;
    setState(() => _selectedWatchTab = label);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollWatchTabIntoView(label);
      if (label == 'Elenco principal') {
        _scrollTopCastIntoView();
      }
    });
  }

  Future<void> _toggleMyList() async {
    final userId = _userId;
    if (userId == null) {
      _showSnack('Faça login para salvar na sua lista.');
      return;
    }

    if (_isSyncing) return;

    var nextListName = _listName;
    if (!_isInMyList && (nextListName == null || nextListName.trim().isEmpty)) {
      final name = await showCreateListModal(context, initialName: _listName);
      if (name == null || !mounted) return;
      nextListName = name;
    }

    setState(() => _isSyncing = true);
    try {
      if (_isInMyList) {
        await _contentService.removeFromWatchlist(
          userId: userId,
          tmdbId: widget.tmdbId,
          mediaType: _normalizedMediaType,
        );
      } else {
        if (nextListName != null && _userName != null) {
          final updatedUser = await _authService.updateProfile(
            userId: userId,
            name: _userName,
            listName: nextListName,
          );
          _userName = updatedUser.name;
        }
        await _contentService.addToWatchlist(
          userId: userId,
          tmdbId: widget.tmdbId,
          mediaType: _normalizedMediaType,
          title: widget.title,
          listName: nextListName,
          posterUrl: widget.posterUrl,
          backdropUrl: widget.backdropUrl,
        );
      }

      if (!mounted) return;
      final nextValue = !_isInMyList;
      setState(() {
        _listName = nextListName;
        _isInMyList = nextValue;
        _isSaved = nextValue;
        _isSyncing = false;
        _interactionError = null;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _isSyncing = false;
        _interactionError = error.message;
      });
      _showSnack(error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSyncing = false;
        _interactionError = 'Erro na comunicação com o servidor.';
      });
      _showSnack('Erro na comunicação com o servidor.');
    }
  }

  Future<void> _persistRating(String rating) async {
    final userId = _userId;
    if (userId == null) {
      _showSnack('Faça login para avaliar.');
      return;
    }

    try {
      await _contentService.saveRating(
        userId: userId,
        tmdbId: widget.tmdbId,
        mediaType: _normalizedMediaType,
        value: _ratingLabelToApi(rating),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _interactionError = error.message);
      _showSnack(error.message);
    }
  }

  Future<void> _handlePlay() async {
    final userId = _userId;
    if (userId != null) {
      try {
        await _contentService.saveWatchHistory(
          userId: userId,
          tmdbId: widget.tmdbId,
          mediaType: _normalizedMediaType,
          title: widget.title,
          seasonNumber: _isSeries ? _selectedSeason : null,
          episodeNumber: _isSeries ? _selectedEpisode : null,
          progressPercent: 0,
          posterUrl: widget.posterUrl,
          backdropUrl: widget.backdropUrl,
        );
      } catch (_) {}
    }

    final uri = _megaEmbedStreamUri();
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => EmbeddedPlayerScreen(url: uri)),
    );
  }

  Future<void> _handleDownload() async {
    final uri = _megaEmbedDownloadUri();
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => EmbeddedPlayerScreen(url: uri)),
    );
  }

  Uri _megaEmbedStreamUri() {
    final path = _isSeries
        ? '/embed/${widget.tmdbId}/$_selectedSeason/$_selectedEpisode'
        : '/embed/${widget.tmdbId}';
    return Uri.https('megaembed.com', path);
  }

  Uri _megaEmbedDownloadUri() {
    final path = _isSeries
        ? '/download/${widget.tmdbId}/$_selectedSeason/$_selectedEpisode'
        : '/download/${widget.tmdbId}';
    return Uri.https('megaembedapi.site', path);
  }

  bool get _isSeries =>
      _normalizedMediaType == 'tv' || _normalizedMediaType == 'series';

  String get _normalizedMediaType =>
      widget.mediaType == 'series' ? 'tv' : widget.mediaType;

  String get _displayTitle => _details?.title ?? widget.title;

  String? get _displayOverview => _details?.overview ?? widget.overview;

  String? get _displayPosterUrl => _details?.posterUrl ?? widget.posterUrl;

  String? get _displayBackdropUrl =>
      _details?.backdropUrl ?? widget.backdropUrl ?? widget.posterUrl;

  String get _watchPosterHeroTag =>
      'watch-poster-$_normalizedMediaType-${widget.tmdbId}';

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFFAD2536),
        ),
      );
  }

  void _scrollTopCastIntoView() {
    if (!_pageScrollController.hasClients) return;

    _pageScrollController.animateTo(
      _pageScrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _scrollWatchTabIntoView(String label, {bool jump = false}) {
    if (!_watchTabController.hasClients) return;

    final metrics = _watchTabMetricsForType[label];
    if (metrics == null) return;

    final position = _watchTabController.position;
    final current = position.pixels;
    final viewport = position.viewportDimension;
    final itemLeft = metrics.left;
    final itemRight = metrics.left + metrics.width;

    double target = current;
    if (itemLeft < current) {
      target = itemLeft;
    } else if (itemRight > current + viewport) {
      target = itemRight - viewport;
    }

    target = target.clamp(position.minScrollExtent, position.maxScrollExtent);
    if ((target - current).abs() < 0.5) return;

    if (jump) {
      _watchTabController.jumpTo(target);
      return;
    }

    _watchTabController.animateTo(
      target,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WatchScreen._bg,
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            _HeroBlurBackground(imageUrl: _displayBackdropUrl),
            Positioned(
              right: -175,
              top: -144,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 300, sigmaY: 300),
                child: Container(
                  width: 350,
                  height: 350,
                  decoration: const ShapeDecoration(
                    color: WatchScreen._border,
                    shape: OvalBorder(),
                  ),
                ),
              ),
            ),
            SingleChildScrollView(
              controller: _pageScrollController,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 76),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: MediaQuery.paddingOf(context).top + 450,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          left: 0,
                          top: MediaQuery.paddingOf(context).top + 58,
                          child: _BackButton(
                            onTap: () => Navigator.of(context).pop(),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          top: MediaQuery.paddingOf(context).top + 58,
                          child: _HeroActionButtons(
                            isSaved: _isSaved || _isInMyList,
                            onSaveTap: _toggleMyList,
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          top: MediaQuery.paddingOf(context).top + 95,
                          child: Center(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Hero(
                                tag: _watchPosterHeroTag,
                                child: _WatchHeroImage(
                                  imageUrl: _displayPosterUrl,
                                  width: 230,
                                  height: 355,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  /*
                  Estilo anterior de informacoes em cards. Para voltar para
                  esse visual, remova este comentario e remova _MovieInfoSummary.
                  const Text(
                    'The Gorge',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontFamily: 'Netflix Sans',
                      fontWeight: FontWeight.w500,
                      height: 1.36,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Adventure, Action, Sci-Fi',
                    style: TextStyle(
                      color: WatchScreen._lightMuted,
                      fontSize: 14,
                      fontFamily: 'Netflix Sans',
                      fontWeight: FontWeight.w500,
                      height: 1.57,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Row(
                    children: [
                      Expanded(
                        child: _InfoCard(
                          label: 'IMDB',
                          value: '7.2',
                          icon:
                              'assets/watch/vectors/vector-I62-2757-62-2603.png',
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: _InfoCard(label: 'Year', value: '2025'),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: _InfoCard(label: 'Time', value: '105 min'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  */
                  _MovieInfoSummary(
                    title: _displayTitle,
                    overview: _displayOverview,
                    details: _details,
                    onPlay: _handlePlay,
                    onDownload: _handleDownload,
                  ),
                  if (_interactionError != null) ...[
                    const SizedBox(height: 12),
                    _WatchInlineError(message: _interactionError!),
                  ],
                  /*
                  Descricao antiga separada. O novo bloco de informacoes do
                  Figma ja inclui a descricao, entao este trecho fica inativo.
                  const SizedBox(height: 20),
                  const Text(
                    'Two highly-trained operatives are appointed to posts in guard towers on opposite sides of a vast and highly classified gorge, protecting the world from a mysterious evil that lurks within. They work together to keep the secret in the gorge.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontFamily: 'Netflix Sans',
                      fontWeight: FontWeight.w400,
                      height: 1.57,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Ler mais',
                    style: TextStyle(
                      color: WatchScreen._muted,
                      fontSize: 12,
                      fontFamily: 'Netflix Sans',
                      fontWeight: FontWeight.w500,
                      height: 1.33,
                    ),
                  ),
                  */
                  const SizedBox(height: 8),
                  CompositedTransformTarget(
                    link: _ratingBadgeLayerLink,
                    child: Transform.translate(
                      offset: const Offset(-18, 0),
                      child: _WatchActionsRow(
                        isInMyList: _isInMyList,
                        onMyListTap: _toggleMyList,
                        onRateTap: _toggleRatingBadge,
                        ratingLabel: _selectedRating == null
                            ? 'Avaliar'
                            : _selectedRating!,
                        isRated: _selectedRating != null,
                        selectedRating: _selectedRating,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _WatchTabBar(
                    controller: _watchTabController,
                    selectedLabel: _selectedWatchTab,
                    tabs: _availableWatchTabs,
                    onSelected: _selectWatchTab,
                  ),
                  SizedBox(height: _selectedWatchTab == 'Episódios' ? 14 : 40),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      final offsetAnimation = Tween<Offset>(
                        begin: const Offset(0, 0.08),
                        end: Offset.zero,
                      ).animate(animation);

                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: offsetAnimation,
                          child: child,
                        ),
                      );
                    },
                    child: _buildSelectedWatchTab(),
                  ),
                  /*
                  Sessao Reviews desativada temporariamente. Para reativar,
                  remova este comentario.
                  const _SectionTitle('Reviews'),
                  const SizedBox(height: 20),
                  const _ReviewCard(
                    avatar: 'assets/watch/vectors/vector-I62-2663-62-2640.png',
                    starPrefix: 'vector-I62-2663',
                  ),
                  const SizedBox(height: 20),
                  const _ReviewCard(
                    avatar: 'assets/watch/vectors/vector-I62-2690-62-2640.png',
                    starPrefix: 'vector-I62-2690',
                  ),
                  */
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _BottomActions(
                bottomPadding: MediaQuery.paddingOf(context).bottom,
              ),
            ),
            if (_isLoadingUserState)
              const Positioned.fill(
                child: ColoredBox(
                  color: WatchScreen._bg,
                  child: Center(child: LogoLoader()),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedWatchTab() {
    if (_selectedWatchTab == 'Episódios') {
      return KeyedSubtree(
        key: ValueKey('episodes-tab-content'),
        child: _EpisodesSection(
          isSeries: _isSeries,
          details: _details,
          seasonDetails: _seasonDetails,
          selectedSeason: _selectedSeason,
          selectedEpisode: _selectedEpisode,
          watchedEpisodes: _watchedEpisodes,
          isLoading: _isLoadingSeason,
          errorMessage: _seasonError,
          onSeasonChanged: _loadSeasonDetails,
          onEpisodeSelected: _selectEpisode,
        ),
      );
    }

    if (_selectedWatchTab == 'Coleção') {
      return KeyedSubtree(
        key: const ValueKey('collection-tab-content'),
        child: _RelatedItemsSection(
          items: _collectionItems,
          emptyMessage: _isSeries
              ? 'Collections ficam disponíveis apenas para filmes.'
              : 'Nenhum item de coleção disponível para este título.',
          onItemTap: _openRelatedItem,
        ),
      );
    }

    if (_selectedWatchTab == 'Mais como este') {
      return KeyedSubtree(
        key: const ValueKey('similar-tab-content'),
        child: _RelatedItemsSection(
          items: _similarItems,
          emptyMessage: 'Nenhum título semelhante disponível agora.',
          onItemTap: _openRelatedItem,
        ),
      );
    }

    if (_selectedWatchTab == 'Elenco principal') {
      return KeyedSubtree(
        key: _topCastKey,
        child: Column(
          children: [
            _CastRow(cast: _cast),
            const SizedBox(height: 2),
          ],
        ),
      );
    }

    return const SizedBox.shrink(key: ValueKey('empty-tab'));
  }

  void _openRelatedItem(_RelatedWatchItem item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => WatchScreen(
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
}

class _HeroBlurBackground extends StatelessWidget {
  const _HeroBlurBackground({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: -1,
      right: 1,
      top: 0,
      height: 604,
      child: Opacity(
        opacity: 0.50,
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _WatchHeroImage(
                imageUrl: imageUrl,
                width: double.infinity,
                height: double.infinity,
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _PressableScale(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: ShapeDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [WatchScreen._secondary, Color(0x330D0D0D)],
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }
}

class _HeroActionButtons extends StatelessWidget {
  const _HeroActionButtons({required this.isSaved, this.onSaveTap});

  final bool isSaved;
  final VoidCallback? onSaveTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: _HeroIconButton(
        asset:
            'assets/watch/vectors/vector-I62-1984-62-1702-61-5532-1-1791.png',
        key: const ValueKey('watch-save-button'),
        isBookmark: true,
        isActive: isSaved,
        onTap: onSaveTap,
      ),
    );
  }
}

class _HeroIconButton extends StatelessWidget {
  const _HeroIconButton({
    super.key,
    required this.asset,
    this.isBookmark = false,
    this.isActive = false,
    this.onTap,
  });

  final String asset;
  final bool isBookmark;
  final bool isActive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return _PressableScale(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        padding: const EdgeInsets.all(10),
        decoration: ShapeDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [WatchScreen._secondary, Color(0x330D0D0D)],
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: isBookmark && isActive
              ? const Icon(
                  Icons.bookmark_rounded,
                  key: ValueKey('watch-save-bookmark-active'),
                  color: Color(0xFFFF4C61),
                  size: 20,
                )
              : Image.asset(
                  asset,
                  key: ValueKey(asset),
                  width: 20,
                  height: 20,
                  fit: BoxFit.contain,
                ),
        ),
      ),
    );
  }
}

class _PressableScale extends StatefulWidget {
  const _PressableScale({
    required this.child,
    this.onTap,
    this.pressedScale = 0.96,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;

  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale> {
  bool _pressed = false;
  Offset? _downPosition;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (event) {
        _downPosition = event.position;
        _setPressed(true);
      },
      onPointerMove: (event) {
        final downPosition = _downPosition;
        if (downPosition != null &&
            (event.position - downPosition).distance > 12) {
          _setPressed(false);
        }
      },
      onPointerCancel: (_) {
        _downPosition = null;
        _setPressed(false);
      },
      onPointerUp: (event) {
        final downPosition = _downPosition;
        _downPosition = null;
        _setPressed(false);

        if (downPosition != null &&
            (event.position - downPosition).distance <= 12) {
          widget.onTap?.call();
        }
      },
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1,
        duration: const Duration(milliseconds: 170),
        curve: Curves.easeOutBack,
        child: AnimatedOpacity(
          opacity: _pressed ? 0.82 : 1,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          child: widget.child,
        ),
      ),
    );
  }
}

const _fallbackOverviewText =
    "Young Blade Runner K's discovery of a long-buried secret leads him to track down former Blade Runner Rick Deckard, who's been missing for thirty years.";

class _MovieInfoSummary extends StatefulWidget {
  const _MovieInfoSummary({
    required this.title,
    required this.onPlay,
    required this.onDownload,
    this.overview,
    this.details,
  });

  final String title;
  final String? overview;
  final _WatchContentDetails? details;
  final Future<void> Function() onPlay;
  final Future<void> Function() onDownload;

  @override
  State<_MovieInfoSummary> createState() => _MovieInfoSummaryState();
}

class _MovieInfoSummaryState extends State<_MovieInfoSummary> {
  bool _isExpanded = false;

  String get _description {
    final overview = widget.overview;
    return overview?.trim().isNotEmpty == true
        ? overview!.trim()
        : _fallbackOverviewText;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final style = TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontFamily: 'Netflix Sans',
          fontWeight: FontWeight.w400,
          height: 22 / 14,
        );
        final painter = TextPainter(
          text: TextSpan(text: _description, style: style),
          maxLines: 3,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: constraints.maxWidth);
        final isTruncated = painter.didExceedMaxLines;
        final showsNetflixBadge = widget.details?.isNetflix == true;

        return SizedBox(
          width: double.infinity,
          height: _isExpanded ? null : 306,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: double.infinity,
                height: showsNetflixBadge ? 100 : 70,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showsNetflixBadge)
                      NetflixBadge(
                        showSeries: widget.details?.mediaType == 'tv',
                      ),
                    SizedBox(
                      height: 38,
                      width: double.infinity,
                      child: Text(
                        widget.title,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontFamily: 'Netflix Sans',
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.25,
                          height: 38 / 32,
                        ),
                      ),
                    ),
                    SizedBox(height: 9),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: widget.details == null
                          ? const _MetaRowSkeleton(
                              key: ValueKey('meta-row-loading'),
                            )
                          : _MovieMetaRow(
                              details: widget.details,
                              key: const ValueKey('meta-row-loaded'),
                            ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8),
              _WatchInlineButtons(
                onPlay: widget.onPlay,
                onDownload: widget.onDownload,
              ),
              SizedBox(height: 20),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child:
                    widget.details == null &&
                        widget.overview?.trim().isNotEmpty != true
                    ? const _OverviewSkeleton(key: ValueKey('overview-loading'))
                    : SizedBox(
                        key: ValueKey('overview-$_description'),
                        width: double.infinity,
                        height: _isExpanded ? null : 70,
                        child: Text(
                          _description,
                          maxLines: _isExpanded ? null : 3,
                          overflow: _isExpanded ? null : TextOverflow.fade,
                          style: style,
                        ),
                      ),
              ),
              if (isTruncated) ...[
                const SizedBox(height: 2),
                SizedBox(
                  height: 16,
                  child: InkWell(
                    onTap: () => setState(() => _isExpanded = !_isExpanded),
                    child: Text(
                      _isExpanded ? 'Ler menos' : 'Ler mais',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontFamily: 'Netflix Sans',
                        fontWeight: FontWeight.w500,
                        height: 16 / 12,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _MovieMetaRow extends StatelessWidget {
  const _MovieMetaRow({super.key, this.details});

  final _WatchContentDetails? details;

  @override
  Widget build(BuildContext context) {
    final year = details?.year ?? '';
    final ageRating = details?.ageRating ?? '16+';
    final runtime = details?.runtimeLabel ?? '';
    final voteAverage = details?.voteAverageLabel ?? '8.0';

    return SizedBox(
      height: 20,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            const Text(
              '91% match',
              style: TextStyle(
                color: Color(0xFF45D468),
                fontSize: 14,
                fontFamily: 'Netflix Sans',
                fontWeight: FontWeight.w400,
                height: 18 / 14,
              ),
            ),
            const SizedBox(width: 8),
            Row(
              children: [
                const Icon(
                  Icons.star_rounded,
                  color: Color(0xFFFDC943),
                  size: 16,
                ),
                const SizedBox(width: 2),
                Text(
                  voteAverage,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontFamily: 'Netflix Sans',
                    fontWeight: FontWeight.w400,
                    height: 18 / 14,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Text(
              year,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontFamily: 'Netflix Sans',
                fontWeight: FontWeight.w400,
                height: 18 / 14,
              ),
            ),
            const SizedBox(width: 8),
            _InfoPill(label: ageRating, filled: true),
            if (runtime.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(
                runtime,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontFamily: 'Netflix Sans',
                  fontWeight: FontWeight.w400,
                  height: 18 / 14,
                ),
              ),
            ],
            const SizedBox(width: 8),
            const _InfoPill(label: 'HD'),
          ],
        ),
      ),
    );
  }
}

class _MetaRowSkeleton extends StatelessWidget {
  const _MetaRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 20,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            const Text(
              '91% match',
              style: TextStyle(
                color: Color(0xFF45D468),
                fontSize: 14,
                fontFamily: 'Netflix Sans',
                fontWeight: FontWeight.w400,
                height: 18 / 14,
              ),
            ),
            const SizedBox(width: 8),
            const _SkeletonBar(width: 26, height: 14),
            const SizedBox(width: 8),
            const _SkeletonBar(width: 34, height: 14),
            const SizedBox(width: 8),
            const _SkeletonPill(),
            const SizedBox(width: 8),
            const _SkeletonBar(width: 46, height: 14),
            const SizedBox(width: 8),
            const _InfoPill(label: 'HD'),
          ],
        ),
      ),
    );
  }
}

class _OverviewSkeleton extends StatelessWidget {
  const _OverviewSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 70,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SkeletonBar(width: double.infinity, height: 14),
          const SizedBox(height: 8),
          const _SkeletonBar(width: 250, height: 14),
          const SizedBox(height: 8),
          const _SkeletonBar(width: 190, height: 14),
        ],
      ),
    );
  }
}

class _SkeletonBar extends StatelessWidget {
  const _SkeletonBar({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

class _SkeletonPill extends StatelessWidget {
  const _SkeletonPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 20,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label, this.filled = false});

  final String label;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: filled ? Colors.white.withValues(alpha: 0.15) : null,
        border: filled
            ? null
            : Border.all(
                color: Colors.white.withValues(alpha: 0.30),
                width: 1.5,
              ),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontFamily: 'Netflix Sans',
          fontWeight: FontWeight.w600,
          height: 12 / 9,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

const _downloadIconSvg = '''
<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<path fill-rule="evenodd" clip-rule="evenodd" d="M3.99902 19H19.999C20.2642 19 20.5186 19.1054 20.7061 19.2929C20.8937 19.4804 20.999 19.7348 20.999 20C20.999 20.2652 20.8937 20.5196 20.7061 20.7071C20.5186 20.8946 20.2642 21 19.999 21H3.99902C3.73381 21 3.47945 20.8946 3.29192 20.7071C3.10438 20.5196 2.99902 20.2652 2.99902 20C2.99902 19.7348 3.10438 19.4804 3.29192 19.2929C3.47945 19.1054 3.73381 19 3.99902 19ZM12.999 13.175L16.242 9.933L17.656 11.347L11.999 17.004L6.34202 11.347L7.75602 9.933L10.999 13.175V2H12.999V13.175Z" fill="white"/>
</svg>
''';

class _WatchInlineButtons extends StatelessWidget {
  const _WatchInlineButtons({required this.onPlay, required this.onDownload});

  final Future<void> Function() onPlay;
  final Future<void> Function() onDownload;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 90,
      child: Column(
        children: [
          _WatchActionButton(
            label: 'Play',
            icon: Icons.play_arrow_rounded,
            primary: true,
            onTap: onPlay,
          ),
          SizedBox(height: 10),
          _WatchActionButton(
            label: 'Download',
            iconSvg: _downloadIconSvg,
            onTap: onDownload,
          ),
        ],
      ),
    );
  }
}

class _WatchActionButton extends StatelessWidget {
  const _WatchActionButton({
    required this.label,
    this.icon,
    this.iconSvg,
    this.primary = false,
    this.onTap,
  });

  final String label;
  final IconData? icon;
  final String? iconSvg;
  final bool primary;
  final Future<void> Function()? onTap;

  @override
  Widget build(BuildContext context) {
    final contentColor = primary ? Colors.black : Colors.white;

    return _PressableScale(
      onTap: onTap == null ? null : () => onTap!.call(),
      pressedScale: 0.96,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        height: 40,
        width: double.infinity,
        decoration: BoxDecoration(
          color: primary ? Colors.white : Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (iconSvg != null) ...[
                SvgPicture.string(
                  iconSvg!,
                  width: 24,
                  height: 24,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 4),
              ] else if (icon != null) ...[
                Icon(icon, color: contentColor, size: 32),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  color: contentColor,
                  fontSize: 16,
                  fontFamily: 'Netflix Sans',
                  fontWeight: FontWeight.w600,
                  height: 22 / 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WatchHeroImage extends StatelessWidget {
  const _WatchHeroImage({
    required this.width,
    required this.height,
    this.imageUrl,
  });

  final String? imageUrl;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return Image.asset(
        'assets/watch/images/image-19-886.png',
        width: width,
        height: height,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
      );
    }

    return Image.network(
      imageUrl!,
      width: width,
      height: height,
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
      errorBuilder: (_, _, _) => Image.asset(
        'assets/watch/images/image-19-886.png',
        width: width,
        height: height,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
      ),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          width: width,
          height: height,
          color: const Color(0xFF111111),
          alignment: Alignment.center,
          child: const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }
}

class _WatchInlineError extends StatelessWidget {
  const _WatchInlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0x33AD2536),
        border: Border.all(color: const Color(0x66AD2536)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontFamily: 'Netflix Sans',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WatchContentDetails {
  const _WatchContentDetails({
    required this.title,
    required this.mediaType,
    this.overview,
    this.posterUrl,
    this.backdropUrl,
    this.year,
    this.ageRating,
    this.runtimeLabel,
    this.voteAverageLabel,
    this.episodesCount,
    this.seasons = const [],
    this.collectionId,
    this.isNetflix = false,
  });

  factory _WatchContentDetails.fromJson(
    Map<String, dynamic> json, {
    required String mediaType,
    required String fallbackTitle,
    String? fallbackPosterUrl,
    String? fallbackBackdropUrl,
    String? fallbackOverview,
  }) {
    final title = (json['title'] ?? json['name'] ?? fallbackTitle).toString();
    final posterPath = json['poster_path']?.toString();
    final backdropPath = json['backdrop_path']?.toString();
    final date = (json['release_date'] ?? json['first_air_date'] ?? '')
        .toString();
    final runtime = _resolveRuntime(json);
    final voteAverage = (json['vote_average'] as num?)?.toDouble();

    return _WatchContentDetails(
      title: title,
      mediaType: mediaType,
      overview: json['overview']?.toString() ?? fallbackOverview,
      // Preserve the image already shown by the previous screen. Replacing it
      // with another TMDB URL after navigation causes a visible second load.
      posterUrl: fallbackPosterUrl ?? _tmdbImageUrl(posterPath),
      backdropUrl:
          fallbackBackdropUrl ??
          fallbackPosterUrl ??
          _tmdbImageUrl(backdropPath, size: 'w1280'),
      year: date.length >= 4 ? date.substring(0, 4) : '',
      ageRating: mediaType == 'tv' ? 'TV' : '16+',
      runtimeLabel: runtime > 0 ? _formatRuntime(runtime) : null,
      voteAverageLabel: voteAverage?.toStringAsFixed(1),
      episodesCount: json['number_of_episodes'] as int?,
      collectionId: (json['belongs_to_collection'] is Map<String, dynamic>)
          ? ((json['belongs_to_collection']['id'] as num?)?.toInt())
          : null,
      isNetflix: _isNetflixNetwork(json['networks']),
      seasons: switch (json['seasons']) {
        final List<dynamic> value => [
          for (final season in value)
            if (season is Map<String, dynamic>)
              _SeasonItemDetails.fromJson(season),
        ],
        _ => const [],
      },
    );
  }

  factory _WatchContentDetails.fallback({
    required String mediaType,
    required String title,
    String? posterUrl,
    String? backdropUrl,
    String? overview,
    String? year,
    String? voteAverageLabel,
    bool isNetflix = false,
  }) {
    return _WatchContentDetails(
      title: title,
      mediaType: mediaType,
      posterUrl: posterUrl,
      backdropUrl: backdropUrl ?? posterUrl,
      overview: overview,
      year: year,
      voteAverageLabel: voteAverageLabel,
      isNetflix: isNetflix,
    );
  }

  final String title;
  final String mediaType;
  final String? overview;
  final String? posterUrl;
  final String? backdropUrl;
  final String? year;
  final String? ageRating;
  final String? runtimeLabel;
  final String? voteAverageLabel;
  final int? episodesCount;
  final List<_SeasonItemDetails> seasons;
  final int? collectionId;
  final bool isNetflix;
}

bool _isNetflixNetwork(dynamic networks) {
  if (networks is! List<dynamic>) return false;
  return networks.any(
    (network) =>
        network is Map<String, dynamic> &&
        network['name']?.toString().toLowerCase() == 'netflix',
  );
}

class _SeasonItemDetails {
  const _SeasonItemDetails({
    required this.id,
    required this.seasonNumber,
    required this.name,
    this.episodeCount,
  });

  factory _SeasonItemDetails.fromJson(Map<String, dynamic> json) {
    return _SeasonItemDetails(
      id: (json['id'] as num?)?.toInt() ?? 0,
      seasonNumber: (json['season_number'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      episodeCount: (json['episode_count'] as num?)?.toInt(),
    );
  }

  final int id;
  final int seasonNumber;
  final String name;
  final int? episodeCount;
}

class _SeasonDetails {
  const _SeasonDetails({this.episodes = const []});

  factory _SeasonDetails.fromJson(Map<String, dynamic> json) {
    return _SeasonDetails(
      episodes: switch (json['episodes']) {
        final List<dynamic> value => [
          for (final episode in value)
            if (episode is Map<String, dynamic>)
              _EpisodeDetails.fromJson(episode),
        ],
        _ => const [],
      },
    );
  }

  final List<_EpisodeDetails> episodes;
}

class _EpisodeDetails {
  const _EpisodeDetails({
    required this.id,
    required this.episodeNumber,
    required this.title,
    required this.description,
    required this.durationLabel,
    this.stillUrl,
    this.airDateLabel,
  });

  factory _EpisodeDetails.fromJson(Map<String, dynamic> json) {
    final runtime = (json['runtime'] as num?)?.toInt() ?? 0;
    final airDateRaw = json['air_date']?.toString();
    return _EpisodeDetails(
      id: (json['id'] as num?)?.toInt() ?? 0,
      episodeNumber: (json['episode_number'] as num?)?.toInt() ?? 0,
      title: json['name']?.toString() ?? 'Episódio',
      description: (json['overview']?.toString().trim().isNotEmpty == true)
          ? json['overview'].toString().trim()
          : 'Sem descrição disponível.',
      durationLabel: runtime > 0 ? _formatRuntime(runtime) : 'Episódio',
      stillUrl: _tmdbImageUrl(json['still_path']?.toString()),
      airDateLabel: _formatAirDate(airDateRaw),
    );
  }

  final int id;
  final int episodeNumber;
  final String title;
  final String description;
  final String durationLabel;
  final String? stillUrl;
  final String? airDateLabel;
}

class _CastPerson {
  const _CastPerson({required this.name, required this.role, this.imageUrl});

  final String name;
  final String role;
  final String? imageUrl;
}

class _RelatedWatchItem {
  const _RelatedWatchItem({
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

int _resolveRuntime(Map<String, dynamic> json) {
  final runtime = json['runtime'];
  if (runtime is num) return runtime.toInt();

  final episodeRuntime = json['episode_run_time'];
  if (episodeRuntime is List && episodeRuntime.isNotEmpty) {
    final first = episodeRuntime.first;
    if (first is num) return first.toInt();
  }

  return 0;
}

String _formatRuntime(int minutes) {
  final hours = minutes ~/ 60;
  final remaining = minutes % 60;
  if (hours <= 0) return '${minutes}m';
  if (remaining == 0) return '${hours}h';
  return '${hours}h ${remaining}m';
}

String? _formatAirDate(String? value) {
  if (value == null || value.isEmpty) return null;
  final date = DateTime.tryParse(value);
  if (date == null) return null;
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

String? _tmdbImageUrl(String? path, {String size = 'w780'}) {
  if (path == null || path.isEmpty) return null;
  if (path.startsWith('http://') || path.startsWith('https://')) return path;
  return 'https://image.tmdb.org/t/p/$size$path';
}

List<_CastPerson> _parseCast(Map<String, dynamic> json) {
  final cast = json['cast'];
  if (cast is! List<dynamic>) return const [];

  return [
    for (final item in cast.take(12))
      if (item is Map<String, dynamic>)
        _CastPerson(
          name: item['name']?.toString() ?? 'Elenco',
          role: item['character']?.toString() ?? '',
          imageUrl: _tmdbImageUrl(
            item['profile_path']?.toString(),
            size: 'w185',
          ),
        ),
  ];
}

List<_RelatedWatchItem> _parseRelatedItems(
  Map<String, dynamic> json,
  String mediaType,
) {
  final results = json['results'];
  if (results is! List<dynamic>) return const [];

  return [
    for (final item in results.take(20))
      if (item is Map<String, dynamic>)
        _RelatedWatchItem(
          tmdbId: (item['id'] as num?)?.toInt() ?? 0,
          mediaType: mediaType,
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

List<_RelatedWatchItem> _parseCollectionItems(Map<String, dynamic> json) {
  final parts = json['parts'];
  if (parts is! List<dynamic>) return const [];

  return [
    for (final item in parts)
      if (item is Map<String, dynamic>)
        _RelatedWatchItem(
          tmdbId: (item['id'] as num?)?.toInt() ?? 0,
          mediaType: 'movie',
          title: item['title']?.toString() ?? 'Filme',
          posterUrl: _tmdbImageUrl(item['poster_path']?.toString()),
          backdropUrl: _tmdbImageUrl(
            item['backdrop_path']?.toString(),
            size: 'w1280',
          ),
          overview: item['overview']?.toString(),
        ),
  ].where((item) => item.tmdbId > 0).toList();
}

// Mantido para reativar o bloco antigo de informacoes em cards, comentado acima.
// ignore: unused_element
class _InfoCard extends StatelessWidget {
  // ignore: unused_element_parameter
  const _InfoCard({required this.label, required this.value, this.icon});

  final String label;
  final String value;
  final String? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 73,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: ShapeDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [WatchScreen._secondary, Color(0x330D0D0D)],
        ),
        shape: RoundedRectangleBorder(
          side: const BorderSide(width: 1, color: WatchScreen._border),
          borderRadius: BorderRadius.circular(15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: WatchScreen._muted,
              fontSize: 12,
              fontFamily: 'Netflix Sans',
              fontWeight: FontWeight.w500,
              height: 1.33,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              if (icon != null) ...[
                Image.asset(icon!, width: 16, height: 16),
                const SizedBox(width: 5),
              ],
              Expanded(
                child: Text(
                  value,
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
        ],
      ),
    );
  }
}

// Mantido para reativar a sessao Reviews comentada acima.
// ignore: unused_element
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontFamily: 'Netflix Sans',
        fontWeight: FontWeight.w500,
        height: 1.50,
      ),
    );
  }
}

class _EpisodesSection extends StatelessWidget {
  const _EpisodesSection({
    required this.isSeries,
    required this.details,
    required this.seasonDetails,
    required this.selectedSeason,
    required this.selectedEpisode,
    required this.watchedEpisodes,
    required this.isLoading,
    required this.errorMessage,
    required this.onSeasonChanged,
    required this.onEpisodeSelected,
  });

  final bool isSeries;
  final _WatchContentDetails? details;
  final _SeasonDetails? seasonDetails;
  final int selectedSeason;
  final int selectedEpisode;
  final Set<int> watchedEpisodes;
  final bool isLoading;
  final String? errorMessage;
  final ValueChanged<int> onSeasonChanged;
  final ValueChanged<int> onEpisodeSelected;

  @override
  Widget build(BuildContext context) {
    if (!isSeries) {
      return const _EpisodesEmptyState(
        message: 'Este título é um filme e não possui temporadas.',
      );
    }

    final seasons =
        details?.seasons.where((season) => season.seasonNumber > 0).toList() ??
        const <_SeasonItemDetails>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SeasonSelector(
          seasons: seasons,
          selectedSeason: selectedSeason,
          onChanged: onSeasonChanged,
        ),
        const SizedBox(height: 8),
        if (details != null) ...[
          Text(
            '${seasons.length} temporadas • ${details!.episodesCount ?? 0} episódios',
            style: const TextStyle(
              color: Color(0xB3FFFFFF),
              fontSize: 12,
              fontFamily: 'Netflix Sans',
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
        ],
        if (isLoading)
          const _EpisodesLoadingState()
        else if (errorMessage != null)
          _EpisodesEmptyState(message: errorMessage!)
        else if (seasonDetails == null || seasonDetails!.episodes.isEmpty)
          const _EpisodesEmptyState(
            message: 'Nenhum episódio encontrado para esta temporada.',
          )
        else ...[
          for (
            var index = 0;
            index < seasonDetails!.episodes.length;
            index++
          ) ...[
            _EpisodeCard(
              item: seasonDetails!.episodes[index],
              isSelected:
                  seasonDetails!.episodes[index].episodeNumber ==
                  selectedEpisode,
              isWatched: watchedEpisodes.contains(
                seasonDetails!.episodes[index].episodeNumber,
              ),
              onTap: () => onEpisodeSelected(
                seasonDetails!.episodes[index].episodeNumber,
              ),
            ),
            if (index != seasonDetails!.episodes.length - 1)
              const SizedBox(height: 28),
          ],
        ],
      ],
    );
  }
}

class _SeasonSelector extends StatelessWidget {
  const _SeasonSelector({
    required this.seasons,
    required this.selectedSeason,
    required this.onChanged,
  });

  final List<_SeasonItemDetails> seasons;
  final int selectedSeason;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    if (seasons.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: selectedSeason,
          dropdownColor: const Color(0xFF171717),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xB3FFFFFF),
            size: 18,
          ),
          style: const TextStyle(
            color: Color(0xB3FFFFFF),
            fontSize: 16,
            fontFamily: 'Netflix Sans',
            fontWeight: FontWeight.w400,
            letterSpacing: 0.64,
          ),
          items: [
            for (final season in seasons)
              DropdownMenuItem<int>(
                value: season.seasonNumber,
                child: Text('Temporada ${season.seasonNumber}'),
              ),
          ],
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
        ),
      ),
    );
  }
}

class _EpisodeCard extends StatelessWidget {
  const _EpisodeCard({
    required this.item,
    required this.isSelected,
    required this.isWatched,
    required this.onTap,
  });

  final _EpisodeDetails item;
  final bool isSelected;
  final bool isWatched;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = (constraints.maxWidth / 347).clamp(0.78, 1.0);
        final imageWidth = 148 * scale;
        final imageHeight = 83 * scale;
        final iconSize = 32 * scale;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: onTap,
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF45D468)
                        : Colors.transparent,
                  ),
                ),
                child: SizedBox(
                  height: imageHeight,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: imageWidth,
                        height: imageHeight,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              _EpisodeStillImage(
                                imageUrl: item.stillUrl,
                                width: imageWidth,
                                height: imageHeight,
                              ),
                              if (isWatched)
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    height: 3 * scale,
                                    color: const Color(0xFFE50914),
                                  ),
                                ),
                              Positioned.fill(
                                child: Center(
                                  child: Container(
                                    width: iconSize,
                                    height: iconSize,
                                    decoration: BoxDecoration(
                                      color: const Color(0x8A000000),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.play_arrow_rounded,
                                      color: Colors.white,
                                      size: iconSize * 0.6,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 7 * scale),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${item.episodeNumber}. ${item.title}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontFamily: 'Netflix Sans',
                                fontWeight: FontWeight.w400,
                                height: 20 / 16,
                              ),
                            ),
                            Text(
                              item.durationLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xB3FFFFFF),
                                fontSize: 14,
                                fontFamily: 'Netflix Sans',
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              item.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontFamily: 'Netflix Sans',
                fontWeight: FontWeight.w400,
              ),
            ),
            if (item.airDateLabel != null) ...[
              const SizedBox(height: 6),
              Text(
                item.airDateLabel!,
                style: const TextStyle(
                  color: Color(0x80FFFFFF),
                  fontSize: 11,
                  fontFamily: 'Netflix Sans',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _EpisodesLoadingState extends StatelessWidget {
  const _EpisodesLoadingState();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < 3; index++) ...[
          Container(
            height: 92,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          if (index != 2) const SizedBox(height: 18),
        ],
      ],
    );
  }
}

class _EpisodesEmptyState extends StatelessWidget {
  const _EpisodesEmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Color(0xB3FFFFFF),
          fontSize: 13,
          fontFamily: 'Netflix Sans',
          fontWeight: FontWeight.w500,
          height: 1.4,
        ),
      ),
    );
  }
}

class _EpisodeStillImage extends StatelessWidget {
  const _EpisodeStillImage({
    required this.imageUrl,
    required this.width,
    required this.height,
  });

  final String? imageUrl;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return Container(
        width: width,
        height: height,
        color: const Color(0xFF171717),
        alignment: Alignment.center,
        child: const Icon(
          Icons.live_tv_rounded,
          color: Color(0x80FFFFFF),
          size: 24,
        ),
      );
    }

    return Image.network(
      imageUrl!,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Container(
        width: width,
        height: height,
        color: const Color(0xFF171717),
        alignment: Alignment.center,
        child: const Icon(
          Icons.live_tv_rounded,
          color: Color(0x80FFFFFF),
          size: 24,
        ),
      ),
    );
  }
}

class _CastRow extends StatelessWidget {
  const _CastRow({required this.cast});

  final List<_CastPerson> cast;

  @override
  Widget build(BuildContext context) {
    if (cast.isEmpty) {
      return const _EpisodesEmptyState(
        message: 'Não foi possível carregar o elenco principal agora.',
      );
    }

    final screenWidth = MediaQuery.sizeOf(context).width;

    return SizedBox(
      height: 106,
      child: OverflowBox(
        alignment: Alignment.center,
        minWidth: screenWidth,
        maxWidth: screenWidth,
        minHeight: 106,
        maxHeight: 106,
        child: SizedBox(
          width: screenWidth,
          height: 106,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: cast.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) => _CastCard(item: cast[index]),
          ),
        ),
      ),
    );
  }
}

class _CastCard extends StatelessWidget {
  const _CastCard({required this.item});

  final _CastPerson item;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 77,
      child: Column(
        children: [
          ClipOval(child: _CastAvatar(imageUrl: item.imageUrl, size: 60)),
          const SizedBox(height: 10),
          Text(
            item.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontFamily: 'Netflix Sans',
              fontWeight: FontWeight.w500,
              height: 1.50,
            ),
          ),
          Text(
            item.role.isEmpty ? 'Elenco' : item.role,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF707070),
              fontSize: 12,
              fontFamily: 'Netflix Sans',
              fontWeight: FontWeight.w500,
              height: 1.50,
            ),
          ),
        ],
      ),
    );
  }
}

class _WatchActionsRow extends StatelessWidget {
  const _WatchActionsRow({
    required this.isInMyList,
    required this.onMyListTap,
    required this.onRateTap,
    required this.ratingLabel,
    required this.isRated,
    required this.selectedRating,
  });

  final bool isInMyList;
  final VoidCallback onMyListTap;
  final VoidCallback onRateTap;
  final String ratingLabel;
  final bool isRated;
  final String? selectedRating;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 66,
      child: OverflowBox(
        alignment: Alignment.centerLeft,
        minWidth: 382,
        maxWidth: 382,
        minHeight: 66,
        maxHeight: 66,
        child: Row(
          children: [
            _WatchActionItem(
              key: const ValueKey('watch-my-list-action'),
              label: 'Minha Lista',
              asset: 'assets/watch/actions/Icon-Add-2778-1427.svg',
              activeSvg: _myListAddedIconSvg,
              isActive: isInMyList,
              onTap: onMyListTap,
            ),
            const SizedBox(width: 8),
            _WatchActionItem(
              label: ratingLabel,
              asset: 'assets/watch/actions/Icon-Rate-2778-1430.svg',
              activeSvg: _ratedActionIconSvg(selectedRating),
              isActive: isRated,
              onTap: onRateTap,
            ),
            const SizedBox(width: 8),
            _WatchActionItem(
              label: 'Compartilhar',
              asset: 'assets/watch/actions/Icon-Share-2778-1433.svg',
            ),
          ],
        ),
      ),
    );
  }
}

class _RatingBadge extends StatelessWidget {
  const _RatingBadge({required this.selectedRating, required this.onSelected});

  final String? selectedRating;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 212,
      height: 76,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SvgPicture.asset(
            _ratingBadgeAsset(selectedRating),
            width: 204,
            height: 76,
            fit: BoxFit.contain,
          ),
          const Positioned(
            left: 8,
            bottom: 7,
            width: 72,
            child: _RatingBadgeLabel('Não gostei'),
          ),
          const Positioned(
            left: 77,
            bottom: 7,
            width: 58,
            child: _RatingBadgeLabel('Curti'),
          ),
          const Positioned(
            left: 139,
            bottom: 7,
            width: 58,
            child: _RatingBadgeLabel('Amei'),
          ),
          Positioned(
            left: 8,
            top: 0,
            width: 72,
            height: 54,
            child: _RatingBadgeChoice(onTap: () => onSelected('Não gostei')),
          ),
          Positioned(
            left: 77,
            top: 0,
            width: 58,
            height: 54,
            child: _RatingBadgeChoice(onTap: () => onSelected('Curti')),
          ),
          Positioned(
            left: 139,
            top: 0,
            width: 58,
            height: 54,
            child: _RatingBadgeChoice(onTap: () => onSelected('Amei')),
          ),
        ],
      ),
    );
  }
}

class _RatingBadgeChoice extends StatelessWidget {
  const _RatingBadgeChoice({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _PressableScale(
      onTap: onTap,
      pressedScale: 0.94,
      child: const SizedBox.expand(),
    );
  }
}

class _RatingBadgeLabel extends StatelessWidget {
  const _RatingBadgeLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: Color(0xFF9E9E9E),
        fontSize: 9,
        fontFamily: 'Netflix Sans',
        fontWeight: FontWeight.w600,
        height: 12 / 9,
      ),
    );
  }
}

class _WatchActionItem extends StatelessWidget {
  const _WatchActionItem({
    super.key,
    required this.label,
    required this.asset,
    this.activeSvg,
    this.isActive = false,
    this.onTap,
  });

  final String label;
  final String asset;
  final String? activeSvg;
  final bool isActive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return _PressableScale(
      onTap: onTap,
      pressedScale: 0.92,
      child: SizedBox(
        width: 122,
        height: 66,
        child: Column(
          children: [
            SizedBox(
              width: 35,
              height: 35,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: isActive && activeSvg != null
                    ? SvgPicture.string(
                        activeSvg!,
                        key: ValueKey(activeSvg),
                        width: 35,
                        height: 35,
                        fit: BoxFit.contain,
                      )
                    : SvgPicture.asset(
                        asset,
                        key: ValueKey(asset),
                        width: 35,
                        height: 35,
                        fit: BoxFit.contain,
                      ),
              ),
            ),
            const SizedBox(height: 5),
            SizedBox(
              height: 13,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: Text(
                  label,
                  key: ValueKey(label),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontFamily: 'Netflix Sans',
                    fontWeight: FontWeight.w600,
                    height: 13 / 10,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _myListAddedIconSvg = '''
<svg width="16" height="16" viewBox="0 0 16 16" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M3 8.2L6.4 11.5L13.5 4.5" stroke="white" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
''';

const _ratedIconSvg = '''
<svg width="32" height="32" viewBox="0 0 32 32" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M14.0314 12.2488L14.5 8.5V7.57282C14.5 7.25646 14.7565 7 15.0728 7C16.2909 7 17.443 7.5537 18.2039 8.50488L18.8112 9.26395C18.9334 9.41675 19 9.60661 19 9.80229V14H21.5858C21.851 14 22.1054 14.1054 22.2929 14.2929L24.7071 16.7071C24.8946 16.8946 25 17.149 25 17.4142V18.901C25 18.9668 24.9935 19.0325 24.9806 19.0971L24.5594 21.2031C24.5207 21.3967 24.4255 21.5745 24.2859 21.7141L23.6669 22.3331C23.5572 22.4428 23.4744 22.5767 23.4253 22.724L23.1085 23.6745C23.0382 23.8855 22.8995 24.067 22.7145 24.1903L21.7519 24.8321C21.5877 24.9416 21.3946 25 21.1972 25H14.2361C14.0808 25 13.9277 24.9639 13.7889 24.8944L11.2111 23.6056C11.0723 23.5361 10.9192 23.5 10.7639 23.5H9C8.44772 23.5 8 23.0523 8 22.5V18.1594C8 17.7594 8.2384 17.3978 8.60608 17.2403L11.2428 16.1102C11.411 16.0381 11.5563 15.9212 11.6626 15.7723L13.8529 12.706C13.9494 12.5708 14.0108 12.4137 14.0314 12.2488Z" fill="white"/>
</svg>
''';

String _ratingLabelToApi(String rating) {
  switch (rating) {
    case 'Amei':
      return 'love';
    case 'NÃ£o gostei':
      return 'dislike';
    default:
      return 'like';
  }
}

class _CastAvatar extends StatelessWidget {
  const _CastAvatar({required this.imageUrl, required this.size});

  final String? imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return Container(
        width: size,
        height: size,
        color: const Color(0xFF1A1A1A),
        alignment: Alignment.center,
        child: const Icon(Icons.person_rounded, color: Colors.white, size: 26),
      );
    }

    return Image.network(
      imageUrl!,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Container(
        width: size,
        height: size,
        color: const Color(0xFF1A1A1A),
        alignment: Alignment.center,
        child: const Icon(Icons.person_rounded, color: Colors.white, size: 26),
      ),
    );
  }
}

class _RelatedItemsSection extends StatelessWidget {
  const _RelatedItemsSection({
    required this.items,
    required this.emptyMessage,
    required this.onItemTap,
  });

  final List<_RelatedWatchItem> items;
  final String emptyMessage;
  final ValueChanged<_RelatedWatchItem> onItemTap;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _EpisodesEmptyState(message: emptyMessage);
    }

    return SizedBox(
      height: 242,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, index) => _RelatedItemCard(
          item: items[index],
          onTap: () => onItemTap(items[index]),
        ),
      ),
    );
  }
}

class _RelatedItemCard extends StatelessWidget {
  const _RelatedItemCard({required this.item, required this.onTap});

  final _RelatedWatchItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 132,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _WatchHeroImage(
                imageUrl: item.posterUrl,
                width: 132,
                height: 186,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              item.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontFamily: 'Netflix Sans',
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String? _ratingLabelFromApi(String? value) {
  switch (value) {
    case 'love':
      return 'Amei';
    case 'dislike':
      return 'NÃ£o gostei';
    case 'like':
      return 'Curti';
    default:
      return null;
  }
}

String _ratedActionIconSvg(String? rating) {
  if (rating == null) return _ratedIconSvg;
  if (rating == 'Amei') return _ratedLoveIconSvg;
  if (rating == 'Curti') return _ratedIconSvg;
  return _ratedDislikeIconSvg;
}

String _ratingBadgeAsset(String? rating) {
  if (rating == null) return 'assets/watch/actions/Frame-2785-1439.svg';
  if (rating == 'Curti') {
    return 'assets/watch/actions/Frame-2785-1439-like.svg';
  }
  if (rating == 'Amei') {
    return 'assets/watch/actions/Frame-2785-1439-love.svg';
  }
  return 'assets/watch/actions/Frame-2785-1439-dislike.svg';
}

const _ratedDislikeIconSvg = '''
<svg width="32" height="32" viewBox="0 0 32 32" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M17.9686 19.7512L17.5 23.5V24.4272C17.5 24.7435 17.2435 25 16.9272 25C15.7091 25 14.557 24.4463 13.7961 23.4951L13.1888 22.7361C13.0666 22.5833 13 22.3934 13 22.1977V18H10.4142C10.149 18 9.89464 17.8946 9.70711 17.7071L7.29289 15.2929C7.10536 15.1054 7 14.851 7 14.5858V13.099C7 13.0332 7.00649 12.9675 7.01942 12.9029L7.44064 10.7969C7.47935 10.6033 7.57447 10.4255 7.71414 10.2859L8.3331 9.6669C8.44281 9.55719 8.52562 9.42329 8.57473 9.27597L8.89154 8.32554C8.96187 8.11455 9.10055 7.93296 9.28548 7.80968L10.2481 7.16795C10.4123 7.05845 10.6054 7 10.8028 7H17.7639C17.9192 7 18.0723 7.03615 18.2111 7.10557L20.7889 8.39443C20.9277 8.46385 21.0808 8.5 21.2361 8.5H23C23.5523 8.5 24 8.94772 24 9.5V13.8406C24 14.2406 23.7616 14.6022 23.3939 14.7597L20.7572 15.8898C20.589 15.9619 20.4437 16.0788 20.3374 16.2277L18.1471 19.294C18.0506 19.4292 17.9892 19.5863 17.9686 19.7512Z" fill="white"/>
</svg>
''';

const _ratedLoveIconSvg = '''
<svg width="32" height="32" viewBox="0 0 32 32" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M16 25.2L14.55 23.88C9.4 19.2 6 16.12 6 12.35C6 9.27 8.42 6.85 11.5 6.85C13.24 6.85 14.91 7.66 16 8.93C17.09 7.66 18.76 6.85 20.5 6.85C23.58 6.85 26 9.27 26 12.35C26 16.12 22.6 19.2 17.45 23.89L16 25.2Z" fill="white"/>
</svg>
''';

class _WatchTabBar extends StatelessWidget {
  const _WatchTabBar({
    required this.controller,
    required this.selectedLabel,
    required this.tabs,
    required this.onSelected,
  });

  final ScrollController controller;
  final String selectedLabel;
  final List<({String label, double width})> tabs;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 43,
      child: SingleChildScrollView(
        controller: controller,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        clipBehavior: Clip.none,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var index = 0; index < tabs.length; index++) ...[
              if (index > 0) const SizedBox(width: 16),
              _WatchTabItem(
                label: tabs[index].label,
                width: tabs[index].width,
                isActive: selectedLabel == tabs[index].label,
                onTap: () => onSelected(tabs[index].label),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _WatchTabItem extends StatelessWidget {
  const _WatchTabItem({
    required this.label,
    required this.width,
    required this.onTap,
    this.isActive = false,
  });

  final String label;
  final double width;
  final VoidCallback onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return _PressableScale(
      onTap: onTap,
      pressedScale: 0.94,
      child: SizedBox(
        width: width,
        height: 43,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              width: width,
              height: 5,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                gradient: isActive
                    ? const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFA259FF), Color(0xFF562199)],
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 14),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              style: TextStyle(
                color: Colors.white.withValues(alpha: isActive ? 1 : 0.5),
                fontSize: 17,
                fontFamily: 'Netflix Sans',
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.17,
              ),
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}

// Mantido para reativar a sessao Reviews comentada acima.
// ignore: unused_element
class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.avatar, required this.starPrefix});

  final String avatar;
  final String starPrefix;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      decoration: ShapeDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [WatchScreen._secondary, Color(0x330D0D0D)],
        ),
        shape: RoundedRectangleBorder(
          side: const BorderSide(width: 1, color: WatchScreen._cardBorder),
          borderRadius: BorderRadius.circular(15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(avatar, width: 30, height: 30),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Jack S.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontFamily: 'Netflix Sans',
                        fontWeight: FontWeight.w500,
                        height: 1.50,
                      ),
                    ),
                    Text(
                      'Há 2 meses',
                      style: TextStyle(
                        color: WatchScreen._muted,
                        fontSize: 12,
                        fontFamily: 'Netflix Sans',
                        fontWeight: FontWeight.w500,
                        height: 1.50,
                      ),
                    ),
                  ],
                ),
              ),
              for (final suffix in ['2645', '2646', '2647', '2648', '2649'])
                Padding(
                  padding: const EdgeInsets.only(left: 3),
                  child: Image.asset(
                    'assets/watch/vectors/$starPrefix-62-$suffix.png',
                    width: 14,
                    height: 14,
                    fit: BoxFit.contain,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            "Sempre confio nas escolhas da maravilhosa Anya Taylor-Joy, que me surpreende toda vez. Acho que este é o primeiro filme que assisti no ano novo, e foi realmente ótimo.",
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontFamily: 'Netflix Sans',
              fontWeight: FontWeight.w400,
              height: 1.57,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Image.asset(
                'assets/watch/vectors/$starPrefix-62-2653-1-2637.png',
                width: 20,
                height: 20,
              ),
              const SizedBox(width: 4),
              const Text(
                '12',
                style: TextStyle(
                  color: WatchScreen._muted,
                  fontSize: 12,
                  fontFamily: 'Netflix Sans',
                  fontWeight: FontWeight.w500,
                  height: 1.50,
                ),
              ),
              const SizedBox(width: 12),
              Image.asset(
                'assets/watch/vectors/$starPrefix-62-2656-1-2633.png',
                width: 20,
                height: 20,
              ),
              const SizedBox(width: 4),
              const Text(
                '1',
                style: TextStyle(
                  color: WatchScreen._muted,
                  fontSize: 12,
                  fontFamily: 'Netflix Sans',
                  fontWeight: FontWeight.w500,
                  height: 1.50,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({required this.bottomPadding});

  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0x000D0D0D),
            Color(0x260D0D0D),
            Color(0xCC0D0D0D),
            WatchScreen._bg,
          ],
          stops: [0.0, 0.42, 0.78, 1.0],
        ),
      ),
      child: SizedBox(height: bottomPadding + 110),
      /*
      Botoes inferiores Buy / Trailer desativados temporariamente.
      Para reativar, substitua o SizedBox acima por este Padding.
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 34, 24, bottomPadding + 20),
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 50,
                decoration: ShapeDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [WatchScreen._primary, Color(0xFF562199)],
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
                    'Comprar',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontFamily: 'Netflix Sans',
                      fontWeight: FontWeight.w500,
                      height: 1.57,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Container(
                height: 50,
                decoration: ShapeDecoration(
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(
                      width: 1,
                      color: WatchScreen._primary,
                    ),
                    borderRadius: BorderRadius.circular(40),
                  ),
                ),
                child: const Center(
                  child: Text(
                    'Trailer',
                    style: TextStyle(
                      color: WatchScreen._primary,
                      fontSize: 14,
                      fontFamily: 'Netflix Sans',
                      fontWeight: FontWeight.w500,
                      height: 1.57,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      */
    );
  }
}
