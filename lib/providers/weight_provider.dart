import 'package:flutter/foundation.dart';

import '../data/models/weight_entry.dart';
import '../data/repositories/weight_repository.dart';

/// Estado del seguimiento de peso.
class WeightProvider extends ChangeNotifier {
  /// Crea el provider con su [repository].
  WeightProvider(this._repository);

  final WeightRepository _repository;
  List<WeightEntry> _entries = const [];
  bool _isLoading = false;
  String? _error;

  /// Registros (fecha descendente).
  List<WeightEntry> get entries => _entries;

  /// Indica si está cargando.
  bool get isLoading => _isLoading;

  /// Último error.
  String? get error => _error;

  /// Registro más reciente.
  WeightEntry? get latest => _entries.isEmpty ? null : _entries.first;

  /// Registro más antiguo.
  WeightEntry? get first => _entries.isEmpty ? null : _entries.last;

  /// Variación (kg) entre el primer y el último registro; null si hay < 2.
  double? get changeSinceFirst {
    if (_entries.length < 2) return null;
    return _entries.first.weightKg - _entries.last.weightKg;
  }

  /// IMC del peso más reciente para [heightCm]; null si no hay datos.
  double? bmi(double heightCm) {
    final w = latest?.weightKg;
    if (w == null || heightCm <= 0) return null;
    final m = heightCm / 100;
    return w / (m * m);
  }

  /// Carga desde la base de datos.
  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _entries = await _repository.getAll();
    } catch (e) {
      _error = 'No se pudo cargar el peso: $e';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _run(Future<void> Function() op) async {
    try {
      _error = null;
      await op();
      _entries = await _repository.getAll();
    } catch (e) {
      _error = 'Error al guardar: $e';
    }
    notifyListeners();
  }

  /// Añade un registro.
  Future<void> add(WeightEntry entry) => _run(() => _repository.insert(entry));

  /// Actualiza un registro.
  Future<void> update(WeightEntry entry) =>
      _run(() => _repository.update(entry));

  /// Elimina un registro.
  Future<void> delete(int id) => _run(() => _repository.delete(id));
}
