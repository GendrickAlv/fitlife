import 'package:fitlife/core/utils/date_utils.dart';
import 'package:fitlife/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
