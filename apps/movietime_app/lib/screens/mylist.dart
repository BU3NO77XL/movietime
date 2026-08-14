import 'dart:ui';

import 'package:flutter/material.dart';

import 'create_list_modal.dart';
import 'my_list_state.dart';
import 'profile.dart';
import 'screen_transitions.dart';
import 'see_all_mylist.dart';
import 'watch_series_mylist.dart';

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
  // ignore: unused_element
  Future<void> _openCreateListModal() async {
    final name = await showCreateListModal(context);
    if (name == null) return;

    setState(() => MyListState.createList(name));
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
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 42, 0, 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 21),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            MyListState.hasCreatedList
                                ? MyListState.listName
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
                        // Botão "Adicionar" desativado: a criação da lista fica
                        // vinculada ao fluxo de salvar conteúdo pela primeira vez.
                        // GestureDetector(
                        //   behavior: HitTestBehavior.opaque,
                        //   onTap: _openCreateListModal,
                        //   child: Container(
                        //     width: 112,
                        //     height: 40,
                        //     decoration: ShapeDecoration(
                        //       gradient: const LinearGradient(
                        //         begin: Alignment.topCenter,
                        //         end: Alignment.bottomCenter,
                        //         colors: [
                        //           MyListScreen._card,
                        //           Color(0x330D0D0D),
                        //         ],
                        //       ),
                        //       shape: RoundedRectangleBorder(
                        //         side: const BorderSide(
                        //           width: 1,
                        //           color: Color(0xFF2C2C2C),
                        //         ),
                        //         borderRadius: BorderRadius.circular(40),
                        //       ),
                        //     ),
                        //     child: Row(
                        //       mainAxisAlignment: MainAxisAlignment.center,
                        //       children: [
                        //         Image.asset(
                        //           'assets/mylist/vectors/vector-I2748-1182-61-5603-1-2275.png',
                        //           width: 20,
                        //           height: 20,
                        //         ),
                        //         const SizedBox(width: 10),
                        //         const Flexible(
                        //           child: Text(
                        //             'Adicionar',
                        //             overflow: TextOverflow.ellipsis,
                        //             style: TextStyle(
                        //               color: MyListScreen._lightMuted,
                        //               fontSize: 12,
                        //               fontFamily: 'Inter',
                        //               fontWeight: FontWeight.w500,
                        //               height: 1.33,
                        //             ),
                        //           ),
                        //         ),
                        //       ],
                        //     ),
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  _FeaturedSection(
                    title: 'Imperdiveis',
                    items: const [
                      _FeaturedItem(
                        image:
                            'assets/mylist/images/image-I63-1609-63-1598.png',
                        title: 'Look for the light',
                        subtitle: 'S01 . E02',
                        opensSeriesWatch: true,
                      ),
                      _FeaturedItem(
                        image:
                            'assets/mylist/images/image-I63-1616-63-1598.png',
                        title: 'Look for the light',
                        subtitle: 'S01 . E02',
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  const _PosterSection(
                    title: 'Adicionados na lista',
                    posters: [
                      _PosterItem(
                        image:
                            'assets/mylist/images/image-124baca1cf984ce56d64128e01abcac487ae5a4d.jpg',
                        bar:
                            'assets/mylist/vectors/vector-I63-1765-63-1750.png',
                        progress:
                            'assets/mylist/vectors/vector-I63-1765-63-1751.png',
                      ),
                      _PosterItem(
                        image:
                            'assets/mylist/images/image-I63-1778-63-1748.png',
                        bar:
                            'assets/mylist/vectors/vector-I63-1778-63-1750.png',
                        progress:
                            'assets/mylist/vectors/vector-I63-1778-63-1751.png',
                      ),
                      _PosterItem(
                        image:
                            'assets/mylist/images/image-I63-1772-63-1748.png',
                        bar:
                            'assets/mylist/vectors/vector-I63-1772-63-1750.png',
                        progress:
                            'assets/mylist/vectors/vector-I63-1772-63-1751.png',
                      ),
                      _PosterItem(
                        image:
                            'assets/mylist/images/image-I63-1758-63-1748.png',
                        bar:
                            'assets/mylist/vectors/vector-I63-1758-63-1750.png',
                        progress:
                            'assets/mylist/vectors/vector-I63-1758-63-1751.png',
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  const _PosterSection(
                    title: 'Vistos recentemente',
                    posters: [
                      _PosterItem(
                        image:
                            'assets/mylist/images/image-124baca1cf984ce56d64128e01abcac487ae5a4d.jpg',
                        bar:
                            'assets/mylist/vectors/vector-I2749-1194-63-1750.png',
                        progress:
                            'assets/mylist/vectors/vector-I2749-1194-63-1751.png',
                      ),
                      _PosterItem(
                        image:
                            'assets/mylist/images/image-I2749-1196-63-1748.png',
                        bar:
                            'assets/mylist/vectors/vector-I2749-1196-63-1750.png',
                        progress:
                            'assets/mylist/vectors/vector-I2749-1196-63-1751.png',
                      ),
                      _PosterItem(
                        image:
                            'assets/mylist/images/image-I2749-1198-63-1748.png',
                        bar:
                            'assets/mylist/vectors/vector-I2749-1198-63-1750.png',
                        progress:
                            'assets/mylist/vectors/vector-I2749-1198-63-1751.png',
                      ),
                      _PosterItem(
                        image:
                            'assets/mylist/images/image-I2749-1200-63-1748.png',
                        bar:
                            'assets/mylist/vectors/vector-I2749-1200-63-1750.png',
                        progress:
                            'assets/mylist/vectors/vector-I2749-1200-63-1751.png',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturedSection extends StatelessWidget {
  const _FeaturedSection({required this.title, required this.items});

  final String title;
  final List<_FeaturedItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: title),
        const SizedBox(height: 20),
        SizedBox(
          height: 263,
          child: Transform.translate(
            offset: const Offset(-24, 0),
            child: OverflowBox(
              alignment: Alignment.centerLeft,
              minWidth: MediaQuery.sizeOf(context).width,
              maxWidth: MediaQuery.sizeOf(context).width,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(width: 20),
                itemBuilder: (context, index) =>
                    _FeaturedCard(item: items[index]),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({required this.item});

  final _FeaturedItem item;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: 306,
      padding: const EdgeInsets.all(12),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.asset(
              item.image,
              width: double.infinity,
              height: 187,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Text(
              item.title,
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
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Text(
              item.subtitle,
              style: const TextStyle(
                color: MyListScreen._muted,
                fontSize: 12,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
                height: 1.33,
              ),
            ),
          ),
        ],
      ),
    );

    if (!item.opensSeriesWatch) return card;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Navigator.of(
          context,
        ).push(cinematicPageRoute(const WatchSeriesMyListScreen()));
      },
      child: card,
    );
  }
}

class _PosterSection extends StatelessWidget {
  const _PosterSection({required this.title, required this.posters});

  final String title;
  final List<_PosterItem> posters;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: title),
        const SizedBox(height: 20),
        SizedBox(
          height: 161,
          child: Transform.translate(
            offset: const Offset(-24, 0),
            child: OverflowBox(
              alignment: Alignment.centerLeft,
              minWidth: MediaQuery.sizeOf(context).width,
              maxWidth: MediaQuery.sizeOf(context).width,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: posters.length,
                separatorBuilder: (_, _) => const SizedBox(width: 14),
                itemBuilder: (context, index) =>
                    _PosterCard(item: posters[index]),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PosterCard extends StatelessWidget {
  const _PosterCard({required this.item});

  final _PosterItem item;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8.32),
            child: Image.asset(
              item.image,
              width: 100,
              height: 147,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 10),
          Image.asset(item.bar, width: 55.47, height: 1.87, fit: BoxFit.fill),
          Image.asset(
            item.progress,
            width: 20.34,
            height: 1.87,
            fit: BoxFit.fill,
          ),
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
    return Padding(
      padding: const EdgeInsets.only(right: 21),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
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
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              Navigator.of(
                context,
              ).push(cinematicPageRoute(SeeAllMyListScreen(title: title)));
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Ver tudo',
                    style: TextStyle(
                      color: MyListScreen._lightMuted,
                      fontSize: 13,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                      height: 1.23,
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: MyListScreen._lightMuted,
                    size: 16,
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

class _FeaturedItem {
  const _FeaturedItem({
    required this.image,
    required this.title,
    required this.subtitle,
    this.opensSeriesWatch = false,
  });

  final String image;
  final String title;
  final String subtitle;
  final bool opensSeriesWatch;
}

class _PosterItem {
  const _PosterItem({
    required this.image,
    required this.bar,
    required this.progress,
  });

  final String image;
  final String bar;
  final String progress;
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
