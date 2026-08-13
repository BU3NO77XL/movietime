import 'package:flutter/material.dart';

enum HomeNavItemId { home, trending, myList, myTime }

class HomeBottomNav extends StatelessWidget {
  const HomeBottomNav({
    super.key,
    this.activeItem = HomeNavItemId.home,
    this.onHomeTap,
    this.onMyListTap,
    this.onMyTimeTap,
  });

  final HomeNavItemId activeItem;
  final VoidCallback? onHomeTap;
  final VoidCallback? onMyListTap;
  final VoidCallback? onMyTimeTap;

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
                label: 'Início',
                active: activeItem == HomeNavItemId.home,
                onTap: onHomeTap,
              ),
              _NavItem(
                icon: 'assets/home/vectors/vector-2705-1278.png',
                label: 'Em Alta',
                active: activeItem == HomeNavItemId.trending,
              ),
              _NavItem(
                icon: 'assets/home/vectors/vector-I2704-1244-1-1791.png',
                label: 'Minha Lista',
                active: activeItem == HomeNavItemId.myList,
                onTap: activeItem == HomeNavItemId.myList ? null : onMyListTap,
              ),
              _NavItem(
                icon: 'assets/home/vectors/vector-2705-1282.png',
                label: 'Minha Time',
                active: activeItem == HomeNavItemId.myTime,
                tintIcon: false,
                onTap: activeItem == HomeNavItemId.myTime ? null : onMyTimeTap,
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
