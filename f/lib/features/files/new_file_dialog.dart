import 'package:flutter/material.dart';

import '../../core/constants/cpp_templates.dart';

class NewFileResult {
  final String fileName;
  final String templateName;
  const NewFileResult({required this.fileName, required this.templateName});
}

Future<NewFileResult?> showNewFileDialog(BuildContext context) {
  final nameController = TextEditingController(text: 'untitled');
  String selectedTemplate = CppTemplates.all.keys.first;

  return showDialog<NewFileResult>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('New C++ File'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'File name', suffixText: '.cpp'),
                ),
                const SizedBox(height: 16),
                const Text('Template', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ...CppTemplates.all.keys.map(
                  (name) => RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(name),
                    value: name,
                    groupValue: selectedTemplate,
                    onChanged: (v) => setState(() => selectedTemplate = v!),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  final name = nameController.text.trim().isEmpty ? 'untitled' : nameController.text.trim();
                  Navigator.pop(context, NewFileResult(fileName: name, templateName: selectedTemplate));
                },
                child: const Text('Create'),
              ),
            ],
          );
        },
      );
    },
  );
}
