import 'dart:async';

import 'package:fitlife/core/constants.dart';
import 'package:fitlife/core/utils/date_utils.dart';
import 'package:fitlife/data/database/app_database.dart';
import 'package:fitlife/data/models/activity.dart';
import 'package:fitlife/data/models/challenge.dart';
import 'package:fitlife/data/models/water_entry.dart';
import 'package:fitlife/data/models/weight_entry.dart';
import 'package:fitlife/data/repositories/activity_repository.dart';
import 'package:fitlife/data/repositories/challenge_repository.dart';
import 'package:fitlife/data/repositories/step_repository.dart';
import 'package:fitlife/data/repositories/water_repository.dart';
import 'package:fitlife/data/repositories/weight_repository.dart';
import 'package:fitlife/providers/activity_provider.dart';
import 'package:fitlife/providers/challenge_provider.dart';
import 'package:fitlife/providers/hydration_provider.dart';
import 'package:fitlife/providers/step_provider.dart';
import 'package:fitlife/providers/weight_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late AppDatabase db;

  setUpAll(sqfliteFfiInit);
  setUp(() async {
    db = AppDatabase.forTesting();
    await db.database;
  });
  tearDown(() => db.close());

  test('WeightProvider: latest, cambio e IMC', () async {
    final p = WeightProvider(WeightRepository(db));
    await p.load();
    expect(p.latest, isNull);
    expect(p.changeSinceFirst, isNull);
    expect(p.bmi(170), isNull);
    await p.add(WeightEntry(weightKg: 80, date: DateTime(2026, 1, 1)));
    await p.add(WeightEntry(weightKg: 76, date: DateTime(2026, 2, 1)));
    expect(p.latest?.weightKg, 76);
    expect(p.changeSinceFirst, closeTo(-4, 0.001));
    expect(p.bmi(200), closeTo(19, 0.001));
    await p.delete(p.latest!.id!);
    expect(p.entries.length, 1);
  });

  test('HydrationProvider: totales', () async {
    final p = HydrationProvider(WaterRepository(db));
    await p.load();
    final now = DateTime.now();
    await p.add(WaterEntry(amountMl: 250, date: now));
    await p.add(WaterEntry(amountMl: 500, date: now));
    await p.add(
      WaterEntry(
        amountMl: 1000,
        date: DateTime(now.year, now.month, now.day - 1, 12),
      ),
    );
    expect(p.todayTotalMl, 750);
    expect(p.totalForDay(now.subtract(const Duration(days: 1))), 1000);
    final totals = p.dailyTotals(3);
    expect(totals.length, 3);
    expect(totals.values.last, 750);
    expect(totals.values.toList()[1], 1000);
    await p.update(p.entries.first.copyWith(amountMl: 100));
    expect(p.entries.any((e) => e.amountMl == 100), true);
  });

  test('ActivityProvider: totales y por día', () async {
    final p = ActivityProvider(ActivityRepository(db));
    await p.load();
    final now = DateTime.now();
    await p.add(
      Activity(
        title: 'a',
        category: 'Cardio',
        durationMinutes: 30,
        calories: 200,
        date: now,
      ),
    );
    expect(p.todayActivities.length, 1);
    expect(p.totalMinutes, 30);
    expect(p.minutesPerDay(7).values.last, 30);
    expect(p.caloriesPerDay(7).length, 7);
    expect(p.activitiesInWeek(DateUtilsX.startOfWeek(now)).length, 1);
  });

  test('StepProvider: detecta picos y persiste', () async {
    final ctrl = StreamController<({double x, double y, double z})>();
    var t = DateTime(2026, 5, 4, 10);
    final repo = StepRepository(db);
    final p = StepProvider(
      repo,
      accelerometer: () => ctrl.stream,
      clock: () => t,
    );
    await p.load();
    await p.start();
    expect(p.isTracking, true);
    for (var i = 0; i < 20; i++) {
      ctrl.add((x: 0, y: 0, z: 13)); // pico
      await Future<void>.delayed(Duration.zero);
      t = t.add(const Duration(milliseconds: 400));
      ctrl.add((x: 0, y: 0, z: 9.8)); // rearma
      await Future<void>.delayed(Duration.zero);
    }
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(p.todaySteps, 20);
    expect((await repo.getForDay('2026-05-04'))?.steps, 20);
    // cambio de día
    t = DateTime(2026, 5, 5, 8);
    ctrl.add((x: 0, y: 0, z: 13));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(p.todaySteps, 1);
    await p.stop();
    expect(p.isTracking, false);
    await ctrl.close();
  });

  test('StepProvider: error del stream => no soportado', () async {
    final ctrl = StreamController<({double x, double y, double z})>();
    final p = StepProvider(
      StepRepository(db),
      accelerometer: () => ctrl.stream,
    );
    await p.load();
    await p.start();
    ctrl.addError(UnsupportedError('no sensor'));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(p.isSupported, false);
    expect(p.isTracking, false);
    await ctrl.close();
  });

  test('ChallengeProvider.progressFor', () async {
    final act = ActivityProvider(ActivityRepository(db));
    final hyd = HydrationProvider(WaterRepository(db));
    final steps = StepProvider(
      StepRepository(db),
      accelerometer: () => const Stream.empty(),
    );
    final ch = ChallengeProvider(ChallengeRepository(db));
    await Future.wait([act.load(), hyd.load(), steps.load(), ch.load()]);
    final now = DateTime.now();
    final week = DateUtilsX.startOfWeek(now);
    await act.add(
      Activity(
        title: 'a',
        category: 'Cardio',
        durationMinutes: 30,
        calories: 200,
        date: week.add(const Duration(hours: 8)),
      ),
    );
    await act.add(
      Activity(
        title: 'b',
        category: 'Cardio',
        durationMinutes: 20,
        calories: 100,
        date: week.subtract(const Duration(days: 1)),
      ),
    );
    await hyd.add(
      WaterEntry(amountMl: 1500, date: week.add(const Duration(hours: 9))),
    );
    await steps.addManualSteps(500);

    double value(ChallengeType t) => ch.progressFor(
      Challenge(
        title: 'x',
        type: t,
        target: 1,
        weekStart: week,
        createdAt: now,
      ),
      activities: act,
      hydration: hyd,
      steps: steps,
    );

    expect(value(ChallengeType.workouts), 1);
    expect(value(ChallengeType.minutes), 30);
    expect(value(ChallengeType.calories), 200);
    expect(value(ChallengeType.water), 1.5);
    expect(value(ChallengeType.steps), 500);

    await ch.add(
      Challenge(
        title: 'c',
        type: ChallengeType.steps,
        target: 10,
        weekStart: week,
        createdAt: now,
      ),
    );
    await ch.add(
      Challenge(
        title: 'old',
        type: ChallengeType.steps,
        target: 10,
        weekStart: DateTime(week.year, week.month, week.day - 7),
        createdAt: now,
      ),
    );
    expect(ch.currentWeekChallenges.length, 1);
    expect(ch.pastChallenges.length, 1);
  });
}
