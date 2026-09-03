import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AvatarState extends ChangeNotifier {
  AvatarState._();

  static final AvatarState instance = AvatarState._();

  static const _kIndexKey = 'movietime_avatar_index';
  static const _kUrlKey = 'movietime_avatar_url';
  static const _storage = FlutterSecureStorage();

  int? _avatarIndex;
  String? _avatarUrl;
  bool _hydrated = false;

  int? get avatarIndex => _avatarIndex;
  String? get avatarUrl => _avatarUrl;

  /// Carrega do storage persistente uma única vez. Chamado antes do menu.
  Future<void> hydrate() async {
    if (_hydrated) return;
    _hydrated = true;
    if (_avatarIndex != null) return;
    try {
      final rawIndex = await _storage.read(key: _kIndexKey);
      final rawUrl = await _storage.read(key: _kUrlKey);
      final idx = rawIndex == null ? null : int.tryParse(rawIndex);
      if (idx != null) {
        _avatarIndex = idx;
        _avatarUrl = rawUrl;
      }
    } catch (_) {}
  }

  void update({required int avatarIndex, String? avatarUrl}) {
    _avatarIndex = avatarIndex;
    _avatarUrl = avatarUrl;
    // Persiste para não piscar mockado na próxima inicialização
    _storage.write(key: _kIndexKey, value: '$avatarIndex');
    if (avatarUrl == null) {
      _storage.delete(key: _kUrlKey);
    } else {
      _storage.write(key: _kUrlKey, value: avatarUrl);
    }
    notifyListeners();
  }

  Future<void> clearPersisted() async {
    _avatarIndex = null;
    _avatarUrl = null;
    _hydrated = false;
    try {
      await _storage.delete(key: _kIndexKey);
      await _storage.delete(key: _kUrlKey);
    } catch (_) {}
    notifyListeners();
  }
}
