import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/run_log_entry.dart';

class RunHistoryController extends StateNotifier<List<RunLogEntry>> {
  RunHistoryController() : super(const []) {
    _load();
  }

  static const _key = 'run_history_entries';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key);
    if (raw == null) return;
    state = raw
        .map((e) => RunLogEntry.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList();
  }

  Future<void> addEntry(RunLogEntry entry) async {
    final updated = [entry, ...state];
    state = updated;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key,
      updated.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }
}

final runHistoryProvider =
    StateNotifierProvider<RunHistoryController, List<RunLogEntry>>((ref) {
      return RunHistoryController();
    });
