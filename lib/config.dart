class AppConfig {
  static const String baseUrl =
  String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://10.85.198.144:8000/api',
  );
}