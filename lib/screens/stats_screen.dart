import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/history_service.dart';
import '../services/pr_service.dart';
import '../providers/library_provider.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final entries = HistoryService.getAll();
    final totalSessions = entries.length;
    final totalMinutes = entries.fold(0, (s, e) => s + (e.durationSeconds ~/ 60));
    // Volume by day (last 7 days)
    final now = DateTime.now();
    final volumeByDay = <int, double>{};
    for (var i = 0; i < 7; i++) volumeByDay[i] = 0;
    for (final entry in entries) {
      final diff = now.difference(entry.startedAt).inDays;
      if (diff < 7) {
        volumeByDay[6 - diff] = (volumeByDay[6 - diff] ?? 0) +
            entry.sets.fold(0.0, (s, r) => s + (r.weight ?? 0) * r.reps);
      }
    }
    final barGroups = volumeByDay.entries.map((e) =>
      BarChartGroupData(x: e.key, barRods: [
        BarChartRodData(
          toY: e.value,
          color: AppColors.accent,
          width: 20,
          borderRadius: BorderRadius.circular(6),
          backDrawRodData: BackgroundBarChartRodData(
            show: true, toY: (volumeByDay.values.isEmpty ? 100
                : volumeByDay.values.reduce((a, b) => a > b ? a : b) * 1.2).toDouble(),
            color: AppColors.cardLight,
          ),
        ),
      ])).toList();

    final days = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    final dayLabels = List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      return days[d.weekday - 1];
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Statistiques')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Summary cards
          Row(children: [
            Expanded(child: _StatCard('Séances', '$totalSessions', Icons.fitness_center_rounded)),
            const SizedBox(width: 12),
            Expanded(child: _StatCard('Minutes', '$totalMinutes', Icons.timer_rounded)),
          ]).animate().fadeIn(duration: 300.ms).slideY(begin: 0.04, end: 0),
          const SizedBox(height: 24),
          // Volume chart
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Volume (kg) — 7 derniers jours',
                    style: TextStyle(color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 20),
                SizedBox(
                  height: 160,
                  child: BarChart(
                    BarChartData(
                      barGroups: barGroups,
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (v, meta) => Text(
                              dayLabels[v.toInt()],
                              style: const TextStyle(
                                  color: AppColors.textSecondary, fontSize: 12)),
                          ),
                        ),
                      ),
                    ),
                    swapAnimationDuration: const Duration(milliseconds: 600),
                    swapAnimationCurve: Curves.easeOutCubic,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
          const SizedBox(height: 24),
          // PRs list
          _PRSection(),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _StatCard(this.label, this.value, this.icon);
  @override
  Widget build(BuildContext ctx) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: AppColors.accent, size: 26),
      const SizedBox(height: 12),
      Text(value, style: const TextStyle(
          color: AppColors.textPrimary, fontSize: 32,
          fontWeight: FontWeight.w900)),
      Text(label, style: const TextStyle(
          color: AppColors.textSecondary, fontSize: 12)),
    ]),
  );
}

class _PRSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final lib = context.read<LibraryProvider>();
    final exercises = lib.exercises;
    final withPR = exercises
        .map((e) => MapEntry(e, PRService.getBest(e.id)))
        .where((e) => e.value != null)
        .toList()
      ..sort((a, b) => b.value!.weight.compareTo(a.value!.weight));

    if (withPR.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: AppColors.card,
            borderRadius: BorderRadius.circular(18)),
        child: const Text('Lance une séance pour voir tes records !',
            style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Records Perso (PR)', style: TextStyle(
            color: AppColors.textPrimary, fontSize: 18,
            fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        ...withPR.asMap().entries.map((entry) {
          final i = entry.key;
          final exo = entry.value.key;
          final pr = entry.value.value!;
          final avg = PRService.getAverageWeight(exo.id);
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(14)),
            child: Row(children: [
              Text('${i + 1}', style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(exo.name, style: const TextStyle(
                      color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                  if (avg != null)
                    Text('Moyenne : ${avg.toStringAsFixed(1)} kg',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 11)),
                ],
              )),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('${pr.weight} kg', style: const TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w800, fontSize: 15)),
                Text('× ${pr.reps} reps', style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 11)),
              ]),
            ]),
          ).animate()
              .fadeIn(delay: Duration(milliseconds: 50 * i), duration: 250.ms)
              .slideX(begin: 0.03, end: 0);
        }),
      ],
    );
  }
}
