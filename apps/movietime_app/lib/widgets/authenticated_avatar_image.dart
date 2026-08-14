import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/api_config.dart';
import '../services/session_store.dart';

class AuthenticatedAvatarImage extends StatelessWidget {
  const AuthenticatedAvatarImage({
    required this.avatarIndex,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.useRemoteAvatar = true,
    this.sessionStore = const SessionStore(),
    super.key,
  });

  final int avatarIndex;
  final double? width;
  final double? height;
  final BoxFit fit;
  final bool useRemoteAvatar;
  final SessionStore sessionStore;

  @override
  Widget build(BuildContext context) {
    if (!useRemoteAvatar) {
      return _placeholder();
    }

    return FutureBuilder<Uint8List?>(
      future: _loadAvatarBytes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return SizedBox(
            width: width,
            height: height,
            child: const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white54,
                ),
              ),
            ),
          );
        }

        final bytes = snapshot.data;
        if (bytes == null || bytes.isEmpty) {
          return _placeholder();
        }

        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, _, _) => _placeholder(),
        );
      },
    );
  }

  Future<Uint8List?> _loadAvatarBytes() async {
    final accessToken = await sessionStore.accessToken();
    if (accessToken == null || accessToken.isEmpty) {
      return null;
    }

    final avatarNumber = (avatarIndex + 1).toString().padLeft(2, '0');
    final avatarUri = Uri.parse(
      '${ApiConfig.baseUrl}/api/avatars/$avatarNumber',
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

  Widget _placeholder() {
    return Container(
      width: width,
      height: height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2C2C2C), Color(0xFF111111)],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.person_rounded,
          color: Colors.white54,
          size: 28,
        ),
      ),
    );
  }
}
