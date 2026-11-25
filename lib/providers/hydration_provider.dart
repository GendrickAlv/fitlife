import 'package:flutter/foundation.dart';

import '../core/utils/date_utils.dart';
import '../data/models/water_entry.dart';
import '../data/repositories/water_repository.dart';

/// Estado de la hidratación.
class HydrationProvider extends ChangeNotifier {
  /// Crea el provider con su [repository].
  HydrationProvider(this._repository);

  final WaterRepository _repository;
  List<WaterEntry> _entries = const [];
  bool _isLoading = false;
  String? _error;

  /// Registros (fecha descendente).
  List<WaterEntry> get entries => _entries;

  /// Indica si está cargando.
  bool get isLoading => _isLoading;

  /// Último error.
  String? get error => _error;

  /// Registros de hoy.
  List<WaterEntry> get todayEntries {
    final now = DateTime.now();
    return _entries.where((e) => DateUtilsX.isSameDay(e.date, now)).toList();
  }

  /// Mililitros bebidos hoy.
  int get todayTotalMl => totalForDay(DateTime.now());

  /// Mililitros bebidos el día [day].
  int totalForDay(DateTime day) => _entries
      .where((e) => DateUtilsX.isSameDay(e.date, day))
      .fold(0, (sum, e) => sum + e.amountMl);

  /// Mililitros en `[from, to)`.
  int totalInRange(DateTime from, DateTime to) => _entries
      .where((e) => !e.date.isBefore(from) && e.date.isBefore(to))
      .fold(0, (sum, e) => sum + e.amountMl);

  /// Totales por día de los últimos [lastNDays] días (el más antiguo primero).
  Map<DateTime, int> dailyTotals(int lastNDays) => {
    for (final d in DateUtilsX.lastDays(lastNDays)) d: totalForDay(d),
  };

  /// Carga desde la base de datos.
  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _entries = await _repository.getAll();
    } catch (e) {
      _error = 'No se pudo cargar la hidratación: $e';
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
  Future<void> add(WaterEntry entry) => _run(() => _repository.insert(entry));

  /// Actualiza un registro.
  Future<void> update(WaterEntry entry) =>
      _run(() => _repository.update(entry));

  /// Elimina un registro.
  Future<void> delete(int id) => _run(() => _repository.delete(id));
}
