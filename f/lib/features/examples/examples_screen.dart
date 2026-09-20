import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/cpp_examples.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/file_repository.dart';

/// "Learn by examples": a list of small, ready-to-run programs. Tap one to
/// read the code, copy it, or open it in the editor as a new file.
class ExamplesScreen extends StatelessWidget {
  /// Called with the id of the newly created file once the user taps
  /// "Open in editor". The screen closes itself first.
  final void Function(String fileId) onOpenFile;

  const ExamplesScreen({super.key, required this.onOpenFile});

  Future<void> _openInEditor(BuildContext context, CppExample example) async {
    final repo = context.read<FileRepository>();
    final navigator = Navigator.of(context);
    final fileName = example.title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    final file = await repo.createFile(name: fileName, content: example.code);
    navigator.pop();
    onOpenFile(file.id);
  }

  void _copy(BuildContext context, CppExample example) {
    Clipboard.setData(ClipboardData(text: example.code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Code copied'), duration: Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    const examples = CppExamples.all;

    return Scaffold(
      appBar: AppBar(title: const Text('Learn by examples')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _InfoCard(),
          const SizedBox(height: 16),
          for (var i = 0; i < examples.length; i++) ...[
            _ExampleCard(
              number: i + 1,
              example: examples[i],
              onOpen: () => _openInEditor(context, examples[i]),
              onCopy: () => _copy(context, examples[i]),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: IdeColors.darkSurfaceAlt,
        borderRadius: BorderRadius.circular(IdeMetrics.radiusSm),
        border: Border.all(color: IdeColors.accent.withOpacity(0.5)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: IdeColors.accent, size: 18),
              SizedBox(width: 8),
              Text('How to write code here', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          SizedBox(height: 10),
          Text(
            'This app runs a simple, C++-style language.\n\n'
            '• Start with:  int main() { ... return 0; }\n'
            '• Show text with print(...), separated by commas:\n'
            '   print("Total = ", total, "\\n");\n'
            '• Every line ends with ;\n'
            '• Declare variables with a type: int, float, string, char, bool\n'
            '• Use i = i + 1 or i++ (but not +=)\n\n'
            'Not supported: #include, cout / cin, vector, classes, pointers.',
            style: TextStyle(fontSize: 12.5, height: 1.45, color: IdeColors.darkTextSecondary),
          ),
        ],
      ),
    );
  }
}

class _ExampleCard extends StatelessWidget {
  final int number;
  final CppExample example;
  final VoidCallback onOpen;
  final VoidCallback onCopy;

  const _ExampleCard({
    required this.number,
    required this.example,
    required this.onOpen,
    required this.onCopy,
  });

  Color get _levelColor {
    switch (example.level) {
      case 'Beginner':
        return IdeColors.success;
      case 'Easy':
        return IdeColors.accent;
      default:
        return IdeColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: IdeColors.darkSurface,
        borderRadius: BorderRadius.circular(IdeMetrics.radiusSm),
        border: Border.all(color: IdeColors.darkBorder),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          title: Text('$number. ${example.title}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: _levelColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    example.level,
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: _levelColor),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    example.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: IdeColors.darkTextSecondary),
                  ),
                ),
              ],
            ),
          ),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: IdeColors.darkBackground,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: IdeColors.darkBorder),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SelectableText(
                  example.code.trimRight(),
                  style: const TextStyle(
                    fontFamily: AppTheme.editorFontFamily,
                    fontSize: 12,
                    height: 1.45,
                    color: IdeColors.darkTextPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onOpen,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Open in editor'),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: onCopy,
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copy'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
