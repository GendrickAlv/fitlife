import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/routine.dart';

/// Acceso singleton a la base de datos SQLite (esquema v1).
class AppDatabase {
  AppDatabase._(this._path, {this.seed = true});

  /// Base de datos en memoria para tests (usa sqflite_common_ffi).
  ///
  /// Requiere haber llamado antes a `sqfliteFfiInit()`.
  factory AppDatabase.forTesting({bool seed = false}) =>
      AppDatabase._(inMemoryDatabasePath, seed: seed);

  /// Instancia global de la aplicación.
  static final AppDatabase instance = AppDatabase._(null);

  static const _dbName = 'fitlife.db';
  static const _version = 1;

  final String? _path;

  /// Si se insertan las rutinas de ejemplo al crear la base.
  final bool seed;
  Database? _db;
  Future<Database>? _opening;

  /// Configura `databaseFactory` para escritorio (Windows/Linux/macOS).
  static void initFactoryForPlatform() {
    if (kIsWeb) return;
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  /// Base de datos abierta (se abre de forma perezosa).
  Future<Database> get database {
    final existing = _db;
    if (existing != null) return Future.value(existing);
    return _opening ??= _open().then((db) => _db = db);
  }

  /// Cierra la base de datos.
  Future<void> close() async {
    final db = _db;
    _db = null;
    _opening = null;
    await db?.close();
  }

  Future<Database> _open() async {
    final path = _path ?? p.join(await getDatabasesPath(), _dbName);
    final factory = _path == inMemoryDatabasePath
        ? databaseFactoryFfi
        : databaseFactory;
    return factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: _version,
        singleInstance: _path != inMemoryDatabasePath,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: _onCreate,
      ),
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch()
      ..execute('''
CREATE TABLE routines (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  category TEXT NOT NULL,
  difficulty TEXT NOT NULL,
  duration_minutes INTEGER NOT NULL,
  estimated_calories INTEGER NOT NULL,
  exercises TEXT NOT NULL,
  is_favorite INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL
)''')
      ..execute('''
CREATE TABLE activities (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  routine_id INTEGER REFERENCES routines(id) ON DELETE SET NULL,
  title TEXT NOT NULL,
  category TEXT NOT NULL,
  duration_minutes INTEGER NOT NULL,
  calories INTEGER NOT NULL,
  date INTEGER NOT NULL,
  notes TEXT NOT NULL DEFAULT '',
  feeling INTEGER NOT NULL DEFAULT 3
)''')
      ..execute('''
CREATE TABLE weight_entries (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  weight_kg REAL NOT NULL,
  date INTEGER NOT NULL,
  note TEXT NOT NULL DEFAULT ''
)''')
      ..execute('''
CREATE TABLE water_entries (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  amount_ml INTEGER NOT NULL,
  date INTEGER NOT NULL
)''')
      ..execute('''
CREATE TABLE challenges (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  type TEXT NOT NULL,
  target REAL NOT NULL,
  week_start INTEGER NOT NULL,
  created_at INTEGER NOT NULL
)''')
      ..execute('''
CREATE TABLE step_records (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  day TEXT NOT NULL UNIQUE,
  steps INTEGER NOT NULL
)''')
      ..execute('CREATE INDEX idx_activities_date ON activities(date)')
      ..execute('CREATE INDEX idx_weight_date ON weight_entries(date)')
      ..execute('CREATE INDEX idx_water_date ON water_entries(date)')
      ..execute('CREATE INDEX idx_challenges_week ON challenges(week_start)');
    await batch.commit(noResult: true);

    if (seed) {
      final now = DateTime.now();
      for (final r in _sampleRoutines(now)) {
        await db.insert('routines', r.toMap());
      }
    }
  }

  static List<Routine> _sampleRoutines(DateTime now) => [
    Routine(
      name: 'Full body para principiantes',
      description: 'Rutina de cuerpo completo con ejercicios básicos.',
      category: 'Fuerza',
      difficulty: 'Principiante',
      durationMinutes: 45,
      estimatedCalories: 320,
      createdAt: now,
      exercises: const [
        Exercise(name: 'Sentadillas', sets: 3, reps: 12, restSeconds: 60),
        Exercise(name: 'Flexiones', sets: 3, reps: 10, restSeconds: 60),
        Exercise(
          name: 'Remo con mancuerna',
          sets: 3,
          reps: 12,
          weightKg: 8,
          restSeconds: 60,
        ),
        Exercise(name: 'Plancha', sets: 3, reps: 30, restSeconds: 45),
      ],
    ),
    Routine(
      name: 'Cardio matinal',
      description: 'Sesión suave para activar el cuerpo por la mañana.',
      category: 'Cardio',
      difficulty: 'Intermedio',
      durationMinutes: 30,
      estimatedCalories: 280,
      createdAt: now,
      exercises: const [
        Exercise(name: 'Trote suave (minutos)', sets: 1, reps: 15),
        Exercise(name: 'Jumping jacks', sets: 3, reps: 30, restSeconds: 30),
        Exercise(name: 'Rodillas al pecho', sets: 3, reps: 20, restSeconds: 30),
        Exercise(name: 'Estiramiento final (minutos)', sets: 1, reps: 5),
      ],
    ),
    Routine(
      name: 'HIIT quema grasa',
      description: 'Intervalos de alta intensidad de 20 minutos.',
      category: 'HIIT',
      difficulty: 'Avanzado',
      durationMinutes: 20,
      estimatedCalories: 250,
      createdAt: now,
      exercises: const [
        Exercise(name: 'Burpees', sets: 4, reps: 12, restSeconds: 30),
        Exercise(name: 'Mountain climbers', sets: 4, reps: 40, restSeconds: 30),
        Exercise(
          name: 'Sentadilla con salto',
          sets: 4,
          reps: 15,
          restSeconds: 30,
        ),
        Exercise(name: 'Skipping', sets: 4, reps: 40, restSeconds: 30),
      ],
    ),
    Routine(
      name: 'Yoga y movilidad',
      description: 'Flujo relajante para ganar flexibilidad.',
      category: 'Yoga',
      difficulty: 'Principiante',
      durationMinutes: 35,
      estimatedCalories: 140,
      createdAt: now,
      exercises: const [
        Exercise(name: 'Saludo al sol', sets: 5, reps: 1),
        Exercise(
          name: 'Postura del guerrero',
          sets: 2,
          reps: 1,
          restSeconds: 20,
        ),
        Exercise(name: 'Perro boca abajo', sets: 3, reps: 1, restSeconds: 20),
        Exercise(name: 'Postura del niño', sets: 1, reps: 1),
      ],
    ),
  ];
}
