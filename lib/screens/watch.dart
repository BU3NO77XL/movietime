import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'create_list_modal.dart';
import 'my_list_state.dart';

class WatchScreen extends StatefulWidget {
  const WatchScreen({super.key});

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

  @override
  State<WatchScreen> createState() => _WatchScreenState();
}

class _WatchScreenState extends State<WatchScreen> {
  bool _isSaved = false;
  bool _isInMyList = false;
  bool _showRatingBadge = false;
  String? _selectedRating;
  String _selectedWatchTab = 'Episodes';
  final ScrollController _pageScrollController = ScrollController();
  final ScrollController _watchTabController = ScrollController();
  final GlobalKey _topCastKey = GlobalKey();
  final LayerLink _ratingBadgeLayerLink = LayerLink();
  OverlayEntry? _ratingBadgeOverlay;

  static const Map<String, ({double left, double width})> _watchTabMetrics = {
    'Episodes': (left: 0, width: 75),
    'Collection': (left: 91, width: 86),
    'More Like This': (left: 193, width: 119),
    'Top Cast': (left: 328, width: 75),
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollWatchTabIntoView(_selectedWatchTab, jump: true);
    });
  }

  @override
  void dispose() {
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
        );
      },
    );

    Overlay.of(context).insert(_ratingBadgeOverlay!);
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
  }

  void _selectWatchTab(String label) {
    setState(() => _selectedWatchTab = label);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollWatchTabIntoView(label);
      if (label == 'Top Cast') {
        _scrollTopCastIntoView();
      }
    });
  }

  Future<void> _toggleMyList() async {
    if (!_isInMyList && !MyListState.hasCreatedList) {
      final name = await showCreateListModal(context);
      if (name == null || !mounted) return;
      MyListState.createList(name);
    }

    setState(() {
      final next = !_isInMyList;
      _isInMyList = next;
      _isSaved = next;
    });
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

    final metrics = _watchTabMetrics[label];
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
            const _HeroBlurBackground(),
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
                            onSaveTap: () {
                              _toggleMyList();
                            },
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          top: MediaQuery.paddingOf(context).top + 95,
                          child: Center(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.asset(
                                'assets/watch/images/image-19-886.png',
                                width: 230,
                                height: 355,
                                fit: BoxFit.cover,
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
                      fontFamily: 'Inter',
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
                      fontFamily: 'Inter',
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
                  const _MovieInfoSummary(),
                  /*
                  Descricao antiga separada. O novo bloco de informacoes do
                  Figma ja inclui a descricao, entao este trecho fica inativo.
                  const SizedBox(height: 20),
                  const Text(
                    'Two highly-trained operatives are appointed to posts in guard towers on opposite sides of a vast and highly classified gorge, protecting the world from a mysterious evil that lurks within. They work together to keep the secret in the gorge.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                      height: 1.57,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Read more',
                    style: TextStyle(
                      color: WatchScreen._muted,
                      fontSize: 12,
                      fontFamily: 'Inter',
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
                            ? 'Rate'
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
                    onSelected: _selectWatchTab,
                  ),
                  SizedBox(height: _selectedWatchTab == 'Episodes' ? 14 : 40),
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
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedWatchTab() {
    if (_selectedWatchTab == 'Episodes') {
      return const KeyedSubtree(
        key: ValueKey('episodes-tab-content'),
        child: _EpisodesSection(),
      );
    }

    if (_selectedWatchTab == 'Top Cast') {
      return KeyedSubtree(
        key: _topCastKey,
        child: const Column(children: [_CastRow(), SizedBox(height: 2)]),
      );
    }

    return const SizedBox.shrink(key: ValueKey('empty-tab'));
  }
}

class _HeroBlurBackground extends StatelessWidget {
  const _HeroBlurBackground();

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
              Image.asset(
                'assets/watch/images/image-19-886.png',
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
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
  const _HeroActionButtons({required this.isSaved, required this.onSaveTap});

  final bool isSaved;
  final VoidCallback onSaveTap;

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
        child: isBookmark && isActive
            ? const Icon(
                Icons.bookmark_rounded,
                color: Color(0xFFFF4C61),
                size: 20,
              )
            : Image.asset(asset, width: 20, height: 20, fit: BoxFit.contain),
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

class _MovieInfoSummary extends StatelessWidget {
  const _MovieInfoSummary();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 254,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 20,
                  child: Text(
                    'Blade Runner 2049',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      height: 20 / 18,
                    ),
                  ),
                ),
                SizedBox(height: 8),
                _MovieMetaRow(),
              ],
            ),
          ),
          SizedBox(height: 8),
          _WatchInlineButtons(),
          SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 70,
            child: Text(
              "Young Blade Runner K's discovery of a long-buried secret leads him to track down former Blade Runner Rick Deckard, who's been missing for thirty years.",
              maxLines: 3,
              overflow: TextOverflow.fade,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
                height: 22 / 14,
              ),
            ),
          ),
          SizedBox(height: 2),
          SizedBox(
            height: 16,
            child: Text(
              'Read more',
              style: TextStyle(
                color: WatchScreen._muted,
                fontSize: 12,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
                height: 16 / 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MovieMetaRow extends StatelessWidget {
  const _MovieMetaRow();

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
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
                height: 18 / 14,
              ),
            ),
            const SizedBox(width: 8),
            const Row(
              children: [
                Icon(Icons.star_rounded, color: Color(0xFFFDC943), size: 16),
                SizedBox(width: 2),
                Text(
                  '8.0',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                    height: 18 / 14,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            const Text(
              '2017',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
                height: 18 / 14,
              ),
            ),
            const SizedBox(width: 8),
            const _InfoPill(label: '16+', filled: true),
            const SizedBox(width: 8),
            const Text(
              '2h 43m',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
                height: 18 / 14,
              ),
            ),
            const SizedBox(width: 8),
            const _InfoPill(label: 'HD'),
          ],
        ),
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
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
          height: 12 / 9,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _WatchInlineButtons extends StatelessWidget {
  const _WatchInlineButtons();

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
          ),
          SizedBox(height: 10),
          _WatchActionButton(label: 'Trailer'),
        ],
      ),
    );
  }
}

class _WatchActionButton extends StatelessWidget {
  const _WatchActionButton({
    required this.label,
    this.icon,
    this.primary = false,
  });

  final String label;
  final IconData? icon;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final contentColor = primary ? Colors.black : Colors.white;

    return _PressableScale(
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
              if (icon != null) ...[
                Icon(icon, color: contentColor, size: 32),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  color: contentColor,
                  fontSize: 16,
                  fontFamily: 'Inter',
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
              fontFamily: 'Inter',
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
                    fontFamily: 'Inter',
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
        fontFamily: 'Inter',
        fontWeight: FontWeight.w500,
        height: 1.50,
      ),
    );
  }
}

class _EpisodesSection extends StatelessWidget {
  const _EpisodesSection();

  static const _episodes = [
    _EpisodeItem(
      image: 'assets/watch/episodes/Frame-120-2787-1588.png',
      title: '1. Episode 1',
      duration: '1h',
      description:
          'In 1977, frustrated FBI hostage negotiator Holden Ford finds an unlikely ally in veteran agent Bill Tench and begins studying a new class of murderer.',
    ),
    _EpisodeItem(
      image: 'assets/watch/episodes/Frame-120-2787-1601.png',
      title: '2. Episode 2',
      duration: '1h',
      description:
          'Holden interviews the eerily articulate murderer Ed Kemper, but his research provokes negative feedback at the Bureau.',
    ),
    _EpisodeItem(
      image: 'assets/watch/episodes/Frame-120-2787-1614.png',
      title: '3. Episode 3',
      duration: '1h',
      description:
          'Dr. Wendy Carr joins Holden and Tench in their first success, when their insights lead to an arrest.',
    ),
    _EpisodeItem(
      image: 'assets/watch/episodes/Frame-120-2787-1588.png',
      title: '4. Episode 4',
      duration: '1h',
      description:
          'Bill and Holden consult on a baffling Altoona case. Wendy rethinks her future as the team tests a new way to understand suspects.',
    ),
    _EpisodeItem(
      image: 'assets/watch/episodes/Frame-120-2787-1588.png',
      title: '5. Episode 5',
      duration: '1h',
      description:
          'Holden and Bill return to a perplexing case in Pennsylvania where a set of clues leading in multiple directions leaves no shortage of suspects.',
    ),
    _EpisodeItem(
      image: 'assets/watch/episodes/Frame-120-2787-1601.png',
      title: '6. Episode 6',
      duration: '1h',
      description:
          'Wendy considers an offer. Holden and Bill struggle to communicate the meaning of their findings to the judicial system in the baffling Altoona case.',
    ),
    _EpisodeItem(
      image: 'assets/watch/episodes/Frame-120-2787-1614.png',
      title: '7. Episode 7',
      duration: '1h',
      description:
          'Wendy takes a career risk to relocate and join the team full time. Holden and Bill find it harder to keep the emotional intensity of work at bay.',
    ),
    _EpisodeItem(
      image: 'assets/watch/episodes/Frame-120-2787-1601.png',
      title: '8. Episode 8',
      duration: '1h',
      description:
          "Bill and Wendy interview candidates for a fourth member of the team. Holden is intrigued by complaints about a school principal's odd habit.",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SeasonSelector(),
        const SizedBox(height: 5),
        for (var index = 0; index < _episodes.length; index++) ...[
          _EpisodeCard(item: _episodes[index]),
          if (index != _episodes.length - 1) const SizedBox(height: 28),
        ],
      ],
    );
  }
}

class _SeasonSelector extends StatelessWidget {
  const _SeasonSelector();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Season 1',
          style: TextStyle(
            color: Color(0xB3FFFFFF),
            fontSize: 16,
            fontFamily: 'Netflix Sans',
            fontWeight: FontWeight.w400,
            letterSpacing: 0.64,
          ),
        ),
        SizedBox(width: 14),
        Icon(
          Icons.keyboard_arrow_down_rounded,
          color: Color(0xB3FFFFFF),
          size: 18,
        ),
      ],
    );
  }
}

class _EpisodeCard extends StatelessWidget {
  const _EpisodeCard({required this.item});

  final _EpisodeItem item;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = (constraints.maxWidth / 347).clamp(0.78, 1.0);
        final imageWidth = 148 * scale;
        final imageHeight = 83 * scale;
        final downloadSize = 32 * scale;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: imageHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: imageWidth,
                    height: imageHeight,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        item.image,
                        width: imageWidth,
                        height: imageHeight,
                        fit: BoxFit.cover,
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
                          item.title,
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
                          item.duration,
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
                  SizedBox(width: 16 * scale),
                  SizedBox(
                    width: downloadSize,
                    height: downloadSize,
                    child: Icon(
                      Icons.file_download_outlined,
                      color: const Color(0xB3FFFFFF),
                      size: 25 * scale,
                    ),
                  ),
                ],
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
          ],
        );
      },
    );
  }
}

class _CastRow extends StatelessWidget {
  const _CastRow();

  static const _cast = [
    _CastItem(
      image: 'assets/watch/vectors/vector-I62-2804-62-2782.png',
      name: 'Tom Hanks',
      role: 'Jeff',
    ),
    _CastItem(
      image: 'assets/watch/vectors/vector-I62-2786-62-2782.png',
      name: 'Tom Hanks',
      role: 'Sharon',
    ),
    _CastItem(
      image: 'assets/watch/vectors/vector-I62-2794-62-2782.png',
      name: 'Tom Hanks',
      role: 'Mary',
    ),
    _CastItem(
      image: 'assets/watch/vectors/vector-I62-2795-62-2782.png',
      name: 'Tom Hanks',
      role: 'Sonia',
    ),
    _CastItem(
      image: 'assets/watch/vectors/vector-I62-2790-62-2782.png',
      name: 'Tom Hanks',
      role: 'Jeff',
    ),
  ];

  @override
  Widget build(BuildContext context) {
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
            itemCount: _cast.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) => _CastCard(item: _cast[index]),
          ),
        ),
      ),
    );
  }
}

class _CastCard extends StatelessWidget {
  const _CastCard({required this.item});

  final _CastItem item;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 77,
      child: Column(
        children: [
          Image.asset(item.image, width: 60, height: 60, fit: BoxFit.contain),
          const SizedBox(height: 10),
          Text(
            item.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
              height: 1.50,
            ),
          ),
          Text(
            item.role,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF707070),
              fontSize: 12,
              fontFamily: 'Inter',
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
              label: 'My List',
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
              label: 'Share',
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
        fontFamily: 'Inter',
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
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                height: 13 / 10,
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
    required this.onSelected,
  });

  final ScrollController controller;
  final String selectedLabel;
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
            _WatchTabItem(
              label: 'Episodes',
              width: 75,
              isActive: selectedLabel == 'Episodes',
              onTap: () => onSelected('Episodes'),
            ),
            const SizedBox(width: 16),
            _WatchTabItem(
              label: 'Collection',
              width: 86,
              isActive: selectedLabel == 'Collection',
              onTap: () => onSelected('Collection'),
            ),
            const SizedBox(width: 16),
            _WatchTabItem(
              label: 'More Like This',
              width: 119,
              isActive: selectedLabel == 'More Like This',
              onTap: () => onSelected('More Like This'),
            ),
            const SizedBox(width: 16),
            _WatchTabItem(
              label: 'Top Cast',
              width: 75,
              isActive: selectedLabel == 'Top Cast',
              onTap: () => onSelected('Top Cast'),
            ),
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
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                        height: 1.50,
                      ),
                    ),
                    Text(
                      '2 Months ago',
                      style: TextStyle(
                        color: WatchScreen._muted,
                        fontSize: 12,
                        fontFamily: 'Inter',
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
            "I always trust the choices of the wonderful Anya Taylor-Joy, who amazes me every time. I think this is the first movie I've watched in the new year, and it was really great.",
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontFamily: 'Inter',
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
                  fontFamily: 'Inter',
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
                  fontFamily: 'Inter',
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
                    'Buy',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontFamily: 'Inter',
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
                      fontFamily: 'Inter',
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

class _CastItem {
  const _CastItem({
    required this.image,
    required this.name,
    required this.role,
  });

  final String image;
  final String name;
  final String role;
}

class _EpisodeItem {
  const _EpisodeItem({
    required this.image,
    required this.title,
    required this.duration,
    required this.description,
  });

  final String image;
  final String title;
  final String duration;
  final String description;
}
