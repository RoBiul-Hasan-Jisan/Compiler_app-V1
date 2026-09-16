import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../data/repositories/settings_repository.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<SettingsRepository>();
    final s = repo.settings;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          _SectionHeader('Editor'),
          ListTile(
            title: const Text('Font size'),
            subtitle: Slider(
              value: s.fontSize,
              min: 10,
              max: 24,
              divisions: 14,
              label: s.fontSize.toStringAsFixed(0),
              onChanged: (v) => repo.update((c) => c.copyWith(fontSize: v)),
            ),
          ),
          ListTile(
            title: const Text('Tab size'),
            subtitle: Slider(
              value: s.tabSize.toDouble(),
              min: 2,
              max: 8,
              divisions: 6,
              label: '${s.tabSize} spaces',
              onChanged: (v) => repo.update((c) => c.copyWith(tabSize: v.round())),
            ),
          ),
          SwitchListTile(
            title: const Text('Word wrap'),
            value: s.wordWrap,
            onChanged: (v) => repo.update((c) => c.copyWith(wordWrap: v)),
          ),
          SwitchListTile(
            title: const Text('Line numbers'),
            value: s.showLineNumbers,
            onChanged: (v) => repo.update((c) => c.copyWith(showLineNumbers: v)),
          ),
          SwitchListTile(
            title: const Text('Auto indentation'),
            value: s.autoIndent,
            onChanged: (v) => repo.update((c) => c.copyWith(autoIndent: v)),
          ),
          SwitchListTile(
            title: const Text('Syntax highlighting'),
            value: s.syntaxHighlighting,
            onChanged: (v) => repo.update((c) => c.copyWith(syntaxHighlighting: v)),
          ),
          const Divider(),
          _SectionHeader('Compiler'),
          ListTile(
            title: const Text('C++ standard'),
            subtitle: const Text(
              'Only affects a real C++ (g++) backend — ignored by the mcpp backend',
              style: TextStyle(fontSize: 11),
            ),
            trailing: DropdownButton<String>(
              value: s.cppStandard,
              items: AppConfig.supportedStandards
                  .map((std) => DropdownMenuItem(value: std, child: Text(std.toUpperCase())))
                  .toList(),
              onChanged: (v) {
                if (v != null) repo.update((c) => c.copyWith(cppStandard: v));
              },
            ),
          ),
          ListTile(
            title: const Text('Compiler endpoint'),
            subtitle: Text(s.compilerApiUrl),
            trailing: const Icon(Icons.edit_outlined, size: 18),
            onTap: () async {
              final controller = TextEditingController(text: s.compilerApiUrl);
              final newUrl = await showDialog<String>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Compiler endpoint'),
                  content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'https://…')),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                    ElevatedButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Save')),
                  ],
                ),
              );
              if (newUrl != null && newUrl.isNotEmpty) {
                repo.update((c) => c.copyWith(compilerApiUrl: newUrl));
              }
            },
          ),
          ListTile(
            title: const Text('Compilation timeout'),
            subtitle: Slider(
              value: s.compilerTimeoutSeconds.toDouble(),
              min: 5,
              max: 60,
              divisions: 11,
              label: '${s.compilerTimeoutSeconds}s',
              onChanged: (v) => repo.update((c) => c.copyWith(compilerTimeoutSeconds: v.round())),
            ),
          ),
          const Divider(),
          _SectionHeader('Appearance'),
          RadioListTile<AppThemeMode>(
            title: const Text('Dark'),
            value: AppThemeMode.dark,
            groupValue: s.themeMode,
            onChanged: (v) => repo.update((c) => c.copyWith(themeMode: v)),
          ),
          RadioListTile<AppThemeMode>(
            title: const Text('Light'),
            value: AppThemeMode.light,
            groupValue: s.themeMode,
            onChanged: (v) => repo.update((c) => c.copyWith(themeMode: v)),
          ),
          RadioListTile<AppThemeMode>(
            title: const Text('System'),
            value: AppThemeMode.system,
            groupValue: s.themeMode,
            onChanged: (v) => repo.update((c) => c.copyWith(themeMode: v)),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
