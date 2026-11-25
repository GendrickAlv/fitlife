import 'dart:async';

import 'package:fitlife/data/database/app_database.dart';
import 'package:fitlife/data/repositories/profile_repository.dart';
import 'package:fitlife/data/repositories/step_repository.dart';
import 'package:fitlife/providers/profile_provider.dart';
import 'package:fitlife/providers/step_provider.dart';
import 'package:fitlife/screens/sensors/step_counter_screen.dart';
import 'package:fitlife/screens/settings/settings_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late AppDatabase db;

  setUpAll(() async {
    sqfliteFfiInit();
    await initializeDateFormatting('es');
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting();
    await db.database;
  });

  tearDown(() => db.close());

  Widget wrap(Widget child, {StepProvider? steps, ProfileProvider? profile}) =>
      MultiProvider(
        providers: [
          ChangeNotifierProvider<StepProvider>.value(
            value: steps ?? StepProvider(StepRepository(db)),
          ),
          ChangeNotifierProvider<ProfileProvider>.value(
            value: profile ?? ProfileProvider(const ProfileRepository()),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('es'),
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          supportedLocales: const [Locale('es')],
          home: child,
        ),
      );

  testWidgets('StepCounterScreen cuenta pasos con acelerómetro falso', (
    tester,
  ) async {
    final controller = StreamController<({double x, double y, double z})>();
    final steps = StepProvider(
      StepRepository(db),
      accelerometer: () => controller.stream,
    );
    await tester.pumpWidget(wrap(const StepCounterScreen(), steps: steps));
    await tester.pump();

    expect(find.text('Iniciar conteo'), findsOneWidget);
    await tester.tap(find.text('Iniciar conteo'));
    await tester.pump();
    expect(steps.isTracking, isTrue);
    expect(find.text('Detener conteo'), findsOneWidget);

    await tester.runAsync(() async {
      controller.add((x: 0, y: 0, z: 9.8));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      controller.add((x: 0, y: 0, z: 14));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump(const Duration(milliseconds: 700));
    expect(steps.todaySteps, 1);
    expect(find.text('Contando pasos...'), findsOneWidget);

    await tester.tap(find.text('Detener conteo'));
    await tester.pump();
    await tester.runAsync(() => controller.close());
    await tester.pump(const Duration(milliseconds: 700));
    expect(steps.isTracking, isFalse);
  });

  testWidgets('StepCounterScreen sin acelerómetro ofrece pasos manuales', (
    tester,
  ) async {
    final steps = StepProvider(
      StepRepository(db),
      accelerometer: () => Stream.error(StateError('sin sensor')),
    );
    await tester.pumpWidget(wrap(const StepCounterScreen(), steps: steps));
    await tester.runAsync(() async {
      await steps.start();
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump(const Duration(milliseconds: 700));
    expect(steps.isSupported, isFalse);
    expect(
      find.textContaining('no tiene acelerómetro disponible'),
      findsOneWidget,
    );

    await tester.tap(find.text('Agregar pasos'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '60000');
    await tester.tap(find.text('Agregar'));
    await tester.pump();
    expect(find.text('Debe estar entre 1 y 50.000'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), '120');
    await tester.tap(find.text('Agregar'));
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump(const Duration(milliseconds: 700));
    expect(steps.todaySteps, 120);
  });

  testWidgets('StepCounterScreen muestra aviso si el sensor nunca emite', (
    tester,
  ) async {
    final controller = StreamController<({double x, double y, double z})>();
    final steps = StepProvider(
      StepRepository(db),
      accelerometer: () => controller.stream,
      sensorTimeout: const Duration(milliseconds: 50),
    );
    await tester.pumpWidget(wrap(const StepCounterScreen(), steps: steps));
    await tester.tap(find.text('Iniciar conteo'));
    await tester.pump();
    expect(find.text('Contando pasos...'), findsOneWidget);

    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 150)),
    );
    await tester.pump(const Duration(milliseconds: 700));
    expect(steps.isSupported, isFalse);
    expect(find.text('Contando pasos...'), findsNothing);
    expect(
      find.textContaining('no tiene acelerómetro disponible'),
      findsOneWidget,
    );
    expect(find.text('Agregar pasos'), findsOneWidget);
    await tester.runAsync(() => controller.close());
  });

  testWidgets('SettingsScreen valida y guarda', (tester) async {
    final profile = ProfileProvider(const ProfileRepository());
    await tester.binding.setSurfaceSize(const Size(360, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(wrap(const SettingsScreen(), profile: profile));
    await tester.pump();

    await tester.enterText(find.byKey(const ValueKey('name_field')), '');
    await tester.enterText(find.byKey(const ValueKey('height_field')), '50');
    await tester.enterText(find.byKey(const ValueKey('water_field')), '100');
    await tester.enterText(find.byKey(const ValueKey('steps_field')), '999999');
    await tester.enterText(find.byKey(const ValueKey('workouts_field')), '20');
    await tester.enterText(
      find.byKey(const ValueKey('goal_weight_field')),
      '5',
    );
    await tester.tap(find.text('Guardar'));
    await tester.pump();
    expect(find.text('El nombre es obligatorio'), findsOneWidget);
    expect(find.text('Debe estar entre 100 y 250'), findsOneWidget);
    expect(find.text('Debe estar entre 500 y 6000'), findsOneWidget);
    expect(find.text('Debe estar entre 1000 y 50000'), findsOneWidget);
    expect(find.text('Debe estar entre 1 y 14'), findsOneWidget);
    expect(find.text('Debe estar entre 20 y 400'), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('name_field')), 'Ana Gil');
    await tester.enterText(find.byKey(const ValueKey('height_field')), '165');
    await tester.enterText(find.byKey(const ValueKey('water_field')), '2000');
    await tester.enterText(find.byKey(const ValueKey('steps_field')), '9000');
    await tester.enterText(find.byKey(const ValueKey('workouts_field')), '3');
    await tester.enterText(find.byKey(const ValueKey('goal_weight_field')), '');
    expect(find.text('AG'), findsOneWidget);
    await tester.tap(find.text('Guardar'));
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();
    expect(profile.profile.name, 'Ana Gil');
    expect(profile.profile.dailyStepGoal, 9000);
    expect(profile.profile.goalWeightKg, isNull);
    expect(find.text('Perfil guardado'), findsOneWidget);

    await tester.tap(find.text('Oscuro'));
    await tester.pump();
    expect(profile.themeMode, ThemeMode.dark);
  });
}
