class AppConfig {
  static const String baseUrl =
  String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://192.168.67.132:8000/api',
  );
}