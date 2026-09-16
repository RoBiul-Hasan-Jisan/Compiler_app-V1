import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config/app_config.dart';

enum AppThemeMode { dark, light, system }

extension AppThemeModeX on AppThemeMode {
  ThemeMode get flutterThemeMode {
    switch (this) {
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }
}

/// All user-configurable preferences, persisted locally.
class IdeSettings {
  final double fontSize;
  final int tabSize;
  final bool wordWrap;
  final bool showLineNumbers;
  final bool autoIndent;
  final bool syntaxHighlighting;

  final String cppStandard;
  final String compilerApiUrl;
  final int compilerTimeoutSeconds;

  final AppThemeMode themeMode;

  const IdeSettings({
    this.fontSize = 14,
    this.tabSize = 4,
    this.wordWrap = false,
    this.showLineNumbers = true,
    this.autoIndent = true,
    this.syntaxHighlighting = true,
    this.cppStandard = AppConfig.defaultStandard,
    this.compilerApiUrl = AppConfig.defaultCompilerApiUrl,
    this.compilerTimeoutSeconds = 15,
    this.themeMode = AppThemeMode.dark,
  });

  IdeSettings copyWith({
    double? fontSize,
    int? tabSize,
    bool? wordWrap,
    bool? showLineNumbers,
    bool? autoIndent,
    bool? syntaxHighlighting,
    String? cppStandard,
    String? compilerApiUrl,
    int? compilerTimeoutSeconds,
    AppThemeMode? themeMode,
  }) {
    return IdeSettings(
      fontSize: fontSize ?? this.fontSize,
      tabSize: tabSize ?? this.tabSize,
      wordWrap: wordWrap ?? this.wordWrap,
      showLineNumbers: showLineNumbers ?? this.showLineNumbers,
      autoIndent: autoIndent ?? this.autoIndent,
      syntaxHighlighting: syntaxHighlighting ?? this.syntaxHighlighting,
      cppStandard: cppStandard ?? this.cppStandard,
      compilerApiUrl: compilerApiUrl ?? this.compilerApiUrl,
      compilerTimeoutSeconds: compilerTimeoutSeconds ?? this.compilerTimeoutSeconds,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}

class SettingsRepository extends ChangeNotifier {
  static const _prefix = 'cpp_ide.settings.';

  IdeSettings _settings = const IdeSettings();
  IdeSettings get settings => _settings;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _settings = IdeSettings(
      fontSize: prefs.getDouble('${_prefix}fontSize') ?? 14,
      tabSize: prefs.getInt('${_prefix}tabSize') ?? 4,
      wordWrap: prefs.getBool('${_prefix}wordWrap') ?? false,
      showLineNumbers: prefs.getBool('${_prefix}showLineNumbers') ?? true,
      autoIndent: prefs.getBool('${_prefix}autoIndent') ?? true,
      syntaxHighlighting: prefs.getBool('${_prefix}syntaxHighlighting') ?? true,
      cppStandard: prefs.getString('${_prefix}cppStandard') ?? AppConfig.defaultStandard,
      compilerApiUrl: prefs.getString('${_prefix}compilerApiUrl') ?? AppConfig.defaultCompilerApiUrl,
      compilerTimeoutSeconds: prefs.getInt('${_prefix}compilerTimeoutSeconds') ?? 15,
      themeMode: AppThemeMode.values[prefs.getInt('${_prefix}themeMode') ?? 0],
    );
    notifyListeners();
  }

  Future<void> update(IdeSettings Function(IdeSettings current) updater) async {
    _settings = updater(_settings);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('${_prefix}fontSize', _settings.fontSize);
    await prefs.setInt('${_prefix}tabSize', _settings.tabSize);
    await prefs.setBool('${_prefix}wordWrap', _settings.wordWrap);
    await prefs.setBool('${_prefix}showLineNumbers', _settings.showLineNumbers);
    await prefs.setBool('${_prefix}autoIndent', _settings.autoIndent);
    await prefs.setBool('${_prefix}syntaxHighlighting', _settings.syntaxHighlighting);
    await prefs.setString('${_prefix}cppStandard', _settings.cppStandard);
    await prefs.setString('${_prefix}compilerApiUrl', _settings.compilerApiUrl);
    await prefs.setInt('${_prefix}compilerTimeoutSeconds', _settings.compilerTimeoutSeconds);
    await prefs.setInt('${_prefix}themeMode', _settings.themeMode.index);
  }
}
