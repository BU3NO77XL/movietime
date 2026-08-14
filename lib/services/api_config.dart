import 'package:flutter/foundation.dart';

class ApiConfig {
  const ApiConfig._();

  static const _definedBaseUrl = String.fromEnvironment(
    'MOVIETIME_API_BASE_URL',
  );

  static String get baseUrl {
    if (_definedBaseUrl.isNotEmpty) return _trimTrailingSlash(_definedBaseUrl);
    if (kIsWeb) return 'http://localhost:3000';

    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'http://10.0.2.2:3000',
      _ => 'http://localhost:3000',
    };
  }

  static String _trimTrailingSlash(String value) {
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }
}
