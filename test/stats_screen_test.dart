import 'package:fitlife/core/theme/app_theme.dart';
import 'package:fitlife/data/database/app_database.dart';
import 'package:fitlife/data/models/activity.dart';
import 'package:fitlife/data/models/water_entry.dart';
import 'package:fitlife/data/models/weight_entry.dart';
import 'package:fitlife/data/repositories/activity_repository.dart';
import 'package:fitlife/data/repositories/water_repository.dart';
import 'package:fitlife/data/repositories/weight_repository.dart';
import 'package:fitlife/providers/activity_provider.dart';
import 'package:fitlife/providers/hydration_provider.dart';
import 'package:fitlife/providers/profile_provider.dart';
import 'package:fitlife/providers/weight_provider.dart';
import 'package:fitlife/data/repositories/profile_repository.dart';
import 'package:fitlife/screens/stats/stats_metrics.dart';
import 'package:fitlife/screens/stats/stats_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Activity _act(DateTime d, String cat) => Activity(
  title: 'Sesión $cat',
  category: cat,
  durationMinutes: 40,
  calories: 300,
  date: d,
);

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    await initializeDateFormatting('es');
  });

  test('labelInterval evita solapamientos', () {
    expect(labelInterval(7), 1);
    expect(labelInterval(30), greaterThan(2));
  });

  test('sessionsByCategory ordena por número de sesiones', () {
    final now = DateTime.now();
    final r = sessionsByCategory([
      _act(now, 'Yoga'),
      _act(now, 'Cardio'),
      _act(now, 'Cardio'),
    ]);
    expect(r.first.key, 'Cardio');
    expect(r.first.value, 2);
  });

  Future<Widget> build({required bool withData}) async {
    SharedPreferences.setMockInitialValues({});
    final db = AppDatabase.forTesting();
    await db.database;
    final now = DateTime.now();
    if (withData) {
      final acts = ActivityRepository(db);
      await acts.insert(_act(now, 'Cardio'));
      await acts.insert(
        _act(DateTime(now.year, now.month, now.day - 1), 'Fuerza'),
      );
      await acts.insert(
        _act(DateTime(now.year, now.month, now.day - 2), 'Cardio'),
      );
      final w = WeightRepository(db);
      await w.insert(
        WeightEntry(
          weightKg: 80,
          date: DateTime(now.year, now.month, now.day - 4),
        ),
      );
      await w.insert(WeightEntry(weightKg: 79, date: now));
      await WaterRepository(db).insert(WaterEntry(amountMl: 2600, date: now));
    }
    final activity = ActivityProvider(ActivityRepository(db));
    final weight = WeightProvider(WeightRepository(db));
    final hydration = HydrationProvider(WaterRepository(db));
    final profile = ProfileProvider(const ProfileRepository());
    await Future.wait([
      activity.load(),
      weight.load(),
      hydration.load(),
      profile.load(),
    ]);
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: activity),
        ChangeNotifierProvider.value(value: weight),
        ChangeNotifierProvider.value(value: hydration),
        ChangeNotifierProvider.value(value: profile),
      ],
      child: MaterialApp(
        theme: AppTheme.dark,
        locale: const Locale('es'),
        supportedLocales: const [Locale('es')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: const StatsScreen(),
      ),
    );
  }

  Future<void> pumpStats(WidgetTester tester, {required bool withData}) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final app = (await tester.runAsync(() => build(withData: withData)))!;
    await tester.pumpWidget(app);
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('pestaña Actividad con datos', (tester) async {
    await pumpStats(tester, withData: true);
    expect(find.text('Sesiones'), findsOneWidget);
    expect(find.text('Minutos por día'), findsOneWidget);
    expect(find.text('Calorías por día'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Sesiones por categoría'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('67%'), findsOneWidget);
    await tester.tap(find.text('30 días'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
  });

  testWidgets('pestañas Peso e Hidratación con datos', (tester) async {
    await pumpStats(tester, withData: true);
    await tester.tap(find.text('Peso'));
    await tester.pumpAndSettle();
    expect(find.text('Evolución del peso'), findsOneWidget);
    expect(find.text('Promedio'), findsOneWidget);

    await tester.tap(find.text('Hidratación'));
    await tester.pumpAndSettle();
    expect(find.text('Agua por día'), findsOneWidget);
    expect(find.text('Días con meta'), findsOneWidget);
    expect(find.text('14%'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('estados vacíos en las tres pestañas', (tester) async {
    await pumpStats(tester, withData: false);
    expect(
      find.text('Aún no hay entrenamientos en este periodo'),
      findsOneWidget,
    );
    await tester.tap(find.text('Peso'));
    await tester.pumpAndSettle();
    expect(find.text('Sin registros de peso en este periodo'), findsOneWidget);
    await tester.tap(find.text('Hidratación'));
    await tester.pumpAndSettle();
    expect(
      find.text('Aún no has registrado agua en este periodo'),
      findsOneWidget,
    );
  });
}
