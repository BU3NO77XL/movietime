import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class AppUpdateInfo {
  const AppUpdateInfo({
    required this.versionName,
    required this.versionCode,
    required this.releaseUrl,
    required this.downloadUrl,
    required this.notes,
  });

  final String versionName;
  final int versionCode;
  final Uri releaseUrl;
  final Uri? downloadUrl;
  final String notes;
}

class AppUpdateService {
  const AppUpdateService();

  static const owner = 'BU3NO77XL';
  static const repository = 'movietime';
  static const _latestReleaseUrl =
      'https://api.github.com/repos/$owner/$repository/releases/latest';

  static final http.Client _client = http.Client();

  Future<AppUpdateInfo?> check() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final response = await _client
          .get(
            Uri.parse(_latestReleaseUrl),
            headers: const {
              'Accept': 'application/vnd.github+json',
              'User-Agent': 'MovieTime-App',
            },
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return null;
      final json = jsonDecode(response.body);
      if (json is! Map<String, dynamic> || json['draft'] == true) return null;

      final tag = json['tag_name']?.toString() ?? '';
      final versionName = _normalizeVersion(tag);
      final versionCode = int.tryParse(
        json['target_commitish']?.toString() ?? '',
      );
      final releaseUrl = Uri.tryParse(json['html_url']?.toString() ?? '');
      if (versionName == null || releaseUrl == null) return null;

      final assets = json['assets'];
      Uri? downloadUrl;
      if (assets is List) {
        for (final asset in assets) {
          if (asset is! Map<String, dynamic>) continue;
          final name = asset['name']?.toString().toLowerCase() ?? '';
          final url = Uri.tryParse(
            asset['browser_download_url']?.toString() ?? '',
          );
          if (url == null || !name.endsWith('.apk')) continue;
          downloadUrl = url;
          if (name == 'movietime.apk') break;
        }
      }

      final latestCode = versionCode ?? _versionCode(versionName);
      final installedCode = int.tryParse(packageInfo.buildNumber) ?? 0;
      if (latestCode <= installedCode) return null;

      return AppUpdateInfo(
        versionName: versionName,
        versionCode: latestCode,
        releaseUrl: releaseUrl,
        downloadUrl: downloadUrl,
        notes: json['body']?.toString().trim() ?? '',
      );
    } catch (_) {
      return null;
    }
  }

  String? _normalizeVersion(String tag) {
    final value = tag.trim().replaceFirst(RegExp(r'^[vV]'), '');
    return RegExp(r'^\d+\.\d+\.\d+(?:[-+][0-9A-Za-z.-]+)?$').hasMatch(value)
        ? value
        : null;
  }

  int _versionCode(String version) {
    final match = RegExp(r'^(\d+)\.(\d+)\.(\d+)').firstMatch(version);
    if (match == null) return 0;
    return int.parse(match.group(1)!) * 1000000 +
        int.parse(match.group(2)!) * 1000 +
        int.parse(match.group(3)!);
  }
}
