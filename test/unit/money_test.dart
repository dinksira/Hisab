import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/money/money.dart';

void main() {
  group('Money domain tests', () {
    test('Exact decimal arithmetic prevents IEEE-754 precision errors', () {
      final a = Money.parse('0.10', 'USD');
      final b = Money.parse('0.20', 'USD');
      final sum = a + b;

      expect(sum.amount, equals(Decimal.parse('0.30')));
      expect(sum.toString(), equals('0.3 USD'));
    });

    test('Prevents arithmetic between incompatible currencies', () {
      final usd = Money.fromNum(100, 'USD');
      final eur = Money.fromNum(100, 'EUR');

      expect(() => usd + eur, throwsArgumentError);
      expect(() => usd - eur, throwsArgumentError);
      expect(() => usd.compareTo(eur), throwsArgumentError);
    });

    test('Handles multiplication and division correctly', () {
      final m = Money.fromNum(150, 'USD');
      final doubled = m.multiply(2);
      expect(doubled, equals(Money.fromNum(300, 'USD')));

      final half = m.divide(2);
      expect(half, equals(Money.fromNum(75, 'USD')));
    });

    test('Division by zero throws ArgumentError', () {
      final m = Money.fromNum(100, 'USD');
      expect(() => m.divide(0), throwsArgumentError);
    });

    test('Minor units calculation for various currencies', () {
      final usd = Money.parse('12.50', 'USD');
      expect(usd.minorUnits, equals(1250));

      final bhd = Money.parse('5.250', 'BHD');
      expect(bhd.minorUnits, equals(5250));

      final jpy = Money.parse('1500', 'JPY');
      expect(jpy.minorUnits, equals(1500));
    });

    test('Formatting produces standard currency representations', () {
      final m = Money.parse('1250.50', 'USD');
      final formatted = m.formatted(includeSymbol: true, locale: 'en_US');
      expect(formatted, contains('1,250.50'));
    });

    test('JSON serialization round-trip', () {
      final original = Money.parse('499.99', 'EUR');
      final json = original.toJson();
      final restored = Money.fromJson(json);

      expect(restored, equals(original));
      expect(restored.currency, equals('EUR'));
    });
  });
}
