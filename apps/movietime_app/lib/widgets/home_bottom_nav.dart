import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/avatar_state.dart';
import 'authenticated_avatar_image.dart';

enum HomeNavItemId { home, trending, myList, myTime }

class HomeBottomNav extends StatefulWidget {
  const HomeBottomNav({
    super.key,
    this.activeItem = HomeNavItemId.home,
    this.onHomeTap,
    this.onTrendingTap,
    this.onMyListTap,
    this.onMyTimeTap,
  });

  final HomeNavItemId activeItem;
  final VoidCallback? onHomeTap;
  final VoidCallback? onTrendingTap;
  final VoidCallback? onMyListTap;
  final VoidCallback? onMyTimeTap;

  @override
  State<HomeBottomNav> createState() => _HomeBottomNavState();
}

class _HomeBottomNavState extends State<HomeBottomNav> {
  late final AuthService _authService;
  late final Future<_BottomNavAvatar?> _avatarFuture;
  _BottomNavAvatar? _avatar;

  @override
  void initState() {
    super.initState();
    _authService = AuthService();
    // Inicializa síncrono com o cache em memória para não piscar
    final cachedIndex = AvatarState.instance.avatarIndex;
    final cachedUrl = AvatarState.instance.avatarUrl;
    if (cachedIndex != null) {
      _avatar = _BottomNavAvatar(avatarIndex: cachedIndex, avatarUrl: cachedUrl);
    }
    _avatarFuture = _loadAvatar();
    AvatarState.instance.addListener(_onAvatarChanged);
    // Hidrata do localStorage (primeira vez após restart) sem piscar mockado
    AvatarState.instance.hydrate().then((_) {
      if (!mounted) return;
      final idx = AvatarState.instance.avatarIndex;
      if (idx != null && _avatar == null) {
        setState(() {
          _avatar = _BottomNavAvatar(
            avatarIndex: idx,
            avatarUrl: AvatarState.instance.avatarUrl,
          );
        });
      }
    });
  }

  @override
  void dispose() {
    AvatarState.instance.removeListener(_onAvatarChanged);
    _authService.close();
    super.dispose();
  }

  void _onAvatarChanged() {
    final index = AvatarState.instance.avatarIndex;
    if (index == null || !mounted) return;
    setState(() {
      _avatar = _BottomNavAvatar(
        avatarIndex: index,
        avatarUrl: AvatarState.instance.avatarUrl,
      );
    });
  }

  Future<_BottomNavAvatar?> _loadAvatar() async {
    // Se já temos avatar em memória (vindo do login/profile), não refaz rede
    if (_avatar != null) return _avatar;
    try {
      final user = await _authService.profile();
      final loaded = _BottomNavAvatar(
        avatarIndex: user.preferences?.avatarIndex ?? 0,
        avatarUrl: user.avatarUrl,
      );
      // Sincroniza cache global para próximas instâncias do menu
      AvatarState.instance.update(
        avatarIndex: loaded.avatarIndex,
        avatarUrl: loaded.avatarUrl,
      );
      if (mounted) {
        setState(() => _avatar = loaded);
      }
      return loaded;
    } catch (_) {
      return _avatar;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.black,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                _NavItem(
                  icon: 'assets/home/vectors/vector-2705-1275.png',
                  label: 'Início',
                  active: widget.activeItem == HomeNavItemId.home,
                  onTap: widget.onHomeTap,
                ),
                _NavItem(
                  icon: 'assets/home/vectors/vector-2705-1278.png',
                  label: 'Em Alta',
                  active: widget.activeItem == HomeNavItemId.trending,
                  onTap: widget.activeItem == HomeNavItemId.trending
                      ? null
                      : widget.onTrendingTap,
                ),
                _NavItem(
                  icon: 'assets/home/vectors/vector-I2704-1244-1-1791.png',
                  label: 'Minha Lista',
                  active: widget.activeItem == HomeNavItemId.myList,
                  onTap: widget.activeItem == HomeNavItemId.myList
                      ? null
                      : widget.onMyListTap,
                ),
                FutureBuilder<_BottomNavAvatar?>(
                  future: _avatarFuture,
                  builder: (context, snapshot) {
                    // Prioriza cache síncrono (_avatar) para evitar piscada
                    // vector -> local -> remoto. Só usa snapshot quando
                    // _avatar ainda é nulo.
                    final effective = _avatar ?? snapshot.data;
                    // Se ainda está carregando e já temos effective, não mostra loading
                    return _NavItem(
                      icon: 'assets/home/vectors/vector-2705-1282.png',
                      label: 'Minha Time',
                      active: widget.activeItem == HomeNavItemId.myTime,
                      tintIcon: false,
                      iconWidget: _MyTimeNavAvatar(
                        data: effective,
                      ),
                      onTap: widget.activeItem == HomeNavItemId.myTime
                          ? null
                          : widget.onMyTimeTap,
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

class _BottomNavAvatar {
  const _BottomNavAvatar({required this.avatarIndex, this.avatarUrl});

  final int avatarIndex;
  final String? avatarUrl;
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    this.active = false,
    this.tintIcon = true,
    this.iconWidget,
    this.onTap,
  });

  final String icon;
  final String label;
  final bool active;
  final bool tintIcon;
  final Widget? iconWidget;
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
              iconWidget ??
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
                      fontFamily: 'Netflix Sans',
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

class _MyTimeNavAvatar extends StatelessWidget {
  const _MyTimeNavAvatar({this.data});

  final _BottomNavAvatar? data;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      padding: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: data == null
            ? Image.asset(
                'assets/home/vectors/vector-2705-1282.png',
                width: 29,
                height: 29,
                fit: BoxFit.contain,
              )
            : AuthenticatedAvatarImage(
                avatarIndex: data!.avatarIndex,
                avatarUrl: data!.avatarUrl,
                width: 29,
                height: 29,
              ),
      ),
    );
  }
}
