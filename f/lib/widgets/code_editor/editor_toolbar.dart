import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Compact row of icon actions above the editor. Kept deliberately sparse
/// per the design brief — only the most-used actions get a permanent slot.
class EditorToolbar extends StatelessWidget {
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onSearch;
  final VoidCallback onGoToLine;
  final VoidCallback onFormat;
  final VoidCallback onSettings;

  const EditorToolbar({
    super.key,
    required this.onUndo,
    required this.onRedo,
    required this.onSearch,
    required this.onGoToLine,
    required this.onFormat,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      color: IdeColors.darkSurface,
      child: Row(
        children: [
          _ToolbarIcon(icon: Icons.undo, tooltip: 'Undo', onTap: onUndo),
          _ToolbarIcon(icon: Icons.redo, tooltip: 'Redo', onTap: onRedo),
          const SizedBox(width: 4),
          const VerticalDivider(width: 1, indent: 10, endIndent: 10, color: IdeColors.darkBorder),
          const SizedBox(width: 4),
          _ToolbarIcon(icon: Icons.search, tooltip: 'Search / Replace', onTap: onSearch),
          _ToolbarIcon(icon: Icons.numbers, tooltip: 'Go to line', onTap: onGoToLine),
          _ToolbarIcon(icon: Icons.auto_fix_high, tooltip: 'Format', onTap: onFormat),
          const Spacer(),
          _ToolbarIcon(icon: Icons.tune, tooltip: 'Editor settings', onTap: onSettings),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

class _ToolbarIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _ToolbarIcon({required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon, size: 20, color: IdeColors.darkTextPrimary),
        splashRadius: 20,
        onPressed: onTap,
      ),
    );
  }
}
