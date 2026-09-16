import 'package:flutter/material.dart';

import 'cpp_editor_controller.dart';

/// Shows a bottom-sheet style search/replace panel operating on
/// [controller]'s text. Kept as free functions (rather than a stateful
/// dialog widget owned by the editor) so it can be triggered from the
/// toolbar without the editor needing to know dialog internals.
Future<void> showSearchReplaceSheet(BuildContext context, CppEditorController controller) {
  final searchCtrl = TextEditingController();
  final replaceCtrl = TextEditingController();
  int currentMatch = -1;
  List<int> matches = [];

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          void runSearch(String query) {
            matches = [];
            currentMatch = -1;
            if (query.isEmpty) {
              setState(() {});
              return;
            }
            final text = controller.text;
            var start = 0;
            while (true) {
              final idx = text.indexOf(query, start);
              if (idx == -1) break;
              matches.add(idx);
              start = idx + query.length;
            }
            if (matches.isNotEmpty) currentMatch = 0;
            setState(() {});
          }

          void selectCurrentMatch() {
            if (currentMatch < 0 || currentMatch >= matches.length) return;
            final start = matches[currentMatch];
            final end = start + searchCtrl.text.length;
            controller.selection = TextSelection(baseOffset: start, extentOffset: end);
          }

          void next() {
            if (matches.isEmpty) return;
            currentMatch = (currentMatch + 1) % matches.length;
            selectCurrentMatch();
            setState(() {});
          }

          void previous() {
            if (matches.isEmpty) return;
            currentMatch = (currentMatch - 1 + matches.length) % matches.length;
            selectCurrentMatch();
            setState(() {});
          }

          void replaceOne() {
            if (currentMatch < 0 || currentMatch >= matches.length) return;
            final start = matches[currentMatch];
            final end = start + searchCtrl.text.length;
            final newText = controller.text.replaceRange(start, end, replaceCtrl.text);
            controller.text = newText;
            runSearch(searchCtrl.text);
          }

          void replaceAll() {
            if (searchCtrl.text.isEmpty) return;
            controller.text = controller.text.replaceAll(searchCtrl.text, replaceCtrl.text);
            runSearch(searchCtrl.text);
          }

          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Search & Replace', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                TextField(
                  controller: searchCtrl,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Search',
                    suffixText: matches.isEmpty ? null : '${currentMatch + 1}/${matches.length}',
                  ),
                  onChanged: runSearch,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: replaceCtrl,
                  decoration: const InputDecoration(labelText: 'Replace with'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(onPressed: previous, child: const Text('Previous')),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(onPressed: next, child: const Text('Next')),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(onPressed: replaceOne, child: const Text('Replace')),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(onPressed: replaceAll, child: const Text('Replace All')),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

/// Prompts for a line number and returns it, or null if cancelled.
Future<int?> showGoToLineDialog(BuildContext context, int maxLine) {
  final controller = TextEditingController();
  return showDialog<int>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Go to line'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(hintText: '1 – $maxLine'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final line = int.tryParse(controller.text);
              Navigator.pop(context, line);
            },
            child: const Text('Go'),
          ),
        ],
      );
    },
  );
}
