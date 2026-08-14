import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/avatar_catalog.dart';
import '../services/auth_models.dart';
import '../services/auth_service.dart';
import '../widgets/authenticated_avatar_image.dart';
import '../widgets/home_bottom_nav.dart';
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
  });

  factory ProfileScreenData.fromAuthUser(AuthUser user) {
    return ProfileScreenData(
      id: user.id,
      name: user.name,
      email: user.email,
      role: user.role,
      avatarIndex: user.preferences?.avatarIndex ?? 0,
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
  static const _fallbackProfile = ProfileScreenData(
    id: 0,
    name: 'Usuário MovieTime',
    email: 'email@example.com',
    role: 'client',
    avatarIndex: 0,
    genres: [],
  );

  late final AuthService _authService;
  late final bool _ownsAuthService;
  late ProfileScreenData _profile;
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _ownsAuthService = widget.authService == null;
    _authService = widget.authService ?? AuthService();
    _profile = widget.initialProfile ?? _fallbackProfile;
    _isLoading = widget.initialProfile == null;

    if (widget.initialProfile == null) {
      _loadProfile();
    }
  }

  @override
  void dispose() {
    if (_ownsAuthService) {
      _authService.close();
    }
    super.dispose();
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
        _errorMessage = 'Não foi possível carregar seu perfil agora.';
      });
    }
  }

  Future<void> _openEditProfileDrawer(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      enableDrag: true,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (context) => _EditProfileDrawer(
        profile: _profile,
        onSave: _saveProfileEdits,
        useRemoteAvatars: widget.useRemoteAvatars,
      ),
    );
  }

  Future<void> _saveProfileEdits(String name, int avatarIndex) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw const ApiException('Digite um nome válido.');
    }

    final avatarChangedWithoutGenres =
        avatarIndex != _profile.avatarIndex && _profile.genres.length < 3;

    final updatedUser = await _authService.updateProfile(
      userId: _profile.id == 0 ? null : _profile.id,
      name: trimmedName,
    );

    if (avatarIndex != _profile.avatarIndex &&
        _profile.id != 0 &&
        _profile.genres.length >= 3) {
      await _authService.savePreferences(
        userId: _profile.id,
        avatarIndex: avatarIndex,
        genres: _profile.genres,
      );
    }

    if (!mounted) return;

    final nextProfile = ProfileScreenData.fromAuthUser(updatedUser).copyWith(
      avatarIndex: avatarIndex,
      genres: updatedUser.preferences?.genres ?? _profile.genres,
      createdAt: updatedUser.createdAt ?? _profile.createdAt,
      recommendationsUpdatedAt:
          updatedUser.preferences?.recommendationsUpdatedAt ??
          _profile.recommendationsUpdatedAt,
    );

    setState(() => _profile = nextProfile);

    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            avatarChangedWithoutGenres
                ? 'Nome salvo. Para persistir avatar, defina 3 gêneros em Configurações.'
                : 'Perfil atualizado com sucesso.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _openSettings(BuildContext context) {
    Navigator.of(context).push(cinematicPageRoute(const SettingScreen()));
  }

  void _openAdminAccess(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Acessos administrativos ainda não estão disponíveis no app Flutter.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
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
                    _ProfileHeader(
                      onSettingsTap: () => _openSettings(context),
                      isRefreshing: _isRefreshing,
                    ),
                    const SizedBox(height: 40),
                    _ProfileSummaryCard(
                      profile: _profile,
                      loading: _isLoading,
                      errorMessage: _errorMessage,
                      onRetry: () => _loadProfile(refresh: true),
                      onEditTap: () => _openEditProfileDrawer(context),
                      onAdminTap: () => _openAdminAccess(context),
                      useRemoteAvatars: widget.useRemoteAvatars,
                    ),
                    const SizedBox(height: 40),
                    const _ProfileSection(title: 'Information'),
                    _SettingsCard(
                      children: [
                        _SettingsRow(
                          label: 'Email address',
                          value: _profile.email,
                        ),
                        _SettingsRow(
                          label: 'Member since',
                          value: _formatMemberSince(_profile.createdAt),
                        ),
                        _SettingsRow(
                          label: 'Account type',
                          value: _formatRole(_profile.role),
                          showDivider: false,
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    const _ProfileSection(title: 'Preferences'),
                    _SettingsCard(
                      children: [
                        _SettingsRow(
                          label: 'Favorite genres',
                          value: _profile.genres.isEmpty
                              ? 'Not configured'
                              : _profile.genres.join(', '),
                        ),
                        _SettingsRow(
                          label: 'Avatar profile',
                          value: 'Avatar #${_profile.avatarIndex + 1}',
                          action: 'Edit profile',
                          showDivider: false,
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    const _ProfileSection(title: 'Support'),
                    const _SettingsCard(
                      compact: true,
                      children: [
                        _SupportRow(label: 'Support center'),
                        _SupportRow(
                          label: 'Privacy & Policy',
                          showDivider: false,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Phone number and password were intentionally removed from this screen because the web profile/settings APIs do not expose those fields.',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 11,
                        fontFamily: 'Inter',
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
  const _ProfileHeader({
    required this.onSettingsTap,
    required this.isRefreshing,
  });

  final VoidCallback onSettingsTap;
  final bool isRefreshing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Expanded(
          child: Text(
            'Profile',
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
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onSettingsTap,
          child: Container(
            width: 40,
            height: 40,
            decoration: ShapeDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_card, Color(0x330D0D0D)],
              ),
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: _border, width: 1),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Icon(
              Icons.settings_outlined,
              color: Color(0xFFBDBDBD),
              size: 22,
            ),
          ),
        ),
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

  final ProfileScreenData profile;
  final bool loading;
  final String? errorMessage;
  final Future<void> Function() onRetry;
  final VoidCallback onEditTap;
  final VoidCallback onAdminTap;
  final bool useRemoteAvatars;

  @override
  Widget build(BuildContext context) {
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
          _ProfileAvatar(
            avatarIndex: profile.avatarIndex,
            isAdmin: profile.role.toLowerCase() == 'admin',
            useRemoteAvatar: useRemoteAvatars,
          ),
          const SizedBox(height: 18),
          if (loading)
            const _SummaryLoadingState()
          else ...[
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
                      fontFamily: 'Inter',
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
                fontFamily: 'Inter',
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
                  fontFamily: 'Inter',
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
                      fontFamily: 'Inter',
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
              onTap: onEditTap,
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
                fontFamily: 'Inter',
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
            child: const Text('Retry'),
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
          fontFamily: 'Inter',
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
    required this.isAdmin,
    required this.useRemoteAvatar,
  });

  final int avatarIndex;
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
              shape: BoxShape.circle,
              border: Border.all(color: _border, width: 2),
            ),
            child: ClipOval(
              child: AuthenticatedAvatarImage(
                avatarIndex: avatarIndex,
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
                child: const Icon(
                  Icons.star,
                  size: 12,
                  color: Colors.black,
                ),
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
          borderRadius: BorderRadius.circular(14),
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
                fontFamily: 'Inter',
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

class _EditProfileDrawer extends StatelessWidget {
  const _EditProfileDrawer({
    required this.profile,
    required this.onSave,
    required this.useRemoteAvatars,
  });

  final ProfileScreenData profile;
  final Future<void> Function(String name, int avatarIndex) onSave;
  final bool useRemoteAvatars;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.902;

    return SizedBox(
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 22,
            right: 22,
            top: -47,
            height: 127,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 300, sigmaY: 300),
                child: Container(color: const Color(0x33A259FF)),
              ),
            ),
          ),
          Positioned.fill(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(30),
              ),
              child: _EditProfileSheetBody(
                profile: profile,
                onSave: onSave,
                useRemoteAvatars: useRemoteAvatars,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditProfileSheetBody extends StatefulWidget {
  const _EditProfileSheetBody({
    required this.profile,
    required this.onSave,
    required this.useRemoteAvatars,
  });

  final ProfileScreenData profile;
  final Future<void> Function(String name, int avatarIndex) onSave;
  final bool useRemoteAvatars;

  @override
  State<_EditProfileSheetBody> createState() => _EditProfileSheetBodyState();
}

class _EditProfileSheetBodyState extends State<_EditProfileSheetBody> {
  late final TextEditingController _nameController;
  late int _selectedAvatar;
  bool _avatarMenuOpen = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _selectedAvatar = widget.profile.avatarIndex;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      await widget.onSave(_nameController.text, _selectedAvatar);
      if (!mounted) return;
      Navigator.of(context).maybePop();
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(error.message),
            backgroundColor: const Color(0xFFAD2536),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Não foi possível salvar seu perfil agora.'),
            backgroundColor: Color(0xFFAD2536),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: ShapeDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_card, _bg],
          ),
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: Color(0xFF2C2C2C), width: 1.4),
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(24, 21, 24, 24 + viewInsets.bottom),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxHeight < 690;
                    final topGap = compact ? 50.0 : 96.0;
                    final fieldGap = compact ? 28.0 : 52.0;

                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: IntrinsicHeight(
                          child: Column(
                            children: [
                              SizedBox(
                                height: 32,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    const Text(
                                      'Edit profile',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w500,
                                        height: 1.5,
                                      ),
                                    ),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: () =>
                                            Navigator.of(context).maybePop(),
                                        child: const SizedBox(
                                          width: 40,
                                          height: 40,
                                          child: Icon(
                                            Icons.close_rounded,
                                            color: Color(0xFF525252),
                                            size: 26,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: topGap),
                              _EditProfileAvatars(
                                selectedAvatar: _selectedAvatar,
                                useRemoteAvatars: widget.useRemoteAvatars,
                                onCurrentAvatarTap: () {
                                  setState(() => _avatarMenuOpen = true);
                                },
                              ),
                              SizedBox(height: fieldGap),
                              _EditNameField(controller: _nameController),
                              const Spacer(),
                              const SizedBox(height: 24),
                              _EditProfileActions(
                                isSaving: _isSaving,
                                onSave: _handleSave,
                                onCancel: () =>
                                    Navigator.of(context).maybePop(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (_avatarMenuOpen)
                Positioned.fill(
                  child: _EditAvatarOverlay(
                    selectedAvatar: _selectedAvatar,
                    useRemoteAvatars: widget.useRemoteAvatars,
                    onSelect: (avatarIndex) {
                      setState(() {
                        _selectedAvatar = avatarIndex;
                        _avatarMenuOpen = false;
                      });
                    },
                    onClose: () => setState(() => _avatarMenuOpen = false),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditProfileAvatars extends StatelessWidget {
  const _EditProfileAvatars({
    required this.selectedAvatar,
    required this.useRemoteAvatars,
    required this.onCurrentAvatarTap,
  });

  final int selectedAvatar;
  final bool useRemoteAvatars;
  final VoidCallback onCurrentAvatarTap;

  @override
  Widget build(BuildContext context) {
    final secondaryAvatar = (selectedAvatar + 1) % totalRemoteAvatars;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onCurrentAvatarTap,
          child: Stack(
            alignment: Alignment.center,
            children: [
              ClipOval(
                child: AuthenticatedAvatarImage(
                  avatarIndex: selectedAvatar,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  useRemoteAvatar: useRemoteAvatars,
                ),
              ),
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0x330D0D0D),
                ),
              ),
              const Icon(
                Icons.photo_camera_outlined,
                color: Colors.white,
                size: 30,
              ),
            ],
          ),
        ),
        const SizedBox(width: 26),
        ClipOval(
          child: AuthenticatedAvatarImage(
            avatarIndex: secondaryAvatar,
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            useRemoteAvatar: useRemoteAvatars,
          ),
        ),
      ],
    );
  }
}

class _EditAvatarOverlay extends StatelessWidget {
  const _EditAvatarOverlay({
    required this.selectedAvatar,
    required this.useRemoteAvatars,
    required this.onSelect,
    required this.onClose,
  });

  final int selectedAvatar;
  final bool useRemoteAvatars;
  final ValueChanged<int> onSelect;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0x660D0D0D),
      child: Center(
        child: Container(
          key: const ValueKey('edit_avatar_menu'),
          width: 280,
          height: 384,
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 26),
          decoration: ShapeDecoration(
            color: _card,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: Column(
            children: [
              const Text(
                'Edit avatar',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  height: 1.57,
                ),
              ),
              const SizedBox(height: 20),
              const _AvatarCategoryTabs(),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: totalRemoteAvatars,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    mainAxisExtent: 50,
                  ),
                  itemBuilder: (context, index) {
                    final active = index == selectedAvatar;
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onSelect(index),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: active
                              ? Border.all(color: Colors.white, width: 2)
                              : null,
                        ),
                        padding: EdgeInsets.all(active ? 2 : 0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: AuthenticatedAvatarImage(
                            avatarIndex: index,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            useRemoteAvatar: useRemoteAvatars,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _DrawerButton(
                      label: 'Save',
                      primary: true,
                      onTap: onClose,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _DrawerButton(label: 'Cancel', onTap: onClose),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvatarCategoryTabs extends StatelessWidget {
  const _AvatarCategoryTabs();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 176,
      height: 40,
      padding: const EdgeInsets.all(5),
      decoration: ShapeDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_card, Color(0x330D0D0D)],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: const Row(
        children: [
          _AvatarTab(label: 'Anime', active: true),
          _AvatarTab(label: 'Emoji'),
          _AvatarTab(label: 'Other'),
        ],
      ),
    );
  }
}

class _AvatarTab extends StatelessWidget {
  const _AvatarTab({required this.label, this.active = false});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 30,
        decoration: active
            ? ShapeDecoration(
                color: _border,
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: Color(0xFF2C2C2C), width: 1),
                  borderRadius: BorderRadius.circular(6),
                ),
              )
            : null,
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : const Color(0xFF9E9E9E),
              fontSize: 10,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              height: 1.6,
            ),
          ),
        ),
      ),
    );
  }
}

class _EditNameField extends StatelessWidget {
  const _EditNameField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Your name',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Color(0xFF9E9E9E),
              fontSize: 14,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
              height: 1.57,
            ),
          ),
          const SizedBox(height: 15),
          Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: ShapeDecoration(
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: _border, width: 1.5),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            alignment: Alignment.center,
            child: TextField(
              controller: controller,
              autofocus: false,
              cursorColor: Colors.white,
              textAlign: TextAlign.center,
              textInputAction: TextInputAction.done,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
                height: 1.25,
              ),
              decoration: const InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditProfileActions extends StatelessWidget {
  const _EditProfileActions({
    required this.onSave,
    required this.onCancel,
    required this.isSaving,
  });

  final VoidCallback onSave;
  final VoidCallback onCancel;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _DrawerButton(
            label: isSaving ? 'Saving...' : 'Save',
            primary: true,
            onTap: onSave,
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _DrawerButton(label: 'Cancel', onTap: onCancel),
        ),
      ],
    );
  }
}

class _DrawerButton extends StatelessWidget {
  const _DrawerButton({
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: ShapeDecoration(
          gradient: primary
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFA259FF), Color(0xFF562199)],
                )
              : null,
          shadows: primary
              ? const [
                  BoxShadow(
                    color: Color(0x33A259FF),
                    blurRadius: 10,
                    offset: Offset(0, 10),
                  ),
                ]
              : null,
          shape: RoundedRectangleBorder(
            side: BorderSide(
              color: primary
                  ? const Color(0xFFC49EFF)
                  : const Color(0xFF2C2C2C),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(40),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: primary ? Colors.white : const Color(0xFF9E9E9E),
            fontSize: 14,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
            height: 1.57,
          ),
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
          fontFamily: 'Inter',
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

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.label,
    required this.value,
    this.action,
    this.showDivider = true,
  });

  final String label;
  final String value;
  final String? action;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 60),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: showDivider
              ? const BorderSide(color: _border, width: 1)
              : BorderSide.none,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: _muted,
                fontSize: 14,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
                height: 1.57,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Flexible(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                  ),
                ),
                if (action != null) ...[
                  const SizedBox(height: 5),
                  Text(
                    action!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 12,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                      height: 1.33,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
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
                fontFamily: 'Inter',
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
  if (createdAt == null || createdAt.isEmpty) return 'Member since unavailable';

  final parsed = DateTime.tryParse(createdAt);
  if (parsed == null) return 'Member since unavailable';

  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  final month = months[math.max(0, math.min(parsed.month - 1, months.length - 1))];
  return '$month ${parsed.year}';
}

String _formatRole(String role) {
  return switch (role.toLowerCase()) {
    'admin' => 'Administrator',
    'client' => 'Client',
    _ => role,
  };
}
