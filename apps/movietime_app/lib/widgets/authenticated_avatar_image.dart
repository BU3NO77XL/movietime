import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/api_config.dart';
import '../services/session_store.dart';
import 'local_avatar_image.dart';

class AuthenticatedAvatarImage extends StatefulWidget {
  const AuthenticatedAvatarImage({
    required this.avatarIndex,
    this.avatarUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.useRemoteAvatar = true,
    this.sessionStore = const SessionStore(),
    super.key,
  });

  final int avatarIndex;
  final String? avatarUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final bool useRemoteAvatar;
  final SessionStore sessionStore;

  @override
  State<AuthenticatedAvatarImage> createState() =>
      _AuthenticatedAvatarImageState();
}

class _AuthenticatedAvatarImageState extends State<AuthenticatedAvatarImage> {
  late Future<Uint8List?> _avatarFuture;

  @override
  void initState() {
    super.initState();
    _avatarFuture = _loadAvatarBytes();
  }

  @override
  void didUpdateWidget(covariant AuthenticatedAvatarImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.avatarIndex != widget.avatarIndex ||
        oldWidget.avatarUrl != widget.avatarUrl ||
        oldWidget.useRemoteAvatar != widget.useRemoteAvatar ||
        oldWidget.sessionStore != widget.sessionStore) {
      _avatarFuture = _loadAvatarBytes();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.useRemoteAvatar) {
      return _localAvatar();
    }

    return FutureBuilder<Uint8List?>(
      future: _avatarFuture,
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (snapshot.connectionState == ConnectionState.done &&
            bytes != null &&
            bytes.isNotEmpty) {
          return Image.memory(
            bytes,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
            errorBuilder: (_, _, _) => _localAvatar(),
          );
        }

        // Keep the selected avatar visible while the authenticated request loads.
        return _localAvatar();
      },
    );
  }

  Widget _localAvatar() {
    return LocalAvatarImage(
      avatarIndex: widget.avatarIndex,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
    );
  }

  Future<Uint8List?> _loadAvatarBytes() async {
    final accessToken = await widget.sessionStore.accessToken();
    if (accessToken == null || accessToken.isEmpty) {
      return null;
    }

    final configuredUrl = widget.avatarUrl?.trim();
    final avatarUri = configuredUrl != null && configuredUrl.isNotEmpty
        ? _resolveAvatarUri(configuredUrl)
        : Uri.parse(
            '${ApiConfig.baseUrl}/api/avatars/${(widget.avatarIndex + 1).toString().padLeft(2, '0')}',
          );
    final response = await http.get(
      avatarUri,
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }

    return response.bodyBytes;
  }

  Uri _resolveAvatarUri(String value) {
    final parsed = Uri.tryParse(value);
    if (parsed?.hasScheme == true) return parsed!;
    return Uri.parse(
      '${ApiConfig.baseUrl}${value.startsWith('/') ? '' : '/'}$value',
    );
  }
}
