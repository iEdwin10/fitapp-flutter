import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/history_service.dart';
import '../models/history_entry.dart';
import '../theme/app_theme.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final entries = HistoryService.getAll();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Historique')),
      body: entries.isEmpty
          ? const Center(child: Text('Aucune séance enregistrée',
              style: TextStyle(color: AppColors.textSecondary)))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _HeatmapWidget(),
                const SizedBox(height: 24),
                ...entries.asMap().entries.map((e) =>
                    _HistoryTile(entry: e.value, index: e.key)),
              ],
            ),
    );
  }
}

class _HeatmapWidget extends StatelessWidget {
  final workoutDates = HistoryService.getWorkoutDates();

  _HeatmapWidget();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // Show last 10 weeks (70 days)
    final start = now.subtract(const Duration(days: 69));
    final days = List.generate(70, (i) => start.add(Duration(days: i)));
    final weeks = <List<DateTime>>[];
    for (var i = 0; i < days.length; i += 7) {
      weeks.add(days.sublist(i, (i + 7).clamp(0, days.length)));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Régularité', style: TextStyle(
            color: AppColors.textPrimary, fontSize: 18,
            fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('${workoutDates.length} séances ces 70 derniers jours',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: weeks.map((week) => Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Column(
                children: week.map((day) {
                  final key = '${day.year}-${day.month.toString().padLeft(2,'0')}-${day.day.toString().padLeft(2,'0')}';
                  final done = workoutDates.contains(key);
                  final isToday = day.day == now.day && day.month == now.month;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: done
                          ? AppColors.accent
                          : AppColors.cardLight,
                      borderRadius: BorderRadius.circular(6),
                      border: isToday
                          ? Border.all(color: AppColors.accent, width: 2)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final HistoryEntry entry;
  final int index;
  const _HistoryTile({required this.entry, required this.index});

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return m > 0 ? '${m}min ${s}s' : '${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final date = entry.startedAt;
    final dateStr = '${date.day.toString().padLeft(2,'0')}/${date.month.toString().padLeft(2,'0')}/${date.year} — ${date.hour.toString().padLeft(2,'0')}h${date.minute.toString().padLeft(2,'0')}';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18)),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.fitness_center, color: AppColors.accent, size: 22)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(entry.playlistName, style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 4),
          Text(dateStr, style: const TextStyle(
              color: AppColors.textSecondary, fontSize: 12)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(_formatDuration(entry.durationSeconds), style: const TextStyle(
              color: AppColors.accent, fontWeight: FontWeight.w700, fontSize: 13)),
          Text('${entry.exercisesCompleted} exos', style: const TextStyle(
              color: AppColors.textSecondary, fontSize: 11)),
        ]),
      ]),
    ).animate()
        .fadeIn(delay: Duration(milliseconds: 40 * index), duration: 250.ms)
        .slideX(begin: 0.04, end: 0);
  }
}
