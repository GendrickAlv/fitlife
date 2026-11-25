import 'package:fitlife/data/database/app_database.dart';
import 'package:fitlife/data/models/weight_entry.dart';
import 'package:fitlife/data/repositories/profile_repository.dart';
import 'package:fitlife/data/repositories/weight_repository.dart';
import 'package:fitlife/providers/profile_provider.dart';
import 'package:fitlife/providers/weight_provider.dart';
import 'package:fitlife/screens/weight/weight_form_screen.dart';
import 'package:fitlife/screens/weight/weight_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Widget _wrap(WeightProvider weight, ProfileProvider profile, Widget child) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: weight),
      ChangeNotifierProvider.value(value: profile),
    ],
    child: MaterialApp(home: child),
  );
}

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    await initializeDateFormatting('es');
  });

  late AppDatabase db;
  late WeightProvider weight;
  late ProfileProvider profile;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting();
    weight = WeightProvider(WeightRepository(db));
    profile = ProfileProvider(const ProfileRepository());
  });

  testWidgets('el formulario muestra errores con valores vacíos o inválidos', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(weight, profile, const WeightFormScreen()));

    await tester.tap(find.text('Guardar'));
    await tester.pump();
    expect(find.text('Introduce un número'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('weightField')), 'abc');
    await tester.tap(find.text('Guardar'));
    await tester.pump();
    expect(find.text('Número no válido'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('weightField')), '10');
    await tester.tap(find.text('Guardar'));
    await tester.pump();
    expect(find.text('Debe estar entre 20 y 400'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('weightField')), '70,5');
    await tester.enterText(find.byKey(const Key('noteField')), 'x' * 121);
    await tester.tap(find.text('Guardar'));
    await tester.pump();
    expect(find.text('Máximo 120 caracteres'), findsOneWidget);
  });

  testWidgets('WeightScreen muestra estado vacío y luego los datos', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.runAsync(() => db.database);
    await tester.runAsync(weight.load);
    await tester.pumpWidget(_wrap(weight, profile, const WeightScreen()));
    expect(find.text('Sin registros de peso'), findsOneWidget);
    expect(find.text('Registrar peso'), findsWidgets);

    final now = DateTime.now();
    await tester.runAsync(() async {
      await weight.add(
        WeightEntry(
          weightKg: 80,
          date: now.subtract(const Duration(days: 5)),
          note: 'Inicio',
        ),
      );
      await weight.add(WeightEntry(weightKg: 78.5, date: now));
    });
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Peso actual'), findsOneWidget);
    expect(find.text('Evolución'), findsOneWidget);
    expect(find.textContaining('78,5'), findsWidgets);
    expect(find.text('Historial'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
