import 'package:flutter_test/flutter_test.dart';
import 'package:fitlife/app.dart';
import 'package:fitlife/data/database/app_database.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    await initializeDateFormatting('es');
  });

  testWidgets('FitLifeApp muestra la navegación inferior', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final db = AppDatabase.forTesting(seed: true);
    await tester.runAsync(() => db.database);
    // Las consultas SQLite reales deben resolverse fuera del reloj falso.
    await tester.runAsync(() async {
      await tester.pumpWidget(FitLifeApp(database: db));
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Inicio'), findsWidgets);
    expect(find.text('Rutinas'), findsOneWidget);
    expect(find.text('Historial'), findsOneWidget);
    expect(find.text('Progreso'), findsOneWidget);
    expect(find.text('Más'), findsWidgets);

    await tester.tap(find.text('Más').last);
    await tester.pump();
    expect(find.text('Acerca de'), findsOneWidget);
  });
}
