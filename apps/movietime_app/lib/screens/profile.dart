import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/avatar_state.dart';
import '../services/auth_models.dart';
import '../services/auth_service.dart';
import '../widgets/authenticated_avatar_image.dart';
import '../widgets/home_bottom_nav.dart';
import 'admin_access.dart';
import 'home.dart';
import 'mylist.dart';
import 'screen_transitions.dart';
import 'setting.dart';

const _bg = Color(0xFF0D0D0D);
const _card = Color(0xFF1A1A1A);
const _border = Color(0xFF262626);
const _muted = Color(0xFF5E5E5E);
const _danger = Color(0xFFFF4C61);

class ProfileScreenData {
  const ProfileScreenData({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.avatarIndex,
    required this.genres,
    this.createdAt,
    this.recommendationsUpdatedAt,
    this.avatarUrl,
  });

  factory ProfileScreenData.fromAuthUser(AuthUser user) {
    return ProfileScreenData(
      id: user.id,
      name: user.name,
      email: user.email,
      role: user.role,
      avatarIndex: user.preferences?.avatarIndex ?? 0,
      avatarUrl: user.avatarUrl,
      genres: user.preferences?.genres ?? const [],
      createdAt: user.createdAt,
      recommendationsUpdatedAt: user.preferences?.recommendationsUpdatedAt,
    );
  }

  ProfileScreenData copyWith({
    int? id,
    String? name,
    String? email,
    String? role,
    int? avatarIndex,
    List<String>? genres,
    String? createdAt,
    String? recommendationsUpdatedAt,
    String? avatarUrl,
  }) {
    return ProfileScreenData(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      avatarIndex: avatarIndex ?? this.avatarIndex,
      genres: genres ?? this.genres,
      createdAt: createdAt ?? this.createdAt,
      recommendationsUpdatedAt:
          recommendationsUpdatedAt ?? this.recommendationsUpdatedAt,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  final int id;
  final String name;
  final String email;
  final String role;
  final int avatarIndex;
  final List<String> genres;
  final String? createdAt;
  final String? recommendationsUpdatedAt;
  final String? avatarUrl;
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    this.authService,
    this.initialProfile,
    this.useRemoteAvatars = true,
  });

  final AuthService? authService;
  final ProfileScreenData? initialProfile;
  final bool useRemoteAvatars;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final AuthService _authService;
  late final bool _ownsAuthService;
  ProfileScreenData? _profile;
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _ownsAuthService = widget.authService == null;
    _authService = widget.authService ?? AuthService();
    _profile = widget.initialProfile;
    _isLoading = widget.initialProfile == null;

    AvatarState.instance.addListener(_onAvatarChanged);
    if (widget.initialProfile == null) {
      _loadProfile();
    } else {
      AvatarState.instance.update(
        avatarIndex: widget.initialProfile!.avatarIndex,
        avatarUrl: widget.initialProfile!.avatarUrl,
      );
    }
  }

  @override
  void dispose() {
    AvatarState.instance.removeListener(_onAvatarChanged);
    if (_ownsAuthService) {
      _authService.close();
    }
    super.dispose();
  }

  void _onAvatarChanged() {
    final profile = _profile;
    final avatarIndex = AvatarState.instance.avatarIndex;
    if (!mounted || profile == null || avatarIndex == null) return;
    if (profile.avatarIndex == avatarIndex &&
        profile.avatarUrl == AvatarState.instance.avatarUrl) {
      return;
    }
    setState(() {
      _profile = profile.copyWith(
        avatarIndex: avatarIndex,
        avatarUrl: AvatarState.instance.avatarUrl,
      );
    });
  }

  Future<void> _loadProfile({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _isRefreshing = true;
        _errorMessage = null;
      });
    }

    try {
      final user = await _authService.profile();
      if (!mounted) return;

      setState(() {
        _profile = ProfileScreenData.fromAuthUser(user);
        _isLoading = false;
        _isRefreshing = false;
        _errorMessage = null;
      });
      AvatarState.instance.update(
        avatarIndex: user.preferences?.avatarIndex ?? 0,
        avatarUrl: user.avatarUrl,
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
        _errorMessage = 'N\u00e3o foi poss\u00edvel carregar seu perfil agora.';
      });
    }
  }

  void _openSettings(BuildContext context) {
    final profile = _profile;
    Navigator.of(context).push(
      cinematicPageRoute(
        SettingScreen(
          initialProfile: profile == null
              ? null
              : AuthUser(
                  id: profile.id,
                  email: profile.email,
                  name: profile.name,
                  role: profile.role,
                  avatarUrl: profile.avatarUrl,
                  createdAt: profile.createdAt,
                  preferences: UserPreferences(
                    avatarIndex: profile.avatarIndex,
                    genres: profile.genres,
                    recommendationsUpdatedAt: profile.recommendationsUpdatedAt,
                  ),
                ),
          useRemoteAvatars: widget.useRemoteAvatars,
        ),
      ),
    );
  }

  void _openAdminAccess(BuildContext context) {
    final profile = _profile;
    if (profile == null || profile.role.toLowerCase() != 'admin') {
      return;
    }

    Navigator.of(context).push(
      cinematicPageRoute(
        AdminAccessScreen(
          requesterId: profile.id,
          useRemoteAvatars: widget.useRemoteAvatars,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    final hasProfile = profile != null;

    return Scaffold(
      backgroundColor: _bg,
      bottomNavigationBar: HomeBottomNav(
        activeItem: HomeNavItemId.myTime,
        onHomeTap: () {
          Navigator.of(
            context,
          ).pushReplacement(cinematicPageRoute(const Home()));
        },
        onMyListTap: () {
          Navigator.of(
            context,
          ).pushReplacement(cinematicPageRoute(const MyListScreen()));
        },
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              left: -145,
              top: -155,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 300, sigmaY: 300),
                child: Container(
                  width: 350,
                  height: 350,
                  decoration: const ShapeDecoration(
                    color: Color(0x33A259FF),
                    shape: OvalBorder(),
                  ),
                ),
              ),
            ),
            RefreshIndicator(
              onRefresh: () => _loadProfile(refresh: true),
              color: Colors.white,
              backgroundColor: _card,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(22, 42, 24, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ProfileHeader(isRefreshing: _isRefreshing),
                    const SizedBox(height: 40),
                    _ProfileSummaryCard(
                      profile: profile,
                      loading: _isLoading,
                      errorMessage: _errorMessage,
                      onRetry: () => _loadProfile(refresh: true),
                      onEditTap: hasProfile
                          ? () => _openSettings(context)
                          : null,
                      onAdminTap: () => _openAdminAccess(context),
                      useRemoteAvatars: widget.useRemoteAvatars,
                    ),
                    /*
                    if (hasProfile) ...[
                      const SizedBox(height: 40),
                      const _ProfileSection(title: 'Information'),
                      _SettingsCard(...),
                      const SizedBox(height: 40),
                      const _ProfileSection(title: 'Preferences'),
                      _SettingsCard(...),
                    */
                    const SizedBox(height: 40),
                    const _ProfileSection(title: 'Suporte'),
                    const _SettingsCard(
                      compact: true,
                      children: [
                        _SupportRow(label: 'Central de ajuda'),
                        _SupportRow(
                          label: 'Privacidade e política',
                          showDivider: false,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Telefone e senha foram removidos intencionalmente desta tela porque as APIs web de perfil/configurações não expõem esses campos.',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 11,
                        fontFamily: 'Netflix Sans',
                        fontWeight: FontWeight.w400,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.isRefreshing});

  final bool isRefreshing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Expanded(
          child: Text(
            'Perfil',
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
        if (isRefreshing)
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white70,
              ),
            ),
          ),
        /*
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onSettingsTap,
          child: Container(...),
        ),
        */
      ],
    );
  }
}

class _ProfileSummaryCard extends StatelessWidget {
  const _ProfileSummaryCard({
    required this.profile,
    required this.loading,
    required this.errorMessage,
    required this.onRetry,
    required this.onEditTap,
    required this.onAdminTap,
    required this.useRemoteAvatars,
  });

  final ProfileScreenData? profile;
  final bool loading;
  final String? errorMessage;
  final Future<void> Function() onRetry;
  final VoidCallback? onEditTap;
  final VoidCallback onAdminTap;
  final bool useRemoteAvatars;

  @override
  Widget build(BuildContext context) {
    final profile = this.profile;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
      decoration: ShapeDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_card, Color(0x330D0D0D)],
        ),
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: _border, width: 1),
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      child: Column(
        children: [
          if (loading)
            const _SummaryLoadingState()
          else if (profile == null)
            _ProfileUnavailableState(
              message: errorMessage ?? 'Erro ao carregar dados.',
              onRetry: onRetry,
            )
          else ...[
            _ProfileAvatar(
              avatarIndex: profile.avatarIndex,
              avatarUrl: profile.avatarUrl,
              isAdmin: profile.role.toLowerCase() == 'admin',
              useRemoteAvatar: useRemoteAvatars,
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    profile.name,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontFamily: 'Netflix Sans',
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onEditTap,
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.edit_outlined,
                      color: Color(0xFFBDBDBD),
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _maskEmail(profile.email),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontFamily: 'Netflix Sans',
                fontWeight: FontWeight.w400,
                height: 1.5,
              ),
            ),
            if (profile.role.toLowerCase() == 'admin') ...[
              const SizedBox(height: 4),
              const Text(
                'Administrador',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontFamily: 'Netflix Sans',
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  color: Color(0xFF9E9E9E),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Membro desde ${_formatMemberSince(profile.createdAt)}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF9E9E9E),
                      fontSize: 13,
                      fontFamily: 'Netflix Sans',
                      fontWeight: FontWeight.w400,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
            if (profile.genres.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final genre in profile.genres.take(3))
                    _TagChip(label: genre),
                ],
              ),
            ],
            const SizedBox(height: 18),
            _ProfileActionButton(
              icon: Icons.settings_outlined,
              label: 'Editar perfil',
              onTap: onEditTap ?? () {},
            ),
            if (profile.role.toLowerCase() == 'admin') ...[
              const SizedBox(height: 10),
              _ProfileActionButton(
                icon: Icons.shield_outlined,
                label: 'Acessos administrativos',
                onTap: onAdminTap,
              ),
            ],
            if (errorMessage != null) ...[
              const SizedBox(height: 18),
              _InlineError(message: errorMessage!, onRetry: onRetry),
            ],
          ],
        ],
      ),
    );
  }
}

class _SummaryLoadingState extends StatelessWidget {
  const _SummaryLoadingState();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _border),
          ),
        ),
        const SizedBox(height: 18),
        Container(
          width: 150,
          height: 18,
          decoration: BoxDecoration(
            color: Colors.white12,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: 200,
          height: 14,
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ],
    );
  }
}

class _ProfileUnavailableState extends StatelessWidget {
  const _ProfileUnavailableState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.cloud_off_rounded, color: Color(0xFFBDBDBD), size: 48),
        const SizedBox(height: 16),
        const Text(
          'Erro ao carregar dados',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontFamily: 'Netflix Sans',
            fontWeight: FontWeight.w600,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFBDBDBD),
            fontSize: 13,
            fontFamily: 'Netflix Sans',
            fontWeight: FontWeight.w400,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Tente novamente mais tarde.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF9E9E9E),
            fontSize: 12,
            fontFamily: 'Netflix Sans',
            fontWeight: FontWeight.w400,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 18),
        OutlinedButton.icon(
          onPressed: () {
            onRetry();
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: _border),
            backgroundColor: const Color(0x14FFFFFF),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Tentar novamente'),
        ),
      ],
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0x14FF4C61),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x33FF4C61)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: _danger, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontFamily: 'Netflix Sans',
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(width: 10),
          TextButton(
            onPressed: () {
              onRetry();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 12,
          fontFamily: 'Netflix Sans',
          fontWeight: FontWeight.w500,
          height: 1.2,
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.avatarIndex,
    this.avatarUrl,
    required this.isAdmin,
    required this.useRemoteAvatar,
  });

  final int avatarIndex;
  final String? avatarUrl;
  final bool isAdmin;
  final bool useRemoteAvatar;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _border, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AuthenticatedAvatarImage(
                avatarIndex: avatarIndex,
                avatarUrl: avatarUrl,
                fit: BoxFit.cover,
                useRemoteAvatar: useRemoteAvatar,
              ),
            ),
          ),
          if (isAdmin)
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFC107),
                  shape: BoxShape.circle,
                  border: Border.all(color: _card, width: 2),
                ),
                child: const Icon(Icons.star, size: 12, color: Colors.black),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProfileActionButton extends StatelessWidget {
  const _ProfileActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontFamily: 'Netflix Sans',
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Text(
        title,
        style: const TextStyle(
          color: _muted,
          fontSize: 14,
          fontFamily: 'Netflix Sans',
          fontWeight: FontWeight.w500,
          height: 1.05,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children, this.compact = false});

  final List<Widget> children;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: compact ? 0 : 10),
      decoration: ShapeDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_card, Color(0x330D0D0D)],
        ),
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: _border, width: 1),
          borderRadius: BorderRadius.circular(15),
        ),
      ),
      child: Column(children: children),
    );
  }
}

class _SupportRow extends StatelessWidget {
  const _SupportRow({required this.label, this.showDivider = true});

  final String label;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        border: Border(
          bottom: showDivider
              ? const BorderSide(color: _border, width: 1)
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
                color: _muted,
                fontSize: 14,
                fontFamily: 'Netflix Sans',
                fontWeight: FontWeight.w500,
                height: 1.57,
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Icon(
            Icons.chevron_right_rounded,
            color: Colors.white,
            size: 30,
          ),
        ],
      ),
    );
  }
}

String _maskEmail(String email) {
  final atIndex = email.indexOf('@');
  if (atIndex <= 1) return email;

  final prefix = email.substring(0, 2);
  final domain = email.substring(atIndex);
  return '$prefix***$domain';
}

String _formatMemberSince(String? createdAt) {
  if (createdAt == null || createdAt.isEmpty) {
    return 'Membro desde indisponível';
  }

  final parsed = DateTime.tryParse(createdAt);
  if (parsed == null) return 'Membro desde indisponível';

  const months = <String>[
    'Jan',
    'Fev',
    'Mar',
    'Abr',
    'Mai',
    'Jun',
    'Jul',
    'Ago',
    'Set',
    'Out',
    'Nov',
    'Dez',
  ];

  final month =
      months[math.max(0, math.min(parsed.month - 1, months.length - 1))];
  return '$month ${parsed.year}';
}
