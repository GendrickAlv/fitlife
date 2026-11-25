import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'data/database/app_database.dart';
import 'data/repositories/activity_repository.dart';
import 'data/repositories/challenge_repository.dart';
import 'data/repositories/profile_repository.dart';
import 'data/repositories/routine_repository.dart';
import 'data/repositories/step_repository.dart';
import 'data/repositories/water_repository.dart';
import 'data/repositories/weight_repository.dart';
import 'providers/activity_provider.dart';
import 'providers/challenge_provider.dart';
import 'providers/hydration_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/routine_provider.dart';
import 'providers/step_provider.dart';
import 'providers/weight_provider.dart';
import 'screens/shell/home_shell.dart';

/// Nombres de rutas de la aplicación.
class AppRoutes {
  const AppRoutes._();

  static const home = '/';
  static const routines = '/routines';
  static const routineDetail = '/routines/detail';
  static const routineForm = '/routines/form';
  static const history = '/history';
  static const activityForm = '/history/form';
  static const weight = '/weight';
  static const hydration = '/hydration';
  static const stats = '/stats';
  static const challenges = '/challenges';
  static const steps = '/steps';
  static const settings = '/settings';
}

/// Raíz de la aplicación: providers + MaterialApp.
class FitLifeApp extends StatelessWidget {
  /// Crea la app. [database] permite inyectar otra base (tests).
  const FitLifeApp({super.key, this.database});

  final AppDatabase? database;

  @override
  Widget build(BuildContext context) {
    final db = database ?? AppDatabase.instance;
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => RoutineProvider(RoutineRepository(db))..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => ActivityProvider(ActivityRepository(db))..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => WeightProvider(WeightRepository(db))..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => HydrationProvider(WaterRepository(db))..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => StepProvider(StepRepository(db))..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => ChallengeProvider(ChallengeRepository(db))..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => ProfileProvider(const ProfileRepository())..load(),
        ),
      ],
      child: const _FitLifeMaterialApp(),
    );
  }
}

class _FitLifeMaterialApp extends StatelessWidget {
  const _FitLifeMaterialApp();

  @override
  Widget build(BuildContext context) {
    final themeMode = context.select<ProfileProvider, ThemeMode>(
      (p) => p.themeMode,
    );
    return MaterialApp(
      title: 'FitLife',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      locale: const Locale('es'),
      supportedLocales: const [Locale('es'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const HomeShell(),
    );
  }
}
