import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/cpp_file.dart';

/// Thin persistence layer over [SharedPreferences].
///
/// Kept isolated behind a small API so a future migration to sqlite or
/// filesystem-based storage only touches this one class.
class FileStorageService {
  static const _filesKey = 'cpp_ide.files';
  static const _recentKey = 'cpp_ide.recent_file_ids';
  static const _lastOpenKey = 'cpp_ide.last_open_file_id';

  Future<List<CppFile>> loadFiles() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_filesKey);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => CppFile.fromJson(e as Map<String, dynamic>))
        .toList(growable: true);
  }

  Future<void> saveFiles(List<CppFile> files) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(files.map((f) => f.toJson()).toList());
    await prefs.setString(_filesKey, raw);
  }

  Future<List<String>> loadRecentIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_recentKey) ?? [];
  }

  Future<void> saveRecentIds(List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_recentKey, ids);
  }

  Future<String?> loadLastOpenFileId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastOpenKey);
  }

  Future<void> saveLastOpenFileId(String? id) async {
    final prefs = await SharedPreferences.getInstance();
    if (id == null) {
      await prefs.remove(_lastOpenKey);
    } else {
      await prefs.setString(_lastOpenKey, id);
    }
  }
}
