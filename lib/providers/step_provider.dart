import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../core/utils/date_utils.dart';
import '../data/models/step_record.dart';
import '../data/repositories/step_repository.dart';

/// Magnitud de aceleración (x, y, z) en m/s².
typedef AccelerationStream =
    Stream<({double x, double y, double z})> Function();

/// Contador de pasos con acelerómetro y detección de picos.
class StepProvider extends ChangeNotifier {
  /// Crea el provider. [accelerometer] y [clock] permiten inyectar fakes.
  StepProvider(
    this._repository, {
    AccelerationStream? accelerometer,
    DateTime Function()? clock,
  }) : _accelerometer = accelerometer ?? _defaultStream,
       _clock = clock ?? DateTime.now;

  /// Umbral de magnitud para detectar un paso (m/s²).
  static const double stepThreshold = 11.5;

  /// Umbral por debajo del cual se rearma el detector.
  static const double rearmThreshold = 10.5;

  /// Intervalo mínimo entre pasos.
  static const Duration minStepInterval = Duration(milliseconds: 300);

  /// Pasos entre persistencias automáticas.
  static const int persistEvery = 20;

  final StepRepository _repository;
  final AccelerationStream _accelerometer;
  final DateTime Function() _clock;

  StreamSubscription<({double x, double y, double z})>? _sub;
  List<StepRecord> _history = const [];
  int _todaySteps = 0;
  String _currentDay = '';
  bool _isTracking = false;
  bool _isSupported = true;
  bool _isLoading = false;
  bool _armed = true;
  DateTime? _lastStepAt;
  String? _error;

  static Stream<({double x, double y, double z})> _defaultStream() =>
      accelerometerEventStream().map((e) => (x: e.x, y: e.y, z: e.z));

  /// Pasos de hoy (en vivo).
  int get todaySteps => _todaySteps;

  /// Si se está escuchando el sensor.
  bool get isTracking => _isTracking;

  /// Si el dispositivo tiene acelerómetro utilizable.
  bool get isSupported => _isSupported;

  /// Indica si está cargando.
  bool get isLoading => _isLoading;

  /// Último error.
  String? get error => _error;

  /// Historial persistido (día descendente).
  List<StepRecord> get history => _history;

  /// Suma de pasos en `[from, to)` incluyendo el conteo en vivo de hoy.
  int stepsInRange(DateTime from, DateTime to) {
    final fromKey = DateUtilsX.dayKey(from);
    final toKey = DateUtilsX.dayKey(to);
    var total = 0;
    var todayCovered = false;
    for (final r in _history) {
      if (r.day.compareTo(fromKey) >= 0 && r.day.compareTo(toKey) < 0) {
        if (r.day == _currentDay) {
          todayCovered = true;
          total += math.max(r.steps, _todaySteps);
        } else {
          total += r.steps;
        }
      }
    }
    if (!todayCovered &&
        _currentDay.compareTo(fromKey) >= 0 &&
        _currentDay.compareTo(toKey) < 0) {
      total += _todaySteps;
    }
    return total;
  }

  /// Carga historial y pasos de hoy.
  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _currentDay = DateUtilsX.dayKey(_clock());
      _history = await _repository.getAll();
      final today = await _repository.getForDay(_currentDay);
      _todaySteps = today?.steps ?? 0;
    } catch (e) {
      _error = 'No se pudieron cargar los pasos: $e';
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Empieza a contar pasos.
  Future<void> start() async {
    if (_isTracking) return;
    try {
      _sub = _accelerometer().listen(
        _onEvent,
        onError: (Object e) {
          _isSupported = false;
          _isTracking = false;
          _sub?.cancel();
          _sub = null;
          notifyListeners();
        },
        cancelOnError: true,
      );
      _isTracking = true;
      _isSupported = true;
    } catch (_) {
      _isSupported = false;
      _isTracking = false;
    }
    notifyListeners();
  }

  /// Detiene el conteo y persiste.
  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    _isTracking = false;
    await _persist();
    notifyListeners();
  }

  /// Suma un paso manualmente (útil sin sensor y para tests).
  Future<void> addManualSteps(int count) async {
    await _rollDayIfNeeded();
    _todaySteps += count;
    await _persist();
    notifyListeners();
  }

  void _onEvent(({double x, double y, double z}) e) {
    final magnitude = math.sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
    if (magnitude < rearmThreshold) {
      _armed = true;
      return;
    }
    if (!_armed || magnitude < stepThreshold) return;
    final now = _clock();
    final last = _lastStepAt;
    if (last != null && now.difference(last) < minStepInterval) return;
    _armed = false;
    _lastStepAt = now;
    unawaited(_registerStep(now));
  }

  Future<void> _registerStep(DateTime now) async {
    await _rollDayIfNeeded();
    _todaySteps++;
    if (_todaySteps % persistEvery == 0) await _persist();
    notifyListeners();
  }

  Future<void> _rollDayIfNeeded() async {
    final key = DateUtilsX.dayKey(_clock());
    if (_currentDay.isEmpty) {
      _currentDay = key;
      return;
    }
    if (key != _currentDay) {
      await _persist();
      _currentDay = key;
      _todaySteps = 0;
    }
  }

  Future<void> _persist() async {
    if (_currentDay.isEmpty) return;
    try {
      await _repository.upsert(
        StepRecord(day: _currentDay, steps: _todaySteps),
      );
      _history = await _repository.getAll();
    } catch (e) {
      _error = 'No se pudieron guardar los pasos: $e';
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
