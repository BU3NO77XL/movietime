import 'dart:ui';

import 'package:flutter/material.dart';

import '../widgets/authenticated_avatar_image.dart';

class HomeSearchScreen extends StatefulWidget {
  const HomeSearchScreen({super.key, this.scrollController});

  final ScrollController? scrollController;

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
  static const _categories = ['New', 'Sci-Fi', 'Comedy', 'Romance'];
  static const _typeFilters = ['All', 'Movies', 'Series', 'Artists'];
  static const _artists = [
    _HomeSearchArtist(
      avatarIndex: 0,
      name: 'Tom Hanks',
    ),
    _HomeSearchArtist(
      avatarIndex: 1,
      name: 'Emma Stone',
    ),
    _HomeSearchArtist(
      avatarIndex: 2,
      name: 'Emily Blunt',
    ),
    _HomeSearchArtist(
      avatarIndex: 3,
      name: 'Tom Hardy',
    ),
  ];

  static const _items = [
    _HomeSearchItem(
      image:
          'assets/mylist/images/image-124baca1cf984ce56d64128e01abcac487ae5a4d.jpg',
      title: 'The Substance',
      type: 'Movies',
      category: 'New',
      year: '2024',
      rating: '7.3',
    ),
    _HomeSearchItem(
      image: 'assets/images/rectangle-395047-fc8f71de.png',
      title: 'You',
      type: 'Series',
      category: 'New',
      year: '2018',
      rating: '7.7',
    ),
    _HomeSearchItem(
      image: 'assets/images/rectangle-395047-d712f5e6.png',
      title: 'Severance',
      type: 'Series',
      category: 'Sci-Fi',
      year: '2022',
      rating: '8.7',
    ),
    _HomeSearchItem(
      image: 'assets/images/rectangle-395047-8b3ec893.png',
      title: 'The Last of Us',
      type: 'Series',
      category: 'New',
      year: '2023',
      rating: '8.6',
    ),
    _HomeSearchItem(
      image: 'assets/images/rectangle-395045-fc8f71de.png',
      title: 'The Gorge',
      type: 'Movies',
      category: 'Romance',
      year: '2025',
      rating: '6.7',
    ),
    _HomeSearchItem(
      image: 'assets/images/rectangle-395044-cd287cf5.png',
      title: 'Arcane',
      type: 'Series',
      category: 'Comedy',
      year: '2021',
      rating: '9.0',
    ),
    _HomeSearchItem(
      image: 'assets/mylist/images/image-I2749-1196-63-1748.png',
      title: 'Black Mirror',
      type: 'Series',
      category: 'Sci-Fi',
      year: '2011',
      rating: '8.7',
    ),
    _HomeSearchItem(
      image: 'assets/mylist/images/image-I2749-1198-63-1748.png',
      title: 'Dune',
      type: 'Movies',
      category: 'Sci-Fi',
      year: '2021',
      rating: '8.0',
    ),
    _HomeSearchItem(
      image: 'assets/images/rectangle-395047-44b1c56e.png',
      title: 'Adolesence',
      type: 'Series',
      category: 'Comedy',
      year: '2025',
      rating: '7.2',
    ),
  ];

  final _controller = TextEditingController();
  String _query = '';
  int _selectedType = 0;
  int _selectedCategory = 0;
  bool _categoryFilterOpen = false;
  bool _gridView = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<_HomeSearchItem> get _visibleItems {
    final type = _typeFilters[_selectedType];
    final hasCategoryFilter = _selectedCategory >= 0;
    final category = hasCategoryFilter ? _categories[_selectedCategory] : null;
    final normalizedQuery = _query.trim().toLowerCase();

    return _items.where((item) {
      final matchesCategory = category == null || item.category == category;
      final matchesType = type == 'All' || item.type == type;
      final matchesQuery =
          normalizedQuery.isEmpty ||
          item.title.toLowerCase().contains(normalizedQuery);
      return matchesCategory && matchesType && matchesQuery;
    }).toList();
  }

  List<_HomeSearchItem> get _typingMovies {
    final normalizedQuery = _query.trim().toLowerCase();
    final movies = _items.where((item) => item.type == 'Movies').toList();
    final matches = movies
        .where((item) => item.title.toLowerCase().contains(normalizedQuery))
        .toList();
    return matches.isEmpty ? movies.take(2).toList() : matches.take(2).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isTyping = _query.trim().isNotEmpty;

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
                  const SizedBox(height: 20),
                  _SearchField(
                    controller: _controller,
                    onChanged: (value) => setState(() => _query = value),
                    onClear: _query.isEmpty
                        ? null
                        : () {
                            _controller.clear();
                            setState(() => _query = '');
                          },
                  ),
                  if (isTyping) ...[
                    const SizedBox(height: 15),
                    _TypingSearchResults(
                      movies: _typingMovies,
                      artists: _artists,
                    ),
                  ] else ...[
                    const SizedBox(height: 20),
                    _CategoryChips(
                      categories: _typeFilters,
                      selectedIndex: _selectedType,
                      onSelect: (index) =>
                          setState(() => _selectedType = index),
                    ),
                    const SizedBox(height: 20),
                    _SearchViewToggles(
                      onSettingsTap: () {
                        setState(
                          () => _categoryFilterOpen = !_categoryFilterOpen,
                        );
                      },
                      categoryLabel: _categories[_selectedCategory],
                      categoryActive: true,
                      viewLabel: _gridView ? 'Grid' : 'List',
                      viewActive: !_gridView,
                      onViewTap: () => setState(() => _gridView = !_gridView),
                    ),
                    const SizedBox(height: 20),
                    _gridView
                        ? _SearchGrid(items: _visibleItems)
                        : _SearchList(items: _visibleItems),
                  ],
                ],
              ),
            ),
            if (_categoryFilterOpen && !isTyping)
              Positioned.fill(
                child: _CategoryFilterModal(
                  options: _categories,
                  selectedIndex: _selectedCategory,
                  onClose: () => setState(() => _categoryFilterOpen = false),
                  onSelect: (index) {
                    setState(() {
                      _selectedCategory = index;
                      _categoryFilterOpen = false;
                    });
                  },
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
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
                height: 1.57,
              ),
              decoration: const InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: 'Artists, Films, Tv shows ...',
                hintStyle: TextStyle(
                  color: HomeSearchScreen.muted,
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
              fontFamily: 'Inter',
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
    required this.categoryLabel,
    required this.categoryActive,
    required this.viewLabel,
    required this.viewActive,
    required this.onViewTap,
  });

  final VoidCallback onSettingsTap;
  final String categoryLabel;
  final bool categoryActive;
  final String viewLabel;
  final bool viewActive;
  final VoidCallback onViewTap;

  @override
  Widget build(BuildContext context) {
    final categoryColor = categoryActive
        ? Colors.white
        : HomeSearchScreen.muted;
    final viewColor = viewActive ? Colors.white : HomeSearchScreen.muted;

    return Row(
      children: [
        _SearchToggleAction(
          key: const ValueKey('home_search_settings_filter'),
          onTap: onSettingsTap,
          icon: _StrokeIcon(painter: _Settings04Painter(color: categoryColor)),
          label: categoryLabel,
          color: categoryColor,
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
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
              height: 1.33,
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

  final List<String> options;
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
                          'Categories',
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
                      _SearchIconButton(
                        icon: Icons.close_rounded,
                        onTap: onClose,
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Choose category',
                    style: TextStyle(
                      color: HomeSearchScreen.lightMuted,
                      fontSize: 12,
                      fontFamily: 'Inter',
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
                        label: options[index],
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
                  fontFamily: 'Inter',
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
  const _SearchGrid({required this.items});

  final List<_HomeSearchItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 48),
        child: Center(
          child: Text(
            'No results found',
            style: TextStyle(
              color: HomeSearchScreen.lightMuted,
              fontSize: 14,
              fontFamily: 'Inter',
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
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 15,
            mainAxisSpacing: 20,
            mainAxisExtent: cardHeight,
          ),
          itemBuilder: (context, index) => _SearchPoster(item: items[index]),
        );
      },
    );
  }
}

class _SearchPoster extends StatelessWidget {
  const _SearchPoster({required this.item});

  final _HomeSearchItem item;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.asset(item.image, fit: BoxFit.cover),
    );
  }
}

class _TypingSearchResults extends StatelessWidget {
  const _TypingSearchResults({required this.movies, required this.artists});

  final List<_HomeSearchItem> movies;
  final List<_HomeSearchArtist> artists;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SearchResultSectionHeader(title: 'Movies'),
        const SizedBox(height: 20),
        SizedBox(
          height: 127,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            physics: const BouncingScrollPhysics(),
            itemCount: movies.length,
            separatorBuilder: (context, index) => const SizedBox(width: 15),
            itemBuilder: (context, index) =>
                _TypingMoviePoster(item: movies[index]),
          ),
        ),
        const SizedBox(height: 27),
        const _SearchResultSectionHeader(title: 'Artists', showViewAll: true),
        const SizedBox(height: 12),
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

class _SearchResultSectionHeader extends StatelessWidget {
  const _SearchResultSectionHeader({
    required this.title,
    this.showViewAll = false,
  });

  final String title;
  final bool showViewAll;

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
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
                height: 1.57,
              ),
            ),
          ),
          if (showViewAll)
            const Text(
              'View all',
              style: TextStyle(
                color: HomeSearchScreen.muted,
                fontSize: 12,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
                height: 1.33,
              ),
            ),
        ],
      ),
    );
  }
}

class _TypingMoviePoster extends StatelessWidget {
  const _TypingMoviePoster({required this.item});

  final _HomeSearchItem item;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.asset(
        item.image,
        width: 104,
        height: 127,
        fit: BoxFit.cover,
      ),
    );
  }
}

class _ArtistResultCard extends StatelessWidget {
  const _ArtistResultCard({required this.artist});

  final _HomeSearchArtist artist;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 77,
      height: 106,
      child: Column(
        children: [
          ClipOval(
            child: AuthenticatedAvatarImage(
              avatarIndex: artist.avatarIndex,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
            ),
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
              fontFamily: 'Inter',
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
  const _SearchList({required this.items});

  final List<_HomeSearchItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 48),
        child: Center(
          child: Text(
            'No results found',
            style: TextStyle(
              color: HomeSearchScreen.lightMuted,
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
      children: [
        for (var index = 0; index < items.length; index++)
          _SearchListTile(
            item: items[index],
            showDivider: index < items.length - 1,
          ),
      ],
    );
  }
}

class _SearchListTile extends StatelessWidget {
  const _SearchListTile({required this.item, required this.showDivider});

  final _HomeSearchItem item;
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
            child: Image.asset(
              item.image,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
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
                    color: HomeSearchScreen.muted,
                    fontSize: 12,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                    height: 1.33,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _RatingBadge(rating: item.rating),
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
            width: 13,
            height: 12,
            child: CustomPaint(painter: _RatingStarPainter()),
          ),
          const SizedBox(width: 5.2),
          Text(
            rating,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
              height: 1.33,
            ),
          ),
        ],
      ),
    );
  }
}

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
      ..cubicTo(10.2799, 11.5372, 10.3092, 11.7084, 10.2541, 11.8099)
      ..cubicTo(10.2061, 11.8983, 10.1208, 11.9602, 10.0219, 11.9786)
      ..cubicTo(9.90827, 11.9996, 9.7546, 11.9188, 9.44726, 11.7572)
      ..lineTo(6.53211, 10.2241)
      ..cubicTo(6.44128, 10.1764, 6.39586, 10.1525, 6.34802, 10.1431)
      ..cubicTo(6.30565, 10.1348, 6.26208, 10.1348, 6.21972, 10.1431)
      ..cubicTo(6.17187, 10.1525, 6.12645, 10.1764, 6.03563, 10.2241)
      ..lineTo(3.12047, 11.7572)
      ..cubicTo(2.81313, 11.9188, 2.65946, 11.9996, 2.54584, 11.9786)
      ..cubicTo(2.44698, 11.9602, 2.36167, 11.8983, 2.31368, 11.8099)
      ..cubicTo(2.25852, 11.7084, 2.28787, 11.5372, 2.34657, 11.195)
      ..lineTo(2.90311, 7.95007)
      ..cubicTo(2.92046, 7.8489, 2.92914, 7.79832, 2.92327, 7.74991)
      ..cubicTo(2.91807, 7.70705, 2.9046, 7.66561, 2.88359, 7.62788)
      ..cubicTo(2.85987, 7.58528, 2.82311, 7.54947, 2.74958, 7.47785)
      ..lineTo(0.390894, 5.18049)
      ..cubicTo(0.142296, 4.93836, 0.0179973, 4.81729, 0.00287169, 4.70276)
      ..cubicTo(-0.0102884, 4.60311, 0.0222232, 4.50284, 0.0913546, 4.42987)
      ..cubicTo(0.170811, 4.346, 0.342502, 4.3209, 0.685883, 4.27071)
      ..lineTo(3.94673, 3.79409)
      ..cubicTo(4.04814, 3.77927, 4.09884, 3.77186, 4.143, 3.75132)
      ..cubicTo(4.1821, 3.73314, 4.2173, 3.70755, 4.24664, 3.67596)
      ..cubicTo(4.27979, 3.64028, 4.30247, 3.59433, 4.34784, 3.50243)
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

class _HomeSearchItem {
  const _HomeSearchItem({
    required this.image,
    required this.title,
    required this.type,
    required this.category,
    required this.year,
    required this.rating,
  });

  final String image;
  final String title;
  final String type;
  final String category;
  final String year;
  final String rating;
}

class _HomeSearchArtist {
  const _HomeSearchArtist({required this.avatarIndex, required this.name});

  final int avatarIndex;
  final String name;
}
