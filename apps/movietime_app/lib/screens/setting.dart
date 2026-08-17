import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../services/api_client.dart';
import '../services/avatar_state.dart';
import '../services/auth_models.dart';
import '../services/auth_service.dart';
import '../services/avatar_catalog.dart';
import '../widgets/local_avatar_image.dart';

const _bg = Color(0xFF0D0D0D);
const _card = Color(0xFF1A1A1A);
const _field = Color(0xFF2A2A2A);
const _border = Color(0xFF262626);
const _muted = Color(0xFF9E9E9E);
const _softText = Color(0xFFBDBDBD);

const _popularGenres = [
  'Ação',
  'Aventura',
  'Comédia',
  'Drama',
  'Fantasia',
  'Ficção Científica',
  'Terror',
  'Romance',
  'Suspense',
  'Documentário',
  'Animação',
  'Crime',
];

const _languages = [
  _ContentLanguage('pt-BR', 'Português (Brasil)', false),
  _ContentLanguage('en', 'English (Indisponível)', true),
  _ContentLanguage('es', 'Espanol (No disponible)', true),
];

const _initialAvatars = 6;
const _contentLangKey = 'movietime_content_language';

class SettingScreen extends StatefulWidget {
  const SettingScreen({
    super.key,
    this.authService,
    this.initialProfile,
    this.useRemoteAvatars = true,
  });

  final AuthService? authService;
  final AuthUser? initialProfile;
  final bool useRemoteAvatars;

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  late final AuthService _authService;
  late final bool _ownsAuthService;
  final _nameController = TextEditingController();
  final _storage = const FlutterSecureStorage();

  AuthUser? _profile;
  bool _loading = true;
  bool _savingName = false;
  bool _savingPrefs = false;
  bool _editingName = false;
  bool _showAllAvatars = false;
  String? _errorMessage;
  int _selectedAvatar = 0;
  List<String> _selectedGenres = const [];
  String _contentLang = 'pt-BR';

  @override
  void initState() {
    super.initState();
    _ownsAuthService = widget.authService == null;
    _authService = widget.authService ?? AuthService();
    final initialProfile = widget.initialProfile;
    if (initialProfile != null) {
      _profile = initialProfile;
      _nameController.text = initialProfile.name;
      _selectedAvatar = initialProfile.preferences?.avatarIndex ?? 0;
      _selectedGenres = initialProfile.preferences?.genres ?? const [];
      _loading = false;
      _loadContentLanguage(initialProfile.preferences?.contentLanguage);
    } else {
      _loadSettings();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    if (_ownsAuthService) {
      _authService.close();
    }
    super.dispose();
  }

  Future<void> _loadContentLanguage(String? remoteLanguage) async {
    final contentLang = await _storage.read(key: _contentLangKey);
    if (!mounted) return;
    setState(() => _contentLang = remoteLanguage ?? contentLang ?? 'pt-BR');
  }

  Future<void> _loadSettings() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final profile = await _authService.profile();
      final contentLang = await _storage.read(key: _contentLangKey);
      if (!mounted) return;

      setState(() {
        _profile = profile;
        _nameController.text = profile.name;
        _selectedAvatar = profile.preferences?.avatarIndex ?? 0;
        _selectedGenres = profile.preferences?.genres ?? const [];
        _contentLang =
            profile.preferences?.contentLanguage ?? contentLang ?? 'pt-BR';
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Não foi possível carregar as configurações.';
        _loading = false;
      });
    }
  }

  Future<void> _saveName() async {
    final profile = _profile;
    final name = _nameController.text.trim();
    if (profile == null || name.isEmpty || _savingName) return;

    setState(() => _savingName = true);
    try {
      final updated = await _authService.updateProfile(
        userId: profile.id,
        name: name,
      );
      if (!mounted) return;
      setState(() {
        _profile = updated;
        _nameController.text = updated.name;
        _editingName = false;
      });
      _showMessage('Nome atualizado!');
    } on ApiException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('Erro de conexão.');
    } finally {
      if (mounted) setState(() => _savingName = false);
    }
  }

  Future<void> _savePreferences() async {
    final profile = _profile;
    if (profile == null || _savingPrefs) return;
    if (_selectedGenres.length < 3) {
      _showMessage('Selecione pelo menos 3 gêneros.');
      return;
    }

    setState(() => _savingPrefs = true);
    try {
      await _authService.savePreferences(
        userId: profile.id,
        avatarIndex: _selectedAvatar,
        genres: _selectedGenres,
        contentLanguage: _contentLang,
      );
      await _storage.write(key: _contentLangKey, value: _contentLang);
      final refreshed = await _authService.profile(profile.id);
      if (!mounted) return;
      setState(() => _profile = refreshed);
      AvatarState.instance.update(
        avatarIndex: _selectedAvatar,
        avatarUrl: refreshed.avatarUrl,
      );
      _showMessage('Preferências salvas!');
    } on ApiException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('Erro de conexão.');
    } finally {
      if (mounted) setState(() => _savingPrefs = false);
    }
  }

  void _toggleGenre(String genre) {
    if (_selectedGenres.contains(genre)) {
      setState(() {
        _selectedGenres = _selectedGenres
            .where((selected) => selected != genre)
            .toList(growable: false);
      });
      return;
    }

    if (_selectedGenres.length >= 3) {
      _showMessage('Máximo de 3 gêneros.');
      return;
    }

    setState(() => _selectedGenres = [..._selectedGenres, genre]);
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
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
            if (_loading)
              const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            else if (_errorMessage != null)
              _ErrorState(message: _errorMessage!, onRetry: _loadSettings)
            else
              RefreshIndicator(
                onRefresh: _loadSettings,
                color: Colors.white,
                backgroundColor: _card,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(22, 34, 24, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Header(onBack: () => Navigator.of(context).maybePop()),
                      const SizedBox(height: 34),
                      const _PageTitle(),
                      const SizedBox(height: 34),
                      _ProfileSection(
                        profile: _profile,
                        editingName: _editingName,
                        savingName: _savingName,
                        nameController: _nameController,
                        onEditName: () => setState(() => _editingName = true),
                        onCancelName: () {
                          setState(() {
                            _editingName = false;
                            _nameController.text = _profile?.name ?? '';
                          });
                        },
                        onSaveName: _saveName,
                      ),
                      const SizedBox(height: 34),
                      _AvatarSection(
                        selectedAvatar: _selectedAvatar,
                        showAllAvatars: _showAllAvatars,
                        useRemoteAvatars: widget.useRemoteAvatars,
                        onSelect: (index) =>
                            setState(() => _selectedAvatar = index),
                        onShowAll: () => setState(() => _showAllAvatars = true),
                      ),
                      const SizedBox(height: 34),
                      _GenresSection(
                        selectedGenres: _selectedGenres,
                        onToggle: _toggleGenre,
                      ),
                      const SizedBox(height: 34),
                      _LanguageSection(
                        value: _contentLang,
                        onChanged: (value) async {
                          setState(() => _contentLang = value);
                          await _storage.write(
                            key: _contentLangKey,
                            value: value,
                          );
                          _showMessage('Idioma salvo!');
                        },
                      ),
                      const SizedBox(height: 28),
                      _SavePreferencesButton(
                        saving: _savingPrefs,
                        onTap: _savePreferences,
                      ),
                    ],
                  ),
                ),
              ),
            if (_showAllAvatars)
              Positioned.fill(
                child: _AllAvatarsModal(
                  selectedAvatar: _selectedAvatar,
                  useRemoteAvatars: widget.useRemoteAvatars,
                  onClose: () => setState(() => _showAllAvatars = false),
                  onSelect: (index) {
                    setState(() {
                      _selectedAvatar = index;
                      _showAllAvatars = false;
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

class _ContentLanguage {
  const _ContentLanguage(this.value, this.label, this.disabled);

  final String value;
  final String label;
  final bool disabled;
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onBack,
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chevron_left_rounded, color: _muted, size: 28),
          SizedBox(width: 4),
          Text(
            'Voltar',
            style: TextStyle(
              color: _muted,
              fontSize: 14,
              fontFamily: 'Netflix Sans',
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _PageTitle extends StatelessWidget {
  const _PageTitle();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Configurações',
      style: TextStyle(
        color: Colors.white,
        fontSize: 30,
        fontFamily: 'Netflix Sans',
        fontWeight: FontWeight.w700,
        height: 1.15,
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontFamily: 'Netflix Sans',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: child,
        ),
      ],
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({
    required this.profile,
    required this.editingName,
    required this.savingName,
    required this.nameController,
    required this.onEditName,
    required this.onCancelName,
    required this.onSaveName,
  });

  final AuthUser? profile;
  final bool editingName;
  final bool savingName;
  final TextEditingController nameController;
  final VoidCallback onEditName;
  final VoidCallback onCancelName;
  final VoidCallback onSaveName;

  @override
  Widget build(BuildContext context) {
    return _SettingsSection(
      icon: Icons.person_outline_rounded,
      title: 'Perfil',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (editingName) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _SmallButton(
                  label: savingName ? 'Salvando...' : 'Salvar',
                  primary: true,
                  onTap: savingName ? null : onSaveName,
                ),
                const SizedBox(width: 10),
                _SmallButton(label: 'Cancelar', onTap: onCancelName),
              ],
            ),
            const SizedBox(height: 14),
            const _FieldLabel('Nome'),
            const SizedBox(height: 8),
            _NameField(controller: nameController),
          ] else ...[
            const _FieldLabel('Nome'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    profile?.name.isNotEmpty == true ? profile!.name : '---',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontFamily: 'Netflix Sans',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onEditName,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Editar'),
                ),
              ],
            ),
          ],
          const SizedBox(height: 22),
          const _FieldLabel('E-mail'),
          const SizedBox(height: 8),
          Text(
            profile?.email.isNotEmpty == true
                ? _maskEmail(profile!.email)
                : '---',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _muted,
              fontSize: 18,
              fontFamily: 'Netflix Sans',
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarSection extends StatelessWidget {
  const _AvatarSection({
    required this.selectedAvatar,
    required this.showAllAvatars,
    required this.useRemoteAvatars,
    required this.onSelect,
    required this.onShowAll,
  });

  final int selectedAvatar;
  final bool showAllAvatars;
  final bool useRemoteAvatars;
  final ValueChanged<int> onSelect;
  final VoidCallback onShowAll;

  List<int> get _visibleAvatars {
    if (showAllAvatars) {
      return List<int>.generate(totalRemoteAvatars, (index) => index);
    }
    if (selectedAvatar < _initialAvatars) {
      return List<int>.generate(_initialAvatars, (index) => index);
    }
    return [
      ...List<int>.generate(_initialAvatars - 1, (index) => index),
      selectedAvatar,
    ];
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsSection(
      icon: Icons.palette_outlined,
      title: 'Avatar',
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        children: [
          for (final index in _visibleAvatars)
            _AvatarTile(
              index: index,
              selected: selectedAvatar == index,
              useRemoteAvatars: useRemoteAvatars,
              onTap: () => onSelect(index),
            ),
          if (!showAllAvatars)
            _ShowAllAvatarsTile(
              remaining: math.max(0, totalRemoteAvatars - _initialAvatars),
              onTap: onShowAll,
            ),
        ],
      ),
    );
  }
}

class _GenresSection extends StatelessWidget {
  const _GenresSection({required this.selectedGenres, required this.onToggle});

  final List<String> selectedGenres;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return _SettingsSection(
      icon: Icons.play_arrow_outlined,
      title: 'Gêneros Preferidos',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final genre in _popularGenres)
                _GenreChip(
                  label: genre,
                  selected: selectedGenres.contains(genre),
                  onTap: () => onToggle(genre),
                ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Selecione até 3 gêneros para recomendações personalizadas.',
            style: TextStyle(
              color: Color(0xFF6F6F6F),
              fontSize: 12,
              fontFamily: 'Netflix Sans',
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageSection extends StatelessWidget {
  const _LanguageSection({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return _SettingsSection(
      icon: Icons.language_rounded,
      title: 'Idioma do Conteúdo',
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: _field,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            dropdownColor: _field,
            iconEnabledColor: Colors.white,
            isExpanded: true,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontFamily: 'Netflix Sans',
              fontWeight: FontWeight.w500,
            ),
            items: [
              for (final language in _languages)
                DropdownMenuItem(
                  value: language.value,
                  enabled: !language.disabled,
                  child: Text(
                    language.label,
                    style: TextStyle(
                      color: language.disabled ? _muted : Colors.white,
                    ),
                  ),
                ),
            ],
            onChanged: (next) {
              if (next != null) onChanged(next);
            },
          ),
        ),
      ),
    );
  }
}

class _AvatarTile extends StatelessWidget {
  const _AvatarTile({
    required this.index,
    required this.selected,
    required this.useRemoteAvatars,
    required this.onTap,
  });

  final int index;
  final bool selected;
  final bool useRemoteAvatars;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? Colors.white
                : Colors.white.withValues(alpha: 0.1),
            width: selected ? 4 : 1,
          ),
        ),
        padding: EdgeInsets.all(selected ? 2 : 0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LocalAvatarImage(avatarIndex: index, fit: BoxFit.cover),
        ),
      ),
    );
  }
}

class _ShowAllAvatarsTile extends StatelessWidget {
  const _ShowAllAvatarsTile({required this.remaining, required this.onTap});

  final int remaining;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        alignment: Alignment.center,
        child: Text(
          '+$remaining',
          style: const TextStyle(
            color: _muted,
            fontSize: 14,
            fontFamily: 'Netflix Sans',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _GenreChip extends StatelessWidget {
  const _GenreChip({
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.black : const Color(0xFFE0E0E0),
            fontSize: 13,
            fontFamily: 'Netflix Sans',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _NameField extends StatelessWidget {
  const _NameField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: true,
      cursorColor: Colors.white,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontFamily: 'Netflix Sans',
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: _field,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: Colors.white),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: _muted,
        fontSize: 14,
        fontFamily: 'Netflix Sans',
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _SmallButton extends StatelessWidget {
  const _SmallButton({required this.label, this.primary = false, this.onTap});

  final String label;
  final bool primary;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.55 : 1,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: primary ? Colors.white : Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: primary ? Colors.black : Colors.white,
              fontSize: 13,
              fontFamily: 'Netflix Sans',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _SavePreferencesButton extends StatelessWidget {
  const _SavePreferencesButton({required this.saving, required this.onTap});

  final bool saving;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: saving ? null : onTap,
      child: Opacity(
        opacity: saving ? 0.6 : 1,
        child: Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            saving ? 'Salvando...' : 'Salvar Preferências',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 14,
              fontFamily: 'Netflix Sans',
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _AllAvatarsModal extends StatelessWidget {
  const _AllAvatarsModal({
    required this.selectedAvatar,
    required this.useRemoteAvatars,
    required this.onClose,
    required this.onSelect,
  });

  final int selectedAvatar;
  final bool useRemoteAvatars;
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
              child: const ColoredBox(color: Color(0xCC000000)),
            ),
          ),
          Center(
            child: Container(
              width: math.min(MediaQuery.of(context).size.width - 32, 720),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.82,
              ),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 14, 14),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Escolha seu avatar',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontFamily: 'Netflix Sans',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: onClose,
                          icon: const Icon(Icons.close_rounded),
                          color: Colors.white,
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white10,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: _border),
                  Flexible(
                    child: GridView.builder(
                      padding: const EdgeInsets.all(20),
                      physics: const BouncingScrollPhysics(),
                      itemCount: totalRemoteAvatars,
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 78,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                          ),
                      itemBuilder: (context, index) {
                        return _AvatarTile(
                          index: index,
                          selected: selectedAvatar == index,
                          useRemoteAvatars: useRemoteAvatars,
                          onTap: () => onSelect(index),
                        );
                      },
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

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, color: _softText, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Erro ao carregar dados',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontFamily: 'Netflix Sans',
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _softText,
                fontSize: 13,
                fontFamily: 'Netflix Sans',
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: () => onRetry(),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: _border),
                backgroundColor: const Color(0x14FFFFFF),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

String _maskEmail(String email) {
  final atIndex = email.indexOf('@');
  if (atIndex <= 1) return email;
  final prefix = email.substring(0, 2);
  final domain = email.substring(atIndex);
  return '$prefix${'*' * (atIndex - 2)}$domain';
}
