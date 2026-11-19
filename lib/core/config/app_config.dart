class AppConfig {
  const AppConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    // defaultValue: 'http://10.0.2.2:8080',
    defaultValue: 'http://72.56.90.117:8080',
  );

  static const Duration requestTimeout = Duration(seconds: 15);

  static String get apiBase => apiBaseUrl.endsWith('/')
      ? apiBaseUrl.substring(0, apiBaseUrl.length - 1)
      : apiBaseUrl;
}
