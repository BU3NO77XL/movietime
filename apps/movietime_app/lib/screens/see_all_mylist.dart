import 'dart:ui';

import 'package:flutter/material.dart';

import '../widgets/home_bottom_nav.dart';

class SeeAllMyListScreen extends StatefulWidget {
  const SeeAllMyListScreen({super.key, this.title});

  final String? title;

  static const _bg = Color(0xFF0D0D0D);
  static const _card = Color(0xFF1A1A1A);
  static const _border = Color(0xFF262626);
  static const _muted = Color(0xFF525252);
  static const _lightMuted = Color(0xFF9E9E9E);

  static const _items = [
    _SeeAllItem(
      image: 'assets/images/rectangle-395047-fc8f71de.png',
      title: 'You',
      year: '2025',
    ),
    _SeeAllItem(
      image: 'assets/images/rectangle-395047-44b1c56e.png',
      title: 'Adolesence',
      year: '2025',
    ),
    _SeeAllItem(
      image: 'assets/images/rectangle-395047-d712f5e6.png',
      title: 'Severance',
      year: '2025',
    ),
    _SeeAllItem(
      image: 'assets/images/rectangle-395047-8b3ec893.png',
      title: 'The Last of Us',
      year: '2025',
    ),
    _SeeAllItem(
      image: 'assets/images/rectangle-395045-fc8f71de.png',
      title: 'The Gorge',
      year: '2025',
    ),
    _SeeAllItem(
      image: 'assets/images/rectangle-395044-cd287cf5.png',
      title: 'Arcane',
      year: '2024',
    ),
    _SeeAllItem(
      image:
          'assets/mylist/images/image-124baca1cf984ce56d64128e01abcac487ae5a4d.jpg',
      title: 'The Substance',
      year: '2024',
    ),
    _SeeAllItem(
      image: 'assets/mylist/images/image-I2749-1196-63-1748.png',
      title: 'Black Mirror',
      year: '2025',
    ),
    _SeeAllItem(
      image: 'assets/mylist/images/image-I2749-1198-63-1748.png',
      title: 'Dune',
      year: '2024',
    ),
    _SeeAllItem(
      image: 'assets/mylist/images/image-I63-1778-63-1748.png',
      title: 'Silo',
      year: '2025',
    ),
    _SeeAllItem(
      image: 'assets/mylist/images/image-I63-1772-63-1748.png',
      title: 'From',
      year: '2024',
    ),
    _SeeAllItem(
      image: 'assets/mylist/images/image-I63-1758-63-1748.png',
      title: 'Dark',
      year: '2025',
    ),
  ];

  @override
  State<SeeAllMyListScreen> createState() => _SeeAllMyListScreenState();
}

class _SeeAllMyListScreenState extends State<SeeAllMyListScreen> {
  static const _menus = [
    _FilterMenuData(
      title: 'G\u00EAnero',
      options: ['A\u00E7\u00E3o', 'Drama', 'Suspense'],
    ),
    _FilterMenuData(title: 'Ano', options: ['2025', '2024', '2023']),
    _FilterMenuData(
      title: 'Avalia\u00E7\u00E3o',
      options: ['Mais avaliados', 'Top trending', 'Populares'],
    ),
    _FilterMenuData(
      title: 'Idioma',
      options: ['Portugu\u00EAs', 'Ingl\u00EAs', 'Espanhol'],
    ),
  ];

  final List<int?> _selectedOptions = [null, null, null, null];
  int? _activeFilterIndex;
  bool _searchOpen = false;

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

  @override
  Widget build(BuildContext context) {
    final activeFilterIndex = _activeFilterIndex;

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
                    title: widget.title ?? 'New released',
                    onSearchTap: _openSearch,
                  ),
                  const SizedBox(height: 30),
                  _FilterList(
                    activeIndex: activeFilterIndex,
                    selectedOptions: _selectedOptions,
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
                        itemCount: SeeAllMyListScreen._items.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 15,
                          mainAxisSpacing: 20,
                          mainAxisExtent: cardHeight,
                        ),
                        itemBuilder: (context, index) => _SeeAllPoster(
                          item: SeeAllMyListScreen._items[index],
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
            _FilterPopoverPosition(
              filterIndex: activeFilterIndex,
              child: _FilterPopover(
                data: _menus[activeFilterIndex],
                selectedIndex: _selectedOptions[activeFilterIndex],
                onOptionTap: _selectOption,
              ),
            ),
          if (_searchOpen)
            Positioned.fill(
              child: _SearchOverlay(
                items: SeeAllMyListScreen._items,
                onClose: _closeSearch,
              ),
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
              fontFamily: 'Inter',
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
    required this.onFilterTap,
    required this.onClearFilter,
  });

  final int? activeIndex;
  final List<int?> selectedOptions;
  final ValueChanged<int> onFilterTap;
  final ValueChanged<int> onClearFilter;

  static const _filters = [
    _FilterChipData(label: 'G\u00EAnero', minWidth: 116),
    _FilterChipData(label: 'Year', minWidth: 87),
    _FilterChipData(label: 'Rate', minWidth: 87),
    _FilterChipData(label: 'Language', minWidth: 127),
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
                selectedValue: _SeeAllMyListScreenState._menus[index]
                    .optionLabel(selectedOptions[index]),
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
                    fontFamily: 'Inter',
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
                  fontFamily: 'Inter',
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(
          width: 236,
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
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: SeeAllMyListScreen._lightMuted,
                  fontSize: 12,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  height: 1.33,
                ),
              ),
              const SizedBox(height: 10),
              for (var index = 0; index < data.options.length; index++)
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
                  fontFamily: 'Inter',
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
                          'Search',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontFamily: 'Inter',
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
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
                height: 1.57,
              ),
              decoration: const InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: 'Search title or year',
                hintStyle: TextStyle(
                  color: SeeAllMyListScreen._muted,
                  fontSize: 14,
                  fontFamily: 'Inter',
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
              fontFamily: 'Inter',
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
          'Results',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontFamily: 'Inter',
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
            child: Image.asset(
              item.image,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
            ),
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
                    fontFamily: 'Inter',
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
                    fontFamily: 'Inter',
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
  const _SeeAllPoster({required this.item});

  final _SeeAllItem item;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final posterHeight = constraints.maxWidth * 162 / 104;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                item.image,
                width: double.infinity,
                height: posterHeight,
                fit: BoxFit.cover,
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
                fontFamily: 'Inter',
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
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
                height: 1.6,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SeeAllItem {
  const _SeeAllItem({
    required this.image,
    required this.title,
    required this.year,
  });

  final String image;
  final String title;
  final String year;
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
