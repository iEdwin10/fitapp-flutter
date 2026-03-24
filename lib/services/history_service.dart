import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/history_entry.dart';

class HistoryService {
  static const _key = 'workout_history';
  static List<HistoryEntry> _cache = [];

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      _cache = (jsonDecode(raw) as List)
          .map((j) => HistoryEntry.fromJson(j))
          .toList();
    }
  }

  static Future<void> save(HistoryEntry entry) async {
    _cache.insert(0, entry);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key,
        jsonEncode(_cache.map((e) => e.toJson()).toList()));
  }

  static List<HistoryEntry> getAll() => List.unmodifiable(_cache);

  static List<HistoryEntry> getLastN(int n) =>
      _cache.take(n).toList();

  /// Returns a Set of dates (yyyy-MM-dd) where a workout happened
  static Set<String> getWorkoutDates() {
    return _cache
        .map((e) => _fmt(e.startedAt))
        .toSet();
  }

  static String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static int get totalSessions => _cache.length;

  static int get totalMinutes =>
      _cache.fold(0, (sum, e) => sum + (e.durationSeconds ~/ 60));
}
