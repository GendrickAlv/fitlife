import 'package:fitlife/core/constants.dart';
import 'package:fitlife/data/database/app_database.dart';
import 'package:fitlife/data/models/challenge.dart';
import 'package:fitlife/data/repositories/activity_repository.dart';
import 'package:fitlife/data/repositories/challenge_repository.dart';
import 'package:fitlife/data/repositories/step_repository.dart';
import 'package:fitlife/data/repositories/water_repository.dart';
import 'package:fitlife/providers/activity_provider.dart';
import 'package:fitlife/providers/challenge_provider.dart';
import 'package:fitlife/providers/hydration_provider.dart';
import 'package:fitlife/providers/step_provider.dart';
import 'package:fitlife/screens/challenges/challenge_form_screen.dart';
import 'package:fitlife/screens/challenges/challenges_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late AppDatabase db;

  setUpAll(() async {
    sqfliteFfiInit();
    await initializeDateFormatting('es');
  });

  setUp(() async {
    db = AppDatabase.forTesting();
    await db.database;
  });

  tearDown(() => db.close());

  Widget wrap(Widget child, ChallengeProvider challenges) => MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: challenges),
      ChangeNotifierProvider(
        create: (_) => ActivityProvider(ActivityRepository(db)),
      ),
      ChangeNotifierProvider(
        create: (_) => HydrationProvider(WaterRepository(db)),
      ),
      ChangeNotifierProvider(create: (_) => StepProvider(StepRepository(db))),
    ],
    child: MaterialApp(
      locale: const Locale('es'),
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [Locale('es')],
      home: child,
    ),
  );

  testWidgets('ChallengesScreen muestra un desafío insertado', (tester) async {
    final provider = ChallengeProvider(ChallengeRepository(db));
    await tester.runAsync(() async {
      await provider.add(
        Challenge(
          title: 'Reto de pasos',
          description: 'Camina más',
          type: ChallengeType.steps,
          target: 5000,
          weekStart: DateTime.now().subtract(
            Duration(days: DateTime.now().weekday - 1),
          ),
          createdAt: DateTime.now(),
        ),
      );
    });
    await tester.pumpWidget(wrap(const ChallengesScreen(), provider));
    await tester.pump();

    expect(find.text('Desafíos semanales'), findsOneWidget);
    expect(find.text('Reto de pasos'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.textContaining('/ 5.000 pasos'), findsOneWidget);
    expect(find.text('Sugerencias'), findsOneWidget);
  });

  testWidgets('ChallengesScreen vacío muestra EmptyState', (tester) async {
    final provider = ChallengeProvider(ChallengeRepository(db));
    await tester.pumpWidget(wrap(const ChallengesScreen(), provider));
    await tester.pump();
    expect(find.text('Aún no tienes desafíos'), findsOneWidget);
  });

  testWidgets('ChallengeFormScreen valida campos', (tester) async {
    final provider = ChallengeProvider(ChallengeRepository(db));
    await tester.binding.setSurfaceSize(const Size(360, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(wrap(const ChallengeFormScreen(), provider));
    await tester.pump();

    final save = find.text('Crear desafío');
    await tester.tap(save);
    await tester.pump();
    expect(find.text('El título es obligatorio'), findsOneWidget);
    expect(find.text('Introduce un número'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'Mi reto');
    await tester.enterText(find.byKey(const ValueKey('target_field')), '99');
    await tester.tap(save);
    await tester.pump();
    expect(find.text('El título es obligatorio'), findsNothing);
    expect(find.text('No puede superar 14 sesiones'), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('target_field')), '0');
    await tester.tap(save);
    await tester.pump();
    expect(find.text('Debe ser mayor que 0'), findsOneWidget);
  });
}
