class AppConfig {
  AppConfig._();

  /// Base URL of the C++ compiler backend.
  ///
  /// Can be overridden at build/run time with:
  /// flutter run --dart-define=COMPILER_API_URL=https://your-server.com
  static const String defaultCompilerApiUrl = String.fromEnvironment(
    'COMPILER_API_URL',
    defaultValue: 'https://compilerbackend-hqwk.onrender.com',
  );

  /// Default request timeout for a compile+run round trip.
  static const Duration defaultCompilerTimeout = Duration(seconds: 15);

  static const String appName = 'C++ IDE';

  static const List<String> supportedStandards = [
    'c++17',
    'c++20',
    'c++23',
  ];

  static const String defaultStandard = 'c++17';

  static const String cppExtension = '.cpp';
}