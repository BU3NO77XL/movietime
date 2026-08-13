import 'dart:ui';

import 'package:flutter/material.dart';

import 'mylist.dart';
import 'profile.dart';
import 'screen_transitions.dart';
import 'watch.dart';
import '../widgets/home_bottom_nav.dart';
import 'home_search.dart';

/// Tela "Início" (Home) gerada a partir do código-fonte-da-home,
/// com o mesmo estilo visual: fundo escuro, destaque central,
/// categorias, carrosséis de filmes e barra de navegação inferior.
class Home extends StatelessWidget {
  const Home({super.key});

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
                // Base: fundo preto da tela (bg scroll do Figma)
                const ColoredBox(color: Color(0xFF0D0D0D)),

                // Área do blur: imagem borrada até o carrossel "Continue Assistindo"
                // (hero blur clip do Figma - 914px de altura)
                // Conteúdo scrollável
                SingleChildScrollView(
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
                                child: Image.asset(
                                  "assets/home/images/image-4929e57e7d013ce2bef71f7eaf6511776f15bbaf.png",
                                  fit: BoxFit.cover,
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
                          // Cabeçalho: logo + título "Início" + ícones à direita
                          Padding(
                            padding: const EdgeInsets.fromLTRB(21, 58, 16, 12),
                            child: Row(
                              children: [
                                Image.asset(
                                  "assets/home/vectors/vector-2688-1528.png",
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
                                  "assets/home/vectors/vector-2688-1548.png",
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
                                    "assets/home/vectors/vector-2688-1549.png",
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

                          // Destaque principal (card hero)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 22),
                            child: _HeroCard(),
                          ),

                          const SizedBox(height: 24),

                          // Carrossel "Continue Assistindo"
                          const _SectionTitle(title: 'Continue Assistindo'),
                          const SizedBox(height: 12),
                          _PosterRow(
                            images: const [
                              "assets/home/images/image-0fa018d1465063ab7cd1fc1419c53cfc69a8891a.png",
                              "assets/home/images/image-9dcfbaaf8cc2c3c348a5364db83832270486e1a0.png",
                              "assets/home/images/image-ff8b37a14527480f375bc225f67fddfc58ed6f83.png",
                              "assets/home/images/image-b654afd941c1b8341bdebd6896412e106b83e46e.png",
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Carrossel "Em Alta"
                          const _SectionTitle(title: 'Em Alta'),
                          const SizedBox(height: 12),
                          _PosterRow(
                            images: const [
                              "assets/home/images/image-0de0dc59d9ec0472e71c82c6137e5e8eedf5a832.png",
                              "assets/home/images/image-0839a5c3fb23f37997085d056599dd4899c04436.png",
                              "assets/home/images/image-35dfeae3fe6baa198696331d2578f4e7c6fba1e7.png",
                              "assets/home/images/image-d68712d3a36f2fbbfadfe378b9f557782090f3af.png",
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Carrossel "Top 10 no Brasil"
                          const _SectionTitle(title: 'Top 10 no Brasil'),
                          const SizedBox(height: 12),
                          _PosterRow(
                            images: const [
                              "",
                              "assets/home/images/image-9ad3cea5150db97346e72805978aaeefa3a32a3d.png",
                              "assets/home/images/image-6ab8120ae3c8c35ba3a48812780635ba3ef599c0.png",
                              "assets/home/images/image-d4bf417506f53feabc70b3ae27433dca7e23157f.png",
                            ],
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

/// Chip de filtro (Séries / Filmes / Novidades / Categorias).
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

/// Card de destaque principal (hero).
class _HeroCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardHeight = (constraints.maxWidth * 487 / 345)
            .clamp(360.0, 487.0)
            .toDouble();
        final isCompactHero = constraints.maxWidth < 260;
        final logoHeight = isCompactHero ? 104.0 : 120.0;
        final categoryFontSize = isCompactHero ? 13.0 : 14.0;
        final bottomSpacing = isCompactHero ? 10.0 : 16.0;

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
                child: Image.asset(
                  "assets/home/images/image-2687-1462.png",
                  fit: BoxFit.cover,
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
                    Image.asset(
                      "assets/home/images/image-2687-1465.png",
                      width: double.infinity,
                      height: logoHeight,
                      fit: BoxFit.cover,
                    ),
                    const SizedBox(height: 8),
                    // Título / categorias
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 4,
                      children: [
                        Text(
                          'Udda',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: categoryFontSize,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        Text(
                          '•',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: categoryFontSize,
                          ),
                        ),
                        Text(
                          'Fyndig',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: categoryFontSize,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        Text(
                          '•',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: categoryFontSize,
                          ),
                        ),
                        Text(
                          'Mörk komedi',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: categoryFontSize,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Botões Assistir / Minha Lista
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.of(
                                  context,
                                ).push(cinematicPageRoute(const WatchScreen()));
                              },
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
                              onTap: () {
                                Navigator.of(context).push(
                                  cinematicPageRoute(const MyListScreen()),
                                );
                              },
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

/// Título de seção dos carrosséis.
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

/// Linha de pôsteres (carrossel horizontal).
class _PosterRow extends StatelessWidget {
  const _PosterRow({required this.images});

  final List<String> images;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: images.length,
        separatorBuilder: (_, _) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final image = images[index];
          return Container(
            width: 120,
            height: 180,
            clipBehavior: Clip.antiAlias,
            decoration: ShapeDecoration(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              image: image.isEmpty
                  ? null
                  : DecorationImage(
                      image: AssetImage(image),
                      fit: BoxFit.cover,
                    ),
            ),
          );
        },
      ),
    );
  }
}
