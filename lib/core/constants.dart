import 'package:material_ui/material_ui.dart';

/// Categorías de rutina disponibles.
class RoutineCategory {
  const RoutineCategory._();

  /// Todas las categorías.
  static const all = <String>[
    'Fuerza',
    'Cardio',
    'HIIT',
    'Flexibilidad',
    'Yoga',
    'Deporte',
    'Otro',
  ];
}

/// Niveles de dificultad de una rutina.
class Difficulty {
  const Difficulty._();

  /// Todos los niveles.
  static const all = <String>['Principiante', 'Intermedio', 'Avanzado'];
}

/// Tipos de desafío semanal.
enum ChallengeType { workouts, minutes, calories, water, steps }

/// Metadatos de presentación de [ChallengeType].
extension ChallengeTypeX on ChallengeType {
  /// Nombre en español.
  String get label => switch (this) {
    ChallengeType.workouts => 'Entrenamientos',
    ChallengeType.minutes => 'Minutos activos',
    ChallengeType.calories => 'Calorías quemadas',
    ChallengeType.water => 'Agua',
    ChallengeType.steps => 'Pasos',
  };

  /// Unidad del objetivo.
  String get unit => switch (this) {
    ChallengeType.workouts => 'sesiones',
    ChallengeType.minutes => 'min',
    ChallengeType.calories => 'kcal',
    ChallengeType.water => 'L',
    ChallengeType.steps => 'pasos',
  };

  /// Icono representativo.
  IconData get icon => switch (this) {
    ChallengeType.workouts => Icons.fitness_center,
    ChallengeType.minutes => Icons.timer_outlined,
    ChallengeType.calories => Icons.local_fire_department_outlined,
    ChallengeType.water => Icons.water_drop_outlined,
    ChallengeType.steps => Icons.directions_walk,
  };
}

/// Icono y color asociados a cada categoría.
class CategoryStyle {
  const CategoryStyle._();

  /// Icono de la [category].
  static IconData icon(String category) => switch (category) {
    'Fuerza' => Icons.fitness_center,
    'Cardio' => Icons.directions_run,
    'HIIT' => Icons.bolt,
    'Flexibilidad' => Icons.accessibility_new,
    'Yoga' => Icons.self_improvement,
    'Deporte' => Icons.sports_soccer,
    _ => Icons.sports_gymnastics,
  };

  /// Color de la [category].
  static Color color(String category) => switch (category) {
    'Fuerza' => const Color(0xFFE53935),
    'Cardio' => const Color(0xFFFB8C00),
    'HIIT' => const Color(0xFFD81B60),
    'Flexibilidad' => const Color(0xFF8E24AA),
    'Yoga' => const Color(0xFF3949AB),
    'Deporte' => const Color(0xFF43A047),
    _ => const Color(0xFF607D8B),
  };
}

/// Metas por defecto.
class Defaults {
  const Defaults._();

  static const dailyWaterGoalMl = 2500;
  static const dailyStepGoal = 8000;
  static const weeklyWorkoutGoal = 4;
  static const heightCm = 170.0;
  static const profileName = 'Atleta';
  static const waterQuickAmountsMl = <int>[150, 250, 330, 500];
}
