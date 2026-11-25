import 'package:fitlife/data/database/app_database.dart';
import 'package:fitlife/data/models/water_entry.dart';
import 'package:fitlife/data/repositories/profile_repository.dart';
import 'package:fitlife/data/repositories/water_repository.dart';
import 'package:fitlife/providers/hydration_provider.dart';
import 'package:fitlife/providers/profile_provider.dart';
import 'package:fitlife/screens/hydration/hydration_screen.dart';
import 'package:fitlife/screens/hydration/water_form_sheet.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Widget _wrap(HydrationProvider water, ProfileProvider profile, Widget child) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: water),
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
  late HydrationProvider water;
  late ProfileProvider profile;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting();
    water = HydrationProvider(WaterRepository(db));
    profile = ProfileProvider(const ProfileRepository());
  });

  testWidgets('el formulario de agua valida cantidad vacía e inválida', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(water, profile, const Scaffold(body: WaterFormSheet())),
    );

    await tester.tap(find.text('Guardar'));
    await tester.pump();
    expect(find.text('Introduce un número'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('amountField')), 'abc');
    await tester.tap(find.text('Guardar'));
    await tester.pump();
    expect(find.text('Número no válido'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('amountField')), '10');
    await tester.tap(find.text('Guardar'));
    await tester.pump();
    expect(find.text('Debe estar entre 50 y 5000'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('amountField')), '9000');
    await tester.tap(find.text('Guardar'));
    await tester.pump();
    expect(find.text('Debe estar entre 50 y 5000'), findsOneWidget);
  });

  testWidgets('HydrationScreen muestra el progreso y los registros de hoy', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.runAsync(() => db.database);
    await tester.runAsync(() async {
      await water.load();
      await water.add(WaterEntry(amountMl: 500, date: DateTime.now()));
    });
    await tester.pumpWidget(_wrap(water, profile, const HydrationScreen()));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('0,5 L'), findsOneWidget);
    expect(find.text('20%'), findsOneWidget);
    expect(find.text('Personalizado'), findsOneWidget);
    expect(find.text('Últimos 7 días'), findsOneWidget);
    expect(find.text('Registros de hoy'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
