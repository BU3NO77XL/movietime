import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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

  // Cache em memória + persistente (localStorage via secure storage)
  // para carregar só na primeira vez e manter sem flash.
  static final Map<String, Uint8List> _bytesCache = {};
  static final Map<String, Future<Uint8List?>> _inFlight = {};
  static const _storage = FlutterSecureStorage();
  static const _bytesPrefix = 'movietime_avatar_bytes_';

  String _cacheKey(String? token, int index, String? url) =>
      '${token ?? ''}|$index|${url ?? ''}';

  String _persistKey(int index, String? url) {
    final raw = url == null || url.isEmpty ? 'idx_$index' : url.hashCode.toString();
    return '$_bytesPrefix${index}_$raw';
  }

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
        // Se já temos bytes em cache, mostra remoto direto sem passar pelo fallback.
        if (bytes != null && bytes.isNotEmpty) {
          return Image.memory(
            bytes,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
            gaplessPlayback: true,
            errorBuilder: (_, _, _) => _localAvatar(),
          );
        }

        // Enquanto carrega, mantém avatar local visível (sem piscada para ícone genérico).
        // Só mostra erro se a requisição terminou sem bytes.
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
    final configuredUrl = widget.avatarUrl?.trim();
    final persistKey = _persistKey(widget.avatarIndex, configuredUrl);
    // 1) Memória
    final memKey = _cacheKey(null, widget.avatarIndex, configuredUrl);
    final memCached = _bytesCache[memKey];
    if (memCached != null && memCached.isNotEmpty) return memCached;

    // 2) LocalStorage persistente — carrega sem rede, sem piscada
    try {
      final b64 = await _storage.read(key: persistKey);
      if (b64 != null && b64.isNotEmpty) {
        final bytes = base64Decode(b64);
        if (bytes.isNotEmpty) {
          _bytesCache[memKey] = bytes;
          return bytes;
        }
      }
    } catch (_) {}

    final accessToken = await widget.sessionStore.accessToken();
    if (accessToken == null || accessToken.isEmpty) {
      return null;
    }

    final key = _cacheKey(accessToken, widget.avatarIndex, configuredUrl);
    final inFlight = _inFlight[key];
    if (inFlight != null) return inFlight;

    final future = _fetchBytes(accessToken, configuredUrl, key, persistKey);
    _inFlight[key] = future;
    final result = await future;
    _inFlight.remove(key);
    return result;
  }

  Future<Uint8List?> _fetchBytes(
    String accessToken,
    String? configuredUrl,
    String cacheKey,
    String persistKey,
  ) async {
    final avatarUri = configuredUrl != null && configuredUrl.isNotEmpty
        ? _resolveAvatarUri(configuredUrl)
        : Uri.parse(
            '${ApiConfig.baseUrl}/api/avatars/${(widget.avatarIndex + 1).toString().padLeft(2, '0')}',
          );
    try {
      final response = await http
          .get(
            avatarUri,
            headers: {'Authorization': 'Bearer $accessToken'},
          )
          .timeout(const Duration(seconds: 8));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }
      final bytes = response.bodyBytes;
      if (bytes.isNotEmpty) {
        final memKey = _cacheKey(null, widget.avatarIndex, configuredUrl);
        _bytesCache[memKey] = bytes;
        _bytesCache[cacheKey] = bytes;
        // Persiste base64 para próxima inicialização sem rede
        try {
          await _storage.write(key: persistKey, value: base64Encode(bytes));
        } catch (_) {}
      }
      return bytes;
    } catch (_) {
      return null;
    }
  }

  Uri _resolveAvatarUri(String value) {
    final parsed = Uri.tryParse(value);
    if (parsed?.hasScheme == true) return parsed!;
    return Uri.parse(
      '${ApiConfig.baseUrl}${value.startsWith('/') ? '' : '/'}$value',
    );
  }
}
