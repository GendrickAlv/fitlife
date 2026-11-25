import 'package:flutter/foundation.dart';

import '../core/constants.dart';
import '../core/utils/date_utils.dart';
import '../data/models/challenge.dart';
import '../data/repositories/challenge_repository.dart';
import 'activity_provider.dart';
import 'hydration_provider.dart';
import 'step_provider.dart';

/// Estado de los desafíos semanales.
class ChallengeProvider extends ChangeNotifier {
  /// Crea el provider con su [repository].
  ChallengeProvider(this._repository);

  final ChallengeRepository _repository;
  List<Challenge> _challenges = const [];
  bool _isLoading = false;
  String? _error;

  /// Todos los desafíos (semana descendente).
  List<Challenge> get challenges => _challenges;

  /// Indica si está cargando.
  bool get isLoading => _isLoading;

  /// Último error.
  String? get error => _error;

  /// Desafíos de la semana actual.
  List<Challenge> get currentWeekChallenges {
    final week = DateUtilsX.startOfWeek(DateTime.now());
    return _challenges
        .where((c) => DateUtilsX.isSameDay(c.weekStart, week))
        .toList();
  }

  /// Desafíos de semanas anteriores.
  List<Challenge> get pastChallenges {
    final week = DateUtilsX.startOfWeek(DateTime.now());
    return _challenges.where((c) => c.weekStart.isBefore(week)).toList();
  }

  /// Valor actual del desafío [c] según los datos de su semana.
  ///
  /// workouts = nº de sesiones, minutes = suma, calories = suma,
  /// water = litros, steps = pasos registrados + conteo en vivo de hoy.
  double progressFor(
    Challenge c, {
    required ActivityProvider activities,
    required HydrationProvider hydration,
    required StepProvider steps,
  }) {
    final from = DateUtilsX.startOfDay(c.weekStart);
    final to = DateTime(from.year, from.month, from.day + 7);
    final week = activities.activitiesInWeek(from);
    return switch (c.type) {
      ChallengeType.workouts => week.length.toDouble(),
      ChallengeType.minutes =>
        week.fold<int>(0, (s, a) => s + a.durationMinutes).toDouble(),
      ChallengeType.calories =>
        week.fold<int>(0, (s, a) => s + a.calories).toDouble(),
      ChallengeType.water => hydration.totalInRange(from, to) / 1000,
      ChallengeType.steps => steps.stepsInRange(from, to).toDouble(),
    };
  }

  /// Carga desde la base de datos.
  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _challenges = await _repository.getAll();
    } catch (e) {
      _error = 'No se pudieron cargar los desafíos: $e';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _run(Future<void> Function() op) async {
    try {
      _error = null;
      await op();
      _challenges = await _repository.getAll();
    } catch (e) {
      _error = 'Error al guardar: $e';
    }
    notifyListeners();
  }

  /// Añade un desafío.
  Future<void> add(Challenge challenge) =>
      _run(() => _repository.insert(challenge));

  /// Actualiza un desafío.
  Future<void> update(Challenge challenge) =>
      _run(() => _repository.update(challenge));

  /// Elimina un desafío.
  Future<void> delete(int id) => _run(() => _repository.delete(id));
}
