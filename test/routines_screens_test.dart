import 'package:fitlife/core/theme/app_theme.dart';
import 'package:fitlife/data/database/app_database.dart';
import 'package:fitlife/data/repositories/activity_repository.dart';
import 'package:fitlife/data/repositories/routine_repository.dart';
import 'package:fitlife/providers/activity_provider.dart';
import 'package:fitlife/providers/routine_provider.dart';
import 'package:fitlife/screens/routines/routine_form_screen.dart';
import 'package:fitlife/screens/routines/routines_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Widget _app(AppDatabase db, Widget home) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(
        create: (_) => RoutineProvider(RoutineRepository(db))..load(),
      ),
      ChangeNotifierProvider(
        create: (_) => ActivityProvider(ActivityRepository(db))..load(),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('es'),
      supportedLocales: const [Locale('es')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: home,
    ),
  );
}

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    await initializeDateFormatting('es');
  });

  testWidgets('RoutineFormScreen vacío muestra errores de validación', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360 * 3, 1400 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final db = AppDatabase.forTesting();
    await tester.runAsync(() => db.database);
    await tester.pumpWidget(_app(db, const RoutineFormScreen()));
    await tester.pump();

    await tester.tap(find.text('Crear rutina'));
    await tester.pump();

    expect(find.text('El nombre es obligatorio'), findsOneWidget);
    expect(find.text('Introduce un número'), findsNWidgets(2));
    expect(find.text('Añade al menos un ejercicio'), findsOneWidget);
  });

  testWidgets('RoutinesScreen renderiza las rutinas de ejemplo', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final db = AppDatabase.forTesting(seed: true);
    await tester.runAsync(() => db.database);
    await tester.pumpWidget(_app(db, const RoutinesScreen()));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pump();

    expect(find.text('Rutinas'), findsOneWidget);
    expect(find.text('Nueva rutina'), findsOneWidget);
    expect(find.text('Favoritas'), findsOneWidget);
    expect(find.byType(Card), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
