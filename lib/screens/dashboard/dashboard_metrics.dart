import '../../core/utils/date_utils.dart';
import '../../data/models/activity.dart';

/// Calcula la racha de días consecutivos con al menos una actividad.
///
/// La racha termina hoy; si hoy todavía no hay actividad, se cuenta desde
/// ayer (para no perder la racha antes de entrenar). [today] permite fijar la
/// fecha de referencia en tests.
int activeDayStreak(Iterable<Activity> activities, {DateTime? today}) {
  final days = <String>{for (final a in activities) DateUtilsX.dayKey(a.date)};
  if (days.isEmpty) return 0;
  var cursor = DateUtilsX.startOfDay(today ?? DateTime.now());
  if (!days.contains(DateUtilsX.dayKey(cursor))) {
    cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
  }
  var streak = 0;
  while (days.contains(DateUtilsX.dayKey(cursor))) {
    streak++;
    cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
  }
  return streak;
}

/// Saludo según la hora del día.
String greetingForHour(int hour) {
  if (hour < 6) return 'Buenas noches';
  if (hour < 13) return 'Buenos días';
  if (hour < 20) return 'Buenas tardes';
  return 'Buenas noches';
}
