import 'package:fitlife/core/constants.dart';
import 'package:fitlife/data/database/app_database.dart';
import 'package:fitlife/data/models/activity.dart';
import 'package:fitlife/data/models/challenge.dart';
import 'package:fitlife/data/models/routine.dart';
import 'package:fitlife/data/models/step_record.dart';
import 'package:fitlife/data/models/water_entry.dart';
import 'package:fitlife/data/models/weight_entry.dart';
import 'package:fitlife/data/repositories/activity_repository.dart';
import 'package:fitlife/data/repositories/challenge_repository.dart';
import 'package:fitlife/data/repositories/routine_repository.dart';
import 'package:fitlife/data/repositories/step_repository.dart';
import 'package:fitlife/data/repositories/water_repository.dart';
import 'package:fitlife/data/repositories/weight_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Routine _routine(String name) => Routine(
  name: name,
  category: 'Cardio',
  difficulty: 'Intermedio',
  durationMinutes: 30,
  estimatedCalories: 200,
  createdAt: DateTime(2026, 1, 1),
  exercises: const [Exercise(name: 'x', sets: 2, reps: 10)],
);

void main() {
  late AppDatabase db;

  setUpAll(sqfliteFfiInit);
  setUp(() async {
    db = AppDatabase.forTesting();
    await db.database;
  });
  tearDown(() => db.close());

  test('seed crea rutinas de ejemplo', () async {
    final seeded = AppDatabase.forTesting(seed: true);
    expect((await RoutineRepository(seeded).getAll()).length, 4);
    await seeded.close();
  });

  test('RoutineRepository CRUD', () async {
    final repo = RoutineRepository(db);
    final id = await repo.insert(_routine('A'));
    expect((await repo.getById(id))?.name, 'A');
    await repo.update((await repo.getById(id))!.copyWith(name: 'B'));
    expect((await repo.getById(id))?.name, 'B');
    await repo.toggleFavorite(id);
    expect((await repo.getById(id))?.isFavorite, true);
    await repo.toggleFavorite(id);
    expect((await repo.getById(id))?.isFavorite, false);
    await repo.delete(id);
    expect(await repo.getAll(), isEmpty);
  });

  test('ActivityRepository CRUD, rango y FK SET NULL', () async {
    final routines = RoutineRepository(db);
    final repo = ActivityRepository(db);
    final rid = await routines.insert(_routine('A'));
    Activity act(DateTime d, {int? routineId}) => Activity(
      routineId: routineId,
      title: 't',
      category: 'Cardio',
      durationMinutes: 10,
      calories: 50,
      date: d,
    );
    final a1 = await repo.insert(act(DateTime(2026, 2, 1), routineId: rid));
    await repo.insert(act(DateTime(2026, 2, 5)));
    final all = await repo.getAll();
    expect(all.first.date, DateTime(2026, 2, 5));
    expect(
      (await repo.getInRange(
        DateTime(2026, 2, 1),
        DateTime(2026, 2, 2),
      )).length,
      1,
    );
    await routines.delete(rid);
    expect((await repo.getAll()).last.routineId, isNull);
    await repo.update((await repo.getAll()).last.copyWith(calories: 99));
    expect((await repo.getAll()).last.calories, 99);
    await repo.delete(a1);
    expect((await repo.getAll()).length, 1);
  });

  test('WeightRepository CRUD', () async {
    final repo = WeightRepository(db);
    final id = await repo.insert(
      WeightEntry(weightKg: 70, date: DateTime(2026, 1, 1)),
    );
    await repo.insert(WeightEntry(weightKg: 71, date: DateTime(2026, 1, 5)));
    expect((await repo.getAll()).first.weightKg, 71);
    await repo.update(
      WeightEntry(id: id, weightKg: 69, date: DateTime(2026, 1, 1)),
    );
    expect((await repo.getAll()).last.weightKg, 69);
    await repo.delete(id);
    expect((await repo.getAll()).length, 1);
  });

  test('WaterRepository CRUD y rango', () async {
    final repo = WaterRepository(db);
    final id = await repo.insert(
      WaterEntry(amountMl: 250, date: DateTime(2026, 1, 1, 9)),
    );
    await repo.insert(WaterEntry(amountMl: 500, date: DateTime(2026, 1, 2, 9)));
    expect(
      (await repo.getInRange(
        DateTime(2026, 1, 1),
        DateTime(2026, 1, 2),
      )).single.amountMl,
      250,
    );
    await repo.update(
      WaterEntry(id: id, amountMl: 300, date: DateTime(2026, 1, 1, 9)),
    );
    expect((await repo.getAll()).last.amountMl, 300);
    await repo.delete(id);
    expect((await repo.getAll()).length, 1);
  });

  test('ChallengeRepository CRUD y semana', () async {
    final repo = ChallengeRepository(db);
    final week = DateTime(2026, 3, 2);
    Challenge ch(DateTime w) => Challenge(
      title: 'c',
      type: ChallengeType.steps,
      target: 1000,
      weekStart: w,
      createdAt: DateTime(2026, 3, 1),
    );
    final id = await repo.insert(ch(week));
    await repo.insert(ch(DateTime(2026, 3, 9)));
    expect((await repo.getForWeek(week)).single.id, id);
    await repo.update((await repo.getForWeek(week)).single.copyWith(target: 5));
    expect((await repo.getForWeek(week)).single.target, 5);
    await repo.delete(id);
    expect((await repo.getAll()).length, 1);
  });

  test('StepRepository upsert', () async {
    final repo = StepRepository(db);
    await repo.upsert(const StepRecord(day: '2026-03-01', steps: 10));
    await repo.upsert(const StepRecord(day: '2026-03-01', steps: 30));
    await repo.upsert(const StepRecord(day: '2026-03-02', steps: 5));
    expect((await repo.getForDay('2026-03-01'))?.steps, 30);
    expect((await repo.getAll()).length, 2);
    expect((await repo.getInRange('2026-03-02', '2026-03-05')).length, 1);
    expect(await repo.getForDay('2000-01-01'), isNull);
  });
}
