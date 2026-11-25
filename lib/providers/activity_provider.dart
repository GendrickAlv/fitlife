import 'package:flutter/foundation.dart';

import '../core/utils/date_utils.dart';
import '../data/models/activity.dart';
import '../data/repositories/activity_repository.dart';

/// Estado del historial de actividades.
class ActivityProvider extends ChangeNotifier {
  /// Crea el provider con su [repository].
  ActivityProvider(this._repository);

  final ActivityRepository _repository;
  List<Activity> _activities = const [];
  bool _isLoading = false;
  String? _error;

  /// Todas las actividades (más recientes primero).
  List<Activity> get activities => _activities;

  /// Indica si está cargando.
  bool get isLoading => _isLoading;

  /// Último error.
  String? get error => _error;

  /// Actividades de hoy.
  List<Activity> get todayActivities {
    final now = DateTime.now();
    return _activities.where((a) => DateUtilsX.isSameDay(a.date, now)).toList();
  }

  /// Actividades de la semana que empieza en [weekStart].
  List<Activity> activitiesInWeek(DateTime weekStart) {
    final from = DateUtilsX.startOfDay(weekStart);
    final to = DateTime(from.year, from.month, from.day + 7);
    return _activities
        .where((a) => !a.date.isBefore(from) && a.date.isBefore(to))
        .toList();
  }

  /// Minutos por día en los últimos [lastNDays] días (el más antiguo primero).
  Map<DateTime, int> minutesPerDay(int lastNDays) =>
      _perDay(lastNDays, (a) => a.durationMinutes);

  /// Calorías por día en los últimos [lastNDays] días.
  Map<DateTime, int> caloriesPerDay(int lastNDays) =>
      _perDay(lastNDays, (a) => a.calories);

  Map<DateTime, int> _perDay(int n, int Function(Activity) value) {
    final days = DateUtilsX.lastDays(n);
    final result = {for (final d in days) d: 0};
    for (final a in _activities) {
      final key = DateUtilsX.startOfDay(a.date);
      if (result.containsKey(key)) result[key] = result[key]! + value(a);
    }
    return result;
  }

  /// Número total de sesiones.
  int get totalSessions => _activities.length;

  /// Minutos totales.
  int get totalMinutes =>
      _activities.fold(0, (sum, a) => sum + a.durationMinutes);

  /// Calorías totales.
  int get totalCalories => _activities.fold(0, (sum, a) => sum + a.calories);

  /// Carga desde la base de datos.
  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _activities = await _repository.getAll();
    } catch (e) {
      _error = 'No se pudo cargar el historial: $e';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _run(Future<void> Function() op) async {
    try {
      _error = null;
      await op();
      _activities = await _repository.getAll();
    } catch (e) {
      _error = 'Error al guardar: $e';
    }
    notifyListeners();
  }

  /// Añade una actividad.
  Future<void> add(Activity activity) =>
      _run(() => _repository.insert(activity));

  /// Actualiza una actividad.
  Future<void> update(Activity activity) =>
      _run(() => _repository.update(activity));

  /// Elimina una actividad.
  Future<void> delete(int id) => _run(() => _repository.delete(id));
}
