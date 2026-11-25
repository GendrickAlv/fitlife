import 'dart:convert';

/// Ejercicio dentro de una rutina.
class Exercise {
  /// Crea un ejercicio.
  const Exercise({
    required this.name,
    required this.sets,
    required this.reps,
    this.weightKg,
    this.restSeconds,
  });

  final String name;
  final int sets;
  final int reps;
  final double? weightKg;
  final int? restSeconds;

  /// Copia con cambios.
  Exercise copyWith({
    String? name,
    int? sets,
    int? reps,
    double? weightKg,
    int? restSeconds,
  }) => Exercise(
    name: name ?? this.name,
    sets: sets ?? this.sets,
    reps: reps ?? this.reps,
    weightKg: weightKg ?? this.weightKg,
    restSeconds: restSeconds ?? this.restSeconds,
  );

  /// Serializa a JSON.
  Map<String, Object?> toJson() => {
    'name': name,
    'sets': sets,
    'reps': reps,
    'weightKg': weightKg,
    'restSeconds': restSeconds,
  };

  /// Crea desde JSON.
  factory Exercise.fromJson(Map<String, Object?> json) => Exercise(
    name: json['name'] as String,
    sets: (json['sets'] as num).toInt(),
    reps: (json['reps'] as num).toInt(),
    weightKg: (json['weightKg'] as num?)?.toDouble(),
    restSeconds: (json['restSeconds'] as num?)?.toInt(),
  );

  @override
  bool operator ==(Object other) =>
      other is Exercise &&
      other.name == name &&
      other.sets == sets &&
      other.reps == reps &&
      other.weightKg == weightKg &&
      other.restSeconds == restSeconds;

  @override
  int get hashCode => Object.hash(name, sets, reps, weightKg, restSeconds);
}

/// Rutina de entrenamiento (tabla `routines`).
class Routine {
  /// Crea una rutina.
  const Routine({
    this.id,
    required this.name,
    this.description = '',
    required this.category,
    required this.difficulty,
    required this.durationMinutes,
    required this.estimatedCalories,
    this.exercises = const [],
    this.isFavorite = false,
    required this.createdAt,
  });

  final int? id;
  final String name;
  final String description;
  final String category;
  final String difficulty;
  final int durationMinutes;
  final int estimatedCalories;
  final List<Exercise> exercises;
  final bool isFavorite;
  final DateTime createdAt;

  /// Copia con cambios.
  Routine copyWith({
    int? id,
    String? name,
    String? description,
    String? category,
    String? difficulty,
    int? durationMinutes,
    int? estimatedCalories,
    List<Exercise>? exercises,
    bool? isFavorite,
    DateTime? createdAt,
  }) => Routine(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description ?? this.description,
    category: category ?? this.category,
    difficulty: difficulty ?? this.difficulty,
    durationMinutes: durationMinutes ?? this.durationMinutes,
    estimatedCalories: estimatedCalories ?? this.estimatedCalories,
    exercises: exercises ?? this.exercises,
    isFavorite: isFavorite ?? this.isFavorite,
    createdAt: createdAt ?? this.createdAt,
  );

  /// Mapa para SQLite.
  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'name': name,
    'description': description,
    'category': category,
    'difficulty': difficulty,
    'duration_minutes': durationMinutes,
    'estimated_calories': estimatedCalories,
    'exercises': jsonEncode([for (final e in exercises) e.toJson()]),
    'is_favorite': isFavorite ? 1 : 0,
    'created_at': createdAt.millisecondsSinceEpoch,
  };

  /// Crea desde una fila de SQLite.
  factory Routine.fromMap(Map<String, Object?> map) {
    final raw = jsonDecode(map['exercises'] as String) as List<Object?>;
    return Routine(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: (map['description'] as String?) ?? '',
      category: map['category'] as String,
      difficulty: map['difficulty'] as String,
      durationMinutes: map['duration_minutes'] as int,
      estimatedCalories: map['estimated_calories'] as int,
      exercises: [
        for (final e in raw)
          Exercise.fromJson((e as Map).cast<String, Object?>()),
      ],
      isFavorite: (map['is_favorite'] as int? ?? 0) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }
}
