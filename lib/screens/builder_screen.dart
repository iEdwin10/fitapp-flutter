import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/playlist.dart';
import '../models/workout_block.dart';
import '../models/exercise.dart';
import '../providers/playlist_provider.dart';
import '../providers/library_provider.dart';
import '../services/haptic_service.dart';
import '../services/difficulty_service.dart';
import '../services/freemium_service.dart';
import '../theme/app_theme.dart';
import '../widgets/bouncy_button.dart';

class BuilderScreen extends StatefulWidget {
  final Playlist? existing;
  final bool isMini;
  const BuilderScreen({super.key, this.existing, this.isMini = false});
  @override
  State<BuilderScreen> createState() => _BuilderScreenState();
}

class _BuilderScreenState extends State<BuilderScreen> {
  late String _name;
  late List<WorkoutBlock> _blocks;
  late PlaylistType _type;

  @override
  void initState() {
    super.initState();
    _name = widget.existing?.name ?? (widget.isMini ? 'Échauffement' : 'Nouvelle Playlist');
    _blocks = List.from(widget.existing?.blocks ?? []);
    _type = widget.isMini ? PlaylistType.mini : (widget.existing?.type ?? PlaylistType.standard);
  }

  int get _exoCount => _blocks.where((b) => b.isExercise).length;

  int get _score {
    final tmp = Playlist(id: 'tmp', name: _name, type: _type,
        blocks: _blocks, difficultyScore: 0, createdAt: DateTime.now());
    return DifficultyService.compute(tmp);
  }

  Color get _scoreColor {
    final s = _score;
    if (s <= 40) return AppColors.easy;
    if (s <= 65) return AppColors.medium;
    if (s <= 80) return AppColors.hard;
    return AppColors.extreme;
  }

  void _addExercise() async {
    if (!FreemiumService.canAddExercise(_exoCount)) {
      HapticService.error();
      _showWall();
      return;
    }
    final lib = context.read<LibraryProvider>();
    final exercise = await showModalBottomSheet<Exercise>(
      context: context, isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => _ExercisePicker(library: lib),
    );
    if (exercise == null || !mounted) return;
    final block = await showModalBottomSheet<WorkoutBlock>(
      context: context, isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => _BlockConfigurator(exercise: exercise),
    );
    if (block == null) return;
    HapticService.heavy();
    setState(() => _blocks.add(block));
  }

  void _addRest() {
    if (_blocks.isEmpty) { HapticService.error(); return; }
    HapticService.medium();
    setState(() => _blocks.add(WorkoutBlock(
      id: UniqueKey().toString(), type: BlockType.rest, restDuration: 60)));
  }

  void _save() {
    if (_blocks.isEmpty) { HapticService.error(); return; }
    final provider = context.read<PlaylistProvider>();
    final playlist = Playlist(
      id: widget.existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _name, type: _type, blocks: _blocks,
      difficultyScore: 0, createdAt: widget.existing?.createdAt ?? DateTime.now());
    if (widget.existing != null) {
      provider.updatePlaylist(playlist);
    } else {
      provider.addPlaylist(playlist);
    }
    HapticService.success();
    Navigator.pop(context);
  }

  void _showWall() {
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: AppColors.card,
      title: const Text('Limite atteinte',
          style: TextStyle(color: AppColors.textPrimary)),
      content: Text('Max ${FreemiumService.maxExercisesPerPlaylist} exercices en version Free.',
          style: const TextStyle(color: AppColors.textSecondary)),
      actions: [TextButton(onPressed: () => Navigator.pop(context),
          child: const Text('OK', style: TextStyle(color: AppColors.accent)))],
    ));
  }

  void _editName() async {
    final ctrl = TextEditingController(text: _name);
    final result = await showDialog<String>(context: context, builder: (_) =>
      AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Renommer',
            style: TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: ctrl, autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.accent)),
            focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.accent))),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context, ctrl.text),
            child: const Text('OK', style: TextStyle(color: AppColors.accent)))],
      ));
    if (result != null && result.isNotEmpty) setState(() => _name = result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: BouncyButton(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.close, color: AppColors.textPrimary),
        ),
        title: GestureDetector(
          onTap: _editName,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(_name, style: const TextStyle(color: AppColors.textPrimary)),
            const SizedBox(width: 6),
            const Icon(Icons.edit_rounded, size: 13, color: AppColors.textSecondary),
          ]),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: _scoreColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10)),
            child: Text('${_score}/100', style: TextStyle(
                color: _scoreColor,
                fontWeight: FontWeight.w700, fontSize: 12)),
          ),
          BouncyButton(
            scaleDown: 0.93,
            onTap: _save,
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(10)),
              child: const Text('Sauver', style: TextStyle(
                  color: Colors.black, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _blocks.isEmpty
                ? Center(child: const Text('Ajoute des exercices \u2193',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 16))
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .fadeIn(duration: 900.ms))
                : ReorderableListView.builder(
                    padding: const EdgeInsets.all(14),
                    onReorder: (old, neo) {
                      HapticService.heavy();
                      setState(() {
                        final item = _blocks.removeAt(old);
                        _blocks.insert(neo > old ? neo - 1 : neo, item);
                      });
                    },
                    itemCount: _blocks.length,
                    itemBuilder: (ctx, i) {
                      final b = _blocks[i];
                      final lib = ctx.read<LibraryProvider>();
                      return _BlockTile(
                        key: ValueKey(b.id),
                        block: b, index: i,
                        exerciseName: b.isExercise
                            ? lib.findById(b.exerciseId ?? '')?.name ?? b.exerciseId ?? '?'
                            : null,
                        onDelete: () {
                          HapticService.heavy();
                          setState(() => _blocks.removeAt(i));
                        },
                      );
                    }),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
            color: AppColors.card,
            child: Row(children: [
              Expanded(
                child: BouncyButton(
                  scaleDown: 0.95,
                  onTap: _addExercise,
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(14)),
                    child: const Row(mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, color: Colors.black),
                          SizedBox(width: 6),
                          Text('Exercice', style: TextStyle(
                              color: Colors.black, fontWeight: FontWeight.w700)),
                        ]),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              BouncyButton(
                onTap: _addRest,
                child: Container(
                  height: 50, width: 70,
                  decoration: BoxDecoration(
                      color: AppColors.cardLight,
                      borderRadius: BorderRadius.circular(14)),
                  child: const Center(child: Text('TR',
                      style: TextStyle(color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700, fontSize: 16))),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

class _BlockTile extends StatelessWidget {
  final WorkoutBlock block;
  final int index;
  final String? exerciseName;
  final VoidCallback onDelete;
  const _BlockTile({super.key, required this.block, required this.index,
      this.exerciseName, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    if (block.isRest) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
            color: AppColors.cardLight,
            borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          const Icon(Icons.timer_outlined, color: AppColors.textSecondary, size: 18),
          const SizedBox(width: 10),
          Text('Repos — ${block.restDuration}s',
              style: const TextStyle(color: AppColors.textSecondary)),
          const Spacer(),
          GestureDetector(onTap: onDelete,
              child: const Icon(Icons.close, color: AppColors.textSecondary, size: 18)),
          const SizedBox(width: 8),
          const Icon(Icons.drag_handle_rounded, color: AppColors.textSecondary, size: 20),
        ]),
      );
    }
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: AppColors.card, borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10)),
          child: Center(child: Text('${index + 1}', style: const TextStyle(
              color: AppColors.accent, fontWeight: FontWeight.w800)))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(exerciseName ?? '?', style: const TextStyle(
              color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(
            block.executionMode == ExecutionMode.timer
                ? '${block.duration}s · timer'
                : '${block.sets} × ${block.reps} reps'
                  '${block.weight != null && block.weight! > 0 ? " · ${block.weight}kg" : ""}'
                  ' · repos ${block.restBetweenSets}s',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ])),
        GestureDetector(onTap: onDelete,
            child: const Icon(Icons.close, color: AppColors.textSecondary, size: 18)),
        const SizedBox(width: 8),
        const Icon(Icons.drag_handle_rounded,
            color: AppColors.textSecondary, size: 20),
      ]),
    );
  }
}

class _ExercisePicker extends StatefulWidget {
  final LibraryProvider library;
  const _ExercisePicker({required this.library});
  @override
  State<_ExercisePicker> createState() => _ExercisePickerState();
}

class _ExercisePickerState extends State<_ExercisePicker> {
  String _q = '';
  @override
  Widget build(BuildContext context) {
    final list = _q.isEmpty ? widget.library.exercises : widget.library.search(_q);
    return DraggableScrollableSheet(
      initialChildSize: 0.85, minChildSize: 0.5, maxChildSize: 0.95,
      expand: false,
      builder: (_, ctrl) => Column(children: [
        const SizedBox(height: 12),
        Container(width: 40, height: 4,
            decoration: BoxDecoration(color: AppColors.cardLight,
                borderRadius: BorderRadius.circular(4))),
        Padding(
          padding: const EdgeInsets.all(14),
          child: TextField(
            autofocus: true,
            onChanged: (v) => setState(() => _q = v),
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Rechercher…',
              hintStyle: const TextStyle(color: AppColors.textSecondary),
              prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
              filled: true, fillColor: AppColors.cardLight,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none)),
          ),
        ),
        Expanded(child: ListView.builder(
          controller: ctrl,
          itemCount: list.length,
          itemBuilder: (_, i) {
            final e = list[i];
            return ListTile(
              title: Text(e.name, style: const TextStyle(color: AppColors.textPrimary)),
              subtitle: Text(e.muscles.map((m) => m.name).join(', '),
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
              leading: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.fitness_center, color: AppColors.accent, size: 18)),
              onTap: () {
                HapticService.medium();
                Navigator.pop(context, e);
              },
            );
          },
        )),
      ]),
    );
  }
}

class _BlockConfigurator extends StatefulWidget {
  final Exercise exercise;
  const _BlockConfigurator({required this.exercise});
  @override
  State<_BlockConfigurator> createState() => _BlockConfiguratorState();
}

class _BlockConfiguratorState extends State<_BlockConfigurator> {
  ExecutionMode _mode = ExecutionMode.classic;
  int _sets = 3, _reps = 10, _rest = 60, _duration = 30;
  double _weight = 0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24,
          MediaQuery.of(context).viewInsets.bottom + 36),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: AppColors.cardLight,
                    borderRadius: BorderRadius.circular(4)))),
            const SizedBox(height: 16),
            Text(widget.exercise.name, style: const TextStyle(
                color: AppColors.textPrimary, fontSize: 22,
                fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            Row(children: [
              _modeBtn('Classique', ExecutionMode.classic),
              const SizedBox(width: 10),
              _modeBtn('Timer', ExecutionMode.timer),
            ]),
            const SizedBox(height: 20),
            if (_mode == ExecutionMode.classic) ...[
              _stepper('Séries', _sets, (v) => setState(() => _sets = v)),
              _stepper('Répétitions', _reps, (v) => setState(() => _reps = v)),
              _stepper('Repos (s)', _rest, (v) => setState(() => _rest = v), step: 15, max: 300),
              _weightStepper(),
            ] else
              _stepper('Durée (s)', _duration,
                  (v) => setState(() => _duration = v), step: 5, max: 600),
            const SizedBox(height: 24),
            BouncyButton(
              scaleDown: 0.95,
              onTap: () {
                final block = WorkoutBlock(
                  id: UniqueKey().toString(),
                  type: BlockType.exercise,
                  exerciseId: widget.exercise.id,
                  executionMode: _mode,
                  sets: _sets, reps: _reps,
                  weight: _weight > 0 ? _weight : null,
                  restBetweenSets: _rest, duration: _duration);
                Navigator.pop(context, block);
              },
              child: Container(
                width: double.infinity, height: 52,
                decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(14)),
                child: const Center(child: Text('Ajouter à la playlist',
                    style: TextStyle(color: Colors.black,
                        fontWeight: FontWeight.w800, fontSize: 16))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _modeBtn(String label, ExecutionMode mode) => Expanded(
    child: BouncyButton(
      onTap: () {
        HapticService.selection();
        setState(() => _mode = mode);
      },
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: _mode == mode ? AppColors.accent : AppColors.cardLight,
          borderRadius: BorderRadius.circular(12)),
        child: Center(child: Text(label, style: TextStyle(
            color: _mode == mode ? Colors.black : AppColors.textSecondary,
            fontWeight: FontWeight.w700))),
      ),
    ),
  );

  Widget _stepper(String label, int value, ValueChanged<int> onChange,
      {int step = 1, int max = 99}) =>
    Padding(padding: const EdgeInsets.only(bottom: 14),
      child: Row(children: [
        Expanded(child: Text(label, style: const TextStyle(
            color: AppColors.textSecondary, fontSize: 14))),
        BouncyButton(onTap: () { if (value > step) onChange(value - step); HapticService.light(); },
          child: Container(width: 36, height: 36,
              decoration: BoxDecoration(color: AppColors.cardLight,
                  borderRadius: BorderRadius.circular(10)),
              child: const Center(child: Icon(Icons.remove,
                  color: AppColors.textPrimary, size: 16)))),
        SizedBox(width: 50, child: Center(child: Text('$value',
            style: const TextStyle(color: AppColors.textPrimary,
                fontSize: 17, fontWeight: FontWeight.w700)))),
        BouncyButton(onTap: () { if (value < max) onChange(value + step); HapticService.light(); },
          child: Container(width: 36, height: 36,
              decoration: BoxDecoration(color: AppColors.cardLight,
                  borderRadius: BorderRadius.circular(10)),
              child: const Center(child: Icon(Icons.add,
                  color: AppColors.accent, size: 16)))),
      ]));

  Widget _weightStepper() =>
    Padding(padding: const EdgeInsets.only(bottom: 14),
      child: Row(children: [
        const Expanded(child: Text('Poids (kg)', style: TextStyle(
            color: AppColors.textSecondary, fontSize: 14))),
        BouncyButton(onTap: () { if (_weight >= 2.5) setState(() => _weight -= 2.5); HapticService.light(); },
          child: Container(width: 36, height: 36,
              decoration: BoxDecoration(color: AppColors.cardLight,
                  borderRadius: BorderRadius.circular(10)),
              child: const Center(child: Icon(Icons.remove,
                  color: AppColors.textPrimary, size: 16)))),
        SizedBox(width: 60, child: Center(child: Text(
            _weight > 0 ? '${_weight}kg' : 'PC',
            style: const TextStyle(color: AppColors.textPrimary,
                fontSize: 15, fontWeight: FontWeight.w700)))),
        BouncyButton(onTap: () { setState(() => _weight += 2.5); HapticService.light(); },
          child: Container(width: 36, height: 36,
              decoration: BoxDecoration(color: AppColors.cardLight,
                  borderRadius: BorderRadius.circular(10)),
              child: const Center(child: Icon(Icons.add,
                  color: AppColors.accent, size: 16)))),
      ]));
}
