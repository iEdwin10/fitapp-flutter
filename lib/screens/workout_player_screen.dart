import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'dart:async';
import '../models/playlist.dart';
import '../models/workout_block.dart';
import '../providers/library_provider.dart';
import '../services/haptic_service.dart';
import '../theme/app_theme.dart';
import '../widgets/bouncy_button.dart';

class WorkoutPlayerScreen extends StatefulWidget {
  final Playlist playlist;
  const WorkoutPlayerScreen({super.key, required this.playlist});
  @override
  State<WorkoutPlayerScreen> createState() => _WorkoutPlayerScreenState();
}

class _WorkoutPlayerScreenState extends State<WorkoutPlayerScreen>
    with SingleTickerProviderStateMixin {
  late List<WorkoutBlock> _queue;
  int _blockIndex = 0;
  int _currentSet = 1;
  int _timerSec = 0;
  bool _timerRunning = false;
  Timer? _timer;
  bool _finished = false;
  bool _swapped = false;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _queue = List.from(widget.playlist.blocks);
    _initBlock();
  }

  WorkoutBlock get _block => _queue[_blockIndex];

  void _initBlock() {
    _timer?.cancel();
    _timerRunning = false;
    _swapped = false;
    if (_blockIndex >= _queue.length) { _finish(); return; }
    if (_block.isRest) {
      _timerSec = _block.restDuration ?? 30;
      _startTimer();
    } else if (_block.executionMode == ExecutionMode.timer) {
      _timerSec = _block.duration ?? 30;
      _currentSet = 1;
      _startTimer();
    } else {
      _currentSet = 1;
    }
    if (mounted) setState(() {});
  }

  void _startTimer() {
    _timerRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_timerSec <= 3 && _timerSec > 0) HapticService.light();
      if (_timerSec <= 0) {
        _timer?.cancel();
        HapticService.timerEnd();
        _onTimerEnd();
      } else {
        setState(() => _timerSec--);
      }
    });
  }

  void _onTimerEnd() {
    if (_block.isRest) {
      _next();
    } else {
      if (_currentSet < (_block.sets ?? 1)) {
        setState(() {
          _currentSet++;
          _timerSec = _block.duration ?? 30;
          _timerRunning = false;
        });
        _startTimer();
      } else {
        _next();
      }
    }
  }

  void _validateSet() {
    if (!_block.isExercise || _block.executionMode == ExecutionMode.timer) return;
    HapticService.seriesValidated();
    if (_currentSet >= (_block.sets ?? 1)) {
      _next();
    } else {
      setState(() {
        _currentSet++;
        _timerSec = _block.restBetweenSets ?? 60;
      });
      _startTimer();
    }
  }

  void _machineBusy() {
    if (!_block.isExercise) return;
    final lib = context.read<LibraryProvider>();
    final original = lib.findById(_block.exerciseId ?? '');
    if (original == null) return;
    final alt = lib.findById(original.alternativeId);
    if (alt == null) return;
    HapticService.swap();
    setState(() {
      _swapped = true;
      _queue[_blockIndex] = WorkoutBlock(
        id: _block.id, type: _block.type, exerciseId: alt.id,
        executionMode: _block.executionMode,
        sets: _block.sets, reps: _block.reps,
        weight: _block.weight, restBetweenSets: _block.restBetweenSets,
        duration: _block.duration);
    });
  }

  void _next() {
    _timer?.cancel();
    setState(() => _blockIndex++);
    _initBlock();
  }

  void _finish() {
    WakelockPlus.disable();
    HapticService.success();
    setState(() => _finished = true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_finished || _blockIndex >= _queue.length) {
      return _FinishedScreen(onClose: () => Navigator.pop(context));
    }
    final block = _block;
    final lib = context.read<LibraryProvider>();
    final exercise = block.isExercise && block.exerciseId != null
        ? lib.findById(block.exerciseId!)
        : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(children: [
                BouncyButton(
                  onTap: () { _timer?.cancel(); WakelockPlus.disable(); Navigator.pop(context); },
                  child: const Icon(Icons.close, color: AppColors.textSecondary)),
                const Spacer(),
                Text(widget.playlist.name,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                const Spacer(),
                Text('${_blockIndex + 1}/${_queue.length}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ]),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_blockIndex + 1) / _queue.length,
                  backgroundColor: AppColors.cardLight,
                  color: AppColors.accent, minHeight: 4),
              ),
              Expanded(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  if (block.isRest) ...[
                    const Icon(Icons.timer_outlined, color: AppColors.accent, size: 72)
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scaleXY(begin: 1.0, end: 1.06, duration: 900.ms,
                            curve: Curves.easeInOut),
                    const SizedBox(height: 16),
                    const Text('REPOS', style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 13,
                        letterSpacing: 4, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    Text('${_timerSec}s', style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 90,
                        fontWeight: FontWeight.w900, letterSpacing: -4)),
                  ] else ...[
                    if (_swapped)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                            color: AppColors.warning.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8)),
                        child: const Text('Exercice substitué \u2194',
                            style: TextStyle(color: AppColors.warning, fontSize: 11)),
                      ),
                    Text(exercise?.name ?? block.exerciseId ?? '?',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: AppColors.textPrimary, fontSize: 34,
                          fontWeight: FontWeight.w900, letterSpacing: -1))
                        .animate().fadeIn(duration: 280.ms)
                        .slideY(begin: 0.04, end: 0),
                    const SizedBox(height: 6),
                    if (exercise?.muscles != null)
                      Text(exercise!.muscles.take(2).map((m) => m.name).join(' · '),
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    const SizedBox(height: 40),
                    if (block.executionMode == ExecutionMode.timer) ...[
                      Text('${_timerSec}s', style: const TextStyle(
                          color: AppColors.accent, fontSize: 86,
                          fontWeight: FontWeight.w900, letterSpacing: -4)),
                      Text('Série $_currentSet / ${block.sets}',
                          style: const TextStyle(color: AppColors.textSecondary)),
                    ] else ...[
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        _BigNum('${block.sets}', 'séries'),
                        const SizedBox(width: 32),
                        _BigNum('${block.reps}', 'reps'),
                        if (block.weight != null && block.weight! > 0) ...[
                          const SizedBox(width: 32),
                          _BigNum('${block.weight}', 'kg'),
                        ],
                      ]),
                      const SizedBox(height: 20),
                      Row(mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(block.sets ?? 1, (i) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 28, height: 8,
                          decoration: BoxDecoration(
                            color: i < _currentSet - 1 ? AppColors.accent
                                : i == _currentSet - 1
                                    ? AppColors.accent.withOpacity(0.45)
                                    : AppColors.cardLight,
                            borderRadius: BorderRadius.circular(4)),
                        ))),
                      if (_timerRunning) ...[
                        const SizedBox(height: 24),
                        Text('Repos: ${_timerSec}s', style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 22,
                            fontWeight: FontWeight.w700)),
                      ],
                    ],
                  ],
                ]),
              ),
              Column(children: [
                if (block.isExercise &&
                    block.executionMode == ExecutionMode.classic &&
                    !_timerRunning)
                  BouncyButton(
                    scaleDown: 0.94,
                    onTap: _validateSet,
                    child: Container(
                      width: double.infinity, height: 58,
                      decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(18)),
                      child: Center(child: Text(
                          'Série $_currentSet / ${block.sets} \u2014 Valider ✓',
                          style: const TextStyle(color: Colors.black,
                              fontWeight: FontWeight.w800, fontSize: 16))),
                    ),
                  ),
                const SizedBox(height: 10),
                if (block.isExercise)
                  BouncyButton(
                    onTap: _machineBusy,
                    child: Container(
                      width: double.infinity, height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.cardLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: AppColors.warning.withOpacity(0.35))),
                      child: const Row(mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.swap_horiz_rounded,
                              color: AppColors.warning, size: 20),
                          SizedBox(width: 8),
                          Text('Machine Occupée', style: TextStyle(
                              color: AppColors.warning, fontWeight: FontWeight.w700)),
                        ]),
                    ),
                  ),
                const SizedBox(height: 8),
                BouncyButton(
                  onTap: _next,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('Passer →', style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 13)),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

class _BigNum extends StatelessWidget {
  final String value, label;
  const _BigNum(this.value, this.label);
  @override
  Widget build(BuildContext ctx) => Column(children: [
    Text(value, style: const TextStyle(
        color: AppColors.textPrimary, fontSize: 56,
        fontWeight: FontWeight.w900, letterSpacing: -2)),
    Text(label, style: const TextStyle(
        color: AppColors.textSecondary, fontSize: 13)),
  ]);
}

class _FinishedScreen extends StatelessWidget {
  final VoidCallback onClose;
  const _FinishedScreen({required this.onClose});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('🏋️‍♂️', style: TextStyle(fontSize: 72))
          .animate()
          .scaleXY(begin: 0.4, end: 1.0, duration: 700.ms, curve: Curves.elasticOut),
      const SizedBox(height: 20),
      const Text('Séance terminée !', style: TextStyle(
          color: AppColors.textPrimary, fontSize: 28,
          fontWeight: FontWeight.w900))
          .animate().fadeIn(delay: 300.ms),
      const SizedBox(height: 8),
      const Text('Excellent travail 💪', style: TextStyle(
          color: AppColors.textSecondary, fontSize: 16))
          .animate().fadeIn(delay: 400.ms),
      const SizedBox(height: 40),
      BouncyButton(
        scaleDown: 0.93,
        onTap: onClose,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 16),
          decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(16)),
          child: const Text('Fermer', style: TextStyle(
              color: Colors.black, fontWeight: FontWeight.w800, fontSize: 16)),
        ),
      ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.06, end: 0),
    ])),
  );
}
