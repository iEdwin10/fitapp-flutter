import 'package:flutter/foundation.dart';

enum BlockType { exercise, rest }
enum ExecutionMode { classic, timer }
enum BreathingPattern { off, box, breathing478 }

extension BreathingPatternLabel on BreathingPattern {
  String get label {
    switch (this) {
      case BreathingPattern.off: return 'Off';
      case BreathingPattern.box: return 'Box (4-4-4-4)';
      case BreathingPattern.breathing478: return '4-7-8';
    }
  }

  // [inspireSeconds, holdSeconds, expireSeconds, hold2Seconds]
  List<int> get phases {
    switch (this) {
      case BreathingPattern.off: return [];
      case BreathingPattern.box: return [4, 4, 4, 4];
      case BreathingPattern.breathing478: return [4, 7, 8, 0];
    }
  }
}

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
  final BreathingPattern breathingPattern;

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
    this.breathingPattern = BreathingPattern.off,
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
    'breathingPattern': breathingPattern.name,
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
    breathingPattern: j['breathingPattern'] != null
        ? BreathingPattern.values.firstWhere(
            (e) => e.name == j['breathingPattern'],
            orElse: () => BreathingPattern.off)
        : BreathingPattern.off,
  );

  WorkoutBlock copyWith({
    String? exerciseId,
    BreathingPattern? breathingPattern,
    int? sets, int? reps, double? weight,
    int? restBetweenSets, int? duration, int? restDuration,
    ExecutionMode? executionMode,
  }) => WorkoutBlock(
    id: id, type: type,
    exerciseId: exerciseId ?? this.exerciseId,
    executionMode: executionMode ?? this.executionMode,
    sets: sets ?? this.sets,
    reps: reps ?? this.reps,
    weight: weight ?? this.weight,
    restBetweenSets: restBetweenSets ?? this.restBetweenSets,
    duration: duration ?? this.duration,
    restDuration: restDuration ?? this.restDuration,
    breathingPattern: breathingPattern ?? this.breathingPattern,
  );
}
