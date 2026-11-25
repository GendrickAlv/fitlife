import 'package:material_ui/material_ui.dart';

import '../../core/constants.dart';

/// Perfil del usuario (SharedPreferences).
class UserProfile {
  /// Crea un perfil.
  const UserProfile({
    this.name = Defaults.profileName,
    this.heightCm = Defaults.heightCm,
    this.goalWeightKg,
    this.dailyWaterGoalMl = Defaults.dailyWaterGoalMl,
    this.dailyStepGoal = Defaults.dailyStepGoal,
    this.weeklyWorkoutGoal = Defaults.weeklyWorkoutGoal,
    this.themeMode = ThemeMode.system,
  });

  final String name;
  final double heightCm;
  final double? goalWeightKg;
  final int dailyWaterGoalMl;
  final int dailyStepGoal;
  final int weeklyWorkoutGoal;
  final ThemeMode themeMode;

  /// Copia con cambios. Usa [clearGoalWeight] para borrar el peso objetivo.
  UserProfile copyWith({
    String? name,
    double? heightCm,
    double? goalWeightKg,
    bool clearGoalWeight = false,
    int? dailyWaterGoalMl,
    int? dailyStepGoal,
    int? weeklyWorkoutGoal,
    ThemeMode? themeMode,
  }) => UserProfile(
    name: name ?? this.name,
    heightCm: heightCm ?? this.heightCm,
    goalWeightKg: clearGoalWeight ? null : (goalWeightKg ?? this.goalWeightKg),
    dailyWaterGoalMl: dailyWaterGoalMl ?? this.dailyWaterGoalMl,
    dailyStepGoal: dailyStepGoal ?? this.dailyStepGoal,
    weeklyWorkoutGoal: weeklyWorkoutGoal ?? this.weeklyWorkoutGoal,
    themeMode: themeMode ?? this.themeMode,
  );

  /// Mapa serializable.
  Map<String, Object?> toMap() => {
    'name': name,
    'heightCm': heightCm,
    'goalWeightKg': goalWeightKg,
    'dailyWaterGoalMl': dailyWaterGoalMl,
    'dailyStepGoal': dailyStepGoal,
    'weeklyWorkoutGoal': weeklyWorkoutGoal,
    'themeMode': themeMode.name,
  };

  /// Crea desde un mapa.
  factory UserProfile.fromMap(Map<String, Object?> map) => UserProfile(
    name: (map['name'] as String?) ?? Defaults.profileName,
    heightCm: (map['heightCm'] as num?)?.toDouble() ?? Defaults.heightCm,
    goalWeightKg: (map['goalWeightKg'] as num?)?.toDouble(),
    dailyWaterGoalMl:
        (map['dailyWaterGoalMl'] as num?)?.toInt() ?? Defaults.dailyWaterGoalMl,
    dailyStepGoal:
        (map['dailyStepGoal'] as num?)?.toInt() ?? Defaults.dailyStepGoal,
    weeklyWorkoutGoal:
        (map['weeklyWorkoutGoal'] as num?)?.toInt() ??
        Defaults.weeklyWorkoutGoal,
    themeMode: ThemeMode.values.firstWhere(
      (m) => m.name == map['themeMode'],
      orElse: () => ThemeMode.system,
    ),
  );
}
