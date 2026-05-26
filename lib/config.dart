class AppConfig {
  static const String baseUrl =
  String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://192.168.66.32:8000/api',
  );
}