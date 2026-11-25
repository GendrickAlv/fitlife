import '../../core/constants.dart';

/// Desafío semanal (tabla `challenges`). El progreso no se guarda.
class Challenge {
  /// Crea un desafío.
  const Challenge({
    this.id,
    required this.title,
    this.description = '',
    required this.type,
    required this.target,
    required this.weekStart,
    required this.createdAt,
  });

  final int? id;
  final String title;
  final String description;
  final ChallengeType type;
  final double target;

  /// Lunes 00:00 de la semana del desafío.
  final DateTime weekStart;
  final DateTime createdAt;

  /// Copia con cambios.
  Challenge copyWith({
    int? id,
    String? title,
    String? description,
    ChallengeType? type,
    double? target,
    DateTime? weekStart,
    DateTime? createdAt,
  }) => Challenge(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description ?? this.description,
    type: type ?? this.type,
    target: target ?? this.target,
    weekStart: weekStart ?? this.weekStart,
    createdAt: createdAt ?? this.createdAt,
  );

  /// Mapa para SQLite.
  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'title': title,
    'description': description,
    'type': type.name,
    'target': target,
    'week_start': weekStart.millisecondsSinceEpoch,
    'created_at': createdAt.millisecondsSinceEpoch,
  };

  /// Crea desde una fila de SQLite.
  factory Challenge.fromMap(Map<String, Object?> map) => Challenge(
    id: map['id'] as int?,
    title: map['title'] as String,
    description: (map['description'] as String?) ?? '',
    type: ChallengeType.values.byName(map['type'] as String),
    target: (map['target'] as num).toDouble(),
    weekStart: DateTime.fromMillisecondsSinceEpoch(map['week_start'] as int),
    createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
  );
}
