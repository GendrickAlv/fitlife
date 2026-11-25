import 'package:fitlife/core/utils/date_utils.dart';
import 'package:fitlife/core/utils/formatters.dart';
import 'package:fitlife/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('es'));

  group('Fmt', () {
    test('plural usa singular solo con 1', () {
      expect(Fmt.plural(0, 'ejercicio', 'ejercicios'), '0 ejercicios');
      expect(Fmt.plural(1, 'ejercicio', 'ejercicios'), '1 ejercicio');
      expect(Fmt.plural(3, 'ejercicio', 'ejercicios'), '3 ejercicios');
      expect(Fmt.plural(1500, 'paso', 'pasos'), '1.500 pasos');
    });
    test('decimal usa coma y separador de miles', () {
      expect(Fmt.decimal(60.5), '60,5');
      expect(Fmt.decimal(20.0), '20');
      expect(Fmt.decimal(0.8), '0,8');
      expect(Fmt.decimal(6500), '6.500');
      expect(Fmt.decimal(0.25, maxDecimals: 2), '0,25');
      expect(Fmt.decimal(2.6, maxDecimals: 0), '3');
    });
    test('mensaje de rango de validators usa coma', () {
      expect(
        Validators.numberInRange(0.5, 20)('99'),
        'Debe estar entre 0,5 y 20',
      );
    });
  });

  group('Validators', () {
    test('required', () {
      expect(Validators.required(null), isNotNull);
      expect(Validators.required('  '), isNotNull);
      expect(Validators.required('a'), isNull);
    });
    test('positiveNumber acepta coma y punto', () {
      expect(Validators.positiveNumber('72,5'), isNull);
      expect(Validators.positiveNumber('72.5'), isNull);
      expect(Validators.positiveNumber('0'), isNotNull);
      expect(Validators.positiveNumber('-3'), isNotNull);
      expect(Validators.positiveNumber('abc'), isNotNull);
      expect(Validators.positiveNumber(''), isNotNull);
    });
    test('numberInRange', () {
      final v = Validators.numberInRange(20, 300);
      expect(v('70,5'), isNull);
      expect(v('10'), isNotNull);
      expect(v('301'), isNotNull);
      expect(v('x'), isNotNull);
    });
    test('maxLength', () {
      expect(Validators.maxLength(3)('abcd'), isNotNull);
      expect(Validators.maxLength(3)('abc'), isNull);
      expect(Validators.maxLength(3)(null), isNull);
    });
  });

  group('DateUtilsX', () {
    test('startOfWeek es lunes', () {
      // 2026-11-25 es miércoles
      expect(
        DateUtilsX.startOfWeek(DateTime(2026, 11, 25, 15)),
        DateTime(2026, 11, 23),
      );
      expect(
        DateUtilsX.startOfWeek(DateTime(2026, 11, 29)),
        DateTime(2026, 11, 23),
      );
      expect(
        DateUtilsX.startOfWeek(DateTime(2026, 11, 23)),
        DateTime(2026, 11, 23),
      );
    });
    test('startOfWeek cruzando mes', () {
      expect(
        DateUtilsX.startOfWeek(DateTime(2026, 12, 2)),
        DateTime(2026, 11, 30),
      );
    });
    test('dayKey y fromDayKey', () {
      expect(DateUtilsX.dayKey(DateTime(2026, 3, 4, 23)), '2026-03-04');
      expect(DateUtilsX.fromDayKey('2026-03-04'), DateTime(2026, 3, 4));
    });
    test('isSameDay y lastDays', () {
      expect(
        DateUtilsX.isSameDay(DateTime(2026, 1, 1, 1), DateTime(2026, 1, 1, 23)),
        true,
      );
      final days = DateUtilsX.lastDays(3, today: DateTime(2026, 3, 1));
      expect(days.first, DateTime(2026, 2, 27));
      expect(days.last, DateTime(2026, 3, 1));
    });
  });
}
