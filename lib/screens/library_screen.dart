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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LibraryProvider>();
    final exercises = _query.isEmpty ? provider.exercises : provider.search(_query);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Exercices')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
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
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 20),
            itemCount: exercises.length,
            itemBuilder: (ctx, i) => _ExerciseTile(exercise: exercises[i], index: i),
          ),
        ),
      ]),
    );
  }
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
      .fadeIn(delay: Duration(milliseconds: 25 * index), duration: 220.ms)
      .slideX(begin: 0.04, end: 0, duration: 220.ms, curve: Curves.easeOut);
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
