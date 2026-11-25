import 'package:material_ui/material_ui.dart';

import '../screens/challenges/challenges_screen.dart';
import '../screens/hydration/hydration_screen.dart';
import '../screens/sensors/step_counter_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/weight/weight_screen.dart';

/// Rutas nombradas de las pantallas secundarias (sin argumentos).
///
/// Las pantallas que reciben datos (detalle/formularios) se abren con
/// `Navigator.push(MaterialPageRoute(...))` pasando el objeto por constructor.
class AppRoutes {
  const AppRoutes._();

  /// Seguimiento de peso.
  static const weight = '/weight';

  /// Hidratación.
  static const hydration = '/hydration';

  /// Desafíos semanales.
  static const challenges = '/challenges';

  /// Contador de pasos (acelerómetro).
  static const steps = '/steps';

  /// Perfil y ajustes.
  static const settings = '/settings';

  /// Tabla de rutas registrada en `MaterialApp.routes`.
  static Map<String, WidgetBuilder> get table => {
    weight: (_) => const WeightScreen(),
    hydration: (_) => const HydrationScreen(),
    challenges: (_) => const ChallengesScreen(),
    steps: (_) => const StepCounterScreen(),
    settings: (_) => const SettingsScreen(),
  };
}
