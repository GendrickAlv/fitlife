import 'package:intl/intl.dart';

/// Formateadores con locale 'es'.
class Fmt {
  const Fmt._();

  static const _locale = 'es';

  /// 25 nov 2026
  static String date(DateTime d) => DateFormat.yMMMd(_locale).format(d);

  /// 25 nov 2026, 18:30
  static String dateTime(DateTime d) =>
      DateFormat.yMMMd(_locale).add_Hm().format(d);

  /// lun 25
  static String shortDay(DateTime d) => DateFormat('EEE d', _locale).format(d);

  /// Inicial del día de la semana (L, M, X...).
  static String weekdayInitial(DateTime d) =>
      DateFormat.E(_locale).format(d).substring(0, 1).toUpperCase();

  /// 72,5 kg
  static String kg(double v) =>
      '${NumberFormat('#,##0.0', _locale).format(v)} kg';

  /// 250 ml
  static String ml(int v) =>
      '${NumberFormat.decimalPattern(_locale).format(v)} ml';

  /// 2,5 L (recibe mililitros).
  static String liters(num ml) =>
      '${NumberFormat('#,##0.0#', _locale).format(ml / 1000)} L';

  /// Entero con separador de miles.
  static String integer(num v) =>
      NumberFormat.decimalPattern(_locale).format(v.round());
}
