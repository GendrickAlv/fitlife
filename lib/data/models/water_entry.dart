/// Registro de agua (tabla `water_entries`).
class WaterEntry {
  /// Crea un registro de agua.
  const WaterEntry({this.id, required this.amountMl, required this.date});

  final int? id;
  final int amountMl;
  final DateTime date;

  /// Copia con cambios.
  WaterEntry copyWith({int? id, int? amountMl, DateTime? date}) => WaterEntry(
    id: id ?? this.id,
    amountMl: amountMl ?? this.amountMl,
    date: date ?? this.date,
  );

  /// Mapa para SQLite.
  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'amount_ml': amountMl,
    'date': date.millisecondsSinceEpoch,
  };

  /// Crea desde una fila de SQLite.
  factory WaterEntry.fromMap(Map<String, Object?> map) => WaterEntry(
    id: map['id'] as int?,
    amountMl: map['amount_ml'] as int,
    date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
  );
}
