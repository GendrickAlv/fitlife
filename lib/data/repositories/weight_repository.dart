import '../database/app_database.dart';
import '../models/weight_entry.dart';

/// Acceso a la tabla `weight_entries`.
class WeightRepository {
  /// Crea el repositorio.
  const WeightRepository(this._db);

  final AppDatabase _db;

  /// Todos los registros (fecha descendente).
  Future<List<WeightEntry>> getAll() async {
    final db = await _db.database;
    final rows = await db.query(
      'weight_entries',
      orderBy: 'date DESC, id DESC',
    );
    return rows.map(WeightEntry.fromMap).toList();
  }

  /// Inserta y devuelve el id.
  Future<int> insert(WeightEntry e) async {
    final db = await _db.database;
    return db.insert('weight_entries', e.toMap()..remove('id'));
  }

  /// Actualiza (requiere id).
  Future<void> update(WeightEntry e) async {
    final db = await _db.database;
    await db.update(
      'weight_entries',
      e.toMap(),
      where: 'id = ?',
      whereArgs: [e.id],
    );
  }

  /// Elimina por [id].
  Future<void> delete(int id) async {
    final db = await _db.database;
    await db.delete('weight_entries', where: 'id = ?', whereArgs: [id]);
  }
}
