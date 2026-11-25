import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_profile.dart';

/// Persistencia del perfil en SharedPreferences.
class ProfileRepository {
  /// Crea el repositorio.
  const ProfileRepository();

  static const _kName = 'profile_name';
  static const _kHeight = 'profile_height_cm';
  static const _kGoalWeight = 'profile_goal_weight_kg';
  static const _kWater = 'profile_daily_water_ml';
  static const _kSteps = 'profile_daily_steps';
  static const _kWorkouts = 'profile_weekly_workouts';
  static const _kTheme = 'profile_theme_mode';

  /// Carga el perfil (valores por defecto si no existe).
  Future<UserProfile> load() async {
    final p = await SharedPreferences.getInstance();
    const d = UserProfile();
    return UserProfile(
      name: p.getString(_kName) ?? d.name,
      heightCm: p.getDouble(_kHeight) ?? d.heightCm,
      goalWeightKg: p.getDouble(_kGoalWeight),
      dailyWaterGoalMl: p.getInt(_kWater) ?? d.dailyWaterGoalMl,
      dailyStepGoal: p.getInt(_kSteps) ?? d.dailyStepGoal,
      weeklyWorkoutGoal: p.getInt(_kWorkouts) ?? d.weeklyWorkoutGoal,
      themeMode: ThemeMode.values.firstWhere(
        (m) => m.name == p.getString(_kTheme),
        orElse: () => ThemeMode.system,
      ),
    );
  }

  /// Guarda el perfil.
  Future<void> save(UserProfile profile) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kName, profile.name);
    await p.setDouble(_kHeight, profile.heightCm);
    final goal = profile.goalWeightKg;
    if (goal == null) {
      await p.remove(_kGoalWeight);
    } else {
      await p.setDouble(_kGoalWeight, goal);
    }
    await p.setInt(_kWater, profile.dailyWaterGoalMl);
    await p.setInt(_kSteps, profile.dailyStepGoal);
    await p.setInt(_kWorkouts, profile.weeklyWorkoutGoal);
    await p.setString(_kTheme, profile.themeMode.name);
  }
}
