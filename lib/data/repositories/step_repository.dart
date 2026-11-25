import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../models/step_record.dart';

/// Acceso a la tabla `step_records`.
class StepRepository {
  /// Crea el repositorio.
  const StepRepository(this._db);

  final AppDatabase _db;

  /// Todos los registros (día descendente).
  Future<List<StepRecord>> getAll() async {
    final db = await _db.database;
    final rows = await db.query('step_records', orderBy: 'day DESC');
    return rows.map(StepRecord.fromMap).toList();
  }

  /// Registro del día [dayKey] ('yyyy-MM-dd') o null.
  Future<StepRecord?> getForDay(String dayKey) async {
    final db = await _db.database;
    final rows = await db.query(
      'step_records',
      where: 'day = ?',
      whereArgs: [dayKey],
    );
    return rows.isEmpty ? null : StepRecord.fromMap(rows.first);
  }

  /// Inserta o reemplaza el registro de su día.
  Future<void> upsert(StepRecord r) async {
    final db = await _db.database;
    await db.insert('step_records', {
      'day': r.day,
      'steps': r.steps,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Registros con `fromKey <= day <= toKey`.
  Future<List<StepRecord>> getInRange(String fromKey, String toKey) async {
    final db = await _db.database;
    final rows = await db.query(
      'step_records',
      where: 'day >= ? AND day <= ?',
      whereArgs: [fromKey, toKey],
      orderBy: 'day DESC',
    );
    return rows.map(StepRecord.fromMap).toList();
  }
}
