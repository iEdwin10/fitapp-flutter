import 'package:flutter/foundation.dart';

enum MuscleGroup {
  chest, back, shoulders, biceps, triceps,
  abs, quads, hamstrings, glutes, calves, fullBody
}

@immutable
class Exercise {
  final String id;
  final String name;
  final String description;
  final String? gifUrl;
  final List<MuscleGroup> muscles;
  final String alternativeId;
  final bool isCustom;

  const Exercise({
    required this.id,
    required this.name,
    required this.description,
    this.gifUrl,
    required this.muscles,
    required this.alternativeId,
    this.isCustom = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'description': description,
    'gifUrl': gifUrl,
    'muscles': muscles.map((m) => m.name).toList(),
    'alternativeId': alternativeId,
    'isCustom': isCustom,
  };

  factory Exercise.fromJson(Map<String, dynamic> j) => Exercise(
    id: j['id'], name: j['name'], description: j['description'],
    gifUrl: j['gifUrl'],
    muscles: (j['muscles'] as List)
        .map((m) => MuscleGroup.values.firstWhere((e) => e.name == m))
        .toList(),
    alternativeId: j['alternativeId'],
    isCustom: j['isCustom'] ?? false,
  );
}
