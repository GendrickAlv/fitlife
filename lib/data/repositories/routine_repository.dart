import '../database/app_database.dart';
import '../models/routine.dart';

/// Acceso a la tabla `routines`.
class RoutineRepository {
  /// Crea el repositorio.
  const RoutineRepository(this._db);

  final AppDatabase _db;

  /// Todas las rutinas (más recientes primero).
  Future<List<Routine>> getAll() async {
    final db = await _db.database;
    final rows = await db.query(
      'routines',
      orderBy: 'created_at DESC, id DESC',
    );
    return rows.map(Routine.fromMap).toList();
  }

  /// Rutina por [id] o null.
  Future<Routine?> getById(int id) async {
    final db = await _db.database;
    final rows = await db.query('routines', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : Routine.fromMap(rows.first);
  }

  /// Inserta y devuelve el id.
  Future<int> insert(Routine routine) async {
    final db = await _db.database;
    return db.insert('routines', routine.toMap()..remove('id'));
  }

  /// Actualiza (requiere id).
  Future<void> update(Routine routine) async {
    final db = await _db.database;
    await db.update(
      'routines',
      routine.toMap(),
      where: 'id = ?',
      whereArgs: [routine.id],
    );
  }

  /// Elimina por [id].
  Future<void> delete(int id) async {
    final db = await _db.database;
    await db.delete('routines', where: 'id = ?', whereArgs: [id]);
  }

  /// Invierte el favorito de la rutina [id].
  Future<void> toggleFavorite(int id) async {
    final db = await _db.database;
    await db.rawUpdate(
      'UPDATE routines SET is_favorite = 1 - is_favorite WHERE id = ?',
      [id],
    );
  }
}
