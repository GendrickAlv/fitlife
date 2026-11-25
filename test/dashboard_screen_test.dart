import 'package:fitlife/core/theme/app_theme.dart';
import 'package:fitlife/data/database/app_database.dart';
import 'package:fitlife/data/models/activity.dart';
import 'package:fitlife/data/models/challenge.dart';
import 'package:fitlife/data/models/water_entry.dart';
import 'package:fitlife/data/models/weight_entry.dart';
import 'package:fitlife/core/constants.dart';
import 'package:fitlife/data/repositories/activity_repository.dart';
import 'package:fitlife/data/repositories/challenge_repository.dart';
import 'package:fitlife/data/repositories/profile_repository.dart';
import 'package:fitlife/data/repositories/step_repository.dart';
import 'package:fitlife/data/repositories/water_repository.dart';
import 'package:fitlife/data/repositories/weight_repository.dart';
import 'package:fitlife/providers/activity_provider.dart';
import 'package:fitlife/providers/challenge_provider.dart';
import 'package:fitlife/providers/hydration_provider.dart';
import 'package:fitlife/providers/profile_provider.dart';
import 'package:fitlife/providers/step_provider.dart';
import 'package:fitlife/providers/weight_provider.dart';
import 'package:fitlife/screens/dashboard/dashboard_metrics.dart';
import 'package:fitlife/screens/dashboard/dashboard_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Activity _act(DateTime d, {String title = 'Sesión'}) => Activity(
  title: title,
  category: 'Cardio',
  durationMinutes: 30,
  calories: 200,
  date: d,
);

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    await initializeDateFormatting('es');
  });

  group('activeDayStreak', () {
    final today = DateTime(2026, 5, 10, 15);
    test('sin actividades es 0', () {
      expect(activeDayStreak(const [], today: today), 0);
    });

    test('cuenta días consecutivos terminando hoy', () {
      final acts = [
        _act(DateTime(2026, 5, 10, 8)),
        _act(DateTime(2026, 5, 10, 19)),
        _act(DateTime(2026, 5, 9)),
        _act(DateTime(2026, 5, 8)),
        _act(DateTime(2026, 5, 6)),
      ];
      expect(activeDayStreak(acts, today: today), 3);
    });

    test('si hoy no hay actividad, la racha cuenta desde ayer', () {
      final acts = [_act(DateTime(2026, 5, 9)), _act(DateTime(2026, 5, 8))];
      expect(activeDayStreak(acts, today: today), 2);
    });

    test('un hueco de más de un día rompe la racha', () {
      final acts = [_act(DateTime(2026, 5, 8))];
      expect(activeDayStreak(acts, today: today), 0);
    });
  });

  test('greetingForHour', () {
    expect(greetingForHour(8), 'Buenos días');
    expect(greetingForHour(15), 'Buenas tardes');
    expect(greetingForHour(23), 'Buenas noches');
  });

  group('DashboardScreen', () {
    late AppDatabase db;
    late HydrationProvider hydration;

    Future<Widget> build({bool withData = true}) async {
      SharedPreferences.setMockInitialValues({});
      db = AppDatabase.forTesting();
      await db.database;
      final now = DateTime.now();
      if (withData) {
        await ActivityRepository(db).insert(_act(now, title: 'Carrera test'));
        await WeightRepository(db).insert(
          WeightEntry(
            weightKg: 80,
            date: DateTime(now.year, now.month, now.day - 3),
          ),
        );
        await WeightRepository(db)
            .insert(WeightEntry(weightKg: 78.5, date: now));
        await WaterRepository(db).insert(WaterEntry(amountMl: 500, date: now));
        await ChallengeRepository(db).insert(
          Challenge(
            title: 'Reto de prueba',
            type: ChallengeType.workouts,
            target: 3,
            weekStart: DateTime(
              now.year,
              now.month,
              now.day - (now.weekday - 1),
            ),
            createdAt: now,
          ),
        );
      }
      final activity = ActivityProvider(ActivityRepository(db));
      final weight = WeightProvider(WeightRepository(db));
      hydration = HydrationProvider(WaterRepository(db));
      final steps = StepProvider(StepRepository(db));
      final challenges = ChallengeProvider(ChallengeRepository(db));
      final profile = ProfileProvider(const ProfileRepository());
      await Future.wait([
        activity.load(),
        weight.load(),
        hydration.load(),
        steps.load(),
        challenges.load(),
        profile.load(),
      ]);
      return MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: activity),
          ChangeNotifierProvider.value(value: weight),
          ChangeNotifierProvider.value(value: hydration),
          ChangeNotifierProvider.value(value: steps),
          ChangeNotifierProvider.value(value: challenges),
          ChangeNotifierProvider.value(value: profile),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('es'),
          supportedLocales: const [Locale('es')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: const DashboardScreen(),
        ),
      );
    }

    testWidgets('muestra resumen con datos y sin overflow a 360px', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360 * 3, 800 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final app = (await tester.runAsync(build))!;
      await tester.pumpWidget(app);
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('Atleta'), findsWidgets);
      expect(find.text('Último peso'), findsOneWidget);
      expect(find.text('Racha'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Reto de prueba'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Reto de prueba'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Carrera test'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Carrera test'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('estados vacíos y botón de agua', (tester) async {
      tester.view.physicalSize = const Size(360 * 3, 800 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final app = (await tester.runAsync(() => build(withData: false)))!;
      await tester.pumpWidget(app);
      await tester.pump(const Duration(milliseconds: 300));

      expect(hydration.todayTotalMl, 0);
      await tester.scrollUntilVisible(
        find.text('Agua +250 ml'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      tester
          .widget<ActionChip>(find.widgetWithText(ActionChip, 'Agua +250 ml'))
          .onPressed!();
      for (var i = 0; i < 30 && hydration.todayTotalMl == 0; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
      }
      await tester.pump(const Duration(milliseconds: 300));
      expect(hydration.error, isNull);
      expect(hydration.todayTotalMl, 250);
      expect(find.text('+250 ml de agua registrados'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Crear desafío'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Crear desafío'), findsOneWidget);
    });
  });
}
