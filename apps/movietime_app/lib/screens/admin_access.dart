import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../services/admin_service.dart';
import '../services/api_client.dart';
import '../widgets/authenticated_avatar_image.dart';

const _bg = Color(0xFF0D0D0D);
const _card = Color(0xFF1A1A1A);
const _border = Color(0xFF262626);
const _muted = Color(0xFF5E5E5E);
const _danger = Color(0xFFFF4C61);

class AdminAccessScreen extends StatefulWidget {
  const AdminAccessScreen({
    super.key,
    required this.requesterId,
    this.adminService,
    this.useRemoteAvatars = true,
  });

  final int requesterId;
  final AdminService? adminService;
  final bool useRemoteAvatars;

  @override
  State<AdminAccessScreen> createState() => _AdminAccessScreenState();
}

class _AdminAccessScreenState extends State<AdminAccessScreen> {
  late final AdminService _adminService;
  late final bool _ownsAdminService;
  final _searchController = TextEditingController();

  List<AdminUser> _users = const [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;
  int? _expandedUserId;
  _AdminTab _activeTab = _AdminTab.history;
  String _searchTerm = '';

  @override
  void initState() {
    super.initState();
    _ownsAdminService = widget.adminService == null;
    _adminService = widget.adminService ?? AdminService();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    if (_ownsAdminService) {
      _adminService.close();
    }
    super.dispose();
  }

  Future<void> _loadUsers({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _isRefreshing = true;
        _errorMessage = null;
      });
    }

    try {
      final users = await _adminService.users(requesterId: widget.requesterId);
      if (!mounted) return;
      setState(() {
        _users = users;
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
        _errorMessage = 'Não foi possível carregar os acessos agora.';
      });
    }
  }

  Future<void> _changeRole(AdminUser user, String role) async {
    final previousUsers = _users;
    setState(() {
      _users = _users
          .map((item) => item.id == user.id ? item.copyWith(role: role) : item)
          .toList(growable: false);
    });

    try {
      await _adminService.updateRole(
        requesterId: widget.requesterId,
        targetUserId: user.id,
        role: role,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _users = previousUsers);
      _showMessage('Não foi possível alterar o cargo.');
    }
  }

  Future<void> _deleteHistory(AdminUser user, AdminRecentActivity item) async {
    final confirmed = await _confirmDelete(
      title: 'Excluir do histórico',
      message: 'Remover "${item.title}" do histórico deste usuário?',
    );
    if (!confirmed) return;

    final previousUsers = _users;
    setState(() {
      _users = _users
          .map((candidate) {
            if (candidate.id != user.id) return candidate;
            final nextActivity = candidate.recentActivity
                .where(
                  (activity) =>
                      activity.tmdbId != item.tmdbId ||
                      activity.mediaType != item.mediaType,
                )
                .toList(growable: false);
            return candidate.copyWith(
              recentActivity: nextActivity,
              totalHistory: math.max(0, candidate.totalHistory - 1),
              movieCount: item.mediaType == 'movie'
                  ? math.max(0, candidate.movieCount - 1)
                  : candidate.movieCount,
              seriesCount: item.mediaType == 'series'
                  ? math.max(0, candidate.seriesCount - 1)
                  : candidate.seriesCount,
            );
          })
          .toList(growable: false);
    });

    try {
      await _adminService.deleteHistory(
        requesterId: widget.requesterId,
        targetProfileId: user.id,
        tmdbId: item.tmdbId,
        mediaType: item.mediaType,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _users = previousUsers);
      _showMessage('Não foi possível remover do histórico.');
    }
  }

  Future<void> _deleteRating(AdminUser user, AdminRating rating) async {
    final confirmed = await _confirmDelete(
      title: 'Excluir avaliação',
      message: 'Remover a avaliação #${rating.tmdbId} deste usuário?',
    );
    if (!confirmed) return;

    final previousUsers = _users;
    setState(() {
      _users = _users
          .map((candidate) {
            if (candidate.id != user.id) return candidate;
            final nextRatings = candidate.ratings
                .where(
                  (item) =>
                      item.tmdbId != rating.tmdbId ||
                      item.mediaType != rating.mediaType,
                )
                .toList(growable: false);
            return candidate.copyWith(
              ratings: nextRatings,
              ratingsCount: math.max(0, candidate.ratingsCount - 1),
            );
          })
          .toList(growable: false);
    });

    try {
      await _adminService.deleteRating(
        requesterId: widget.requesterId,
        targetProfileId: user.id,
        tmdbId: rating.tmdbId,
        mediaType: rating.mediaType,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _users = previousUsers);
      _showMessage('Não foi possível remover a avaliação.');
    }
  }

  Future<bool> _confirmDelete({
    required String title,
    required String message,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: _border),
        ),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(
          message,
          style: const TextStyle(color: Color(0xFFBDBDBD), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir', style: TextStyle(color: _danger)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  @override
  Widget build(BuildContext context) {
    final filteredUsers = _users
        .where((user) {
          final query = _searchTerm.trim().toLowerCase();
          if (query.isEmpty) return true;
          return user.name.toLowerCase().contains(query) ||
              user.email.toLowerCase().contains(query);
        })
        .toList(growable: false);

    final totals = _AdminTotals.fromUsers(_users);

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
            RefreshIndicator(
              onRefresh: () => _loadUsers(refresh: true),
              color: Colors.white,
              backgroundColor: _card,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(22, 34, 24, 18),
                    sliver: SliverToBoxAdapter(
                      child: _AdminHeader(
                        isRefreshing: _isRefreshing,
                        onBack: () => Navigator.of(context).maybePop(),
                      ),
                    ),
                  ),
                  if (_isLoading)
                    const SliverFillRemaining(child: _AdminLoadingState())
                  else if (_errorMessage != null)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _AdminErrorState(
                        message: _errorMessage!,
                        onRetry: () => _loadUsers(refresh: true),
                      ),
                    )
                  else ...[
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(22, 0, 24, 24),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _AdminSearchField(
                              controller: _searchController,
                              onChanged: (value) =>
                                  setState(() => _searchTerm = value),
                            ),
                            const SizedBox(height: 24),
                            _TotalsGrid(totals: totals),
                            const SizedBox(height: 28),
                            _SectionTitle(
                              title: 'Usuários',
                              count: filteredUsers.length,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (filteredUsers.isEmpty)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: _EmptyUsersState(),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(22, 0, 24, 40),
                        sliver: SliverList.separated(
                          itemCount: filteredUsers.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final user = filteredUsers[index];
                            return _AdminUserCard(
                              user: user,
                              expanded: _expandedUserId == user.id,
                              activeTab: _activeTab,
                              useRemoteAvatars: widget.useRemoteAvatars,
                              onTap: () {
                                setState(() {
                                  _expandedUserId = _expandedUserId == user.id
                                      ? null
                                      : user.id;
                                  _activeTab = _AdminTab.history;
                                });
                              },
                              onTabChanged: (tab) =>
                                  setState(() => _activeTab = tab),
                              onRoleChanged: (role) => _changeRole(user, role),
                              onDeleteHistory: (item) =>
                                  _deleteHistory(user, item),
                              onDeleteRating: (rating) =>
                                  _deleteRating(user, rating),
                            );
                          },
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _AdminTab { history, ratings, settings }

class _AdminHeader extends StatelessWidget {
  const _AdminHeader({required this.onBack, required this.isRefreshing});

  final VoidCallback onBack;
  final bool isRefreshing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onBack,
          child: const SizedBox(
            width: 40,
            height: 40,
            child: Icon(
              Icons.chevron_left_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'Acessos administrativos',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontFamily: 'Netflix Sans',
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
        ),
        if (isRefreshing)
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              color: Colors.white70,
              strokeWidth: 2,
            ),
          ),
      ],
    );
  }
}

class _AdminSearchField extends StatelessWidget {
  const _AdminSearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: Color(0xFF9E9E9E), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              cursorColor: Colors.white,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontFamily: 'Netflix Sans',
              ),
              decoration: const InputDecoration(
                hintText: 'Buscar por nome ou email',
                hintStyle: TextStyle(color: _muted),
                border: InputBorder.none,
                isCollapsed: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalsGrid extends StatelessWidget {
  const _TotalsGrid({required this.totals});

  final _AdminTotals totals;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.75,
      children: [
        _MetricCard(
          icon: Icons.group_outlined,
          value: totals.users.toString(),
          label: 'Usuários',
          color: const Color(0xFF5CE1E6),
        ),
        _MetricCard(
          icon: Icons.movie_outlined,
          value: totals.movies.toString(),
          label: 'Filmes vistos',
          color: const Color(0xFF5C9DFF),
        ),
        _MetricCard(
          icon: Icons.tv_outlined,
          value: totals.series.toString(),
          label: 'Séries vistas',
          color: const Color(0xFFA259FF),
        ),
        _MetricCard(
          icon: Icons.star_border_rounded,
          value: totals.ratings.toString(),
          label: 'Avaliações',
          color: const Color(0xFFFFC107),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: ShapeDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_card, Color(0x330D0D0D)],
        ),
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: _border, width: 1),
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontFamily: 'Netflix Sans',
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFBDBDBD),
                    fontSize: 12,
                    fontFamily: 'Netflix Sans',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _muted,
            fontSize: 14,
            fontFamily: 'Netflix Sans',
            fontWeight: FontWeight.w500,
            height: 1.05,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '($count)',
          style: const TextStyle(
            color: Color(0xFF9E9E9E),
            fontSize: 13,
            fontFamily: 'Netflix Sans',
          ),
        ),
      ],
    );
  }
}

class _AdminUserCard extends StatelessWidget {
  const _AdminUserCard({
    required this.user,
    required this.expanded,
    required this.activeTab,
    required this.useRemoteAvatars,
    required this.onTap,
    required this.onTabChanged,
    required this.onRoleChanged,
    required this.onDeleteHistory,
    required this.onDeleteRating,
  });

  final AdminUser user;
  final bool expanded;
  final _AdminTab activeTab;
  final bool useRemoteAvatars;
  final VoidCallback onTap;
  final ValueChanged<_AdminTab> onTabChanged;
  final ValueChanged<String> onRoleChanged;
  final ValueChanged<AdminRecentActivity> onDeleteHistory;
  final ValueChanged<AdminRating> onDeleteRating;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: ShapeDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_card, Color(0x330D0D0D)],
        ),
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: _border, width: 1),
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      child: Column(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _AdminAvatar(
                        user: user,
                        useRemoteAvatars: useRemoteAvatars,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    user.name.isEmpty ? 'Sem nome' : user.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontFamily: 'Netflix Sans',
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                _RolePill(role: user.role),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFFBDBDBD),
                                fontSize: 12,
                                fontFamily: 'Netflix Sans',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        expanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _UserStatsRow(user: user),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            const Divider(height: 1, color: _border),
            _AdminTabs(activeTab: activeTab, onChanged: onTabChanged),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: switch (activeTab) {
                _AdminTab.history => _HistoryPanel(
                  items: user.recentActivity,
                  onDelete: onDeleteHistory,
                ),
                _AdminTab.ratings => _RatingsPanel(
                  ratings: user.ratings,
                  onDelete: onDeleteRating,
                ),
                _AdminTab.settings => _SettingsPanel(
                  user: user,
                  onRoleChanged: onRoleChanged,
                ),
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _AdminAvatar extends StatelessWidget {
  const _AdminAvatar({required this.user, required this.useRemoteAvatars});

  final AdminUser user;
  final bool useRemoteAvatars;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: AuthenticatedAvatarImage(
              avatarIndex: user.preferences?.avatarIndex ?? 0,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              useRemoteAvatar: useRemoteAvatars,
            ),
          ),
          if (user.role.toLowerCase() == 'admin')
            Positioned(
              right: -4,
              bottom: -4,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFC107),
                  shape: BoxShape.circle,
                  border: Border.all(color: _card, width: 2),
                ),
                child: const Icon(Icons.star, color: Colors.black, size: 10),
              ),
            ),
        ],
      ),
    );
  }
}

class _RolePill extends StatelessWidget {
  const _RolePill({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    final isAdmin = role.toLowerCase() == 'admin';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isAdmin ? const Color(0x26FF4C61) : Colors.white10,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isAdmin ? 'Administrador' : 'Usuário',
        style: TextStyle(
          color: isAdmin ? _danger : const Color(0xFFE0E0E0),
          fontSize: 10,
          fontFamily: 'Netflix Sans',
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _UserStatsRow extends StatelessWidget {
  const _UserStatsRow({required this.user});

  final AdminUser user;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _MiniStat(value: user.movieCount.toString(), label: 'Filmes'),
        const SizedBox(width: 8),
        _MiniStat(value: user.seriesCount.toString(), label: 'Séries'),
        const SizedBox(width: 8),
        _MiniStat(value: user.ratingsCount.toString(), label: 'Aval.'),
        const SizedBox(width: 8),
        _MiniStat(value: user.totalHistory.toString(), label: 'Hist.'),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontFamily: 'Netflix Sans',
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFFBDBDBD),
                  fontSize: 10,
                  fontFamily: 'Netflix Sans',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminTabs extends StatelessWidget {
  const _AdminTabs({required this.activeTab, required this.onChanged});

  final _AdminTab activeTab;
  final ValueChanged<_AdminTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          _TabButton(
            icon: Icons.timeline_rounded,
            label: 'Atividade',
            active: activeTab == _AdminTab.history,
            onTap: () => onChanged(_AdminTab.history),
          ),
          _TabButton(
            icon: Icons.star_border_rounded,
            label: 'Avaliações',
            active: activeTab == _AdminTab.ratings,
            onTap: () => onChanged(_AdminTab.ratings),
          ),
          _TabButton(
            icon: Icons.manage_accounts_outlined,
            label: 'Configurações',
            active: activeTab == _AdminTab.settings,
            onTap: () => onChanged(_AdminTab.settings),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active ? Colors.white : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: active ? Colors.white : const Color(0xFFBDBDBD),
              size: 17,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : const Color(0xFFBDBDBD),
                fontSize: 12,
                fontFamily: 'Netflix Sans',
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryPanel extends StatelessWidget {
  const _HistoryPanel({required this.items, required this.onDelete});

  final List<AdminRecentActivity> items;
  final ValueChanged<AdminRecentActivity> onDelete;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _PanelEmpty(message: 'Nenhuma atividade recente.');
    }

    return Column(
      children: [
        for (final item in items) ...[
          _HistoryRow(item: item, onDelete: () => onDelete(item)),
          if (item != items.last) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.item, required this.onDelete});

  final AdminRecentActivity item;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return _PanelRow(
      posterUrl: item.posterUrl,
      fallback: item.mediaType == 'series' ? 'TV' : 'MV',
      title: item.title.isEmpty ? '#${item.tmdbId}' : item.title,
      subtitle: item.mediaType == 'series'
          ? 'Temporada ${item.seasonNumber} - Ep. ${item.episodeNumber}'
          : 'Filme',
      meta: _formatWatchedDate(item.watchedAt),
      onDelete: onDelete,
    );
  }
}

class _RatingsPanel extends StatelessWidget {
  const _RatingsPanel({required this.ratings, required this.onDelete});

  final List<AdminRating> ratings;
  final ValueChanged<AdminRating> onDelete;

  @override
  Widget build(BuildContext context) {
    if (ratings.isEmpty) {
      return const _PanelEmpty(message: 'Nenhuma avaliação.');
    }

    return Column(
      children: [
        for (final rating in ratings) ...[
          _RatingRow(rating: rating, onDelete: () => onDelete(rating)),
          if (rating != ratings.last) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _RatingRow extends StatelessWidget {
  const _RatingRow({required this.rating, required this.onDelete});

  final AdminRating rating;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return _PanelRow(
      fallback: rating.mediaType == 'series' ? 'TV' : 'MV',
      title: '#${rating.tmdbId}',
      subtitle: rating.mediaType == 'series' ? 'Série' : 'Filme',
      meta: _ratingLabel(rating.value),
      onDelete: onDelete,
    );
  }
}

class _PanelRow extends StatelessWidget {
  const _PanelRow({
    required this.fallback,
    required this.title,
    required this.subtitle,
    required this.meta,
    required this.onDelete,
    this.posterUrl,
  });

  final String? posterUrl;
  final String fallback;
  final String title;
  final String subtitle;
  final String meta;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF252525),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 42,
              height: 58,
              child: posterUrl == null || posterUrl!.isEmpty
                  ? Container(
                      color: Colors.white10,
                      alignment: Alignment.center,
                      child: Text(
                        fallback,
                        style: const TextStyle(
                          color: Color(0xFF9E9E9E),
                          fontSize: 10,
                          fontFamily: 'Netflix Sans',
                        ),
                      ),
                    )
                  : Image.network(
                      posterUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: Colors.white10,
                        alignment: Alignment.center,
                        child: Text(
                          fallback,
                          style: const TextStyle(
                            color: Color(0xFF9E9E9E),
                            fontSize: 10,
                            fontFamily: 'Netflix Sans',
                          ),
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontFamily: 'Netflix Sans',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFBDBDBD),
                    fontSize: 11,
                    fontFamily: 'Netflix Sans',
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  meta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 10,
                    fontFamily: 'Netflix Sans',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            tooltip: 'Excluir',
            icon: const Icon(Icons.delete_outline_rounded),
            color: _danger,
          ),
        ],
      ),
    );
  }
}

class _SettingsPanel extends StatelessWidget {
  const _SettingsPanel({required this.user, required this.onRoleChanged});

  final AdminUser user;
  final ValueChanged<String> onRoleChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InfoLine(
          icon: Icons.access_time_rounded,
          label: 'Membro desde',
          value: _formatMemberSince(user.createdAt),
        ),
        const SizedBox(height: 16),
        const Text(
          'Cargo do usuário',
          style: TextStyle(
            color: Color(0xFFBDBDBD),
            fontSize: 12,
            fontFamily: 'Netflix Sans',
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        _RoleSelector(role: user.role, onChanged: onRoleChanged),
        const SizedBox(height: 16),
        _InfoLine(
          icon: Icons.interests_outlined,
          label: 'Gêneros preferidos',
          value: user.preferences?.genres.isNotEmpty == true
              ? user.preferences!.genres.join(', ')
              : 'Nenhum',
        ),
      ],
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFBDBDBD), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFFBDBDBD),
                  fontSize: 12,
                  fontFamily: 'Netflix Sans',
                ),
              ),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontFamily: 'Netflix Sans',
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RoleSelector extends StatelessWidget {
  const _RoleSelector({required this.role, required this.onChanged});

  final String role;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF252525),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: role.toLowerCase() == 'admin' ? 'admin' : 'user',
          dropdownColor: _card,
          iconEnabledColor: Colors.white,
          isExpanded: true,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Netflix Sans',
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          items: const [
            DropdownMenuItem(value: 'user', child: Text('Usuário')),
            DropdownMenuItem(value: 'admin', child: Text('Administrador')),
          ],
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
        ),
      ),
    );
  }
}

class _PanelEmpty extends StatelessWidget {
  const _PanelEmpty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF9E9E9E),
            fontSize: 13,
            fontFamily: 'Netflix Sans',
          ),
        ),
      ),
    );
  }
}

class _AdminLoadingState extends StatelessWidget {
  const _AdminLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
    );
  }
}

class _AdminErrorState extends StatelessWidget {
  const _AdminErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            color: Color(0xFFBDBDBD),
            size: 50,
          ),
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
              color: Color(0xFFBDBDBD),
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
    );
  }
}

class _EmptyUsersState extends StatelessWidget {
  const _EmptyUsersState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Nenhum usuário encontrado.',
        style: TextStyle(
          color: Color(0xFF9E9E9E),
          fontSize: 14,
          fontFamily: 'Netflix Sans',
        ),
      ),
    );
  }
}

class _AdminTotals {
  const _AdminTotals({
    required this.users,
    required this.movies,
    required this.series,
    required this.ratings,
  });

  factory _AdminTotals.fromUsers(List<AdminUser> users) {
    return _AdminTotals(
      users: users.length,
      movies: users.fold(0, (total, user) => total + user.movieCount),
      series: users.fold(0, (total, user) => total + user.seriesCount),
      ratings: users.fold(0, (total, user) => total + user.ratingsCount),
    );
  }

  final int users;
  final int movies;
  final int series;
  final int ratings;
}

String _formatWatchedDate(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return 'Data indisponível';
  final parsed = DateTime.tryParse(dateStr);
  if (parsed == null) return 'Data indisponível';

  final now = DateTime.now();
  final diff = now.difference(parsed);
  if (diff.inDays <= 0) return 'Hoje';
  if (diff.inDays == 1) return 'Ontem';
  if (diff.inDays < 7) return '${diff.inDays} dias atras';
  return '${parsed.day.toString().padLeft(2, '0')}/'
      '${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
}

String _formatMemberSince(String? createdAt) {
  if (createdAt == null || createdAt.isEmpty) return 'Indisponível';

  final parsed = DateTime.tryParse(createdAt);
  if (parsed == null) return 'Indisponível';

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

String _ratingLabel(String value) {
  return switch (value) {
    'love' => 'Amei',
    'like' => 'Gostei',
    'dislike' => 'Nao gostei',
    _ => value,
  };
}
