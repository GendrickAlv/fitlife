/// Registro de peso (tabla `weight_entries`).
class WeightEntry {
  /// Crea un registro de peso.
  const WeightEntry({
    this.id,
    required this.weightKg,
    required this.date,
    this.note = '',
  });

  final int? id;
  final double weightKg;
  final DateTime date;
  final String note;

  /// Copia con cambios.
  WeightEntry copyWith({
    int? id,
    double? weightKg,
    DateTime? date,
    String? note,
  }) => WeightEntry(
    id: id ?? this.id,
    weightKg: weightKg ?? this.weightKg,
    date: date ?? this.date,
    note: note ?? this.note,
  );

  /// Mapa para SQLite.
  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'weight_kg': weightKg,
    'date': date.millisecondsSinceEpoch,
    'note': note,
  };

  /// Crea desde una fila de SQLite.
  factory WeightEntry.fromMap(Map<String, Object?> map) => WeightEntry(
    id: map['id'] as int?,
    weightKg: (map['weight_kg'] as num).toDouble(),
    date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
    note: (map['note'] as String?) ?? '',
  );
}
