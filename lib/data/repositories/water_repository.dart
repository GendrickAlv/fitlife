import '../database/app_database.dart';
import '../models/water_entry.dart';

/// Acceso a la tabla `water_entries`.
class WaterRepository {
  /// Crea el repositorio.
  const WaterRepository(this._db);

  final AppDatabase _db;

  /// Todos los registros (fecha descendente).
  Future<List<WaterEntry>> getAll() async {
    final db = await _db.database;
    final rows = await db.query('water_entries', orderBy: 'date DESC, id DESC');
    return rows.map(WaterEntry.fromMap).toList();
  }

  /// Registros con `from <= date < to`.
  Future<List<WaterEntry>> getInRange(DateTime from, DateTime to) async {
    final db = await _db.database;
    final rows = await db.query(
      'water_entries',
      where: 'date >= ? AND date < ?',
      whereArgs: [from.millisecondsSinceEpoch, to.millisecondsSinceEpoch],
      orderBy: 'date DESC, id DESC',
    );
    return rows.map(WaterEntry.fromMap).toList();
  }

  /// Inserta y devuelve el id.
  Future<int> insert(WaterEntry e) async {
    final db = await _db.database;
    return db.insert('water_entries', e.toMap()..remove('id'));
  }

  /// Actualiza (requiere id).
  Future<void> update(WaterEntry e) async {
    final db = await _db.database;
    await db.update(
      'water_entries',
      e.toMap(),
      where: 'id = ?',
      whereArgs: [e.id],
    );
  }

  /// Elimina por [id].
  Future<void> delete(int id) async {
    final db = await _db.database;
    await db.delete('water_entries', where: 'id = ?', whereArgs: [id]);
  }
}
