import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'dart:async';
import '../models/playlist.dart';
import '../models/workout_block.dart';
import '../models/history_entry.dart';
import '../providers/library_provider.dart';
import '../providers/playlist_provider.dart';
import '../services/haptic_service.dart';
import '../services/pr_service.dart';
import '../services/history_service.dart';
import '../theme/app_theme.dart';
import '../widgets/bouncy_button.dart';

class WorkoutPlayerScreen extends StatefulWidget {
  final Playlist playlist;
  final bool isWarmup;
  const WorkoutPlayerScreen({
    super.key,
    required this.playlist,
    this.isWarmup = false,
  });
  @override
  State<WorkoutPlayerScreen> createState() => _WorkoutPlayerScreenState();
}

class _WorkoutPlayerScreenState extends State<WorkoutPlayerScreen>
    with TickerProviderStateMixin {
  late List<WorkoutBlock> _queue;
  int _blockIndex = 0;
  int _currentSet = 1;
  int _timerSec = 0;
  bool _timerRunning = false;
  Timer? _timer;
  bool _finished = false;
  bool _swapped = false;
  bool _isNewPR = false;

  // Breathing
  late AnimationController _breathCtrl;
  int _breathPhaseIndex = 0;
  Timer? _breathTimer;
  static const _breathLabels = ['INSPIRE', 'RETIENS', 'EXPIRE', 'RETIENS'];

  // Session tracking
  final DateTime _sessionStart = DateTime.now();
  final List<SetRecord> _sessionSets = [];

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _queue = List.from(widget.playlist.blocks);
    _breathCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _initBlock();
  }

  WorkoutBlock get _block => _queue[_blockIndex];

  void _initBlock() {
    _timer?.cancel();
    _breathTimer?.cancel();
    _breathCtrl.stop();
    _timerRunning = false;
    _swapped = false;
    _isNewPR = false;
    _breathPhaseIndex = 0;
    if (_blockIndex >= _queue.length) { _finish(); return; }
    if (_block.isRest) {
      _timerSec = _block.restDuration ?? 30;
      _startTimer();
      if (_block.breathingPattern != BreathingPattern.off) {
        _startBreathing(_block.breathingPattern);
      }
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

  void _adjustTimer(int delta) {
    HapticService.medium();
    setState(() => _timerSec = (_timerSec + delta).clamp(0, 600));
  }

  void _skipRest() {
    _timer?.cancel();
    _breathTimer?.cancel();
    _breathCtrl.stop();
    HapticService.selection();
    _next();
  }

  void _startBreathing(BreathingPattern pattern) {
    final phases = pattern.phases;
    if (phases.isEmpty) return;

    void runPhase(int index) {
      if (!mounted) return;
      final phase = phases[index % phases.length];
      if (phase == 0) { runPhase(index + 1); return; }
      setState(() => _breathPhaseIndex = index % phases.length);
      _breathCtrl.duration = Duration(seconds: phase);
      _breathCtrl.forward(from: 0);
      _breathTimer = Timer(Duration(seconds: phase), () => runPhase(index + 1));
    }
    runPhase(0);
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

  void _validateSet() async {
    if (!_block.isExercise || _block.executionMode == ExecutionMode.timer) return;
    // Record set
    if (_block.weight != null && _block.weight! > 0) {
      _sessionSets.add(SetRecord(
        exerciseId: _block.exerciseId ?? '',
        reps: _block.reps ?? 0,
        weight: _block.weight!,
        performedAt: DateTime.now(),
      ));
      final newPR = await PRService.record(
          _block.exerciseId ?? '', _block.weight!, _block.reps ?? 0);
      if (newPR && mounted) {
        HapticService.success();
        setState(() => _isNewPR = true);
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) setState(() => _isNewPR = false);
        });
      }
    }
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
      _queue[_blockIndex] = _block.copyWith(exerciseId: alt.id);
    });
  }

  void _next() {
    _timer?.cancel();
    setState(() => _blockIndex++);
    _initBlock();
  }

  void _finish() {
    _breathTimer?.cancel();
    _breathCtrl.stop();
    WakelockPlus.disable();
    HapticService.success();
    final duration = DateTime.now().difference(_sessionStart).inSeconds;
    final exercisesCount = _queue.where((b) => b.isExercise).length;
    HistoryService.save(HistoryEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      playlistId: widget.playlist.id,
      playlistName: widget.playlist.name,
      startedAt: _sessionStart,
      durationSeconds: duration,
      exercisesCompleted: exercisesCount,
      sets: _sessionSets,
    ));
    setState(() => _finished = true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _breathTimer?.cancel();
    _breathCtrl.dispose();
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
    final best = block.isExercise && block.exerciseId != null
        ? PRService.getBest(block.exerciseId!)
        : null;
    final avg = block.isExercise && block.exerciseId != null
        ? PRService.getAverageWeight(block.exerciseId!)
        : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Header
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
              // PR Banner
              if (_isNewPR)
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      AppColors.accent.withOpacity(0.3),
                      AppColors.accent.withOpacity(0.1),
                    ]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('🏆', style: TextStyle(fontSize: 20)),
                      SizedBox(width: 8),
                      Text('NOUVEAU RECORD PERSO !', style: TextStyle(
                          color: AppColors.accent, fontWeight: FontWeight.w900,
                          fontSize: 13, letterSpacing: 1)),
                    ]),
                ).animate().fadeIn(duration: 300.ms).scaleXY(begin: 0.9, end: 1.0,
                    curve: Curves.elasticOut),

              Expanded(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  // REST BLOCK
                  if (block.isRest) ...[
                    if (block.breathingPattern != BreathingPattern.off) ...[
                      AnimatedBuilder(
                        animation: _breathCtrl,
                        builder: (_, __) => Transform.scale(
                          scale: 0.8 + 0.4 * _breathCtrl.value,
                          child: Container(
                            width: 120, height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.accent.withOpacity(0.08 + 0.15 * _breathCtrl.value),
                              border: Border.all(
                                  color: AppColors.accent.withOpacity(0.4 + 0.6 * _breathCtrl.value),
                                  width: 2),
                            ),
                            child: Center(child: Text(
                              _breathLabels[_breathPhaseIndex],
                              style: const TextStyle(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13, letterSpacing: 1.5),
                            )),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ] else
                      const Icon(Icons.timer_outlined, color: AppColors.accent, size: 64)
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .scaleXY(begin: 1.0, end: 1.06, duration: 900.ms),
                    const SizedBox(height: 8),
                    const Text('REPOS', style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 13,
                        letterSpacing: 4, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    // Big timer
                    Text('${_timerSec}s', style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 86,
                        fontWeight: FontWeight.w900, letterSpacing: -4))
                        .animate(key: ValueKey(_timerSec))
                        .fadeIn(duration: 120.ms),
                    const SizedBox(height: 20),
                    // +15/-15 buttons
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      BouncyButton(
                        onTap: () => _adjustTimer(-15),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                              color: AppColors.cardLight,
                              borderRadius: BorderRadius.circular(12)),
                          child: const Text('-15s', style: TextStyle(
                              color: AppColors.textPrimary, fontWeight: FontWeight.w700,
                              fontSize: 15)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      BouncyButton(
                        onTap: () => _adjustTimer(15),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                              color: AppColors.cardLight,
                              borderRadius: BorderRadius.circular(12)),
                          child: const Text('+15s', style: TextStyle(
                              color: AppColors.accent, fontWeight: FontWeight.w700,
                              fontSize: 15)),
                        ),
                      ),
                    ]),
                  ] else ...[
                    // EXERCISE BLOCK
                    if (_swapped)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                            color: AppColors.warning.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8)),
                        child: const Text('Exercice substitué ↔',
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
                    const SizedBox(height: 12),
                    // PR + Avg badges
                    if (best != null || avg != null)
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        if (best != null)
                          _Badge('🏆 ${best.weight}kg × ${best.reps}', AppColors.accent),
                        if (best != null && avg != null)
                          const SizedBox(width: 8),
                        if (avg != null)
                          _Badge('∅ ${avg!.toStringAsFixed(1)}kg', AppColors.textSecondary),
                      ]),
                    const SizedBox(height: 28),
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
                      const SizedBox(height: 16),
                      // Set dots
                      Row(mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(block.sets ?? 1, (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: i == _currentSet - 1 ? 32 : 24,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i < _currentSet - 1 ? AppColors.accent
                                : i == _currentSet - 1
                                    ? AppColors.accent.withOpacity(0.5)
                                    : AppColors.cardLight,
                            borderRadius: BorderRadius.circular(4)),
                        ))),
                      if (_timerRunning) ...[
                        const SizedBox(height: 20),
                        Text('Repos: ${_timerSec}s', style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 22,
                            fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          BouncyButton(
                            onTap: () => _adjustTimer(-15),
                            child: _SmallAdjust('-15s'),
                          ),
                          const SizedBox(width: 12),
                          BouncyButton(
                            onTap: () => _adjustTimer(15),
                            child: _SmallAdjust('+15s', accent: true),
                          ),
                        ]),
                      ],
                    ],
                  ],
                ]),
              ),
              // Bottom actions
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
                          'Série $_currentSet / ${block.sets} — Valider ✓',
                          style: const TextStyle(color: Colors.black,
                              fontWeight: FontWeight.w800, fontSize: 16))),
                    ),
                  ),
                const SizedBox(height: 10),
                if (block.isRest)
                  BouncyButton(
                    scaleDown: 0.95,
                    onTap: _skipRest,
                    child: Container(
                      width: double.infinity, height: 46,
                      decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(14)),
                      child: const Row(mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.skip_next_rounded, color: Colors.black, size: 22),
                          SizedBox(width: 6),
                          Text('Passer le repos', style: TextStyle(
                              color: Colors.black, fontWeight: FontWeight.w800)),
                        ]),
                    ),
                  ),
                if (block.isExercise) ...[
                  const SizedBox(height: 8),
                  BouncyButton(
                    onTap: _machineBusy,
                    child: Container(
                      width: double.infinity, height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.cardLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.warning.withOpacity(0.35))),
                      child: const Row(mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.swap_horiz_rounded, color: AppColors.warning, size: 20),
                          SizedBox(width: 8),
                          Text('Machine Occupée', style: TextStyle(
                              color: AppColors.warning, fontWeight: FontWeight.w700)),
                        ]),
                    ),
                  ),
                ],
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

class _Badge extends StatelessWidget {
  final String text; final Color color;
  const _Badge(this.text, this.color);
  @override
  Widget build(BuildContext ctx) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8)),
    child: Text(text, style: TextStyle(
        color: color, fontSize: 12, fontWeight: FontWeight.w700)));
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

class _SmallAdjust extends StatelessWidget {
  final String label; final bool accent;
  const _SmallAdjust(this.label, {this.accent = false});
  @override
  Widget build(BuildContext ctx) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(10)),
    child: Text(label, style: TextStyle(
        color: accent ? AppColors.accent : AppColors.textPrimary,
        fontWeight: FontWeight.w700)));
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

/// Shows warmup proposal dialog, returns true = do warmup, false = skip warmup, null = cancelled
Future<bool?> showWarmupProposal(BuildContext context, String warmupName) =>
    showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: const [
          Text('🔥', style: TextStyle(fontSize: 28)),
          SizedBox(width: 10),
          Expanded(child: Text('Échauffement disponible',
              style: TextStyle(color: AppColors.textPrimary,
                  fontSize: 16, fontWeight: FontWeight.w800))),
        ]),
        content: Text('Veux-tu d\'abord faire "$warmupName" avant ta séance ?',
            style: const TextStyle(color: AppColors.textSecondary)),
        actionsAlignment: MainAxisAlignment.end,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Refuser', style: TextStyle(color: AppColors.error)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Passer', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Oui, échauffer !',
                style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
