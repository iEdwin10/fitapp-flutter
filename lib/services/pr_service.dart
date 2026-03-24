import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class PREntry {
  final double weight;
  final int reps;
  final DateTime date;
  PREntry({required this.weight, required this.reps, required this.date});

  Map<String, dynamic> toJson() => {
    'weight': weight, 'reps': reps, 'date': date.toIso8601String(),
  };
  factory PREntry.fromJson(Map<String, dynamic> j) => PREntry(
    weight: (j['weight'] as num).toDouble(),
    reps: j['reps'],
    date: DateTime.parse(j['date']),
  );
}

class PRService {
  static const _key = 'pr_records';
  static Map<String, List<PREntry>> _cache = {};

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      _cache = map.map((k, v) => MapEntry(
        k,
        (v as List).map((e) => PREntry.fromJson(e)).toList(),
      ));
    }
  }

  static Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(
      _cache.map((k, v) => MapEntry(k, v.map((e) => e.toJson()).toList())),
    ));
  }

  /// Returns true if this is a new PR
  static Future<bool> record(String exerciseId, double weight, int reps) async {
    final entries = _cache[exerciseId] ?? [];
    final isNewPR = entries.isEmpty ||
        weight > entries.map((e) => e.weight).reduce((a, b) => a > b ? a : b);
    entries.add(PREntry(weight: weight, reps: reps, date: DateTime.now()));
    _cache[exerciseId] = entries;
    await _save();
    return isNewPR;
  }

  static PREntry? getBest(String exerciseId) {
    final entries = _cache[exerciseId] ?? [];
    if (entries.isEmpty) return null;
    return entries.reduce((a, b) => a.weight >= b.weight ? a : b);
  }

  static double? getAverageWeight(String exerciseId) {
    final entries = _cache[exerciseId] ?? [];
    if (entries.isEmpty) return null;
    final withWeight = entries.where((e) => e.weight > 0).toList();
    if (withWeight.isEmpty) return null;
    return withWeight.map((e) => e.weight).reduce((a, b) => a + b) / withWeight.length;
  }

  static List<PREntry> getHistory(String exerciseId) =>
      List.unmodifiable(_cache[exerciseId] ?? []);
}
