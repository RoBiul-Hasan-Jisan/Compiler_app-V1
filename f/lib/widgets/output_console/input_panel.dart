import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';

/// Multiline stdin input panel with clear/paste/run-with-input actions.
class InputPanel extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onRunWithInput;

  const InputPanel({super.key, required this.controller, required this.onRunWithInput});

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      controller.text = data!.text!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: IdeColors.darkSurface,
        border: Border(top: BorderSide(color: IdeColors.darkBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 4, 4),
            child: Row(
              children: [
                const Text(
                  'INPUT',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: IdeColors.darkTextSecondary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.content_paste, size: 16, color: IdeColors.darkTextSecondary),
                  tooltip: 'Paste',
                  splashRadius: 16,
                  onPressed: _paste,
                ),
                IconButton(
                  icon: const Icon(Icons.clear, size: 16, color: IdeColors.darkTextSecondary),
                  tooltip: 'Clear input',
                  splashRadius: 16,
                  onPressed: () => controller.clear(),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                color: IdeColors.darkSurfaceAlt,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: IdeColors.darkBorder),
              ),
              child: TextField(
                controller: controller,
                maxLines: null,
                expands: true,
                style: const TextStyle(
                  fontFamily: AppTheme.editorFontFamily,
                  fontSize: 13,
                  color: IdeColors.darkTextPrimary,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.all(10),
                  hintText: 'stdin — one value per line',
                  hintStyle: TextStyle(color: IdeColors.darkTextSecondary, fontSize: 12),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onRunWithInput,
                icon: const Icon(Icons.play_arrow, size: 16),
                label: const Text('Run with input'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
