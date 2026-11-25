/// Sesión de entrenamiento realizada (tabla `activities`).
class Activity {
  /// Crea una actividad.
  const Activity({
    this.id,
    this.routineId,
    required this.title,
    required this.category,
    required this.durationMinutes,
    required this.calories,
    required this.date,
    this.notes = '',
    this.feeling = 3,
  });

  final int? id;
  final int? routineId;
  final String title;
  final String category;
  final int durationMinutes;
  final int calories;
  final DateTime date;
  final String notes;

  /// Sensación de 1 a 5.
  final int feeling;

  /// Copia con cambios.
  Activity copyWith({
    int? id,
    int? routineId,
    String? title,
    String? category,
    int? durationMinutes,
    int? calories,
    DateTime? date,
    String? notes,
    int? feeling,
  }) => Activity(
    id: id ?? this.id,
    routineId: routineId ?? this.routineId,
    title: title ?? this.title,
    category: category ?? this.category,
    durationMinutes: durationMinutes ?? this.durationMinutes,
    calories: calories ?? this.calories,
    date: date ?? this.date,
    notes: notes ?? this.notes,
    feeling: feeling ?? this.feeling,
  );

  /// Mapa para SQLite.
  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'routine_id': routineId,
    'title': title,
    'category': category,
    'duration_minutes': durationMinutes,
    'calories': calories,
    'date': date.millisecondsSinceEpoch,
    'notes': notes,
    'feeling': feeling,
  };

  /// Crea desde una fila de SQLite.
  factory Activity.fromMap(Map<String, Object?> map) => Activity(
    id: map['id'] as int?,
    routineId: map['routine_id'] as int?,
    title: map['title'] as String,
    category: map['category'] as String,
    durationMinutes: map['duration_minutes'] as int,
    calories: map['calories'] as int,
    date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
    notes: (map['notes'] as String?) ?? '',
    feeling: (map['feeling'] as int?) ?? 3,
  );
}
