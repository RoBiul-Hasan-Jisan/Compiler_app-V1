import 'package:flutter/material.dart';

import '../../core/utils/ui_state.dart';
import '../../features/editor/editor_screen.dart';
import '../../features/files/files_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/settings/settings_screen.dart';

/// Owns the simple 4-tab bottom navigation. The Editor tab always opens the
/// last-open (or a newly created) file, matching the brief's request for
/// a lightweight, uncomplicated navigation structure.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  void goToEditor([String? fileId]) {
    setState(() {
      _index = 1;
      _pendingFileId = fileId;
    });
  }

  String? _pendingFileId;

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(onOpenFile: goToEditor),
      EditorScreen(initialFileId: _pendingFileId),
      FilesScreen(onOpenFile: goToEditor),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: ValueListenableBuilder<bool>(
        valueListenable: UiState.editorFullscreen,
        builder: (context, fullscreen, child) {
          if (fullscreen && _index == 1) return const SizedBox.shrink();
          return child!;
        },
        child: BottomNavigationBar(
          currentIndex: _index,
          onTap: (i) => setState(() {
            _index = i;
            if (i != 1) _pendingFileId = null;
          }),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.code), label: 'Editor'),
            BottomNavigationBarItem(icon: Icon(Icons.folder_outlined), activeIcon: Icon(Icons.folder), label: 'Files'),
            BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), activeIcon: Icon(Icons.settings), label: 'Settings'),
          ],
        ),
      ),
    );
  }
}
