import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/library_provider.dart';
import '../models/exercise.dart';
import '../services/haptic_service.dart';
import '../theme/app_theme.dart';
import '../widgets/bouncy_button.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});
  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String _query = '';
  MuscleGroup? _selectedMuscle;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LibraryProvider>();
    List<Exercise> exercises = _query.isEmpty
        ? provider.exercises
        : provider.search(_query);
    if (_selectedMuscle != null) {
      exercises = exercises
          .where((e) => e.muscles.any((m) => m == _selectedMuscle))
          .toList();
    }
    // Group by primary muscle
    final grouped = <String, List<Exercise>>{};
    for (final e in exercises) {
      final group = _selectedMuscle != null
          ? _selectedMuscle!.name
          : (e.muscles.isNotEmpty ? e.muscles.first.name : 'Autre');
      grouped.putIfAbsent(group, () => []).add(e);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Exercices')),
      body: Column(children: [
        // Search
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: TextField(
            onChanged: (v) {
              HapticService.light();
              setState(() => _query = v);
            },
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Rechercher un exercice…',
              hintStyle: const TextStyle(color: AppColors.textSecondary),
              prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
              filled: true, fillColor: AppColors.card,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none),
            ),
          ),
        ),
        // Muscle filter chips
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              _FilterChip(label: 'Tous', selected: _selectedMuscle == null,
                  onTap: () => setState(() => _selectedMuscle = null)),
              ...MuscleGroup.values.map((m) => _FilterChip(
                label: m.name,
                selected: _selectedMuscle == m,
                onTap: () {
                  HapticService.selection();
                  setState(() => _selectedMuscle = _selectedMuscle == m ? null : m);
                },
              )),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Grouped list
        Expanded(
          child: grouped.isEmpty
              ? const Center(child: Text('Aucun exercice trouvé',
                  style: TextStyle(color: AppColors.textSecondary)))
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 20),
                  itemCount: grouped.keys.length,
                  itemBuilder: (ctx, gi) {
                    final group = grouped.keys.elementAt(gi);
                    final list = grouped[group]!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                          child: Text(group.toUpperCase(), style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 11,
                              fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                        ),
                        ...list.asMap().entries.map((e) =>
                            _ExerciseTile(exercise: e.value, index: e.key)),
                      ],
                    );
                  }),
        ),
      ]),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label; final bool selected; final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext ctx) => BouncyButton(
    scaleDown: 0.94,
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? AppColors.accent : AppColors.card,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(label, style: TextStyle(
          color: selected ? Colors.black : AppColors.textSecondary,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
          fontSize: 13)),
    ),
  );
}

class _ExerciseTile extends StatelessWidget {
  final Exercise exercise;
  final int index;
  const _ExerciseTile({required this.exercise, required this.index});

  @override
  Widget build(BuildContext context) {
    return BouncyButton(
      onTap: () {
        HapticService.medium();
        _showDetail(context);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.fitness_center,
                color: AppColors.accent, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(exercise.name, style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 4),
            Wrap(spacing: 4, children: exercise.muscles.take(3).map((m) =>
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6)),
                child: Text(m.name, style: const TextStyle(
                    color: AppColors.accent, fontSize: 9,
                    fontWeight: FontWeight.w700)),
              )).toList()),
          ])),
          const Icon(Icons.arrow_forward_ios_rounded,
              color: AppColors.textSecondary, size: 14),
        ]),
      ),
    ).animate()
      .fadeIn(delay: Duration(milliseconds: 20 * index), duration: 200.ms)
      .slideX(begin: 0.03, end: 0, curve: Curves.easeOut);
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: AppColors.cardLight,
                    borderRadius: BorderRadius.circular(4)))),
            const SizedBox(height: 20),
            Text(exercise.name, style: const TextStyle(
                color: AppColors.textPrimary, fontSize: 26,
                fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(exercise.description, style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 14, height: 1.5)),
            const SizedBox(height: 16),
            Wrap(spacing: 6, runSpacing: 6,
              children: exercise.muscles.map((m) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10)),
                child: Text(m.name, style: const TextStyle(
                    color: AppColors.accent, fontWeight: FontWeight.w700)),
              )).toList()),
          ]),
      ),
    );
  }
}
