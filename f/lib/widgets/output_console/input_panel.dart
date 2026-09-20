import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';

/// Multiline stdin input panel with clear/paste/run-with-input actions.
///
/// The panel can be collapsed (tap the header or the chevron) to give the
/// code editor more room on small screens.
class InputPanel extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onRunWithInput;

  const InputPanel({super.key, required this.controller, required this.onRunWithInput});

  @override
  State<InputPanel> createState() => _InputPanelState();
}

class _InputPanelState extends State<InputPanel> {
  final FocusNode _focusNode = FocusNode();
  bool _collapsed = false;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.isEmpty) return;
    widget.controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  /// Empties the input. Sets the whole value (text + a valid selection)
  /// instead of relying on `clear()`, so the on-screen keyboard's text
  /// state is reset reliably too.
  void _clear() {
    widget.controller.value = const TextEditingValue(
      text: '',
      selection: TextSelection.collapsed(offset: 0),
    );
    if (!_collapsed) _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: IdeColors.darkSurface,
        border: Border(top: BorderSide(color: IdeColors.darkBorder)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _collapsed = !_collapsed),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 4, 0),
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
                    icon: const Icon(Icons.content_paste, size: 18, color: IdeColors.darkTextSecondary),
                    tooltip: 'Paste',
                    onPressed: _paste,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: IdeColors.darkTextSecondary),
                    tooltip: 'Clear input',
                    onPressed: _clear,
                  ),
                  IconButton(
                    icon: Icon(
                      _collapsed ? Icons.expand_less : Icons.expand_more,
                      size: 22,
                      color: IdeColors.darkTextSecondary,
                    ),
                    tooltip: _collapsed ? 'Show input' : 'Hide input',
                    onPressed: () => setState(() => _collapsed = !_collapsed),
                  ),
                ],
              ),
            ),
          ),
          if (!_collapsed) ...[
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
                  controller: widget.controller,
                  focusNode: _focusNode,
                  maxLines: null,
                  expands: true,
                  keyboardType: TextInputType.multiline,
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
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: widget.onRunWithInput,
                  icon: const Icon(Icons.play_arrow, size: 16),
                  label: const Text('Run with input'),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
