/// Utilidades de fechas.
class DateUtilsX {
  const DateUtilsX._();

  /// Medianoche del día de [d].
  static DateTime startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Lunes 00:00 de la semana de [d].
  static DateTime startOfWeek(DateTime d) {
    final day = startOfDay(d);
    return DateTime(day.year, day.month, day.day - (day.weekday - 1));
  }

  /// Medianoche del día siguiente a [d].
  static DateTime endOfDayExclusive(DateTime d) {
    final day = startOfDay(d);
    return DateTime(day.year, day.month, day.day + 1);
  }

  /// Clave 'yyyy-MM-dd'.
  static String dayKey(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year.toString().padLeft(4, '0')}-$m-$dd';
  }

  /// Convierte una clave 'yyyy-MM-dd' en fecha.
  static DateTime fromDayKey(String key) {
    final p = key.split('-');
    return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
  }

  /// Indica si [a] y [b] son el mismo día.
  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Últimos [n] días (el más antiguo primero) terminando en [today].
  static List<DateTime> lastDays(int n, {DateTime? today}) {
    final t = startOfDay(today ?? DateTime.now());
    return [
      for (var i = n - 1; i >= 0; i--) DateTime(t.year, t.month, t.day - i),
    ];
  }
}
