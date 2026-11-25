import 'package:fitlife/core/theme/app_theme.dart';
import 'package:fitlife/data/database/app_database.dart';
import 'package:fitlife/data/repositories/activity_repository.dart';
import 'package:fitlife/data/repositories/routine_repository.dart';
import 'package:fitlife/providers/activity_provider.dart';
import 'package:fitlife/providers/routine_provider.dart';
import 'package:fitlife/screens/history/activity_form_screen.dart';
import 'package:fitlife/screens/history/history_screen.dart';
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

  testWidgets('ActivityFormScreen vacío muestra errores de validación', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final db = AppDatabase.forTesting();
    await tester.runAsync(() => db.database);
    await tester.pumpWidget(_app(db, const ActivityFormScreen()));
    await tester.pump();

    await tester.ensureVisible(find.text('Guardar actividad'));
    await tester.tap(find.text('Guardar actividad'));
    await tester.pump();

    expect(find.text('El título es obligatorio'), findsOneWidget);
    expect(find.text('Introduce un número'), findsNWidgets(2));
  });

  testWidgets('ActivityFormScreen limpia el error del título al escribir '
      'sin volver a guardar', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final db = AppDatabase.forTesting();
    await tester.runAsync(() => db.database);
    await tester.pumpWidget(_app(db, const ActivityFormScreen()));
    await tester.pump();

    await tester.ensureVisible(find.text('Guardar actividad'));
    await tester.tap(find.text('Guardar actividad'));
    await tester.pump();
    expect(find.text('El título es obligatorio'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'Correr');
    await tester.pump();

    expect(find.text('El título es obligatorio'), findsNothing);
  });

  testWidgets('HistoryScreen sin datos muestra el estado vacío', (
    tester,
  ) async {
    final db = AppDatabase.forTesting();
    await tester.runAsync(() => db.database);
    await tester.pumpWidget(_app(db, const HistoryScreen()));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pump();

    expect(find.text('Sin actividades'), findsOneWidget);
    expect(find.text('Registrar actividad'), findsWidgets);
  });
}
