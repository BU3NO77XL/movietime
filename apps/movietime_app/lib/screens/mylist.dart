import 'dart:ui';

import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/auth_models.dart';
import '../services/auth_service.dart';
import '../services/content_models.dart';
import '../services/content_service.dart';
import 'create_list_modal.dart';
import 'profile.dart';
import 'screen_transitions.dart';
import 'watch.dart';

class MyListScreen extends StatefulWidget {
  const MyListScreen({super.key});

  static const _bg = Color(0xFF0D0D0D);
  static const _card = Color(0xFF1A1A1A);
  static const _border = Color(0xFF262626);
  static const _muted = Color(0xFF525252);
  static const _lightMuted = Color(0xFF9E9E9E);

  @override
  State<MyListScreen> createState() => _MyListScreenState();
}

class _MyListScreenState extends State<MyListScreen> {
  final AuthService _authService = AuthService();
  final ContentService _contentService = ContentService();

  bool _isLoading = true;
  bool _isSavingListName = false;
  String? _errorMessage;
  AuthUser? _user;
  String? _listName;
  List<WatchlistItem> _watchlist = const [];
  List<WatchHistoryItem> _history = const [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _authService.close();
    _contentService.close();
    super.dispose();
  }

  Future<void> _loadData({bool refresh = false}) async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = refresh ? null : _errorMessage;
      });
    }

    try {
      final user = await _authService.profile();
      final results = await Future.wait([
        _contentService.watchlistData(user.id),
        _contentService.watchHistory(user.id),
      ]);
      final watchlist = results[0] as WatchlistResponse;
      final history = results[1] as List<WatchHistoryItem>;

      if (!mounted) return;
      setState(() {
        _user = user;
        _listName = watchlist.listName ?? user.listName;
        _watchlist = watchlist.items;
        _history = history;
        _isLoading = false;
        _errorMessage = null;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Não foi possível carregar sua lista agora.';
      });
    }
  }

  Future<void> _editListName() async {
    final user = _user;
    if (user == null || _isSavingListName) return;

    final name = await showCreateListModal(context, initialName: _listName);
    if (name == null || !mounted) return;

    setState(() => _isSavingListName = true);
    try {
      final updatedUser = await _authService.updateProfile(
        userId: user.id,
        name: user.name,
        listName: name,
      );
      if (!mounted) return;
      setState(() {
        _user = updatedUser;
        _listName = updatedUser.listName ?? name;
        _isSavingListName = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _isSavingListName = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: const Color(0xFFAD2536),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSavingListName = false);
    }
  }

  Future<void> _removeFromWatchlist(WatchlistItem item) async {
    final user = _user;
    if (user == null) return;

    try {
      await _contentService.removeFromWatchlist(
        userId: user.id,
        tmdbId: item.tmdbId,
        mediaType: item.mediaType,
      );
      if (!mounted) return;
      setState(() {
        _watchlist = _watchlist
            .where(
              (entry) =>
                  entry.tmdbId != item.tmdbId ||
                  entry.mediaType != item.mediaType,
            )
            .toList();
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: const Color(0xFFAD2536),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyListScreen._bg,
      bottomNavigationBar: const _MyListBottomNav(),
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
            RefreshIndicator(
              color: Colors.white,
              backgroundColor: const Color(0xFF1A1A1A),
              onRefresh: () => _loadData(refresh: true),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(24, 42, 24, 36),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _listName?.trim().isNotEmpty == true
                              ? _listName!.trim()
                              : 'Minha lista',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                            height: 1.42,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _user == null ? null : _editListName,
                        icon: _isSavingListName
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.edit_outlined,
                                color: Colors.white,
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _user == null
                        ? 'Carregando seus dados...'
                        : 'Seus títulos salvos e vistos recentemente em um só lugar.',
                    style: const TextStyle(
                      color: MyListScreen._lightMuted,
                      fontSize: 13,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_isLoading)
                    const _CenteredStatus(
                      icon: Icons.hourglass_top_rounded,
                      title: 'Carregando sua lista',
                      message: 'Buscando watchlist e recentes.',
                    )
                  else if (_errorMessage != null)
                    _CenteredStatus(
                      icon: Icons.error_outline_rounded,
                      title: 'Erro ao carregar dados',
                      message: _errorMessage!,
                      actionLabel: 'Tentar novamente',
                      onTap: () => _loadData(refresh: true),
                    )
                  else if (_watchlist.isEmpty && _history.isEmpty)
                    const _CenteredStatus(
                      icon: Icons.bookmark_border_rounded,
                      title: 'Sua lista ainda está vazia',
                      message:
                          'Quando você salvar um título ou começar a assistir, ele aparece aqui.',
                    )
                  else ...[
                    _SectionHeader(title: 'Adicionados na lista'),
                    const SizedBox(height: 14),
                    _PosterRail(
                      items: _watchlist,
                      emptyMessage: 'Nenhum título salvo ainda.',
                      onTap: (item) => Navigator.of(context).push(
                        cinematicPageRoute(WatchScreen.fromWatchlist(item)),
                      ),
                      onRemove: _removeFromWatchlist,
                    ),
                    const SizedBox(height: 28),
                    _SectionHeader(title: 'Vistos recentemente'),
                    const SizedBox(height: 14),
                    _PosterRail(
                      items: _history,
                      emptyMessage: 'Seu histórico aparece aqui.',
                      onTap: (item) => Navigator.of(context).push(
                        cinematicPageRoute(WatchScreen.fromHistory(item)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PosterRail<T extends WatchlistItem> extends StatelessWidget {
  const _PosterRail({
    required this.items,
    required this.emptyMessage,
    required this.onTap,
    this.onRemove,
  });

  final List<T> items;
  final String emptyMessage;
  final ValueChanged<T> onTap;
  final ValueChanged<T>? onRemove;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: ShapeDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [MyListScreen._card, Color(0x330D0D0D)],
          ),
          shape: RoundedRectangleBorder(
            side: const BorderSide(width: 1, color: MyListScreen._border),
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Text(
          emptyMessage,
          style: const TextStyle(
            color: MyListScreen._lightMuted,
            fontSize: 13,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return SizedBox(
      height: 208,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final item = items[index];
          return _PosterCard(
            item: item,
            onTap: () => onTap(item),
            onRemove: onRemove == null ? null : () => onRemove!(item),
          );
        },
      ),
    );
  }
}

class _PosterCard extends StatelessWidget {
  const _PosterCard({required this.item, required this.onTap, this.onRemove});

  final WatchlistItem item;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 128,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _RemotePoster(url: item.posterUrl, width: 128),
                ),
                if (onRemove != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: onRemove,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.72),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              item.title.isEmpty ? 'Título indisponível' : item.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item.mediaType == 'tv' || item.mediaType == 'series'
                  ? 'Série'
                  : 'Filme',
              style: const TextStyle(
                color: MyListScreen._lightMuted,
                fontSize: 12,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
              ),
            ),
            if (item is WatchHistoryItem) ...[
              const SizedBox(height: 4),
              Text(
                _historyLabel(item as WatchHistoryItem),
                style: const TextStyle(
                  color: MyListScreen._muted,
                  fontSize: 11,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _historyLabel(WatchHistoryItem item) {
    if (item.seasonNumber > 0 && item.episodeNumber > 0) {
      return 'S${item.seasonNumber} • E${item.episodeNumber}';
    }
    return 'Assistido recentemente';
  }
}

class _RemotePoster extends StatelessWidget {
  const _RemotePoster({required this.url, required this.width});

  final String? url;
  final double width;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return _PosterFallback(width: width);
    }

    return Image.network(
      url!,
      width: width,
      height: 165,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _PosterFallback(width: width),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return _PosterFallback(width: width, loading: true);
      },
    );
  }
}

class _PosterFallback extends StatelessWidget {
  const _PosterFallback({required this.width, this.loading = false});

  final double width;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 165,
      color: const Color(0xFF1A1A1A),
      alignment: Alignment.center,
      child: loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(
              Icons.movie_creation_outlined,
              color: Color(0xFF9E9E9E),
              size: 28,
            ),
    );
  }
}

class _CenteredStatus extends StatelessWidget {
  const _CenteredStatus({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: ShapeDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [MyListScreen._card, Color(0x330D0D0D)],
        ),
        shape: RoundedRectangleBorder(
          side: const BorderSide(width: 1, color: MyListScreen._border),
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: MyListScreen._lightMuted,
              fontSize: 13,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
          if (actionLabel != null && onTap != null) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: onTap,
              child: Text(
                actionLabel!,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontFamily: 'Inter',
        fontWeight: FontWeight.w500,
        height: 1.57,
      ),
    );
  }
}

class _MyListBottomNav extends StatelessWidget {
  const _MyListBottomNav();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.black,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _NavItem(
                icon: 'assets/home/vectors/vector-2705-1275.png',
                label: 'Inicio',
                onTap: () => Navigator.of(context).maybePop(),
              ),
              const _NavItem(
                icon: 'assets/home/vectors/vector-2705-1278.png',
                label: 'Em Alta',
              ),
              const _NavItem(
                icon: 'assets/home/vectors/vector-I2704-1244-1-1791.png',
                label: 'Minha Lista',
                active: true,
              ),
              _NavItem(
                icon: 'assets/home/vectors/vector-2705-1282.png',
                label: 'Minha Time',
                tintIcon: false,
                onTap: () {
                  Navigator.of(
                    context,
                  ).pushReplacement(cinematicPageRoute(const ProfileScreen()));
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    this.active = false,
    this.tintIcon = true,
    this.onTap,
  });

  final String icon;
  final String label;
  final bool active;
  final bool tintIcon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? Colors.white : const Color(0xFF9A9A9A);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 72,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                icon,
                width: 32,
                height: 32,
                fit: BoxFit.contain,
                color: tintIcon ? color : null,
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
