import '../models/playlist.dart';
import '../models/workout_block.dart';

/// Difficulty score 0-100
/// Formula: (volumeScore * 0.6) + (densityScore * 0.4)
class DifficultyService {
  static const _maxExpectedReps = 400.0;

  static int compute(Playlist playlist) {
    final blocks = playlist.blocks;
    if (blocks.isEmpty) return 0;

    double totalVolume = 0;
    double totalWork   = 0;
    double totalRest   = 0;

    for (final b in blocks) {
      if (b.isRest) {
        totalRest += b.restDuration ?? 0;
      } else if (b.executionMode == ExecutionMode.timer) {
        final dur = (b.duration ?? 30) * (b.sets ?? 1).toDouble();
        totalWork += dur;
        totalVolume += dur / 5.0;
        totalRest += (b.restBetweenSets ?? 0) * (b.sets ?? 1).toDouble();
      } else {
        final reps = (b.sets ?? 1) * (b.reps ?? 10);
        totalVolume += reps * (1 + (b.weight ?? 0) / 80.0);
        totalWork += reps * 3;
        totalRest += (b.restBetweenSets ?? 60) * ((b.sets ?? 1) - 1).toDouble();
      }
    }

    final volumeScore = (totalVolume / _maxExpectedReps * 100).clamp(0.0, 100.0);
    final totalTime   = totalWork + totalRest;
    final densityScore = totalTime > 0
        ? ((totalWork / totalTime) * 100).clamp(0.0, 100.0)
        : 50.0;

    return ((volumeScore * 0.6) + (densityScore * 0.4)).round().clamp(0, 100);
  }
}
