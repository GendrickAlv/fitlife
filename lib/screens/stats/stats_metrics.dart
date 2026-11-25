import '../../data/models/activity.dart';

/// Intervalo entre etiquetas del eje X para que no se solapen.
///
/// Con [count] puntos devuelve cada cuántos índices se muestra una etiqueta.
int labelInterval(int count) {
  if (count <= 7) return 1;
  if (count <= 14) return 2;
  return 5;
}

/// Número de sesiones por categoría, ordenado de mayor a menor.
List<MapEntry<String, int>> sessionsByCategory(Iterable<Activity> activities) {
  final counts = <String, int>{};
  for (final a in activities) {
    counts[a.category] = (counts[a.category] ?? 0) + 1;
  }
  return counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
}

/// Actividades dentro de [days] (inclusive) terminando en [today].
List<Activity> activitiesInPeriod(Iterable<Activity> all, List<DateTime> days) {
  if (days.isEmpty) return const [];
  final from = days.first;
  final to = DateTime(days.last.year, days.last.month, days.last.day + 1);
  return all
      .where((a) => !a.date.isBefore(from) && a.date.isBefore(to))
      .toList();
}
