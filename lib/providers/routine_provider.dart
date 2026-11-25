import 'package:flutter/foundation.dart';

import '../data/models/routine.dart';
import '../data/repositories/routine_repository.dart';

/// Estado de las rutinas.
class RoutineProvider extends ChangeNotifier {
  /// Crea el provider con su [repository].
  RoutineProvider(this._repository);

  final RoutineRepository _repository;
  List<Routine> _routines = const [];
  bool _isLoading = false;
  String? _error;

  /// Todas las rutinas.
  List<Routine> get routines => _routines;

  /// Rutinas favoritas.
  List<Routine> get favorites =>
      _routines.where((r) => r.isFavorite).toList(growable: false);

  /// Indica si está cargando.
  bool get isLoading => _isLoading;

  /// Último error.
  String? get error => _error;

  /// Rutinas de una categoría (todas si [category] es null).
  List<Routine> byCategory(String? category) => category == null
      ? _routines
      : _routines.where((r) => r.category == category).toList();

  /// Busca una rutina por id.
  Routine? byId(int id) {
    for (final r in _routines) {
      if (r.id == id) return r;
    }
    return null;
  }

  /// Carga desde la base de datos.
  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _routines = await _repository.getAll();
    } catch (e) {
      _error = 'No se pudieron cargar las rutinas: $e';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _run(Future<void> Function() op) async {
    try {
      _error = null;
      await op();
      _routines = await _repository.getAll();
    } catch (e) {
      _error = 'Error al guardar: $e';
    }
    notifyListeners();
  }

  /// Añade una rutina.
  Future<void> add(Routine routine) => _run(() => _repository.insert(routine));

  /// Actualiza una rutina.
  Future<void> update(Routine routine) =>
      _run(() => _repository.update(routine));

  /// Elimina una rutina.
  Future<void> delete(int id) => _run(() => _repository.delete(id));

  /// Alterna favorito.
  Future<void> toggleFavorite(int id) =>
      _run(() => _repository.toggleFavorite(id));
}
