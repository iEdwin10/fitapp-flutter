import '../models/playlist.dart';
import '../models/workout_block.dart';
import 'difficulty_service.dart';

/// Pokémon Showdown-style import/export
/// Export format:
/// === NAME: Pecs | TYPE: standard ===
/// EXO: bench_press | S:4 | R:10 | P:80 | PAUSE:60
/// TR: 30
/// EXO: planche | TIME: 60
class ParserService {
  static String exportPlaylistToText(Playlist playlist) {
    final buf = StringBuffer();
    buf.writeln('=== NAME: ${playlist.name} | TYPE: ${playlist.type.name} ===');
    for (final block in playlist.blocks) {
      if (block.isRest) {
        buf.writeln('TR: ${block.restDuration}');
      } else if (block.executionMode == ExecutionMode.timer) {
        buf.writeln('EXO: ${block.exerciseId} | TIME: ${block.duration}');
      } else {
        final parts = StringBuffer('EXO: ${block.exerciseId}');
        parts.write(' | S:${block.sets}');
        parts.write(' | R:${block.reps}');
        if (block.weight != null && block.weight! > 0)
          parts.write(' | P:${block.weight}');
        if (block.restBetweenSets != null)
          parts.write(' | PAUSE:${block.restBetweenSets}');
        buf.writeln(parts);
      }
    }
    return buf.toString().trim();
  }

  static Playlist? importTextToPlaylist(String text) {
    try {
      final lines = text.trim().split('\n').map((l) => l.trim()).toList();
      if (lines.isEmpty) return null;

      final header = lines.first;
      final nameMatch = RegExp(r'NAME:\s*([^|]+)').firstMatch(header);
      final typeMatch = RegExp(r'TYPE:\s*(\w+)').firstMatch(header);
      if (nameMatch == null) return null;

      final name = nameMatch.group(1)!.trim();
      final type = typeMatch != null
          ? PlaylistType.values.firstWhere(
              (e) => e.name == typeMatch.group(1)!.trim().toLowerCase(),
              orElse: () => PlaylistType.standard)
          : PlaylistType.standard;

      final blocks = <WorkoutBlock>[];

      for (final line in lines.skip(1)) {
        if (line.isEmpty) continue;
        final uid = '${DateTime.now().millisecondsSinceEpoch}${blocks.length}';

        if (line.startsWith('TR:')) {
          final sec = int.tryParse(line.replaceAll('TR:', '').trim()) ?? 30;
          blocks.add(WorkoutBlock(
            id: uid, type: BlockType.rest, restDuration: sec));
        } else if (line.startsWith('EXO:')) {
          final parts = line.split('|').map((p) => p.trim()).toList();
          final exoId = parts[0].replaceAll('EXO:', '').trim();
          final hasTime = parts.any((p) => p.startsWith('TIME:'));

          if (hasTime) {
            final dur = int.tryParse(
                parts.firstWhere((p) => p.startsWith('TIME:'),
                    orElse: () => 'TIME:30').replaceAll('TIME:', '').trim()) ?? 30;
            blocks.add(WorkoutBlock(
              id: uid, type: BlockType.exercise, exerciseId: exoId,
              executionMode: ExecutionMode.timer, sets: 1, duration: dur));
          } else {
            int? s, r; double? p; int? pause;
            for (final part in parts.skip(1)) {
              if (part.startsWith('S:'))     s = int.tryParse(part.substring(2));
              if (part.startsWith('R:'))     r = int.tryParse(part.substring(2));
              if (part.startsWith('P:'))     p = double.tryParse(part.substring(2));
              if (part.startsWith('PAUSE:')) pause = int.tryParse(part.substring(6));
            }
            blocks.add(WorkoutBlock(
              id: uid, type: BlockType.exercise, exerciseId: exoId,
              executionMode: ExecutionMode.classic,
              sets: s ?? 3, reps: r ?? 10, weight: p,
              restBetweenSets: pause ?? 60));
          }
        }
      }

      final draft = Playlist(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name, type: type, blocks: blocks,
        difficultyScore: 0, createdAt: DateTime.now());

      final score = DifficultyService.compute(draft);
      return Playlist(
        id: draft.id, name: draft.name, type: draft.type,
        blocks: draft.blocks, warmupPlaylistId: draft.warmupPlaylistId,
        difficultyScore: score, createdAt: draft.createdAt);
    } catch (_) {
      return null;
    }
  }
}
