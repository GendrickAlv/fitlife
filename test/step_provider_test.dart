import 'dart:async';

import 'package:fitlife/data/database/app_database.dart';
import 'package:fitlife/data/repositories/step_repository.dart';
import 'package:fitlife/providers/step_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

typedef _Sample = ({double x, double y, double z});

void main() {
  late AppDatabase db;
  const timeout = Duration(milliseconds: 50);
  const wait = Duration(milliseconds: 150);

  setUpAll(sqfliteFfiInit);
  setUp(() async {
    db = AppDatabase.forTesting();
    await db.database;
  });
  tearDown(() => db.close());

  StepProvider build(Stream<_Sample> Function() stream) => StepProvider(
    StepRepository(db),
    accelerometer: stream,
    sensorTimeout: timeout,
  );

  test('sin muestras: tras el timeout queda no soportado', () async {
    final ctrl = StreamController<_Sample>();
    final p = build(() => ctrl.stream);
    await p.load();
    await p.start();
    expect(p.isTracking, isTrue);
    expect(p.isSupported, isTrue);

    await Future<void>.delayed(wait);
    expect(p.isTracking, isFalse);
    expect(p.isSupported, isFalse);
    expect(ctrl.hasListener, isFalse);
    await ctrl.close();
    p.dispose();
  });

  test('solo muestras (0,0,0): no cuentan como datos reales', () async {
    final ctrl = StreamController<_Sample>();
    final p = build(() => ctrl.stream);
    await p.load();
    await p.start();
    ctrl.add((x: 0, y: 0, z: 0));
    await Future<void>.delayed(wait);
    expect(p.isTracking, isFalse);
    expect(p.isSupported, isFalse);
    expect(p.todaySteps, 0);
    await ctrl.close();
    p.dispose();
  });

  test('muestras reales cancelan el watchdog y cuentan pasos', () async {
    final ctrl = StreamController<_Sample>();
    var t = DateTime(2026, 5, 4, 10);
    final p = StepProvider(
      StepRepository(db),
      accelerometer: () => ctrl.stream,
      clock: () => t,
      sensorTimeout: timeout,
    );
    await p.load();
    await p.start();
    ctrl.add((x: 0, y: 0, z: 9.8));
    await Future<void>.delayed(Duration.zero);
    ctrl.add((x: 0, y: 0, z: 13));
    await Future<void>.delayed(Duration.zero);
    t = t.add(const Duration(milliseconds: 400));

    await Future<void>.delayed(wait);
    expect(p.isTracking, isTrue);
    expect(p.isSupported, isTrue);
    expect(p.todaySteps, 1);
    await p.stop();
    await ctrl.close();
    p.dispose();
  });

  test('stop() cancela el watchdog', () async {
    final ctrl = StreamController<_Sample>();
    final p = build(() => ctrl.stream);
    await p.load();
    await p.start();
    await p.stop();
    await Future<void>.delayed(wait);
    expect(p.isSupported, isTrue);
    expect(p.isTracking, isFalse);
    await ctrl.close();
    p.dispose();
  });
}
