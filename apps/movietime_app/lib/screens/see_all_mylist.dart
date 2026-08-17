import 'dart:ui';

import 'package:flutter/material.dart';

import '../services/content_models.dart';
import '../services/content_service.dart';
import '../widgets/home_bottom_nav.dart';
import 'screen_transitions.dart';
import 'watch.dart';

class SeeAllMyListScreen extends StatefulWidget {
  const SeeAllMyListScreen({super.key, this.title, this.items = const []});

  final String? title;
  final List<WatchlistItem> items;

  static const _bg = Color(0xFF0D0D0D);
  static const _card = Color(0xFF1A1A1A);
  static const _border = Color(0xFF262626);
  static const _muted = Color(0xFF525252);
  static const _lightMuted = Color(0xFF9E9E9E);

  @override
  State<SeeAllMyListScreen> createState() => _SeeAllMyListScreenState();
}

class _SeeAllMyListScreenState extends State<SeeAllMyListScreen> {
  late final ContentService _contentService = ContentService();
  late List<_SeeAllItem> _items;

  List<_FilterMenuData> get _menus {
    final genres = <String>{};
    final years = <String>{};
    for (final item in _items) {
      genres.addAll(item.genres);
      if (item.year != '\u2014') years.add(item.year);
    }
    return [
      _FilterMenuData(title: 'G\u00EAnero', options: genres.toList()..sort()),
      _FilterMenuData(
        title: 'Ano',
        options: years.toList()..sort((a, b) => b.compareTo(a)),
      ),
      const _FilterMenuData(
        title: 'Avalia\u00E7\u00E3o',
        options: ['Mais avaliados', 'Em alta', 'Populares'],
      ),
      const _FilterMenuData(
        title: 'Idioma',
        options: ['Portugu\u00EAs', 'Ingl\u00EAs', 'Espanhol'],
      ),
    ];
  }

  final List<int?> _selectedOptions = [null, null, null, null];
  int? _activeFilterIndex;
  bool _searchOpen = false;

  @override
  void initState() {
    super.initState();
    _items = [
      for (final item in widget.items)
        _SeeAllItem(
          content: item,
          image: item.posterUrl ?? '',
          title: item.title,
          year: '\u2014',
        ),
    ];
    _loadMetadata();
  }

  @override
  void dispose() {
    _contentService.close();
    super.dispose();
  }

  Future<void> _loadMetadata() async {
    final enriched = await Future.wait(
      _items.map((item) async {
        try {
          final prefix = item.content.mediaType == 'tv' ? 'tv' : 'movie';
          final data = await _contentService.tmdb(
            '$prefix/${item.content.tmdbId}',
            query: const {'language': 'pt-BR'},
          );
          final rawGenres = data['genres'];
          return item.copyWith(
            genres: [
              if (rawGenres is List<dynamic>)
                for (final genre in rawGenres)
                  if (genre is Map<String, dynamic>)
                    genre['name']?.toString() ?? '',
            ].where((genre) => genre.isNotEmpty).toList(),
            year: _yearFromData(data)?.toString() ?? '\u2014',
            rating: (data['vote_average'] as num?)?.toDouble(),
            language: _languageName(data['original_language']?.toString()),
          );
        } catch (_) {
          return item;
        }
      }),
    );
    if (!mounted) return;
    setState(() {
      _items = enriched;
    });
  }

  int? _yearFromData(Map<String, dynamic> data) {
    final date = (data['release_date'] ?? data['first_air_date'])?.toString();
    return date != null && date.length >= 4
        ? int.tryParse(date.substring(0, 4))
        : null;
  }

  String _languageName(String? code) {
    return switch (code) {
      'pt' => 'Portugu\u00EAs',
      'es' => 'Espanhol',
      _ => 'Ingl\u00EAs',
    };
  }

  void _toggleFilter(int index) {
    setState(() {
      _activeFilterIndex = _activeFilterIndex == index ? null : index;
    });
  }

  void _selectOption(int optionIndex) {
    final filterIndex = _activeFilterIndex;
    if (filterIndex == null) return;

    setState(() {
      _selectedOptions[filterIndex] = optionIndex;
      _activeFilterIndex = null;
    });
  }

  void _clearFilter(int index) {
    setState(() {
      _selectedOptions[index] = null;
      if (_activeFilterIndex == index) _activeFilterIndex = null;
    });
  }

  void _openSearch() {
    setState(() {
      _activeFilterIndex = null;
      _searchOpen = true;
    });
  }

  void _closeSearch() {
    setState(() => _searchOpen = false);
  }

  List<_SeeAllItem> get _filteredItems {
    final menus = _menus;
    return _items.where((item) {
      final genre = _selectedOptions[0] == null
          ? null
          : menus[0].options[_selectedOptions[0]!];
      final year = _selectedOptions[1] == null
          ? null
          : menus[1].options[_selectedOptions[1]!];
      final rating = _selectedOptions[2] == null
          ? null
          : menus[2].options[_selectedOptions[2]!];
      final language = _selectedOptions[3] == null
          ? null
          : menus[3].options[_selectedOptions[3]!];
      if (genre != null && !item.genres.contains(genre)) return false;
      if (year != null && item.year != year) return false;
      if (language != null && item.language != language) return false;
      if (rating == 'Mais avaliados' && (item.rating ?? 0) < 7) return false;
      if (rating == 'Em alta' && (item.rating ?? 0) < 6) return false;
      if (rating == 'Populares' && (item.rating ?? 0) < 5) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final activeFilterIndex = _activeFilterIndex;
    /* final items = [
      for (final item in _filteredItems)
        _SeeAllItem(
          content: item.content,
          image: item.image,
          title: item.title,
          year: '—',
        ),
    ]; */
    final items = _filteredItems;

    return Scaffold(
      backgroundColor: SeeAllMyListScreen._bg,
      bottomNavigationBar: HomeBottomNav(
        activeItem: HomeNavItemId.myList,
        onHomeTap: () => Navigator.of(context).maybePop(),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 42, 24, 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SeeAllHeader(
                    title: widget.title ?? 'Novidades',
                    onSearchTap: _openSearch,
                  ),
                  const SizedBox(height: 30),
                  _FilterList(
                    activeIndex: activeFilterIndex,
                    selectedOptions: _selectedOptions,
                    menus: _menus,
                    onFilterTap: _toggleFilter,
                    onClearFilter: _clearFilter,
                  ),
                  const SizedBox(height: 30),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final cardWidth = (constraints.maxWidth - 30) / 3;
                      final cardHeight = (cardWidth * 162 / 104) + 42;

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: items.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 15,
                          mainAxisSpacing: 20,
                          mainAxisExtent: cardHeight,
                        ),
                        itemBuilder: (context, index) => _SeeAllPoster(
                          item: items[index],
                          onTap: () => Navigator.of(context).push(
                            cinematicPageRoute(
                              WatchScreen.fromWatchlist(items[index].content),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          // Gradiente inferior desativado nesta página.
          // const Positioned(
          //   left: 0,
          //   right: 0,
          //   bottom: 0,
          //   height: 207,
          //   child: IgnorePointer(child: _BottomFade()),
          // ),
          if (activeFilterIndex != null)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => setState(() => _activeFilterIndex = null),
                onPanStart: (_) => setState(() => _activeFilterIndex = null),
              ),
            ),
          if (activeFilterIndex != null)
            Positioned.fill(
              child: _SeeAllFilterModal(
                data: _menus[activeFilterIndex],
                selectedIndex: _selectedOptions[activeFilterIndex],
                onClose: () => setState(() => _activeFilterIndex = null),
                onOptionTap: _selectOption,
              ),
            ),
          if (_searchOpen)
            Positioned.fill(
              child: _SearchOverlay(items: items, onClose: _closeSearch),
            ),
        ],
      ),
    );
  }
}

// Gradiente inferior desativado nesta página.
// class _BottomFade extends StatelessWidget {
//   const _BottomFade();
//
//   @override
//   Widget build(BuildContext context) {
//     return DecoratedBox(
//       decoration: const BoxDecoration(
//         gradient: LinearGradient(
//           begin: Alignment.topCenter,
//           end: Alignment.bottomCenter,
//           colors: [Color(0x000D0D0D), SeeAllMyListScreen._bg],
//           stops: [0, 0.979],
//         ),
//       ),
//     );
//   }
// }

class _SeeAllHeader extends StatelessWidget {
  const _SeeAllHeader({required this.title, required this.onSearchTap});

  final String title;
  final VoidCallback onSearchTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: _HeaderIconButton(
              icon: Icons.chevron_left_rounded,
              onTap: () => Navigator.of(context).maybePop(),
            ),
          ),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontFamily: 'Netflix Sans',
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: _HeaderIconButton(
              icon: Icons.search_rounded,
              onTap: onSearchTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({required this.icon, this.onTap});

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
            colors: [SeeAllMyListScreen._card, Color(0x330D0D0D)],
          ),
          shape: RoundedRectangleBorder(
            side: const BorderSide(width: 1, color: SeeAllMyListScreen._border),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}

class _FilterList extends StatelessWidget {
  const _FilterList({
    required this.activeIndex,
    required this.selectedOptions,
    required this.menus,
    required this.onFilterTap,
    required this.onClearFilter,
  });

  final int? activeIndex;
  final List<int?> selectedOptions;
  final List<_FilterMenuData> menus;
  final ValueChanged<int> onFilterTap;
  final ValueChanged<int> onClearFilter;

  static const _filters = [
    _FilterChipData(label: 'G\u00EAnero', minWidth: 116),
    _FilterChipData(label: 'Ano', minWidth: 87),
    _FilterChipData(label: 'Nota', minWidth: 87),
    _FilterChipData(label: 'Idioma', minWidth: 127),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: SingleChildScrollView(
        key: const ValueKey('see_all_filter_scroll'),
        physics: const BouncingScrollPhysics(),
        clipBehavior: Clip.none,
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var index = 0; index < _filters.length; index++) ...[
              _FilterChip(
                data: _filters[index],
                isActive: activeIndex == index,
                selectedValue: menus[index].optionLabel(selectedOptions[index]),
                onTap: () => onFilterTap(index),
                onClear: () => onClearFilter(index),
              ),
              if (index < _filters.length - 1) const SizedBox(width: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.data,
    required this.isActive,
    required this.selectedValue,
    required this.onTap,
    required this.onClear,
  });

  final _FilterChipData data;
  final bool isActive;
  final String? selectedValue;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final value = selectedValue;
    final isFiltered = value != null;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        constraints: BoxConstraints(minWidth: data.minWidth),
        decoration: ShapeDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [SeeAllMyListScreen._card, Color(0x330D0D0D)],
          ),
          shape: RoundedRectangleBorder(
            side: BorderSide(width: 1, color: _borderColor(isActive, value)),
            borderRadius: BorderRadius.circular(40),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (isFiltered)
              RichText(
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  style: const TextStyle(
                    color: SeeAllMyListScreen._lightMuted,
                    fontSize: 14,
                    fontFamily: 'Netflix Sans',
                    fontWeight: FontWeight.w500,
                    height: 1.57,
                  ),
                  children: [
                    TextSpan(text: '${data.label}: '),
                    TextSpan(
                      text: value,
                      style: const TextStyle(color: Color(0xFF9B6CFF)),
                    ),
                  ],
                ),
              )
            else
              Text(
                data.label,
                maxLines: 1,
                softWrap: false,
                style: const TextStyle(
                  color: SeeAllMyListScreen._lightMuted,
                  fontSize: 14,
                  fontFamily: 'Netflix Sans',
                  fontWeight: FontWeight.w500,
                  height: 1.57,
                ),
              ),
            SizedBox(width: isFiltered ? 14 : 10),
            if (isFiltered)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onClear,
                child: const SizedBox(
                  width: 28,
                  height: 40,
                  child: Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.close_rounded,
                      color: SeeAllMyListScreen._lightMuted,
                      size: 19,
                      opticalSize: 19,
                    ),
                  ),
                ),
              )
            else
              Icon(
                isActive
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                color: SeeAllMyListScreen._lightMuted,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  Color _borderColor(bool isActive, String? value) {
    if (isActive) return Colors.white;
    if (value != null) return SeeAllMyListScreen._lightMuted;
    return SeeAllMyListScreen._border;
  }
}

class _SeeAllFilterModal extends StatelessWidget {
  const _SeeAllFilterModal({
    required this.data,
    required this.selectedIndex,
    required this.onClose,
    required this.onOptionTap,
  });

  final _FilterMenuData data;
  final int? selectedIndex;
  final VoidCallback onClose;
  final ValueChanged<int> onOptionTap;

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
              padding: const EdgeInsets.fromLTRB(24, 42, 24, 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          data.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontFamily: 'Netflix Sans',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      _HeaderIconButton(
                        icon: Icons.close_rounded,
                        onTap: onClose,
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Escolha uma opção',
                    style: TextStyle(
                      color: SeeAllMyListScreen._lightMuted,
                      fontSize: 12,
                      fontFamily: 'Netflix Sans',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: data.options.length,
                      itemBuilder: (context, index) => _FilterOptionRow(
                        label: data.options[index],
                        selected: selectedIndex == index,
                        showDivider: index < data.options.length - 1,
                        onTap: () => onOptionTap(index),
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

// ignore: unused_element
class _FilterPopoverPosition extends StatelessWidget {
  const _FilterPopoverPosition({
    required this.filterIndex,
    required this.child,
  });

  final int filterIndex;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final safeTop = MediaQuery.paddingOf(context).top;
    final preferredLeft = switch (filterIndex) {
      0 => 24.0,
      1 => 100.0,
      2 => 177.0,
      _ => screenWidth - 260,
    };
    final left = preferredLeft.clamp(16.0, screenWidth - 252.0);

    return Positioned(top: safeTop + 163, left: left, child: child);
  }
}

// ignore: unused_element
class _FilterPopover extends StatelessWidget {
  const _FilterPopover({
    required this.data,
    required this.selectedIndex,
    required this.onOptionTap,
  });

  final _FilterMenuData data;
  final int? selectedIndex;
  final ValueChanged<int> onOptionTap;

  @override
  Widget build(BuildContext context) {
    final availableHeight =
        MediaQuery.sizeOf(context).height -
        MediaQuery.paddingOf(context).top -
        163 -
        16;
    final preferredHeight = data.title == 'G\u00EAnero' ? 380.0 : 220.0;
    final popupHeight = preferredHeight
        .clamp(160.0, availableHeight)
        .toDouble();

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: SizedBox(
          width: 236,
          height: popupHeight,
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 20, 20, 8),
            decoration: ShapeDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [SeeAllMyListScreen._card, Color(0x330D0D0D)],
              ),
              shape: RoundedRectangleBorder(
                side: const BorderSide(
                  width: 1,
                  color: SeeAllMyListScreen._border,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: SeeAllMyListScreen._lightMuted,
                    fontSize: 12,
                    fontFamily: 'Netflix Sans',
                    fontWeight: FontWeight.w500,
                    height: 1.33,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        for (
                          var index = 0;
                          index < data.options.length;
                          index++
                        )
                          _FilterOptionRow(
                            label: data.options[index],
                            selected: selectedIndex == index,
                            showDivider: index < data.options.length - 1,
                            onTap: () => onOptionTap(index),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterOptionRow extends StatelessWidget {
  const _FilterOptionRow({
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
        height: 40,
        decoration: BoxDecoration(
          border: Border(
            bottom: showDivider
                ? const BorderSide(color: SeeAllMyListScreen._border, width: 1)
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
                  fontSize: 12,
                  fontFamily: 'Netflix Sans',
                  fontWeight: FontWeight.w500,
                  height: 1.33,
                ),
              ),
            ),
            const SizedBox(width: 10),
            _RadioDot(selected: selected),
          ],
        ),
      ),
    );
  }
}

class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.selected});

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

class _SearchOverlay extends StatefulWidget {
  const _SearchOverlay({required this.items, required this.onClose});

  final List<_SeeAllItem> items;
  final VoidCallback onClose;

  @override
  State<_SearchOverlay> createState() => _SearchOverlayState();
}

class _SearchOverlayState extends State<_SearchOverlay> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final normalizedQuery = _query.trim().toLowerCase();
    final results = normalizedQuery.isEmpty
        ? widget.items.take(5).toList()
        : widget.items
              .where(
                (item) =>
                    item.title.toLowerCase().contains(normalizedQuery) ||
                    item.year.contains(normalizedQuery),
              )
              .toList();

    return Material(
      color: SeeAllMyListScreen._bg,
      child: SafeArea(
        child: Stack(
          fit: StackFit.expand,
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
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 42, 24, 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
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
                      ),
                      _HeaderIconButton(
                        icon: Icons.close_rounded,
                        onTap: widget.onClose,
                      ),
                    ],
                  ),
                  const SizedBox(height: 17),
                  _SearchInput(
                    controller: _controller,
                    onChanged: (value) => setState(() => _query = value),
                    onClear: _query.isEmpty
                        ? null
                        : () {
                            _controller.clear();
                            setState(() => _query = '');
                          },
                  ),
                  const SizedBox(height: 15),
                  _SearchResults(items: results, query: _query),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchInput extends StatelessWidget {
  const _SearchInput({
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
        color: SeeAllMyListScreen._card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 15),
          const Icon(
            Icons.search_rounded,
            color: SeeAllMyListScreen._lightMuted,
            size: 20,
          ),
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
                hintText: 'Buscar título ou ano',
                hintStyle: TextStyle(
                  color: SeeAllMyListScreen._muted,
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
                  color: SeeAllMyListScreen._lightMuted,
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

class _SearchResults extends StatelessWidget {
  const _SearchResults({required this.items, required this.query});

  final List<_SeeAllItem> items;
  final String query;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 44),
        child: Center(
          child: Text(
            'Nenhum resultado para "$query"',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: SeeAllMyListScreen._lightMuted,
              fontSize: 14,
              fontFamily: 'Netflix Sans',
              fontWeight: FontWeight.w500,
              height: 1.57,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Resultados',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontFamily: 'Netflix Sans',
            fontWeight: FontWeight.w500,
            height: 1.57,
          ),
        ),
        const SizedBox(height: 20),
        for (var index = 0; index < items.length; index++) ...[
          _SearchResultTile(item: items[index]),
          if (index < items.length - 1) const SizedBox(height: 11),
        ],
      ],
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({required this.item});

  final _SeeAllItem item;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: ValueKey('search_result_${item.title}'),
      height: 60,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _seeAllImage(item.image, width: 60, height: 60),
          ),
          const SizedBox(width: 15),
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
                  item.year,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: SeeAllMyListScreen._muted,
                    fontSize: 12,
                    fontFamily: 'Netflix Sans',
                    fontWeight: FontWeight.w500,
                    height: 1.33,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const Icon(
            Icons.chevron_right_rounded,
            color: SeeAllMyListScreen._lightMuted,
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _SeeAllPoster extends StatelessWidget {
  const _SeeAllPoster({required this.item, required this.onTap});

  final _SeeAllItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final posterHeight = constraints.maxWidth * 162 / 104;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _seeAllImage(
                  item.image,
                  width: double.infinity,
                  height: posterHeight,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontFamily: 'Netflix Sans',
                  fontWeight: FontWeight.w500,
                  height: 1.33,
                ),
              ),
              Text(
                item.year,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: SeeAllMyListScreen._muted,
                  fontSize: 10,
                  fontFamily: 'Netflix Sans',
                  fontWeight: FontWeight.w400,
                  height: 1.6,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SeeAllItem {
  const _SeeAllItem({
    required this.content,
    required this.image,
    required this.title,
    required this.year,
    this.genres = const [],
    this.rating,
    this.language,
  });

  _SeeAllItem copyWith({
    List<String>? genres,
    String? year,
    double? rating,
    String? language,
  }) {
    return _SeeAllItem(
      content: content,
      image: image,
      title: title,
      year: year ?? this.year,
      genres: genres ?? this.genres,
      rating: rating ?? this.rating,
      language: language ?? this.language,
    );
  }

  final String image;
  final WatchlistItem content;
  final String title;
  final String year;
  final List<String> genres;
  final double? rating;
  final String? language;
}

Widget _seeAllImage(
  String image, {
  required double width,
  required double height,
}) {
  if (image.isEmpty) {
    return SizedBox(
      width: width,
      height: height,
      child: const ColoredBox(
        color: Color(0xFF262626),
        child: Icon(
          Icons.image_not_supported_outlined,
          color: Color(0xFF525252),
        ),
      ),
    );
  }

  final isRemote = image.startsWith('http://') || image.startsWith('https://');
  final child = isRemote
      ? Image.network(
          image,
          width: width,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const ColoredBox(
            color: Color(0xFF262626),
            child: Icon(
              Icons.image_not_supported_outlined,
              color: Color(0xFF525252),
            ),
          ),
        )
      : Image.asset(image, width: width, height: height, fit: BoxFit.cover);
  return child;
}

class _FilterChipData {
  const _FilterChipData({required this.label, required this.minWidth});

  final String label;
  final double minWidth;
}

class _FilterMenuData {
  const _FilterMenuData({required this.title, required this.options});

  final String title;
  final List<String> options;

  String? optionLabel(int? index) {
    if (index == null || index < 0 || index >= options.length) return null;
    return options[index];
  }
}
