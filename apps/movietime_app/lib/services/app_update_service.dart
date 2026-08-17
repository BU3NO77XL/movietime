import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import 'api_config.dart';

class AppUpdateInfo {
  const AppUpdateInfo({
    required this.versionName,
    required this.versionCode,
    required this.downloadUrl,
    required this.notes,
    required this.mandatory,
  });

  final String versionName;
  final int versionCode;
  final Uri downloadUrl;
  final String notes;
  final bool mandatory;
}

class AppUpdateService {
  const AppUpdateService();

  static final http.Client _client = http.Client();

  Future<AppUpdateInfo?> check() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final response = await _client
          .get(
            Uri.parse('${ApiConfig.baseUrl}/api/app-version'),
            headers: const {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return null;
      final json = jsonDecode(response.body);
      if (json is! Map<String, dynamic>) return null;

      final versionName = json['versionName']?.toString();
      final versionCode = (json['versionCode'] as num?)?.toInt();
      final downloadUrl = Uri.tryParse(json['downloadUrl']?.toString() ?? '');
      if (versionName == null ||
          versionCode == null ||
          downloadUrl == null ||
          !downloadUrl.hasScheme) {
        return null;
      }

      final installedCode = int.tryParse(packageInfo.buildNumber) ?? 0;
      if (versionCode <= installedCode) return null;

      return AppUpdateInfo(
        versionName: versionName,
        versionCode: versionCode,
        downloadUrl: downloadUrl,
        notes: json['notes']?.toString().trim() ?? '',
        mandatory: json['mandatory'] == true,
      );
    } catch (_) {
      return null;
    }
  }
}
