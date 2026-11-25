import 'package:fitlife/core/constants.dart';
import 'package:fitlife/data/models/activity.dart';
import 'package:fitlife/data/models/challenge.dart';
import 'package:fitlife/data/models/routine.dart';
import 'package:fitlife/data/models/step_record.dart';
import 'package:fitlife/data/models/user_profile.dart';
import 'package:fitlife/data/models/water_entry.dart';
import 'package:fitlife/data/models/weight_entry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  final date = DateTime(2026, 3, 4, 10, 30);

  test('Routine roundtrip', () {
    final r = Routine(
      id: 3,
      name: 'A',
      category: 'Fuerza',
      difficulty: 'Avanzado',
      durationMinutes: 40,
      estimatedCalories: 300,
      isFavorite: true,
      createdAt: date,
      exercises: const [
        Exercise(name: 'x', sets: 3, reps: 10, weightKg: 12.5, restSeconds: 30),
        Exercise(name: 'y', sets: 1, reps: 1),
      ],
    );
    final back = Routine.fromMap(r.toMap());
    expect(back.id, 3);
    expect(back.isFavorite, true);
    expect(back.exercises, r.exercises);
    expect(back.createdAt, date);
    expect(r.copyWith(name: 'B').name, 'B');
  });

  test('Activity roundtrip', () {
    final a = Activity(
      id: 1,
      routineId: 2,
      title: 't',
      category: 'Yoga',
      durationMinutes: 20,
      calories: 100,
      date: date,
      notes: 'n',
      feeling: 5,
    );
    final b = Activity.fromMap(a.toMap());
    expect(b.toMap(), a.toMap());
  });

  test('Weight, Water, Step roundtrip', () {
    final w = WeightEntry(id: 1, weightKg: 70.5, date: date, note: 'x');
    expect(WeightEntry.fromMap(w.toMap()).toMap(), w.toMap());
    final h = WaterEntry(id: 1, amountMl: 250, date: date);
    expect(WaterEntry.fromMap(h.toMap()).toMap(), h.toMap());
    const s = StepRecord(id: 1, day: '2026-03-04', steps: 900);
    expect(StepRecord.fromMap(s.toMap()).toMap(), s.toMap());
  });

  test('Challenge roundtrip', () {
    final c = Challenge(
      id: 1,
      title: 'c',
      type: ChallengeType.water,
      target: 14,
      weekStart: DateTime(2026, 3, 2),
      createdAt: date,
    );
    final b = Challenge.fromMap(c.toMap());
    expect(b.type, ChallengeType.water);
    expect(b.target, 14);
  });

  test('UserProfile roundtrip y defaults', () {
    const p = UserProfile(
      name: 'Ana',
      goalWeightKg: 60,
      themeMode: ThemeMode.dark,
    );
    final b = UserProfile.fromMap(p.toMap());
    expect(b.name, 'Ana');
    expect(b.goalWeightKg, 60);
    expect(b.themeMode, ThemeMode.dark);
    const d = UserProfile();
    expect(d.name, 'Atleta');
    expect(d.dailyWaterGoalMl, 2500);
    expect(d.copyWith(clearGoalWeight: true).goalWeightKg, isNull);
  });
}
