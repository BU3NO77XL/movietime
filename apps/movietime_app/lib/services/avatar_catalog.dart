const totalAvatars = 255;

// The selection catalog is bundled with the app so it is available offline.
const totalRemoteAvatars = totalAvatars;

String localAvatarAsset(int index) {
  final number = (index + 1).toString().padLeft(2, '0');
  return 'assets/avatars/images/$number.png';
}
