import '../database/app_database.dart';
import '../models/challenge.dart';

/// Acceso a la tabla `challenges`.
class ChallengeRepository {
  /// Crea el repositorio.
  const ChallengeRepository(this._db);

  final AppDatabase _db;

  /// Todos los desafíos (semana descendente).
  Future<List<Challenge>> getAll() async {
    final db = await _db.database;
    final rows = await db.query(
      'challenges',
      orderBy: 'week_start DESC, id DESC',
    );
    return rows.map(Challenge.fromMap).toList();
  }

  /// Desafíos de la semana que empieza en [weekStart].
  Future<List<Challenge>> getForWeek(DateTime weekStart) async {
    final db = await _db.database;
    final rows = await db.query(
      'challenges',
      where: 'week_start = ?',
      whereArgs: [weekStart.millisecondsSinceEpoch],
      orderBy: 'id DESC',
    );
    return rows.map(Challenge.fromMap).toList();
  }

  /// Inserta y devuelve el id.
  Future<int> insert(Challenge c) async {
    final db = await _db.database;
    return db.insert('challenges', c.toMap()..remove('id'));
  }

  /// Actualiza (requiere id).
  Future<void> update(Challenge c) async {
    final db = await _db.database;
    await db.update(
      'challenges',
      c.toMap(),
      where: 'id = ?',
      whereArgs: [c.id],
    );
  }

  /// Elimina por [id].
  Future<void> delete(int id) async {
    final db = await _db.database;
    await db.delete('challenges', where: 'id = ?', whereArgs: [id]);
  }
}
