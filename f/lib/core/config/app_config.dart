/// Central, environment-driven configuration for the app.
///
/// Nothing sensitive lives here — the compiler endpoint is the only
/// externally-configurable value and it defaults to the Android emulator's
/// loopback alias so a locally-run compiler backend "just works" in dev.
class AppConfig {
  AppConfig._();

  /// Base URL of the C++ compiler backend.
  ///
  /// Override at build/run time with:
  ///   flutter run --dart-define=COMPILER_API_URL=https://your-server.com
  static const String defaultCompilerApiUrl = String.fromEnvironment(
    'COMPILER_API_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  /// Default request timeout for a compile+run round trip.
  static const Duration defaultCompilerTimeout = Duration(seconds: 15);

  static const String appName = 'C++ IDE';

  static const List<String> supportedStandards = ['c++17', 'c++20', 'c++23'];
  static const String defaultStandard = 'c++17';

  static const String cppExtension = '.cpp';
}
