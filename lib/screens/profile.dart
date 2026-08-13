import 'dart:ui';

import 'package:flutter/material.dart';

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

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _openEditProfileDrawer(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      enableDrag: true,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (context) => const _EditProfileDrawer(),
    );
  }

  void _openSettings(BuildContext context) {
    Navigator.of(context).push(cinematicPageRoute(const SettingScreen()));
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
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(22, 42, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ProfileHeader(onSettingsTap: () => _openSettings(context)),
                  const SizedBox(height: 54),
                  _ProfilePeople(
                    onEditTap: () => _openEditProfileDrawer(context),
                  ),
                  const SizedBox(height: 54),
                  const _ProfileSection(
                    title: 'Information',
                    child: _SettingsCard(
                      children: [
                        _SettingsRow(
                          label: 'Email address',
                          value: 'fgh.jahromi@gmail.com',
                          action: 'Edit email address',
                        ),
                        _SettingsRow(
                          label: 'Phone number',
                          value: '+44 202 777 1111',
                          action: 'Change number',
                        ),
                        _SettingsRow(
                          label: 'Password',
                          value: '@Jha4TGjdl*)wq',
                          action: 'Change password',
                          showDivider: false,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  const _ProfileSection(
                    title: 'Subscription',
                    child: _SettingsCard(
                      children: [
                        _SettingsRow(
                          label: 'Your plan',
                          value: 'Standard \$14.99 mo',
                        ),
                        _SettingsRow(
                          label: 'Next payment',
                          value: 'July 12, 2024',
                          action: 'Cancel',
                          actionColor: _danger,
                        ),
                        _SettingsRow(
                          label: 'Credit card',
                          value: '**** **** **** 2137',
                          showDivider: false,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  const _ProfileSection(
                    title: 'Support',
                    child: _SettingsCard(
                      compact: true,
                      children: [
                        _SupportRow(label: 'Support center'),
                        _SupportRow(
                          label: 'Privacy & Policy',
                          showDivider: false,
                        ),
                      ],
                    ),
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

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.onSettingsTap});

  final VoidCallback onSettingsTap;

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

class _ProfilePeople extends StatelessWidget {
  const _ProfilePeople({required this.onEditTap});

  final VoidCallback onEditTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProfileAvatar(onEditTap: onEditTap),
          const SizedBox(width: 40),
          const _AddProfileButton(),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.onEditTap});

  final VoidCallback onEditTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      child: Column(
        children: [
          ClipOval(
            child: Image.asset(
              'assets/images/control_profile/images/rectangle-395048-72a84d89.png',
              width: 64,
              height: 64,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onEditTap,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Flexible(
                  child: Text(
                    'Ryan',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                      height: 1.57,
                    ),
                  ),
                ),
                SizedBox(width: 5),
                Icon(Icons.edit_outlined, color: Color(0xFF525252), size: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EditProfileDrawer extends StatelessWidget {
  const _EditProfileDrawer();

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
              child: const _EditProfileSheetBody(),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditProfileSheetBody extends StatefulWidget {
  const _EditProfileSheetBody();

  @override
  State<_EditProfileSheetBody> createState() => _EditProfileSheetBodyState();
}

class _EditProfileSheetBodyState extends State<_EditProfileSheetBody> {
  late final TextEditingController _nameController;
  bool _avatarMenuOpen = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: 'Ryan Clark');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
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
                padding: EdgeInsets.fromLTRB(
                  24,
                  21,
                  24,
                  24 + viewInsets.bottom,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxHeight < 690;
                    final topGap = compact ? 58.0 : 115.0;
                    final fieldGap = compact ? 40.0 : 75.0;

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
                                onCurrentAvatarTap: () {
                                  setState(() => _avatarMenuOpen = true);
                                },
                              ),
                              SizedBox(height: fieldGap),
                              _EditNameField(controller: _nameController),
                              const Spacer(),
                              const SizedBox(height: 24),
                              _EditProfileActions(
                                onSave: () => Navigator.of(context).maybePop(),
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
  const _EditProfileAvatars({required this.onCurrentAvatarTap});

  final VoidCallback onCurrentAvatarTap;

  @override
  Widget build(BuildContext context) {
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
                child: Image.asset(
                  'assets/images/control_profile/images/rectangle-395048-72a84d89.png',
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
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
          child: Image.asset(
            'assets/images/control_profile/images/rectangle-395048-e2a7c4c6.png',
            width: 80,
            height: 80,
            fit: BoxFit.cover,
          ),
        ),
      ],
    );
  }
}

class _EditAvatarOverlay extends StatelessWidget {
  const _EditAvatarOverlay({required this.onClose});

  final VoidCallback onClose;

  static const _avatarImages = [
    'assets/images/control_profile/images/rectangle-395048-72a84d89.png',
    'assets/images/control_profile/images/rectangle-395048-e2a7c4c6.png',
    'assets/images/control_profile/images/rectangle-395048-4d7c7301.png',
    'assets/images/control_profile/images/rectangle-395048-e872905c.png',
    'assets/images/control_profile/images/rectangle-395048-400d326e.png',
    'assets/mylist/images/image-I63-1778-63-1748.png',
    'assets/mylist/images/image-I63-1772-63-1748.png',
    'assets/images/rectangle-395047-d712f5e6.png',
    'assets/images/rectangle-395047-8b3ec893.png',
    'assets/images/rectangle-395047-44b1c56e.png',
    'assets/images/rectangle-395044-cd287cf5.png',
    'assets/images/rectangle-395045-fc8f71de.png',
  ];

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
                  itemCount: _avatarImages.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    mainAxisExtent: 50,
                  ),
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onClose,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(
                          _avatarImages[index],
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
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
  const _EditProfileActions({required this.onSave, required this.onCancel});

  final VoidCallback onSave;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _DrawerButton(label: 'Save', primary: true, onTap: onSave),
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

class _AddProfileButton extends StatelessWidget {
  const _AddProfileButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: ShapeDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_card, Color(0x330D0D0D)],
              ),
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: Color(0xFF2C2C2C), width: 1),
                borderRadius: BorderRadius.circular(40),
              ),
            ),
            child: const Icon(Icons.add_rounded, color: _muted, size: 30),
          ),
          const SizedBox(height: 10),
          const Text(
            'Add',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _muted,
              fontSize: 14,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
              height: 1.57,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _muted,
            fontSize: 14,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 18),
        child,
      ],
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
    this.actionColor = _muted,
    this.showDivider = true,
  });

  final String label;
  final String value;
  final String? action;
  final Color actionColor;
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
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 175),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                    height: 1.57,
                  ),
                ),
                if (action != null) ...[
                  const SizedBox(height: 5),
                  Text(
                    action!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: actionColor,
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
