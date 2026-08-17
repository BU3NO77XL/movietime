import 'package:flutter/foundation.dart';

class AvatarState extends ChangeNotifier {
  AvatarState._();

  static final AvatarState instance = AvatarState._();

  int? _avatarIndex;
  String? _avatarUrl;

  int? get avatarIndex => _avatarIndex;
  String? get avatarUrl => _avatarUrl;

  void update({required int avatarIndex, String? avatarUrl}) {
    _avatarIndex = avatarIndex;
    _avatarUrl = avatarUrl;
    notifyListeners();
  }
}
