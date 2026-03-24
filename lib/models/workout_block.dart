import 'package:flutter/foundation.dart';

enum BlockType { exercise, rest }
enum ExecutionMode { classic, timer }

@immutable
class WorkoutBlock {
  final String id;
  final BlockType type;
  final String? exerciseId;
  final ExecutionMode? executionMode;
  final int? sets;
  final int? reps;
  final double? weight;
  final int? restBetweenSets;
  final int? duration;
  final int? restDuration;

  const WorkoutBlock({
    required this.id,
    required this.type,
    this.exerciseId,
    this.executionMode,
    this.sets,
    this.reps,
    this.weight,
    this.restBetweenSets,
    this.duration,
    this.restDuration,
  });

  bool get isExercise => type == BlockType.exercise;
  bool get isRest     => type == BlockType.rest;

  Map<String, dynamic> toJson() => {
    'id': id, 'type': type.name,
    'exerciseId': exerciseId,
    'executionMode': executionMode?.name,
    'sets': sets, 'reps': reps, 'weight': weight,
    'restBetweenSets': restBetweenSets,
    'duration': duration, 'restDuration': restDuration,
  };

  factory WorkoutBlock.fromJson(Map<String, dynamic> j) => WorkoutBlock(
    id: j['id'],
    type: BlockType.values.firstWhere((e) => e.name == j['type']),
    exerciseId: j['exerciseId'],
    executionMode: j['executionMode'] != null
        ? ExecutionMode.values.firstWhere((e) => e.name == j['executionMode'])
        : null,
    sets: j['sets'], reps: j['reps'],
    weight: (j['weight'] as num?)?.toDouble(),
    restBetweenSets: j['restBetweenSets'],
    duration: j['duration'], restDuration: j['restDuration'],
  );
}
