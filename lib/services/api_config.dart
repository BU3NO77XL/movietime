class ApiConfig {
  const ApiConfig._();

  static const _definedBaseUrl = String.fromEnvironment(
    'MOVIETIME_API_BASE_URL',
  );

  static String get baseUrl {
    if (_definedBaseUrl.isNotEmpty) return _trimTrailingSlash(_definedBaseUrl);
    return 'https://movietimeweb.vercel.app';
  }

  static String _trimTrailingSlash(String value) {
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }
}
