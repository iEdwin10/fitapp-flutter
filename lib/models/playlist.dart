import 'package:flutter/material.dart';
import 'workout_block.dart';
import '../theme/app_theme.dart';

enum PlaylistType { standard, mini }

class Playlist {
  final String id;
  final String name;
  final PlaylistType type;
  final List<WorkoutBlock> blocks;
  final String? warmupPlaylistId;
  final int difficultyScore;
  final DateTime createdAt;

  const Playlist({
    required this.id,
    required this.name,
    required this.type,
    required this.blocks,
    this.warmupPlaylistId,
    required this.difficultyScore,
    required this.createdAt,
  });

  Color get difficultyColor {
    if (difficultyScore <= 40) return AppColors.easy;
    if (difficultyScore <= 65) return AppColors.medium;
    if (difficultyScore <= 80) return AppColors.hard;
    return AppColors.extreme;
  }

  String get difficultyLabel {
    if (difficultyScore <= 40) return 'Facile';
    if (difficultyScore <= 65) return 'Intense';
    if (difficultyScore <= 80) return 'Difficile';
    return 'Extreme';
  }

  int get exerciseCount => blocks.where((b) => b.isExercise).length;

  int get estimatedDuration {
    int total = 0;
    for (final b in blocks) {
      if (b.isRest) {
        total += b.restDuration ?? 0;
      } else if (b.executionMode == ExecutionMode.timer) {
        total += (b.duration ?? 0) * (b.sets ?? 1);
      } else {
        final setTime = (b.reps ?? 0) * 3;
        total += (setTime + (b.restBetweenSets ?? 60)) * (b.sets ?? 1);
      }
    }
    return (total / 60).ceil();
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'type': type.name,
    'blocks': blocks.map((b) => b.toJson()).toList(),
    'warmupPlaylistId': warmupPlaylistId,
    'difficultyScore': difficultyScore,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Playlist.fromJson(Map<String, dynamic> j) => Playlist(
    id: j['id'], name: j['name'],
    type: PlaylistType.values.firstWhere((e) => e.name == j['type']),
    blocks: (j['blocks'] as List).map((b) => WorkoutBlock.fromJson(b)).toList(),
    warmupPlaylistId: j['warmupPlaylistId'],
    difficultyScore: j['difficultyScore'],
    createdAt: DateTime.parse(j['createdAt']),
  );
}
