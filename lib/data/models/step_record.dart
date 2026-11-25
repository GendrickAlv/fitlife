/// Pasos de un día (tabla `step_records`).
class StepRecord {
  /// Crea un registro de pasos.
  const StepRecord({this.id, required this.day, required this.steps});

  final int? id;

  /// Día con formato 'yyyy-MM-dd'.
  final String day;
  final int steps;

  /// Copia con cambios.
  StepRecord copyWith({int? id, String? day, int? steps}) => StepRecord(
    id: id ?? this.id,
    day: day ?? this.day,
    steps: steps ?? this.steps,
  );

  /// Mapa para SQLite.
  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'day': day,
    'steps': steps,
  };

  /// Crea desde una fila de SQLite.
  factory StepRecord.fromMap(Map<String, Object?> map) => StepRecord(
    id: map['id'] as int?,
    day: map['day'] as String,
    steps: map['steps'] as int,
  );
}
