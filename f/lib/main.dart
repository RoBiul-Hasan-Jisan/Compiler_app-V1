import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/file_repository.dart';
import 'data/repositories/settings_repository.dart';
import 'widgets/common/root_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CppIdeApp());
}

class CppIdeApp extends StatefulWidget {
  const CppIdeApp({super.key});

  @override
  State<CppIdeApp> createState() => _CppIdeAppState();
}

class _CppIdeAppState extends State<CppIdeApp> {
  late final FileRepository _fileRepository;
  late final SettingsRepository _settingsRepository;

  @override
  void initState() {
    super.initState();
    _fileRepository = FileRepository();
    _settingsRepository = SettingsRepository();
    _fileRepository.load();
    _settingsRepository.load();
  }

  @override
  void dispose() {
    _fileRepository.dispose();
    _settingsRepository.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _fileRepository),
        ChangeNotifierProvider.value(value: _settingsRepository),
      ],
      child: Consumer<SettingsRepository>(
        builder: (context, settingsRepo, _) {
          return MaterialApp(
            title: AppConfig.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: settingsRepo.settings.themeMode.flutterThemeMode,
            home: const RootShell(),
          );
        },
      ),
    );
  }
}
