import '../database/app_database.dart';
import '../models/activity.dart';

/// Acceso a la tabla `activities`.
class ActivityRepository {
  /// Crea el repositorio.
  const ActivityRepository(this._db);

  final AppDatabase _db;

  /// Todas las actividades (fecha descendente).
  Future<List<Activity>> getAll() async {
    final db = await _db.database;
    final rows = await db.query('activities', orderBy: 'date DESC, id DESC');
    return rows.map(Activity.fromMap).toList();
  }

  /// Actividades con `from <= date < to`.
  Future<List<Activity>> getInRange(DateTime from, DateTime to) async {
    final db = await _db.database;
    final rows = await db.query(
      'activities',
      where: 'date >= ? AND date < ?',
      whereArgs: [from.millisecondsSinceEpoch, to.millisecondsSinceEpoch],
      orderBy: 'date DESC, id DESC',
    );
    return rows.map(Activity.fromMap).toList();
  }

  /// Inserta y devuelve el id.
  Future<int> insert(Activity a) async {
    final db = await _db.database;
    return db.insert('activities', a.toMap()..remove('id'));
  }

  /// Actualiza (requiere id).
  Future<void> update(Activity a) async {
    final db = await _db.database;
    await db.update(
      'activities',
      a.toMap(),
      where: 'id = ?',
      whereArgs: [a.id],
    );
  }

  /// Elimina por [id].
  Future<void> delete(int id) async {
    final db = await _db.database;
    await db.delete('activities', where: 'id = ?', whereArgs: [id]);
  }
}
